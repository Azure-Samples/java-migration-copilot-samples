package com.microsoft.migration.assets.worker.config;

import com.microsoft.migration.assets.worker.service.AzureBlobFileProcessingService;
import com.microsoft.migration.assets.worker.service.S3FileProcessingService;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Integration test to verify that the feature flag correctly routes requests
 * to the appropriate storage service implementation.
 */
public class StorageProviderFeatureFlagTest {

    private final ApplicationContextRunner contextRunner = new ApplicationContextRunner()
            .withUserConfiguration(TestConfiguration.class);

    @Test
    void whenAzureFlagIsFalse_thenS3ServiceIsLoaded() {
        contextRunner
                .withPropertyValues(
                        "storage.provider.use-azure=false",
                        "aws.s3.bucket=test-bucket",
                        "aws.accessKeyId=test-key",
                        "aws.secretKey=test-secret",
                        "aws.region=us-east-1",
                        "spring.profiles.active=test"
                )
                .run(context -> {
                    // When storage.provider.use-azure is false, S3FileProcessingService should be present
                    assertThat(context).hasSingleBean(S3FileProcessingService.class);
                    // Azure service should NOT be present
                    assertThat(context).doesNotHaveBean(AzureBlobFileProcessingService.class);
                });
    }

    @Test
    void whenAzureFlagIsTrue_thenAzureServiceIsLoaded() {
        contextRunner
                .withPropertyValues(
                        "storage.provider.use-azure=true",
                        "azure.storage.endpoint=https://testaccount.blob.core.windows.net",
                        "azure.storage.container=test-container",
                        "spring.profiles.active=test"
                )
                .run(context -> {
                    // When storage.provider.use-azure is true, AzureBlobFileProcessingService should be present
                    assertThat(context).hasSingleBean(AzureBlobFileProcessingService.class);
                    // S3 service should NOT be present
                    assertThat(context).doesNotHaveBean(S3FileProcessingService.class);
                });
    }

    @Test
    void whenAzureFlagIsNotSet_thenS3ServiceIsLoadedByDefault() {
        contextRunner
                .withPropertyValues(
                        "aws.s3.bucket=test-bucket",
                        "aws.accessKeyId=test-key",
                        "aws.secretKey=test-secret",
                        "aws.region=us-east-1",
                        "spring.profiles.active=test"
                )
                .run(context -> {
                    // When flag is not set, S3FileProcessingService should be loaded by default
                    assertThat(context).hasSingleBean(S3FileProcessingService.class);
                    // Azure service should NOT be present
                    assertThat(context).doesNotHaveBean(AzureBlobFileProcessingService.class);
                });
    }

    /**
     * Test configuration that provides minimal beans needed for the test.
     * This avoids loading the full application context.
     */
    @Configuration
    static class TestConfiguration {
        // Mock beans that would normally be provided by Spring Boot auto-configuration
        @Bean
        public com.microsoft.migration.assets.worker.repository.ImageMetadataRepository imageMetadataRepository() {
            return org.mockito.Mockito.mock(com.microsoft.migration.assets.worker.repository.ImageMetadataRepository.class);
        }
    }
}
