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
- [Azure subscription](https://azure.microsoft.com/free/): Required to deploy the migrated application to Azure.
- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli): Required if you deploy the migrated application to Azure locally. The latest version is recommended.
- Fork the [GitHub repository](https://github.com/Azure-Samples/java-migration-copilot-samples) that contains the sample Java application, and clone it to your local machine. Open the `asset-manager` folder in VSCode and checkout the `workshop` branch.

## Install Java Migration Copilot Tool

Reference the doc **Installation Guide.docx** to install the Java Migration Copilot Tool.

## Migrate the Sample Java Application

Reference the doc **Getting Started.docx** for how to use the Java Migration Copilot Tool. The following sections guide you through the process of migrating the sample Java application `asset-manager` to Azure using the Java Migration Copilot Tool.

### Assess Your Java Application

The first step is to assess the sample Java application `asset-manager`. The assessment provides insights into the application's readiness for migration to Azure.

1. Open Java Migration Copilot tool in VSCode. It consists of Assessment and Prompts features currently.
1. Select **Assess**, wait for the assessment to complete, and review the assessment report.
   > [!NOTE]
   > If you are asked to allow the tool access the language models provided by GitHub Copilot Chat, slect **Allow** to proceed.
1. Select **Propose Solution** to view the proposed solutions for the issues identified in the assessment report, for example, **Migrate from AWS S3 to Azure Blob Storage**, **Migrate from Spring AMQP RabbitMQ to Azure Service Bus** and **Use Azure Database for PostgreSQL**.
1. For this workshop, deselect all solutions and select **Use Azure Database for PostgreSQL**, then select **Confirm the Solution**.
1. Review the solution details and select **Migrate** to initiate the migration process.

### Migrate to Azure Database for PostgreSQL Flexible Server using Predefined Prompt

You should see the matched predefined prompts for the selected solution are listed. Follow instructions to start the migration process.

1. Select the predefined prompt that best matches the solution, and confirm the prompt to run.
1. Review the migration plan with files proposed to be modified. Disregard files you believe are not necessary to modify. For files you want to modify, do the following for each file:
   - Select the file. It starts to generate the code changes. Wait until the code changes are generated.
   - Review the proposed changes carefully.
   - Select **Accept** to apply the changes if you agree with them.

Once you complete this step, suggest opening **Source Control** view to revisit the changes, and stage changes if you are satisfied with them.

### Migrate to Azure Blob Storage and Azure Service Bus using Custom Prompt

Recall that the sample Java application `asset-manager` uses AWS S3 for image storage and Spring AMQP RabbitMQ for message queuing. The `workshop` branch has additional commits that have already migrated the code for **Web Application** with custom code remediation to use Azure Blob Storage and Azure Service Bus, respectively. 

Now, you migrate the **Worker Service** to use Azure Blob Storage and Azure Service Bus as well, by using custom propmt created from existing commits that migrated the **Web Application**.

1. Select **Create prompt from source control**, type **migrate web** to search for the commits that migrated the **Web Application**, and you should see two commits listed:
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

At this point, you have successfully migrated the sample Java application `asset-manager` to use Azure Database for PostgreSQL, Azure Blob Storage, and Azure Service Bus. Now, you deploy the migrated application to Azure using the Azure CLI. You can either run the deployment script locally or use the GitHub Codespaces. The recommended approach is to run the deployment script in the GitHub Codespaces, as it provides a ready-to-use environment with all the necessary dependencies.

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
