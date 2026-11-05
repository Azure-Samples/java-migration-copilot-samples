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
public class ServiceBusConfig {
    public static final String IMAGE_PROCESSING_QUEUE = "image-processing";

    @Bean
    public ServiceBusAdministrationClient serviceBusAdministrationClient(
            AzureServiceBusProperties properties, TokenCredential credential) {
        return new ServiceBusAdministrationClientBuilder()
                .credential(properties.getFullyQualifiedNamespace(), credential)
                .buildClient();
    }

    @Bean
    public QueueProperties imageProcessingQueue(ServiceBusAdministrationClient adminClient) {
        try {
            return adminClient.getQueue(IMAGE_PROCESSING_QUEUE);
        } catch (ResourceNotFoundException e) {
            try {
                return adminClient.createQueue(IMAGE_PROCESSING_QUEUE);
            } catch (ResourceExistsException ex) {
                return adminClient.getQueue(IMAGE_PROCESSING_QUEUE);
            }
        }
    }

    @Bean
    public PropertiesSupplier<ConsumerIdentifier, ProcessorProperties> processorPropertiesSupplier() {
        return identifier -> {
            ProcessorProperties properties = new ProcessorProperties();
            properties.setAutoComplete(false);
            return properties;
        };
    }
}
