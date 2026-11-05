package com.microsoft.migration.assets.worker.service;

import com.azure.messaging.servicebus.ServiceBusReceivedMessageContext;
import com.microsoft.migration.assets.worker.model.ImageProcessingMessage;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.file.Path;

import static org.mockito.Mockito.*;

class AbstractFileProcessingServiceTest {

    @Test
    void completesMessagesForOtherStorageTypes() {
        ServiceBusReceivedMessageContext context = mock(ServiceBusReceivedMessageContext.class);
        TestFileProcessingService processor = new TestFileProcessingService("s3", false);

        processor.processImage(new ImageProcessingMessage("image.jpg", "image/jpeg", "local", 12), context);

        verify(context).complete();
        verify(context, never()).abandon();
    }

    @Test
    void abandonsMessagesWhenProcessingFails() {
        ServiceBusReceivedMessageContext context = mock(ServiceBusReceivedMessageContext.class);
        TestFileProcessingService processor = new TestFileProcessingService("s3", true);

        processor.processImage(new ImageProcessingMessage("image.jpg", "image/jpeg", "s3", 12), context);

        verify(context).abandon();
        verify(context, never()).complete();
    }

    private static class TestFileProcessingService extends AbstractFileProcessingService {
        private final String storageType;
        private final boolean failDownload;

        private TestFileProcessingService(String storageType, boolean failDownload) {
            this.storageType = storageType;
            this.failDownload = failDownload;
        }

        @Override
        public void downloadOriginal(String key, Path destination) throws Exception {
            if (failDownload) {
                throw new IOException("test failure");
            }
        }

        @Override
        public void uploadThumbnail(Path source, String key, String contentType) {
        }

        @Override
        public String getStorageType() {
            return storageType;
        }

        @Override
        protected String generateUrl(String key) {
            return key;
        }
    }
}
