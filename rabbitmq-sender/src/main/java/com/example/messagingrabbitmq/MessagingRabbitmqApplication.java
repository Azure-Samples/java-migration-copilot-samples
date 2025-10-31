package com.example.messagingrabbitmq;

import com.azure.core.credential.TokenCredential;
import com.azure.core.exception.ResourceNotFoundException;
import com.azure.messaging.servicebus.administration.ServiceBusAdministrationClient;
import com.azure.messaging.servicebus.administration.ServiceBusAdministrationClientBuilder;
import com.azure.messaging.servicebus.administration.models.QueueProperties;
import com.azure.spring.cloud.autoconfigure.implementation.servicebus.properties.AzureServiceBusProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class MessagingRabbitmqApplication {

    static final String queueName1 = "queue1";
    static final String queueName2 = "queue2";

    public static void main(String[] args) throws InterruptedException {
        ConfigurableApplicationContext applicationContext = SpringApplication.run(MessagingRabbitmqApplication.class);
        Producer producer = applicationContext.getBean(Producer.class);
        producer.run();
    }

    @Bean
    ServiceBusAdministrationClient serviceBusAdministrationClient(
        AzureServiceBusProperties properties,
        TokenCredential credential) {
        return new ServiceBusAdministrationClientBuilder()
            .credential(properties.getFullyQualifiedNamespace(), credential)
            .buildClient();
    }

    @Bean
    QueueProperties queue1(ServiceBusAdministrationClient adminClient) {
        try {
            return adminClient.getQueue(queueName1);
        } catch (ResourceNotFoundException e) {
            return adminClient.createQueue(queueName1);
        }
    }

    @Bean
    QueueProperties queue2(ServiceBusAdministrationClient adminClient) {
        try {
            return adminClient.getQueue(queueName2);
        } catch (ResourceNotFoundException e) {
            return adminClient.createQueue(queueName2);
        }
    }

}
