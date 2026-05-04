package com.microsoft.migration.assets;

import com.azure.spring.messaging.implementation.annotation.EnableAzureMessaging;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.ApplicationPidFileWriter;

@SpringBootApplication
@EnableAzureMessaging
public class AssetsManagerApplication {
    public static void main(String[] args) {
        SpringApplication application = new SpringApplication(AssetsManagerApplication.class);
        application.addListeners(new ApplicationPidFileWriter());
        application.run(args);
    }
}
