package com.microsoft.migration.assets.config;

import com.azure.core.credential.TokenCredential;
import com.azure.core.exception.ResourceExistsException;
import com.azure.core.exception.ResourceNotFoundException;
import com.azure.messaging.servicebus.administration.ServiceBusAdministrationClient;
import com.azure.messaging.servicebus.administration.ServiceBusAdministrationClientBuilder;
import com.azure.messaging.servicebus.administration.models.QueueProperties;
import com.azure.spring.cloud.autoconfigure.implementation.servicebus.properties.AzureServiceBusProperties;
import com.azure.spring.messaging.ConsumerIdentifier;
import com.azure.spring.messaging.PropertiesSupplier;
import com.azure.spring.messaging.servicebus.core.properties.ProcessorProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitConfig {
    public static final String IMAGE_PROCESSING_QUEUE = "image-processing";

    @Bean
    public ServiceBusAdministrationClient adminClient(AzureServiceBusProperties properties, TokenCredential credential) {
        return new ServiceBusAdministrationClientBuilder()
            .credential(properties.getFullyQualifiedNamespace(), credential)
            .buildClient();
    }


    @Bean
    public QueueProperties imageProcessingQueue(ServiceBusAdministrationClient adminClient) {
        QueueProperties queue;
        try {
            queue = adminClient.getQueue(IMAGE_PROCESSING_QUEUE);
        } catch (ResourceNotFoundException e) {
            try {
                queue = adminClient.createQueue(IMAGE_PROCESSING_QUEUE);
            } catch (ResourceExistsException ex) {
                // Queue was created by another instance in the meantime
                queue = adminClient.getQueue(IMAGE_PROCESSING_QUEUE);
            }
        }
        return queue;
    }

    @Bean
    public PropertiesSupplier<ConsumerIdentifier, ProcessorProperties> propertiesSupplier() {
        return identifier -> {
            ProcessorProperties processorProperties = new ProcessorProperties();
            processorProperties.setAutoComplete(false);
            return processorProperties;
        };
    }
}
