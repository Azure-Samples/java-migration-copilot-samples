package com.microsoft.migration.assets.config;

import org.springframework.amqp.core.AcknowledgeMode;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.QueueBuilder;
import org.springframework.amqp.rabbit.config.SimpleRabbitListenerContainerFactory;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.boot.autoconfigure.amqp.SimpleRabbitListenerContainerFactoryConfigurer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.Duration;

@Configuration
public class RabbitConfig {
    public static final String IMAGE_PROCESSING_QUEUE = "image-processing";

    @Bean
    public Queue imageProcessingQueue() {
        return QueueBuilder.durable(IMAGE_PROCESSING_QUEUE)
        .build();
    }

    @Bean
    public QueueProperties imageProcessingQueue(ServiceBusAdministrationClient adminClient, QueueProperties retryQueue) {
        QueueProperties queue;
        try {
            queue = adminClient.getQueue(IMAGE_PROCESSING_QUEUE);
        } catch (ResourceNotFoundException e) {
            try {
                CreateQueueOptions options = new CreateQueueOptions()
                    .setForwardDeadLetteredMessagesTo(RETRY_QUEUE);
                queue = adminClient.createQueue(IMAGE_PROCESSING_QUEUE, options);
            } catch (ResourceExistsException ex) {
                // Queue was created by another instance in the meantime
                queue = adminClient.getQueue(IMAGE_PROCESSING_QUEUE);
            }
        }
        
        // Configure retry queue's DLQ forwarding now that image processing queue exists
        try {
            retryQueue.setForwardDeadLetteredMessagesTo(IMAGE_PROCESSING_QUEUE);
            adminClient.updateQueue(retryQueue);
        } catch (Exception ex) {
            // Ignore update errors since basic functionality will still work
        }
        
        return queue;
    }

    @Bean
    public SimpleRabbitListenerContainerFactory rabbitListenerContainerFactory(
            ConnectionFactory connectionFactory,
            SimpleRabbitListenerContainerFactoryConfigurer configurer) {
        SimpleRabbitListenerContainerFactory factory = new SimpleRabbitListenerContainerFactory();
        configurer.configure(factory, connectionFactory);
        factory.setMessageConverter(jsonMessageConverter());
        factory.setAcknowledgeMode(AcknowledgeMode.MANUAL);
        return factory;
    }
}
