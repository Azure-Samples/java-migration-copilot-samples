# Java Migration Copilot Workshop

> [!IMPORTANT]
> The Java Migration Copilot Tool is in preview and is subject to change before becoming generally available.

The Java Migration Copilot Tool assists with app assessment, planning and code remediation. It automates repetitive tasks, boosting developer confidence and speeding up the Azure migration and ongoing optimization.

In this workshop, you learn how to use the Java Migration Copilot Tool to assess and migrate a sample Java application `asset-manager` to Azure. For more information about the sample application, see [Asset Manager](README.md).

## Prerequisites

To successfully complete this workshop, you need the following:

- [VSCode](https://code.visualstudio.com/): The latest version is recommended.
- [A Github account with Github Copilot enabled](https://github.com/features/copilot): All plans are supported, including the Free plan.
- [GitHub Copilot extension in VSCode](https://code.visualstudio.com/docs/copilot/overview): The latest version is recommended.
- [Docker Desktop](https://www.docker.com/products/docker-desktop/): Required for the Assessment feature and running the initial application locally.
- [JDK 21](https://learn.microsoft.com/en-us/java/openjdk/download#openjdk-21): Required for the code remediation feature and running the initial application locally.
- [Maven 3.9.9](https://maven.apache.org/install.html): Required for the code remediation feature.
- [Azure subscription](https://azure.microsoft.com/free/): Required to deploy the migrated application to Azure.
- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli): Required if you deploy the migrated application to Azure locally. The latest version is recommended.
- Fork the [GitHub repository](https://github.com/Azure-Samples/java-migration-copilot-samples) that contains the sample Java application. **MAKE SURE TO UNCHECK THE BOX "Copy the `main` branch only.** Clone it to your local machine. Open the `asset-manager` folder in VSCode and checkout the `workshop` branch.

## Install Java Migration Copilot Tool

Reference the doc **Installation Guide.docx** to install the Java Migration Copilot Tool.

## Migrate the Sample Java Application

Reference the doc **Getting Started.docx** for how to use the Java Migration Copilot Tool. The following sections guide you through the process of migrating the sample Java application `asset-manager` to Azure using the Java Migration Copilot Tool.

### Assess Your Java Application

The first step is to assess the sample Java application `asset-manager`. The assessment provides insights into the application's readiness for migration to Azure.

1. Ensure Docker Desktop is running.
1. Open the VS code with all the prerequisites installed on the asset manager by changing the directory to the `asset manager` directory and running `code .` in that directory.
1. Open Java Migration Copilot tool in VSCode. It consists of Assessment and Prompts features currently. As of 2025-04-03, the icon looks like the M365 a copilot icon in one color.
1. The **Assess** button looks a triangle pointing right. Select **Assess**, wait for the assessment to complete, and review the assessment report.

   > **NOTE**: If you are asked to allow the tool access the language models provided by GitHub Copilot Chat, slect **Allow** to proceed.

1. On the **Summary** pane, scroll to the bottom. Select **Propose Solution** to view the proposed solutions for the issues identified in the assessment report, for example, **Migrate from AWS S3 to Azure Blob Storage**, **Migrate from Spring AMQP RabbitMQ to Azure Service Bus** and **Use Azure Database for PostgreSQL**.
1. For this workshop, deselect all solutions and select **Use Azure Database for PostgreSQL**, then select **Confirm the Solution**.
1. Review the solution details and select **Migrate** to initiate the migration process. **Migrate** is located in the middle pane.

### Migrate to Azure Database for PostgreSQL Flexible Server using Predefined Prompt

You should see the matched predefined prompts for the selected solution are listed. Follow instructions to start the migration process.

1. Select the predefined prompt that best matches the solution. In this workshop, select the one for **Spring** because the sample Java application is a Spring Boot application.
1. In the search area, select **OK**.
1. In the **Formulas** pane, on the left, review the migration plan with files proposed to be modified. Disregard files you believe are not necessary to modify. For files you want to modify, do the following for each file:
   - Select the file. It starts to generate the code changes. Wait until the code changes are generated.
   - Review the proposed changes carefully.
   - In the **Apply Formulas** pane, select the checkmark (the tooltip is **Accept**) to apply the changes if you agree with them.

Once you complete this step, suggest opening **Source Control** view to revisit the changes, and stage changes if you are satisfied with them.

### Migrate to Azure Blob Storage and Azure Service Bus using Custom Prompt

Recall that the sample Java application `asset-manager` uses AWS S3 for image storage and Spring AMQP RabbitMQ for message queuing. The `workshop` branch has additional commits that have already migrated the code for **Web Application** with custom code remediation to use Azure Blob Storage and Azure Service Bus, respectively. 

Now, you migrate the **Worker Service** to use Azure Blob Storage and Azure Service Bus as well, by using custom prompt created from existing commits that migrated the **Web Application**.

1. In the **Formulas** section, select **Create formula from source control**. This icon looks like two circles with arrows pointing to the other circle. Type **migrate web** to search for the commits that migrated the **Web Application**, and you should see two commits listed:
   * migrate web rabbitmq to azure service bus
   * migrate web s3 to azure blob storage
1. Select these two commits to create a custom prompt, with all defaults populated including the name and description. 
1. Select and run the custom prompt you just created, and follow the same steps as the predefined prompt to review and apply the changes.

Once you complete this step, suggest opening **Source Control** view to revisit the changes, and stage changes if you are satisfied with them.

### Build and Fix

Once you have completed the code changes, you can ask the tool to automatically build the application and fix any issues that may arise.

1. Select **Fix build** to build and fix the application.
1. Wait for the process to complete. If no build erros found, you can proceed to the next step. Otherwise, review the build errors and fix them manually.

## Deploy to Azure

At this point, you have successfully migrated the sample Java application `asset-manager` to use Azure Database for PostgreSQL, Azure Blob Storage, and Azure Service Bus. Now, you deploy the migrated application to Azure using the Azure CLI after you identify a working location for your Azure resources.

For example, an Azure Database for PostgreSQL Flexible Server requires a location that supports the service. Follow the instructions below to find a suitable location.

1. Run the following command to list all available locations for your account:

   ```bash
   az account list-locations -o table
   ```

1. Try a location from column **Name** in the output. For example, `eastus2` stands for **East US 2**.

1. Run the following command to list all available SKUs in the selected location for Azure Database for PostgreSQL Flexible Server:

   ```bash
   az postgres flexible-server list-skus --location <your location> -o table
   ```

1. If you see the output contains the SKU `Standard_B1ms` and the **Tier** is `Burstable`, you can use the location for the deployment. Otherwise, try another location.

   ```text
   SKU                Tier             VCore    Memory    Max Disk IOPS
   -----------------  ---------------  -------  --------  ---------------
   Standard_B1ms      Burstable        1        2 GiB     640e
   ```

You can either run the deployment script locally or use the GitHub Codespaces. The recommended approach is to run the deployment script in the GitHub Codespaces, as it provides a ready-to-use environment with all the necessary dependencies.

Deploy using GitHub Codespaces:
1. Commit and push the changes to your forked repository.
1. Follow instructions in [Use GitHub Codespaces for Deployment](README.md#use-github-codespaces-for-deployment) to deploy the app to Azure.

Deploy using local environment by running the deployment script in the terminal:
1. Run `az login` to sign in to Azure.
1. Run the following commands to deploy the app to Azure:
   
   Winndows:
   ```batch
   scripts\deploy-to-azure.cmd -ResourceGroupName <your resource group name> -Location <your resource group location, e.g., eastus2> -Prefix <your unique resource prefix>
   ```

   Linux:
   ```bash
   scripts/deploy-to-azure.sh -ResourceGroupName <your resource group name> -Location <your resource group location, e.g., eastus2> -Prefix <your unique resource prefix>
   ```

Once the deployment script completes successfully, it outputs the URL of the Web application. Open the URL in a browser to verify if the application is running as expected.

## Clean up

When you are done with the workshop, clean up the Azure resources to avoid incurring costs.

Winndows:
```batch
scripts\cleanup-azure-resources.cmd -ResourceGroupName <your resource group name>
```

Linux:
```bash
scripts/cleanup-azure-resources.sh -ResourceGroupName <your resource group name>
```

If you deploy the app using GitHub Codespaces, delete the Codespaces environment by navigating to your forked repository in GitHub and selecting **Code** > **Codespaces** > **Delete**.
