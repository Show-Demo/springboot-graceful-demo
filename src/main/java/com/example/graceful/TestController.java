package com.example.graceful;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class TestController {

    @GetMapping("/hello")
    public String hello() throws InterruptedException {
        System.out.println("Received request, simulating 10秒处理...");
        // 模拟处理耗时
        Thread.sleep(10000);
        System.out.println("Hello, world!");
        return "Hello, world!";
    }
}
