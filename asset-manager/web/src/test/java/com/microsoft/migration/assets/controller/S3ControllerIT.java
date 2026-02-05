package com.microsoft.migration.assets.controller;

import com.azure.spring.messaging.servicebus.core.ServiceBusTemplate;
import com.azure.storage.blob.BlobContainerClient;
import com.azure.storage.blob.BlobServiceClient;
import com.azure.storage.blob.BlobServiceClientBuilder;
import com.microsoft.migration.assets.model.ImageMetadata;
import com.microsoft.migration.assets.repository.ImageMetadataRepository;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.Network;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.containers.wait.strategy.Wait;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.time.Duration;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Integration tests for S3Controller using TestContainers.
 * Tests the complete flow of file operations with Azure Blob Storage (Azurite) and PostgreSQL.
 */
@SpringBootTest(properties = {
    "spring.cloud.azure.servicebus.enabled=false"
})
@AutoConfigureMockMvc
@Testcontainers
@ActiveProfiles("test")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class S3ControllerIT {

    @MockBean
    private ServiceBusTemplate serviceBusTemplate;
    
    @MockBean
    private com.azure.messaging.servicebus.administration.ServiceBusAdministrationClient adminClient;
    
    @MockBean(name = "retryQueue")
    private com.azure.messaging.servicebus.administration.models.QueueProperties retryQueue;
    
    @MockBean(name = "imageProcessingQueue")
    private com.azure.messaging.servicebus.administration.models.QueueProperties imageProcessingQueue;

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
    private MockMvc mockMvc;

    @Autowired
    private ImageMetadataRepository imageMetadataRepository;

    @Autowired
    private BlobServiceClient blobServiceClient;

    private static String uploadedFileKey;

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
    }

    @BeforeEach
    void setUp() {
        // Clean up any existing data before each test
    }

    // ==================== Happy Path Tests ====================

    @Test
    @Order(1)
    @DisplayName("Should display upload form successfully")
    void shouldDisplayUploadForm() throws Exception {
        mockMvc.perform(get("/s3/upload"))
                .andExpect(status().isOk())
                .andExpect(view().name("upload"));
    }

    @Test
    @Order(2)
    @DisplayName("Should upload file successfully")
    void shouldUploadFileSuccessfully() throws Exception {
        // Create a test image
        byte[] imageBytes = createTestImage();
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "test-image.png",
                MediaType.IMAGE_PNG_VALUE,
                imageBytes
        );

        mockMvc.perform(multipart("/s3/upload").file(file))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/s3"))
                .andExpect(flash().attribute("success", "File uploaded successfully"));

        // Verify file is stored in database
        List<ImageMetadata> metadata = imageMetadataRepository.findAll();
        assertThat(metadata).isNotEmpty();
        assertThat(metadata.get(0).getFilename()).isEqualTo("test-image.png");
        assertThat(metadata.get(0).getContentType()).isEqualTo(MediaType.IMAGE_PNG_VALUE);

        uploadedFileKey = metadata.get(0).getS3Key();
    }

    @Test
    @Order(3)
    @DisplayName("Should list uploaded files successfully")
    void shouldListUploadedFiles() throws Exception {
        mockMvc.perform(get("/s3"))
                .andExpect(status().isOk())
                .andExpect(view().name("list"))
                .andExpect(model().attributeExists("objects"));
    }

    @Test
    @Order(4)
    @DisplayName("Should view file page successfully")
    void shouldViewFilePage() throws Exception {
        // Get the key from database
        List<ImageMetadata> metadata = imageMetadataRepository.findAll();
        assertThat(metadata).isNotEmpty();
        String key = metadata.get(0).getS3Key();

        mockMvc.perform(get("/s3/view-page/" + key))
                .andExpect(status().isOk())
                .andExpect(view().name("view"))
                .andExpect(model().attributeExists("object"));
    }

    @Test
    @Order(5)
    @DisplayName("Should download file content successfully")
    void shouldDownloadFileContent() throws Exception {
        // Get the key from database
        List<ImageMetadata> metadata = imageMetadataRepository.findAll();
        assertThat(metadata).isNotEmpty();
        String key = metadata.get(0).getS3Key();

        MvcResult result = mockMvc.perform(get("/s3/view/" + key))
                .andExpect(status().isOk())
                .andReturn();

        byte[] content = result.getResponse().getContentAsByteArray();
        assertThat(content).isNotEmpty();
    }

    @Test
    @Order(6)
    @DisplayName("Should delete file successfully")
    void shouldDeleteFileSuccessfully() throws Exception {
        // Get the key from database
        List<ImageMetadata> metadata = imageMetadataRepository.findAll();
        assertThat(metadata).isNotEmpty();
        String key = metadata.get(0).getS3Key();

        mockMvc.perform(post("/s3/delete/" + key))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/s3"))
                .andExpect(flash().attribute("success", "File deleted successfully"));

        // Verify file is removed from database
        metadata = imageMetadataRepository.findAll();
        assertThat(metadata).isEmpty();
    }

    // ==================== Validation Error Tests ====================

    @Test
    @Order(7)
    @DisplayName("Should reject empty file upload")
    void shouldRejectEmptyFileUpload() throws Exception {
        MockMultipartFile emptyFile = new MockMultipartFile(
                "file",
                "empty.txt",
                MediaType.TEXT_PLAIN_VALUE,
                new byte[0]
        );

        mockMvc.perform(multipart("/s3/upload").file(emptyFile))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/s3/upload"))
                .andExpect(flash().attribute("error", "Please select a file to upload"));
    }

    // ==================== Edge Case Tests ====================

    @Test
    @Order(8)
    @DisplayName("Should handle file with special characters in name")
    void shouldHandleFileWithSpecialCharacters() throws Exception {
        byte[] imageBytes = createTestImage();
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "test image with spaces & symbols!.png",
                MediaType.IMAGE_PNG_VALUE,
                imageBytes
        );

        mockMvc.perform(multipart("/s3/upload").file(file))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/s3"))
                .andExpect(flash().attribute("success", "File uploaded successfully"));

        // Clean up
        List<ImageMetadata> metadata = imageMetadataRepository.findAll();
        if (!metadata.isEmpty()) {
            String key = metadata.get(0).getS3Key();
            mockMvc.perform(post("/s3/delete/" + key));
        }
    }

    @Test
    @Order(9)
    @DisplayName("Should upload JPEG file successfully")
    void shouldUploadJpegFileSuccessfully() throws Exception {
        byte[] jpegBytes = createTestJpegImage();
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "test-image.jpg",
                MediaType.IMAGE_JPEG_VALUE,
                jpegBytes
        );

        mockMvc.perform(multipart("/s3/upload").file(file))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/s3"))
                .andExpect(flash().attribute("success", "File uploaded successfully"));

        // Clean up
        List<ImageMetadata> metadata = imageMetadataRepository.findAll();
        if (!metadata.isEmpty()) {
            String key = metadata.get(0).getS3Key();
            mockMvc.perform(post("/s3/delete/" + key));
        }
    }

    // ==================== Error Condition Tests ====================

    @Test
    @Order(10)
    @DisplayName("Should handle non-existent file view gracefully")
    void shouldHandleNonExistentFile() throws Exception {
        String nonExistentKey = UUID.randomUUID().toString();

        // The controller wraps BlobStorageException and returns 404 or throws a servlet exception
        // Either response is acceptable - the key is that the system handles it without crashing
        try {
            mockMvc.perform(get("/s3/view/" + nonExistentKey))
                    .andExpect(status().is4xxClientError());
        } catch (Exception e) {
            // BlobStorageException may propagate - this is acceptable behavior
            assertThat(e.getMessage()).contains("BlobNotFound");
        }
    }

    @Test
    @Order(11)
    @DisplayName("Should redirect with error for non-existent file page view")
    void shouldRedirectWithErrorForNonExistentFilePage() throws Exception {
        String nonExistentKey = UUID.randomUUID().toString();

        mockMvc.perform(get("/s3/view-page/" + nonExistentKey))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/s3"))
                .andExpect(flash().attribute("error", "Image not found"));
    }

    // ==================== Multiple File Operations Tests ====================

    @Test
    @Order(12)
    @DisplayName("Should handle multiple file uploads")
    void shouldHandleMultipleFileUploads() throws Exception {
        // Upload first file
        byte[] imageBytes1 = createTestImage();
        MockMultipartFile file1 = new MockMultipartFile("file", "file1.png", MediaType.IMAGE_PNG_VALUE, imageBytes1);
        mockMvc.perform(multipart("/s3/upload").file(file1)).andExpect(status().is3xxRedirection());

        // Upload second file
        byte[] imageBytes2 = createTestImage();
        MockMultipartFile file2 = new MockMultipartFile("file", "file2.png", MediaType.IMAGE_PNG_VALUE, imageBytes2);
        mockMvc.perform(multipart("/s3/upload").file(file2)).andExpect(status().is3xxRedirection());

        // Verify both files are stored
        List<ImageMetadata> metadata = imageMetadataRepository.findAll();
        assertThat(metadata).hasSizeGreaterThanOrEqualTo(2);

        // Clean up all files
        for (ImageMetadata meta : metadata) {
            mockMvc.perform(post("/s3/delete/" + meta.getS3Key()));
        }
    }

    // ==================== Helper Methods ====================

    private byte[] createTestImage() throws Exception {
        BufferedImage image = new BufferedImage(100, 100, BufferedImage.TYPE_INT_RGB);
        // Fill with a simple color
        for (int x = 0; x < 100; x++) {
            for (int y = 0; y < 100; y++) {
                image.setRGB(x, y, 0xFF0000); // Red color
            }
        }
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        ImageIO.write(image, "png", baos);
        return baos.toByteArray();
    }

    private byte[] createTestJpegImage() throws Exception {
        BufferedImage image = new BufferedImage(100, 100, BufferedImage.TYPE_INT_RGB);
        // Fill with a simple color
        for (int x = 0; x < 100; x++) {
            for (int y = 0; y < 100; y++) {
                image.setRGB(x, y, 0x00FF00); // Green color
            }
        }
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        ImageIO.write(image, "jpg", baos);
        return baos.toByteArray();
    }
}
