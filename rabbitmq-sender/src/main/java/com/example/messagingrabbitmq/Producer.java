package com.example.messagingrabbitmq;

import org.springframework.messaging.Message;
import org.springframework.stereotype.Component;
import com.azure.spring.messaging.servicebus.core.ServiceBusTemplate;
import org.springframework.messaging.support.MessageBuilder;
import org.springframework.beans.factory.annotation.Autowired;

@Component
public class Producer {

    @Autowired
    private final ServiceBusTemplate serviceBusTemplate;

    public Producer(ServiceBusTemplate serviceBusTemplate) {
        this.serviceBusTemplate = serviceBusTemplate;
    }

    public void run()  {
        for (int i = 0; i < 10; i++) {
            System.out.println("Sending message..."+i);
            String responseString = "test "+i;
            Message<String> responseMessage = MessageBuilder.withPayload(responseString)
                    .build();
            if (i % 2 == 0) {
                serviceBusTemplate.send(MessagingRabbitmqApplication.queueName2, responseMessage);
            } else {
                serviceBusTemplate.send(MessagingRabbitmqApplication.queueName1, responseMessage);
            }
        }
    }
}