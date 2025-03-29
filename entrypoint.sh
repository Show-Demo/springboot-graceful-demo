#!/bin/bash

# 启动 Java 进程，并在后台运行
java -jar /app/app.jar &
app_pid=$!  # 记录 Java 进程的 PID

# 定义信号处理函数
terminate() {
  echo "Received SIGTERM, stopping application..."
  kill -TERM "$app_pid"  # 向 Java 进程发送 SIGTERM 信号
  wait "$app_pid"        # 等待 Java 进程退出
  echo "Application stopped."
  exit 0
}

# 捕获 SIGTERM 信号
trap terminate SIGTERM

# 等待 Java 进程退出
wait "$app_pid"
