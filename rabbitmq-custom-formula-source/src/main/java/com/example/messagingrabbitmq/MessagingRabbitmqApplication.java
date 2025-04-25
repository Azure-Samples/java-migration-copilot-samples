package com.example.messagingrabbitmq;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.amqp.core.Queue;

@SpringBootApplication
public class MessagingRabbitmqApplication {

    static final String queueName = "queue";

    public static void main(String[] args) throws InterruptedException {
        ConfigurableApplicationContext applicationContext = SpringApplication.run(MessagingRabbitmqApplication.class);
        Producer producer = applicationContext.getBean(Producer.class);
        producer.run();
    }

    @Bean
    public Queue queue() {
        return new Queue(queueName, true);
    }

}
