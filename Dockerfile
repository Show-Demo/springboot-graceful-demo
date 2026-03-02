# syntax=docker/dockerfile:1

# docker build -t graceful-demo:latest .
FROM maven:3.9.9-eclipse-temurin-17 AS builder
WORKDIR /app

COPY pom.xml /app/pom.xml
COPY src /app/src
RUN mvn -q -DskipTests clean package

FROM eclipse-temurin:17-jre-jammy

RUN apt-get update \
    && apt-get install -y --no-install-recommends tini \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app/target/springboot-graceful-demo-0.0.1-SNAPSHOT.jar /app/app.jar
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENV TZ=Asia/Shanghai
EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "--", "/app/entrypoint.sh"]
