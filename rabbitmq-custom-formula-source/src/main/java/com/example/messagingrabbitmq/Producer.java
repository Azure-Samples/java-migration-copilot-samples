package com.example.messagingrabbitmq;

import org.springframework.amqp.core.Message;
import org.springframework.stereotype.Component;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Autowired;

@Component
public class Producer {

    @Autowired
    private final RabbitTemplate rabbitTemplate;

    public Producer(RabbitTemplate rabbitTemplate) {
        this.rabbitTemplate = rabbitTemplate;
    }

    public void run()  {
        for (int i = 0; i < 10; i++) {
            System.out.println("Sending message..." + i);
            String responseString = "test " + i;
            rabbitTemplate.convertAndSend(MessagingRabbitmqApplication.queueName, new Message(responseString.getBytes()));
        }
    }
}