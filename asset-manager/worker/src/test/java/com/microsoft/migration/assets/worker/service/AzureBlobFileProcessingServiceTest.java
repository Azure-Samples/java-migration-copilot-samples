package com.microsoft.migration.assets.worker.service;

import com.azure.storage.blob.BlobClient;
import com.azure.storage.blob.BlobContainerClient;
import com.azure.storage.blob.BlobServiceClient;
import com.azure.storage.blob.models.BlobHttpHeaders;
import com.microsoft.migration.assets.worker.repository.ImageMetadataRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Collections;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class AzureBlobFileProcessingServiceTest {

    @Mock
    private BlobServiceClient blobServiceClient;

    @Mock
    private BlobContainerClient blobContainerClient;

    @Mock
    private BlobClient blobClient;

    @Mock
    private ImageMetadataRepository imageMetadataRepository;

    @InjectMocks
    private AzureBlobFileProcessingService azureBlobFileProcessingService;

    private final String containerName = "test-container";
    private final String testKey = "test-image.jpg";
    private final String thumbnailKey = "test-image_thumbnail.jpg";

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(azureBlobFileProcessingService, "containerName", containerName);
        
        // Setup mock chain
        when(blobServiceClient.getBlobContainerClient(anyString())).thenReturn(blobContainerClient);
        when(blobContainerClient.getBlobClient(anyString())).thenReturn(blobClient);
    }

    @Test
    void getStorageTypeReturnsAzure() {
        // Act
        String result = azureBlobFileProcessingService.getStorageType();

        // Assert
        assertEquals("azure", result);
    }

    @Test
    void downloadOriginalCopiesFileFromAzureBlob() throws Exception {
        // Arrange
        Path tempFile = Files.createTempFile("download-", ".tmp");
        byte[] testData = "test data".getBytes();
        InputStream mockInputStream = new ByteArrayInputStream(testData);

        // Mock openInputStream to return a generic InputStream (test will cast appropriately)
        when(blobClient.openInputStream()).thenAnswer(invocation -> mockInputStream);

        // Act
        azureBlobFileProcessingService.downloadOriginal(testKey, tempFile);

        // Assert
        verify(blobServiceClient).getBlobContainerClient(containerName);
        verify(blobContainerClient).getBlobClient(testKey);
        verify(blobClient).openInputStream();

        // Clean up
        Files.deleteIfExists(tempFile);
    }

    @Test
    void uploadThumbnailPutsFileToAzureBlob() throws Exception {
        // Arrange
        Path tempFile = Files.createTempFile("thumbnail-", ".tmp");
        when(imageMetadataRepository.findAll()).thenReturn(Collections.emptyList());
        doNothing().when(blobClient).setHttpHeaders(any(BlobHttpHeaders.class));

        // Act
        azureBlobFileProcessingService.uploadThumbnail(tempFile, thumbnailKey, "image/jpeg");

        // Assert
        verify(blobServiceClient).getBlobContainerClient(containerName);
        verify(blobContainerClient).getBlobClient(thumbnailKey);
        verify(blobClient).uploadFromFile(tempFile.toString(), true);
        verify(blobClient).setHttpHeaders(any(BlobHttpHeaders.class));

        // Clean up
        Files.deleteIfExists(tempFile);
    }

    @Test
    void generateUrlReturnsBlobUrlWithSasToken() {
        // Arrange
        String mockBlobUrl = "https://testaccount.blob.core.windows.net/container/test.jpg";
        String mockSasToken = "sv=2021-06-08&ss=b&srt=o&sp=r&se=2024-12-31T23:59:59Z&st=2024-12-01T00:00:00Z&spr=https&sig=signature";
        
        when(blobClient.getBlobUrl()).thenReturn(mockBlobUrl);
        when(blobClient.generateSas(any())).thenReturn(mockSasToken);

        // Act
        String result = ReflectionTestUtils.invokeMethod(azureBlobFileProcessingService, "generateUrl", testKey);

        // Assert
        verify(blobServiceClient).getBlobContainerClient(containerName);
        verify(blobContainerClient).getBlobClient(testKey);
        assertEquals(mockBlobUrl + "?" + mockSasToken, result);
    }

    @Test
    void testExtractOriginalKey() {
        // Use reflection to test private method
        String result = (String) ReflectionTestUtils.invokeMethod(
                azureBlobFileProcessingService,
                "extractOriginalKey",
                "image_thumbnail.jpg");

        // Assert
        assertEquals("image.jpg", result);
    }
}
