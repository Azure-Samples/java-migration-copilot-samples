# Asset Manager

This [workshop/initial](https://github.com/Azure-Samples/java-migration-copilot-samples/tree/workshop/initial/asset-manager) branch of the asset-manager project is the original state before being migrated to Azure services. It is organized as follows:
* AWS S3 for image storage, using password-based authentication (access key/secret key)
* RabbitMQ for message queuing, using password-based authentication
* PostgreSQL database for metadata storage, using password-based authentication

In this workshop, you will use the **GitHub Copilot app modernization** extension to assess, upgrade, migrate, and finally deploy the project to Azure. There are 3 branches we have prepared for you in case you have any problems with any steps in this workshop:
* [workshop/initial](https://github.com/Azure-Samples/java-migration-copilot-samples/tree/workshop/initial/asset-manager): The original state of the asset-manager application.
* [workshop/java-upgrade](https://github.com/Azure-Samples/java-migration-copilot-samples/tree/workshop/java-upgrade/asset-manager): The project state after assessment and Java upgrading steps.
* [workshop/expected](https://github.com/Azure-Samples/java-migration-copilot-samples/tree/workshop/expected/asset-manager): The project state after assessment, Java upgrading, and migration steps.

## Current Architecture
```mermaid
flowchart TD

%% Applications
WebApp[Web Application]
Worker[Worker Service]

%% Storage Components
S3[(AWS S3)]
LocalFS[("Local File System<br/>dev only")]

%% Message Broker
RabbitMQ(RabbitMQ)

%% Database
PostgreSQL[(PostgreSQL)]

%% Queues
Queue[image-processing queue]
RetryQueue[image-processing.retry queue]

%% User
User([User])

%% User Flow
User -->|Upload Image| WebApp
User -->|View Images| WebApp

%% Web App Flows
WebApp -->|Store Original Image| S3
WebApp -->|Store Original Image| LocalFS
WebApp -->|Send Processing Message| RabbitMQ
WebApp -->|Store Metadata| PostgreSQL
WebApp -->|Retrieve Images| S3
WebApp -->|Retrieve Images| LocalFS
WebApp -->|Retrieve Metadata| PostgreSQL

%% RabbitMQ Flow
RabbitMQ -->|Push Message| Queue
Queue -->|Processing Failed| RetryQueue
RetryQueue -->|After 1 min delay| Queue
Queue -->|Consume Message| Worker

%% Worker Flow
Worker -->|Download Original| S3
Worker -->|Download Original| LocalFS
Worker -->|Upload Thumbnail| S3
Worker -->|Upload Thumbnail| LocalFS
Worker -->|Store Metadata| PostgreSQL
Worker -->|Retrieve Metadata| PostgreSQL

%% Styling
classDef app fill:#90caf9,stroke:#0d47a1,color:#0d47a1
classDef storage fill:#a5d6a7,stroke:#1b5e20,color:#1b5e20
classDef broker fill:#ffcc80,stroke:#e65100,color:#e65100
classDef db fill:#ce93d8,stroke:#4a148c,color:#4a148c
classDef queue fill:#fff59d,stroke:#f57f17,color:#f57f17
classDef user fill:#ef9a9a,stroke:#b71c1c,color:#b71c1c

class WebApp,Worker app
class S3,LocalFS storage
class RabbitMQ broker
class PostgreSQL db
class Queue,RetryQueue queue
class User user
```
Password-based authentication

## Run Locally

Check out the [workshop/initial](https://github.com/Azure-Samples/java-migration-copilot-samples/tree/workshop/initial/asset-manager) branch to run the current infrastructure locally:

```bash
git clone https://github.com/Azure-Samples/java-migration-copilot-samples.git
cd java-migration-copilot-samples/asset-manager
git checkout workshop/initial
```

**Prerequisites**: 
- [JDK 8](https://learn.microsoft.com/en-us/java/openjdk/download#openjdk-8): Required for running the initial application locally.
- [Maven 3.6.0+](https://maven.apache.org/install.html): Required to build the application locally.
- [Docker](https://docs.docker.com/desktop/): Required for running the application locally.

Run the following commands to start the apps locally. This will:
* Use the local file system instead of S3 to store images
* Launch RabbitMQ and PostgreSQL using Docker

Windows:

```batch
scripts\start.cmd
```

Linux:

```bash
scripts/start.sh
```

To stop, run `stop.cmd` or `stop.sh` in the `scripts` directory.

## App Modernization

The following sections guide you through the process of modernizing the sample Java application `asset-manager` to Azure using GitHub Copilot app modernization.

**Prerequisites**: 
To successfully complete this workshop, you need the following:

- [VSCode](https://code.visualstudio.com/): The latest version is recommended.
- [A GitHub account with GitHub Copilot enabled](https://github.com/features/copilot): All plans are supported, including the Free plan.
- [GitHub Copilot extension in VSCode](https://code.visualstudio.com/docs/copilot/overview): The latest version is recommended.
- [JDK 21](https://learn.microsoft.com/en-us/java/openjdk/download#openjdk-21): Required for the code remediation feature and running the initial application locally.
- [Maven 3.9.9](https://maven.apache.org/install.html): Required for the assessment and code remediation feature.

If you want to deploy the application to Azure, the following are also required:
- [Azure subscription](https://azure.microsoft.com/free/): Required to deploy the migrated application to Azure.
- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli): Required if you deploy the migrated application to Azure locally. The latest version is recommended.
- Fork the [GitHub repository](https://github.com/Azure-Samples/java-migration-copilot-samples) that contains the sample Java application. Please ensure you **uncheck** the default selection "Copy the `main` branch only". Clone it to your local machine. Open the `asset-manager` folder in VSCode and check out the `workshop/initial` branch.

### Install GitHub Copilot app modernization

In VSCode, open the Extensions view from the Activity Bar, search for the `GitHub Copilot app modernization` extension in the marketplace. Click the Install button for the extension. After installation completes, you should see a notification in the bottom-right corner of VSCode confirming success.

**Alternative: IntelliJ IDEA**
Alternatively, you can use IntelliJ IDEA. Open **File** > **Settings** (or **IntelliJ IDEA** > **Preferences** on macOS), navigate to **Plugins** > **Marketplace**, search for `GitHub Copilot app modernization`, and click **Install**. Restart IntelliJ IDEA if prompted.

### Assess Your Java Application

The first step is to assess the sample Java application `asset-manager`. The assessment provides insights into the application's readiness for migration to Azure.

1. Open VS Code with all the prerequisites installed for the asset manager by changing the directory to the `asset-manager` directory and running `code .` in that directory.
1. Open the `GitHub Copilot app modernization` extension.
1. In the **QUICKSTART** view, click the **Migrate to Azure** button to trigger the Modernization Assessor.

   ![Trigger Assessment](doc-media/trigger-assessment.png)

1. Wait for the assessment to be completed and the report to be generated.
1. Review the **Assessment Report**. Select the **Issues** tab to view the proposed solutions for the issues identified in the report.

### Upgrade Your Java Application

1. In the **Java Upgrade** table at the bottom of the **Issues** tab, click the **Run Task** button of the first entry **Java Version Upgrade**.

    ![Java Upgrade](doc-media/java-upgrade.png)
1. After clicking the **Run Task** button, the Copilot Chat panel will open with Agent Mode. The agent will check out a new branch and start upgrading the JDK version and Spring/Spring Boot framework. Click **Allow** for any requests from the agent.

1. Refer to the [workshop/java-upgrade](https://github.com/Azure-Samples/java-migration-copilot-samples/tree/workshop/java-upgrade/asset-manager) branch for the upgraded status of the project. Additionally, if you have any problems with the Java upgrading step, you can start from that branch for the content below.

### Migrate to Azure Database for PostgreSQL Flexible Server using Predefined Tasks

1. For this workshop, select **Migrate to Azure Database for PostgreSQL (Spring)** in the Solution list, then click **Run Task**.

   ![Confirm Solution](doc-media/confirm-postgresql-solution.png)
1. After clicking the **Run Task** button in the Assessment Report, the Copilot Chat panel will open with Agent Mode.
1. The Copilot Agent will first analyze the project and generate a migration plan.
1. After the plan is generated, Copilot Chat will stop with two generated files: **plan.md** and **progress.md**. Please manually input "Continue" or "Proceed" in the chat to confirm the plan and proceed with its subsequent actions to execute the plan.
1. When the code is migrated, the extension will prepare the **CVE Validation and Fixing** process. Click **Allow** to proceed.
1. Review the proposed code changes and click **Keep** to apply them.

### Migrate to Azure Blob Storage using Predefined Tasks

1. Click the **Run Task** in the Assessment Report, on the right of the row `Storage Migration (AWS S3)` - `Migrate from AWS S3 to Azure Blob Storage`.
1. The following steps are the same as the above PostgreSQL server migration.

### Migrate to Azure Service Bus using Predefined Tasks

1. Click the **Run Task** in the Assessment Report, on the right of the row `Messaging Service Migration (Spring AMQP RabbitMQ)` - `Migrate from RabbitMQ(AMQP) to Azure Service Bus`.
1. The following steps are the same as the above PostgreSQL server migration.

### Expose health endpoints using Custom Tasks

In this section, you will use custom tasks to expose health endpoints for your applications instead of writing code yourself.
> Note: Custom tasks are not supported for the IntelliJ IDEA plugin. If you are using IntelliJ IDEA, you can skip this section.

The following steps demonstrate how to generate custom tasks based on external web links and proper prompts.

1. Open the sidebar of `GITHUB COPILOT APP MODERNIZATION`. Click the `+` button in the **Tasks** view to create a custom task.

   ![Create Formula From Source Control](doc-media/create-formula-from-source-control.png)
1. In the opened tab, enter the **Task Name** and **Task Prompt** as shown below:
   - **Task Name**: Expose health endpoint via Spring Boot Actuator
   - **Task Prompt**: You are a Spring Boot developer assistant, follow the Spring Boot Actuator documentation to add basic health endpoints for Azure Container Apps deployment.
1. Click the **Add References** button to add the Spring Boot Actuator official documentation as references.

   ![Health endpoint task](doc-media/health-endpoint-task.png)
1. In the popped-up quick-pick window, select **External links**. Then paste the following link: `https://docs.spring.io/spring-boot/reference/actuator/endpoints.html`. Click **Save** to create the task.
1. Click the **Run** button to trigger the custom task.
1. Follow the same steps as the predefined task to review and apply the changes.
1. Review the proposed code changes and click **Keep** to apply them.

### Containerize Applications

Now that you have successfully migrated your Java application to use Azure services, the next step is to prepare it for cloud deployment by containerizing both the web and worker modules. In this section, you will use **Containerization Tasks** to containerize your migrated applications.
> Note: If you have any problems with the previous migration step, you can start from the [workshop/expected](https://github.com/Azure-Samples/java-migration-copilot-samples/tree/workshop/expected/asset-manager) branch for the deployment operation.

1. Open the sidebar of `GITHUB COPILOT APP MODERNIZATION`. In **Tasks** view, click the **Run Task** button of **Java** -> **Containerization Tasks** -> **Containerize Application**.
  
    ![Run Containerize Application task](doc-media/containerization-run-task.png)

1. A predefined prompt will be populated in the Copilot Chat panel with Agent Mode. Copilot Agent will start to analyze the workspace and to create a **containerization-plan.copiotmd** with the containerization plan.

    ![Containerization prompt and plan](doc-media/containerization-plan.png)
1. View the plan and collaborate with Copilot Agent as it follows the **Execution Steps** in the plan by clicking **Continue**/**Allow** in pop-up chat notifications to run commands. Some of the execution steps leverage agentic tools of **Container Assist**.

    <!-- ![Containerization execution steps](doc-media/containerization-execution-steps.png) -->
1. Copilot Agent will help generate Dockerfile, build Docker images and fix build errors if there are any. Click **Keep** to apply the generated code.

### Deploy to Azure

At this point, you have successfully migrated the sample Java application `asset-manager` to Azure Database for PostgreSQL (Spring), Azure Blob Storage, and Azure Service Bus, and exposed health endpoints via Spring Boot Actuator.
> Note: If you have any problems with the previous migration step, you can start from the [workshop/expected](https://github.com/Azure-Samples/java-migration-copilot-samples/tree/workshop/expected/asset-manager) branch for the deployment operation.

Now, you can deploy the migrated application to Azure using the Azure CLI after you identify a working location for your Azure resources. For example, an Azure Database for PostgreSQL Flexible Server requires a location that supports the service. Follow the instructions below to find a suitable location.

1. Run the following command to list all available locations for the current subscription.

   ```bash
   az account list-locations -o table
   ```

1. Select a location from column **Name** in the output.

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

You can either run the deployment script locally or use GitHub Codespaces. The recommended approach is to run the deployment script in GitHub Codespaces, as it provides a ready-to-use environment with all the necessary dependencies.

Deploy using GitHub Codespaces:
1. Commit and push the changes to your forked repository.
1. Follow the instructions in [Use GitHub Codespaces for Deployment](README.md#use-github-codespaces-for-deployment) to deploy the app to Azure.

Deploy using the local environment by running the deployment script in the terminal:
1. Run `az login` to sign in to Azure.
1. Run the following commands to deploy the app to Azure:

   Windows:
   ```batch
   scripts\deploy-to-azure.cmd -ResourceGroupName <your resource group name> -Location <your resource group location, e.g., eastus2> -Prefix <your unique resource prefix>
   ```

   Linux:
   ```bash
   scripts/deploy-to-azure.sh -ResourceGroupName <your resource group name> -Location <your resource group location, e.g., eastus2> -Prefix <your unique resource prefix>
   ```

Once the deployment script completes successfully, it will output the URL of the web application. Open the URL in a browser to verify that the application is running as expected.

#### Clean up

When no longer needed, you can delete all related resources using the following scripts.

Windows:
```batch
scripts\cleanup-azure-resources.cmd -ResourceGroupName <your resource group name>
```

Linux:
```bash
scripts/cleanup-azure-resources.sh -ResourceGroupName <your resource group name>
```

If you deploy the app using GitHub Codespaces, delete the Codespaces environment by navigating to your forked repository in GitHub and selecting **Code** > **Codespaces** > **Delete**.