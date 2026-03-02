# springboot-graceful-demo

Spring Boot + Docker + Kubernetes 优雅下线最小可复现 Demo。

> [!TIP]
> 如果你将 `spring.lifecycle.timeout-per-shutdown-phase=30s`，建议 Kubernetes `terminationGracePeriodSeconds` 设为 `40~60s`，避免应用尚未处理完在途请求时被强制杀死。

## 目标

这个项目演示以下三层链路：

1. Java 应用层：Spring Boot 收到 `SIGTERM` 后进入 graceful shutdown。
2. 容器进程层：`tini` 作为 PID 1，负责信号转发与子进程回收。
3. Kubernetes 编排层：Pod 终止时先摘流、再发 `SIGTERM`、最后等待宽限期。

## Spring Boot 关键配置

```properties
server.shutdown=graceful
spring.lifecycle.timeout-per-shutdown-phase=30s
server.port=8080
```

当前接口 `/hello` 会 sleep 10 秒，用于模拟在途请求。

## 时间配置规律（Java + K8s）

建议按下面的公式配置 Kubernetes 终止宽限期：

`terminationGracePeriodSeconds >= T_prestop + T_app + T_drain + T_margin`

- `T_app`：`spring.lifecycle.timeout-per-shutdown-phase`（应用优雅停机等待时间）
- `T_prestop`：`preStop` 中 sleep 或摘流等待时间
- `T_drain`：流量摘除传播时间（Service/Ingress/mesh），通常 5~10 秒
- `T_margin`：安全余量，建议 5~10 秒

本项目可直接代入：

- `T_app = 30s`
- `T_prestop = 5s`
- `T_drain + T_margin = 10~20s`
- 推荐 `terminationGracePeriodSeconds = 45~60s`（当前示例使用 `60s`）

## 信号链路图（推荐方案）

```mermaid
flowchart LR
  A["kubectl delete pod / 滚动发布"] --> B["Kubelet 终止 Pod"]
  B --> C["从 Service Endpoints 摘除 Pod"]
  C --> D["向容器 PID 1 发送 SIGTERM"]
  D --> E["tini(PID 1) 转发 SIGTERM"]
  E --> F["java -jar app.jar"]
  F --> G["Spring Boot graceful shutdown"]
  G --> H["拒绝新请求，等待在途请求完成"]
  H --> I["进程正常退出"]
  I --> J["宽限期内完成终止"]
```

## 容器启动方式结论

### 推荐

1. `tini + exec java`（本项目采用）
2. 直接 `ENTRYPOINT ["java", "-jar", ...]`（简单场景可用）

### 不推荐

1. `ENTRYPOINT ["sh", "-c", "java -jar ..."]`

`sh -c` 作为 PID 1 时，信号转发行为不稳定，容易导致优雅停机链路失真，不适合做标准示例。

## 本地验证

```bash
# 1) 启动容器
docker build -t graceful-demo:latest .
docker run --rm -p 8080:8080 graceful-demo:latest

# 2) 发起一个慢请求（约 10 秒）
curl http://localhost:8080/hello

# 3) 另一个终端向容器发 SIGTERM
docker kill --signal=SIGTERM <container_id>
```

预期：`/hello` 在在途请求完成后返回，随后应用退出。

## 验证步骤与预期结果

| 步骤 | 操作 | 预期结果 |
|---|---|---|
| 1 | 启动服务后访问 `/health` | 快速返回 `200 OK` |
| 2 | 发起一个 `/hello` 慢请求（10 秒） | 请求保持进行中 |
| 3 | 在第 2 秒执行 `docker kill --signal=SIGTERM <container_id>` 或 `kubectl delete pod <pod-name>` | 应用开始优雅停机，不再接收新请求 |
| 4 | 等待慢请求结束 | `/hello` 正常返回 `200`（不是连接中断/5xx） |
| 5 | 观察容器/Pod 退出 | 在宽限期内退出，K8s 拉起新 Pod 并恢复 Ready |

## Kubernetes 最小示例

已提供可直接应用的清单：`k8s/graceful-demo.yaml`

```bash
kubectl apply -f k8s/graceful-demo.yaml
kubectl get pods -w
```

## 参考

- Spring Boot Graceful Shutdown 官方文档  https://docs.spring.io/spring-boot/docs/2.5.0/reference/htmlsingle/#features.graceful-shutdown
- Kubernetes Pod 生命周期与终止流程  https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-termination
- tini: A tiny but valid init for containers  https://github.com/krallin/tini

- 面试官：SpringBoot如何优雅停机？ https://www.cnblogs.com/vipstone/p/18080968
- Java服务如何优雅的上下线？ https://mp.weixin.qq.com/s/bb3mYDkudxdFe7yslWF3sg
- Pod容器应用"优雅发布 https://www.cnblogs.com/kevingrace/p/13970331.html
- 容器的 1 号进程 https://zhuanlan.zhihu.com/p/665241249
- Docker 容器优雅终止方案 https://www.cnblogs.com/ryanyangcs/p/13036095.html
