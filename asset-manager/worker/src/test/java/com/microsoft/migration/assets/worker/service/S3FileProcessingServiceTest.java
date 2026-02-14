package com.microsoft.migration.assets.worker.service;

import com.azure.storage.blob.BlobClient;
import com.azure.storage.blob.BlobContainerClient;
import com.azure.storage.blob.BlobServiceClient;
import com.azure.storage.blob.specialized.BlobInputStream;
import com.microsoft.migration.assets.worker.repository.ImageMetadataRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.test.util.ReflectionTestUtils;

import java.io.ByteArrayInputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Collections;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
public class S3FileProcessingServiceTest {

    @Mock
    private BlobServiceClient blobServiceClient;

    @Mock
    private BlobContainerClient blobContainerClient;

    @Mock
    private BlobClient blobClient;

    @Mock
    private BlobInputStream blobInputStream;

    @Mock
    private ImageMetadataRepository imageMetadataRepository;

    @InjectMocks
    private S3FileProcessingService s3FileProcessingService;

    private final String containerName = "test-container";
    private final String testKey = "test-image.jpg";
    private final String thumbnailKey = "test-image_thumbnail.jpg";

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(s3FileProcessingService, "containerName", containerName);
        when(blobServiceClient.getBlobContainerClient(containerName)).thenReturn(blobContainerClient);
    }

    @Test
    void getStorageTypeReturnsBlob() {
        // Act
        String result = s3FileProcessingService.getStorageType();

        // Assert
        assertEquals("blob", result);
    }

    @Test
    void downloadOriginalCopiesFileFromBlob() throws Exception {
        // Arrange
        Path tempFile = Files.createTempFile("download-", ".tmp");

        when(blobContainerClient.getBlobClient(testKey)).thenReturn(blobClient);
        when(blobClient.openInputStream()).thenReturn(blobInputStream);

        // Act
        s3FileProcessingService.downloadOriginal(testKey, tempFile);

        // Assert
        verify(blobContainerClient).getBlobClient(testKey);
        verify(blobClient).openInputStream();

        // Clean up
        Files.deleteIfExists(tempFile);
    }

    @Test
    void uploadThumbnailPutsFileToBlob() throws Exception {
        // Arrange
        Path tempFile = Files.createTempFile("thumbnail-", ".tmp");
        when(blobContainerClient.getBlobClient(thumbnailKey)).thenReturn(blobClient);
        when(imageMetadataRepository.findAll()).thenReturn(Collections.emptyList());

        // Act
        s3FileProcessingService.uploadThumbnail(tempFile, thumbnailKey, "image/jpeg");

        // Assert
        verify(blobContainerClient).getBlobClient(thumbnailKey);
        verify(blobClient).uploadFromFile(tempFile.toString(), true);

        // Clean up
        Files.deleteIfExists(tempFile);
    }

    @Test
    void testExtractOriginalKey() throws Exception {
        // Use reflection to test private method
        String result = (String) ReflectionTestUtils.invokeMethod(
                s3FileProcessingService,
                "extractOriginalKey",
                "image_thumbnail.jpg");

        // Assert
        assertEquals("image.jpg", result);
    }
}
