package com.example.graceful;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class GracefulShutdownDemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(GracefulShutdownDemoApplication.class, args);
        System.out.println("Application started...");
    }
}
