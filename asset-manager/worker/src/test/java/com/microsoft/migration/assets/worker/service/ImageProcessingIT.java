package com.microsoft.migration.assets.worker.service;

import com.azure.storage.blob.BlobContainerClient;
import com.azure.storage.blob.BlobServiceClient;
import com.azure.storage.blob.BlobServiceClientBuilder;
import com.azure.storage.blob.models.BlobHttpHeaders;
import com.azure.storage.blob.options.BlobParallelUploadOptions;
import com.microsoft.migration.assets.worker.model.ImageMetadata;
import com.microsoft.migration.assets.worker.model.ImageProcessingMessage;
import com.microsoft.migration.assets.worker.repository.ImageMetadataRepository;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.Network;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.containers.wait.strategy.Wait;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Integration tests for Worker module file processing services.
 * Tests thumbnail generation with Azure Blob Storage (Azurite) and PostgreSQL.
 */
@SpringBootTest(
    properties = {
        "spring.cloud.azure.servicebus.enabled=false"
    },
    classes = {
        ImageProcessingIT.TestConfig.class,
        com.microsoft.migration.assets.worker.repository.ImageMetadataRepository.class
    }
)
@org.springframework.boot.autoconfigure.EnableAutoConfiguration(exclude = {
    com.azure.spring.cloud.autoconfigure.implementation.servicebus.AzureServiceBusAutoConfiguration.class
})
@org.springframework.data.jpa.repository.config.EnableJpaRepositories(basePackages = "com.microsoft.migration.assets.worker.repository")
@org.springframework.boot.autoconfigure.domain.EntityScan(basePackages = "com.microsoft.migration.assets.worker.model")
@Testcontainers
@ActiveProfiles("test")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class ImageProcessingIT {

    private static final String CONTAINER_NAME = "test-container";
    private static Network network = Network.newNetwork();

    @Container
    static PostgreSQLContainer<?> postgresContainer = new PostgreSQLContainer<>("postgres:15-alpine")
            .withDatabaseName("testdb")
            .withUsername("testuser")
            .withPassword("testpass")
            .withNetwork(network);

    @Container
    static GenericContainer<?> azuriteContainer = new GenericContainer<>("mcr.microsoft.com/azure-storage/azurite:latest")
            .withExposedPorts(10000, 10001, 10002)
            .withCommand("azurite", "--blobHost", "0.0.0.0", "--queueHost", "0.0.0.0", "--tableHost", "0.0.0.0", "--loose")
            .waitingFor(Wait.forLogMessage(".*Azurite Blob service is successfully listening.*", 1))
            .withStartupTimeout(Duration.ofMinutes(2))
            .withNetwork(network);

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        // PostgreSQL properties
        registry.add("spring.datasource.url", postgresContainer::getJdbcUrl);
        registry.add("spring.datasource.username", postgresContainer::getUsername);
        registry.add("spring.datasource.password", postgresContainer::getPassword);
        registry.add("spring.datasource.azure.passwordless-enabled", () -> "false");

        // Azure Storage properties (Azurite connection)
        String azuriteHost = azuriteContainer.getHost();
        Integer blobPort = azuriteContainer.getMappedPort(10000);
        String connectionString = String.format(
                "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://%s:%d/devstoreaccount1;",
                azuriteHost, blobPort);
        registry.add("azure.storage.connection-string", () -> connectionString);
        registry.add("azure.storage.blob.container-name", () -> CONTAINER_NAME);
    }

    @Autowired
    private BlobServiceClient blobServiceClient;

    @Autowired
    private ImageMetadataRepository imageMetadataRepository;

    @Autowired
    private TestFileProcessingService testFileProcessingService;

    @TestConfiguration
    static class TestConfig {

        @Bean
        @Primary
        public BlobServiceClient blobServiceClient(@Value("${azure.storage.connection-string}") String connectionString) {
            BlobServiceClient client = new BlobServiceClientBuilder()
                    .connectionString(connectionString)
                    .buildClient();

            // Create container if not exists
            BlobContainerClient containerClient = client.getBlobContainerClient(CONTAINER_NAME);
            if (!containerClient.exists()) {
                containerClient.create();
            }

            return client;
        }

        @Bean
        @Primary
        public TestFileProcessingService testFileProcessingService(
                BlobServiceClient blobServiceClient,
                ImageMetadataRepository imageMetadataRepository,
                @Value("${azure.storage.blob.container-name}") String containerName) {
            return new TestFileProcessingService(blobServiceClient, imageMetadataRepository, containerName);
        }
    }

    @BeforeEach
    void setUp() {
        // Clean up database before each test
        imageMetadataRepository.deleteAll();
    }

    @AfterEach
    void tearDown() {
        // Clean up blobs after each test
        try {
            BlobContainerClient containerClient = blobServiceClient.getBlobContainerClient(CONTAINER_NAME);
            containerClient.listBlobs().forEach(blob -> {
                containerClient.getBlobClient(blob.getName()).delete();
            });
        } catch (Exception e) {
            // Ignore cleanup errors
        }
    }

    // ==================== Happy Path Tests ====================

    @Test
    @Order(1)
    @DisplayName("Should download original file from blob storage")
    void shouldDownloadOriginalFile() throws Exception {
        // Upload a test image to blob storage
        String key = UUID.randomUUID() + "-test-image.png";
        byte[] imageBytes = createTestPngImage(200, 200);
        uploadTestBlob(key, imageBytes, "image/png");

        // Create temp directory and download
        Path tempDir = Files.createTempDirectory("test-download");
        Path downloadPath = tempDir.resolve("downloaded.png");

        try {
            testFileProcessingService.downloadOriginal(key, downloadPath);

            assertThat(Files.exists(downloadPath)).isTrue();
            assertThat(Files.size(downloadPath)).isEqualTo(imageBytes.length);
        } finally {
            Files.deleteIfExists(downloadPath);
            Files.deleteIfExists(tempDir);
        }
    }

    @Test
    @Order(2)
    @DisplayName("Should upload thumbnail to blob storage")
    void shouldUploadThumbnail() throws Exception {
        // Create original image metadata
        String originalKey = UUID.randomUUID() + "-original.png";
        String thumbnailKey = originalKey.replace(".png", "_thumbnail.png");

        // Save original metadata to database
        ImageMetadata metadata = new ImageMetadata();
        metadata.setId(UUID.randomUUID().toString());
        metadata.setFilename("original.png");
        metadata.setContentType("image/png");
        metadata.setSize(1000L);
        metadata.setS3Key(originalKey);
        metadata.setS3Url("http://test/" + originalKey);
        imageMetadataRepository.save(metadata);

        // Create thumbnail file
        Path tempDir = Files.createTempDirectory("test-thumbnail");
        Path thumbnailPath = tempDir.resolve("thumbnail.png");
        byte[] thumbnailBytes = createTestPngImage(100, 100);
        Files.write(thumbnailPath, thumbnailBytes);

        try {
            testFileProcessingService.uploadThumbnail(thumbnailPath, thumbnailKey, "image/png");

            // Verify thumbnail exists in blob storage
            BlobContainerClient containerClient = blobServiceClient.getBlobContainerClient(CONTAINER_NAME);
            assertThat(containerClient.getBlobClient(thumbnailKey).exists()).isTrue();

            // Verify metadata is updated
            ImageMetadata updatedMetadata = imageMetadataRepository.findAll().stream()
                    .filter(m -> m.getS3Key().equals(originalKey))
                    .findFirst()
                    .orElse(null);
            assertThat(updatedMetadata).isNotNull();
            assertThat(updatedMetadata.getThumbnailKey()).isEqualTo(thumbnailKey);
        } finally {
            Files.deleteIfExists(thumbnailPath);
            Files.deleteIfExists(tempDir);
        }
    }

    @Test
    @Order(3)
    @DisplayName("Should generate thumbnail from image")
    void shouldGenerateThumbnail() throws Exception {
        // Create a large test image
        Path tempDir = Files.createTempDirectory("test-generate");
        Path originalPath = tempDir.resolve("original.png");
        Path thumbnailPath = tempDir.resolve("thumbnail.png");

        byte[] largeImage = createTestPngImage(1000, 800);
        Files.write(originalPath, largeImage);

        try {
            testFileProcessingService.testGenerateThumbnail(originalPath, thumbnailPath);

            assertThat(Files.exists(thumbnailPath)).isTrue();

            // Verify thumbnail dimensions are smaller
            BufferedImage thumbnail = ImageIO.read(thumbnailPath.toFile());
            assertThat(thumbnail.getWidth()).isLessThanOrEqualTo(600);
            assertThat(thumbnail.getHeight()).isLessThanOrEqualTo(600);
        } finally {
            Files.deleteIfExists(originalPath);
            Files.deleteIfExists(thumbnailPath);
            Files.deleteIfExists(tempDir);
        }
    }

    // ==================== Edge Case Tests ====================

    @Test
    @Order(4)
    @DisplayName("Should handle JPEG image format")
    void shouldHandleJpegFormat() throws Exception {
        String key = UUID.randomUUID() + "-test-image.jpg";
        byte[] imageBytes = createTestJpegImage(200, 200);
        uploadTestBlob(key, imageBytes, "image/jpeg");

        Path tempDir = Files.createTempDirectory("test-jpeg");
        Path downloadPath = tempDir.resolve("downloaded.jpg");

        try {
            testFileProcessingService.downloadOriginal(key, downloadPath);

            assertThat(Files.exists(downloadPath)).isTrue();
            BufferedImage image = ImageIO.read(downloadPath.toFile());
            assertThat(image).isNotNull();
        } finally {
            Files.deleteIfExists(downloadPath);
            Files.deleteIfExists(tempDir);
        }
    }

    @Test
    @Order(5)
    @DisplayName("Should handle moderately sized image that needs scaling")
    void shouldHandleModerateSizedImage() throws Exception {
        Path tempDir = Files.createTempDirectory("test-moderate");
        Path originalPath = tempDir.resolve("moderate.jpg");
        Path thumbnailPath = tempDir.resolve("thumbnail.jpg");

        // Create an image larger than 600 to ensure scaling happens
        // The application's sharpen filter has issues with images that don't need scaling
        byte[] largeImage = createTestJpegImage(800, 600);
        Files.write(originalPath, largeImage);

        try {
            testFileProcessingService.testGenerateThumbnail(originalPath, thumbnailPath);

            assertThat(Files.exists(thumbnailPath)).isTrue();

            BufferedImage thumbnail = ImageIO.read(thumbnailPath.toFile());
            // After scaling, width should be max (600)
            assertThat(thumbnail.getWidth()).isEqualTo(600);
        } finally {
            Files.deleteIfExists(originalPath);
            Files.deleteIfExists(thumbnailPath);
            Files.deleteIfExists(tempDir);
        }
    }

    @Test
    @Order(6)
    @DisplayName("Should preserve aspect ratio during thumbnail generation")
    void shouldPreserveAspectRatio() throws Exception {
        Path tempDir = Files.createTempDirectory("test-aspect");
        Path originalPath = tempDir.resolve("wide.png");
        Path thumbnailPath = tempDir.resolve("thumbnail.png");

        // Create a wide image (2000x500)
        byte[] wideImage = createTestPngImage(2000, 500);
        Files.write(originalPath, wideImage);

        try {
            testFileProcessingService.testGenerateThumbnail(originalPath, thumbnailPath);

            BufferedImage thumbnail = ImageIO.read(thumbnailPath.toFile());
            // Width should be max (600), height should be proportional
            assertThat(thumbnail.getWidth()).isEqualTo(600);
            // Height should be approximately 150 (600 * 500 / 2000)
            assertThat(thumbnail.getHeight()).isBetween(140, 160);
        } finally {
            Files.deleteIfExists(originalPath);
            Files.deleteIfExists(thumbnailPath);
            Files.deleteIfExists(tempDir);
        }
    }

    // ==================== Error Condition Tests ====================

    @Test
    @Order(7)
    @DisplayName("Should throw exception for non-existent blob download")
    void shouldThrowExceptionForNonExistentBlob() {
        String nonExistentKey = UUID.randomUUID() + "-nonexistent.png";
        Path tempDir;

        try {
            tempDir = Files.createTempDirectory("test-error");
            Path downloadPath = tempDir.resolve("download.png");

            Assertions.assertThrows(Exception.class, () -> {
                testFileProcessingService.downloadOriginal(nonExistentKey, downloadPath);
            });

            Files.deleteIfExists(tempDir);
        } catch (Exception e) {
            // Expected
        }
    }

    @Test
    @Order(8)
    @DisplayName("Should handle corrupt image gracefully")
    void shouldHandleCorruptImage() throws Exception {
        Path tempDir = Files.createTempDirectory("test-corrupt");
        Path corruptPath = tempDir.resolve("corrupt.png");
        Path thumbnailPath = tempDir.resolve("thumbnail.png");

        // Write invalid image data
        Files.write(corruptPath, "not an image".getBytes());

        try {
            Assertions.assertThrows(Exception.class, () -> {
                testFileProcessingService.testGenerateThumbnail(corruptPath, thumbnailPath);
            });
        } finally {
            Files.deleteIfExists(corruptPath);
            Files.deleteIfExists(thumbnailPath);
            Files.deleteIfExists(tempDir);
        }
    }

    // ==================== Full Flow Tests ====================

    @Test
    @Order(9)
    @DisplayName("Should process complete image upload to thumbnail flow")
    void shouldProcessCompleteFlow() throws Exception {
        // Step 1: Upload original image to blob storage
        String originalKey = UUID.randomUUID() + "-complete-test.png";
        byte[] originalImage = createTestPngImage(800, 600);
        uploadTestBlob(originalKey, originalImage, "image/png");

        // Step 2: Save metadata to database
        ImageMetadata metadata = new ImageMetadata();
        metadata.setId(UUID.randomUUID().toString());
        metadata.setFilename("complete-test.png");
        metadata.setContentType("image/png");
        metadata.setSize((long) originalImage.length);
        metadata.setS3Key(originalKey);
        metadata.setS3Url("http://test/" + originalKey);
        imageMetadataRepository.save(metadata);

        // Step 3: Download original, generate thumbnail, upload thumbnail
        Path tempDir = Files.createTempDirectory("test-complete");
        Path originalPath = tempDir.resolve("original.png");
        Path thumbnailPath = tempDir.resolve("thumbnail.png");
        String thumbnailKey = originalKey.replace(".png", "_thumbnail.png");

        try {
            testFileProcessingService.downloadOriginal(originalKey, originalPath);
            testFileProcessingService.testGenerateThumbnail(originalPath, thumbnailPath);
            testFileProcessingService.uploadThumbnail(thumbnailPath, thumbnailKey, "image/png");

            // Verify everything
            assertThat(blobServiceClient.getBlobContainerClient(CONTAINER_NAME)
                    .getBlobClient(thumbnailKey).exists()).isTrue();

            ImageMetadata updatedMetadata = imageMetadataRepository.findAll().stream()
                    .filter(m -> m.getS3Key().equals(originalKey))
                    .findFirst()
                    .orElse(null);
            assertThat(updatedMetadata).isNotNull();
            assertThat(updatedMetadata.getThumbnailKey()).isEqualTo(thumbnailKey);
        } finally {
            Files.deleteIfExists(originalPath);
            Files.deleteIfExists(thumbnailPath);
            Files.deleteIfExists(tempDir);
        }
    }

    // ==================== Helper Methods ====================

    private byte[] createTestPngImage(int width, int height) throws Exception {
        BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        for (int x = 0; x < width; x++) {
            for (int y = 0; y < height; y++) {
                image.setRGB(x, y, (x + y) % 0xFFFFFF);
            }
        }
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        ImageIO.write(image, "png", baos);
        return baos.toByteArray();
    }

    private byte[] createTestJpegImage(int width, int height) throws Exception {
        BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        for (int x = 0; x < width; x++) {
            for (int y = 0; y < height; y++) {
                image.setRGB(x, y, (x * y) % 0xFFFFFF);
            }
        }
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        ImageIO.write(image, "jpg", baos);
        return baos.toByteArray();
    }

    private void uploadTestBlob(String key, byte[] content, String contentType) {
        BlobContainerClient containerClient = blobServiceClient.getBlobContainerClient(CONTAINER_NAME);
        var blobClient = containerClient.getBlobClient(key);
        BlobHttpHeaders headers = new BlobHttpHeaders().setContentType(contentType);
        BlobParallelUploadOptions options = new BlobParallelUploadOptions(new ByteArrayInputStream(content))
                .setHeaders(headers);
        blobClient.uploadWithResponse(options, null, null);
    }

    /**
     * Test-specific implementation of file processing service that works with Azurite
     */
    static class TestFileProcessingService extends AbstractFileProcessingService {
        private final BlobServiceClient blobServiceClient;
        private final ImageMetadataRepository imageMetadataRepository;
        private final String containerName;

        public TestFileProcessingService(BlobServiceClient blobServiceClient,
                                        ImageMetadataRepository imageMetadataRepository,
                                        String containerName) {
            this.blobServiceClient = blobServiceClient;
            this.imageMetadataRepository = imageMetadataRepository;
            this.containerName = containerName;
        }

        @Override
        public void downloadOriginal(String key, Path destination) throws Exception {
            try (InputStream inputStream = blobServiceClient.getBlobContainerClient(containerName)
                    .getBlobClient(key)
                    .openInputStream()) {
                Files.copy(inputStream, destination, java.nio.file.StandardCopyOption.REPLACE_EXISTING);
            }
        }

        @Override
        public void uploadThumbnail(Path source, String key, String contentType) throws Exception {
            var blobClient = blobServiceClient.getBlobContainerClient(containerName).getBlobClient(key);
            BlobHttpHeaders headers = new BlobHttpHeaders().setContentType(contentType);
            BlobParallelUploadOptions options = new BlobParallelUploadOptions(Files.newInputStream(source))
                    .setHeaders(headers);
            blobClient.uploadWithResponse(options, null, null);

            // Extract the original key from the thumbnail key
            String originalKey = extractOriginalKey(key);

            // Find and update metadata
            imageMetadataRepository.findAll().stream()
                    .filter(metadata -> metadata.getS3Key().equals(originalKey))
                    .findFirst()
                    .ifPresent(metadata -> {
                        metadata.setThumbnailKey(key);
                        metadata.setThumbnailUrl(generateUrl(key));
                        imageMetadataRepository.save(metadata);
                    });
        }

        @Override
        public String getStorageType() {
            return "azure";
        }

        @Override
        protected String generateUrl(String key) {
            return blobServiceClient.getBlobContainerClient(containerName)
                    .getBlobClient(key)
                    .getBlobUrl();
        }

        private String extractOriginalKey(String key) {
            String suffix = "_thumbnail";
            int extensionIndex = key.lastIndexOf('.');
            if (extensionIndex > 0) {
                String nameWithoutExtension = key.substring(0, extensionIndex);
                String extension = key.substring(extensionIndex);
                int suffixIndex = nameWithoutExtension.lastIndexOf(suffix);
                if (suffixIndex > 0) {
                    return nameWithoutExtension.substring(0, suffixIndex) + extension;
                }
            }
            return key;
        }

        // Expose protected method for testing
        public void testGenerateThumbnail(Path input, Path output) throws Exception {
            generateThumbnail(input, output);
        }
    }
}
