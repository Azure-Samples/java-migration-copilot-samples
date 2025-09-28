package com.microsoft.migration.assets.worker.config;

import com.azure.core.credential.TokenCredential;
import com.azure.core.exception.ResourceNotFoundException;
import com.azure.messaging.servicebus.administration.ServiceBusAdministrationClient;
import com.azure.messaging.servicebus.administration.ServiceBusAdministrationClientBuilder;
import com.azure.messaging.servicebus.administration.models.CreateRuleOptions;
import com.azure.messaging.servicebus.administration.models.CreateSubscriptionOptions;
import com.azure.messaging.servicebus.administration.models.CorrelationRuleFilter;
import com.azure.messaging.servicebus.administration.models.SubscriptionProperties;
import com.azure.messaging.servicebus.administration.models.TopicProperties;
import com.azure.spring.cloud.autoconfigure.implementation.servicebus.properties.AzureServiceBusProperties;
import com.azure.spring.messaging.implementation.annotation.EnableAzureMessaging;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.DependsOn;

@Configuration
@EnableAzureMessaging
public class ServiceBusConfig { // Renamed to reflect Azure Service Bus configuration
    public static final String IMAGE_PROCESSING_TOPIC = "image-processing"; // primary processing topic
    public static final String IMAGE_PROCESSING_SUBSCRIPTION = "image-processing"; // primary subscription

    public static final String RETRY_TOPIC = "image-processing-retry"; // retry topic (mapped from previous retry exchange)
    public static final String RETRY_SUBSCRIPTION = "image-processing-retry"; // retry subscription (mapped from previous retry queue)
    public static final String RETRY_ROUTING_KEY = "retry"; // used as label filter

    @Bean
    public ServiceBusAdministrationClient adminClient(AzureServiceBusProperties properties, TokenCredential credential) {
        return new ServiceBusAdministrationClientBuilder()
                .credential(properties.getFullyQualifiedNamespace(), credential)
                .buildClient();
    }

    // Primary topic
    @Bean
    public TopicProperties imageProcessingTopic(ServiceBusAdministrationClient adminClient) {
        try {
            return adminClient.getTopic(IMAGE_PROCESSING_TOPIC);
        } catch (ResourceNotFoundException e) {
            return adminClient.createTopic(IMAGE_PROCESSING_TOPIC);
        }
    }

    // Retry topic
    @Bean
    public TopicProperties retryTopic(ServiceBusAdministrationClient adminClient) {
        try {
            return adminClient.getTopic(RETRY_TOPIC);
        } catch (ResourceNotFoundException e) {
            return adminClient.createTopic(RETRY_TOPIC);
        }
    }

    // Primary subscription
    @Bean
    @DependsOn("imageProcessingTopic")
    public SubscriptionProperties imageProcessingSubscription(ServiceBusAdministrationClient adminClient) {
        try {
            return adminClient.getSubscription(IMAGE_PROCESSING_TOPIC, IMAGE_PROCESSING_SUBSCRIPTION);
        } catch (ResourceNotFoundException e) {
            return adminClient.createSubscription(IMAGE_PROCESSING_TOPIC, IMAGE_PROCESSING_SUBSCRIPTION);
        }
    }

    // Retry subscription with rule matching 'retry' as label (mapping previous routing key concept)
    @Bean
    @DependsOn("retryTopic")
    public SubscriptionProperties retrySubscription(ServiceBusAdministrationClient adminClient) {
        try {
            return adminClient.getSubscription(RETRY_TOPIC, RETRY_SUBSCRIPTION);
        } catch (ResourceNotFoundException e) {
            CorrelationRuleFilter ruleFilter = new CorrelationRuleFilter();
            ruleFilter.setLabel(RETRY_ROUTING_KEY);
            CreateRuleOptions ruleOptions = new CreateRuleOptions().setFilter(ruleFilter);
            return adminClient.createSubscription(RETRY_TOPIC, RETRY_SUBSCRIPTION, "RouteKey", new CreateSubscriptionOptions(), ruleOptions);
        }
    }
}
