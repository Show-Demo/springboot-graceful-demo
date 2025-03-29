# docker build -t graceful-demo .
# 第一阶段：构建阶段，使用 Maven 和 JDK 17
FROM maven:3.8.5-openjdk-17 AS builder
WORKDIR /app
COPY . /app
RUN mvn clean package -DskipTests

# 第二阶段：运行阶段，使用轻量级 JDK 镜像，并安装 tini
FROM openjdk:17-slim

# 安装 tini
RUN apt-get update && \
    apt-get install -y tini procps && \
    rm -rf /var/lib/apt/lists/*

# 将构建好的 jar 包复制到镜像中
COPY --from=builder /app/target/springboot-graceful-demo-0.0.1-SNAPSHOT.jar /app/app.jar

# 复制 entrypoint.sh 到容器中，并确保有可执行权限
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# 设置时区（可选）
ENV TZ=Asia/Shanghai

# 暴露端口
EXPOSE 8080

# 使用 tini 作为 init 进程启动应用，确保信号正确转发
#ENTRYPOINT ["/usr/bin/tini", "--", "java", "-jar", "/app/app.jar"]
#ENTRYPOINT ["sh", "-c", "java -jar /app/app.jar"]
# 直接使用 entrypoint.sh 启动应用（不使用 tini）
ENTRYPOINT ["/app/entrypoint.sh"]
# 使用 tini 作为 init 进程，并执行 entrypoint.sh
#ENTRYPOINT ["/usr/bin/tini", "--", "/app/entrypoint.sh"]