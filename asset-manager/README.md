# Asset Manager

This document serves as a comprehensive workshop guide that will walk you through the process of migrating a Java application to Azure using GitHub Copilot app modernization. The workshop covers assessment, Java/framework upgrades, migration to Azure services, containerization, and deployment.

**What the modernization Process Will Do:**
The modernization will transform your application from the outdated technologies to a modern Azure-native solution. This includes upgrading from Java 8 to Java 21, migrating from Spring Boot 2.x to 3.x, replacing AWS S3 with Azure Blob Storage, switching from RabbitMQ to Azure Service Bus, migrating to Azure Database for PostgreSQL, implementing managed identity authentication, adding health checks, containerizing the applications, and preparing them for cloud deployment with proper monitoring.

## Table of Contents

- [Overview](#overview)
- [Current Architecture](#current-architecture)
- [Run Locally](#run-locally)
- [App Modernization](#app-modernization)
  - [Install GitHub Copilot app modernization](#install-github-copilot-app-modernization)
  - [Assess Your Java Application](#assess-your-java-application)
  - [Upgrade Runtime & Frameworks](#upgrade-runtime--frameworks)
  - [Migrate to Azure Database for PostgreSQL Flexible Server](#migrate-to-azure-database-for-postgresql-flexible-server)
  - [Migrate to Azure Blob Storage](#migrate-to-azure-blob-storage)
  - [Migrate to Azure Service Bus](#migrate-to-azure-service-bus)
  - [Expose health endpoints using Custom Skills](#expose-health-endpoints-using-custom-skills)
  - [Containerize Applications](#containerize-applications)
  - [Deploy to Azure](#deploy-to-azure)

## Overview

The [main](https://github.com/Azure-Samples/java-migration-copilot-samples/tree/main/asset-manager) branch of the asset-manager project is the original state before being migrated to Azure services. It is organized as follows:
* AWS S3 for image storage, using password-based authentication (access key/secret key)
* RabbitMQ for message queuing, using password-based authentication
* PostgreSQL database for metadata storage, using password-based authentication

In this workshop, you will use the **GitHub Copilot app modernization** extension to assess, upgrade, migrate, and finally deploy the project to Azure.

**Time Estimates:**
The complete workshop takes approximately **2 hours** to complete. Here's the breakdown for each major step:
- **Assess Your Java Application**: ~5 minutes
- **Upgrade Runtime & Frameworks**: ~10 minutes
- **Migrate to Azure Database for PostgreSQL**: ~15 minutes
- **Migrate to Azure Blob Storage**: ~15 minutes
- **Migrate to Azure Service Bus**: ~15 minutes
- **Expose Health Endpoints**: ~15 minutes
- **Containerize Applications**: ~5 minutes
- **Deploy to Azure**: ~40 minutes

There are 3 branches we have prepared for you in case you have any problems with any steps in this workshop:
* [main](https://github.com/Azure-Samples/java-migration-copilot-samples/tree/main/asset-manager): The original state of the asset-manager application.
* [workshop/java-upgrade](https://github.com/Azure-Samples/java-migration-copilot-samples/tree/workshop/java-upgrade/asset-manager): The project state after assessment and Java upgrading steps.
* [workshop/expected](https://github.com/Azure-Samples/java-migration-copilot-samples/tree/workshop/expected/asset-manager): The project state after assessment, Java upgrading, and migration steps.
* [workshop/deployment-expected](https://github.com/Azure-Samples/java-migration-copilot-samples/tree/workshop/deployment-expected/asset-manager): The project state after containerization and deployment steps.

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

Clone the repository and open the asset-manager folder to run the current project locally:

```bash
git clone https://github.com/Azure-Samples/java-migration-copilot-samples.git
cd java-migration-copilot-samples/asset-manager
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
scripts\startapp.cmd
```

Linux:

```bash
scripts/startapp.sh
```

To stop, run `stopapp.cmd` or `stopapp.sh` in the `scripts` directory.

## App Modernization

The following sections guide you through the process of modernizing the sample Java application `asset-manager` to Azure using GitHub Copilot app modernization.

**Prerequisites**: 
- A GitHub account with [GitHub Copilot](https://github.com/features/copilot) enabled. A Pro, Pro+, Business, or Enterprise plan is required.
- One of the following IDEs:
  - The latest version of [Visual Studio Code](https://code.visualstudio.com/). Must be version 1.101 or later.
    - [GitHub Copilot in Visual Studio Code](https://code.visualstudio.com/docs/copilot/overview). For setup instructions, see [Set up GitHub Copilot in Visual Studio Code](https://code.visualstudio.com/docs/copilot/setup). Be sure to sign in to your GitHub account within Visual Studio Code.
    - [GitHub Copilot app modernization](https://marketplace.visualstudio.com/items?itemName=vscjava.migrate-java-to-azure). Restart Visual Studio Code after installation.
  - The latest version of [IntelliJ IDEA](https://www.jetbrains.com/idea/download). Must be version 2023.3 or later.
    - [GitHub Copilot](https://plugins.jetbrains.com/plugin/17718-github-copilot). Must be version 1.5.59 or later. For more instructions, see [Set up GitHub Copilot in IntelliJ IDEA](https://docs.github.com/en/copilot/get-started/quickstart). Be sure to sign in to your GitHub account within IntelliJ IDEA.
    - [GitHub Copilot app modernization](https://plugins.jetbrains.com/plugin/28791-github-copilot-app-modernization). Restart IntelliJ IDEA after installation. If you don't have GitHub Copilot installed, you can install GitHub Copilot app modernization directly.
    - For more efficient use of Copilot in app modernization: in the IntelliJ IDEA settings, select the **Tools** > **GitHub Copilot** configuration window, and then select **Auto-approve** and **Trust MCP Tool Annotations**. For more information, see [Configure settings for GitHub Copilot app modernization to optimize the experience for IntelliJ](configure-settings-intellij.md).
- [Java JDK](/java/openjdk/download) for both the source and target JDK versions.
- [Maven](https://maven.apache.org/download.cgi) or [Gradle](https://gradle.org/install/) to build Java projects.
- A Git-managed Java project using Maven or Gradle.
- For Maven-based projects: access to the public Maven Central repository.
- In the Visual Studio Code settings, make sure `chat.extensionTools.enabled` is set to `true`. This setting might be controlled by your organization.

> Note: If you're using Gradle, only the Gradle wrapper version 5+ is supported. The Kotlin Domain Specific Language (DSL) isn't supported.
>
> The function `My Tasks` isn't supported yet for IntelliJ IDEA.

### Install GitHub Copilot app modernization

In VSCode, open the Extensions view from the Activity Bar, search for the `GitHub Copilot app modernization` extension in the marketplace. Click the Install button for the extension. After installation completes, you should see a notification in the bottom-right corner of VSCode confirming success.

**Alternative: IntelliJ IDEA**
Alternatively, you can use IntelliJ IDEA. Open **File** > **Settings** (or **IntelliJ IDEA** > **Preferences** on macOS), navigate to **Plugins** > **Marketplace**, search for `GitHub Copilot app modernization`, and click **Install**. Restart IntelliJ IDEA if prompted.

### Assess Your Java Application

The first step is to assess the sample Java application `asset-manager`. The assessment provides insights into the application's readiness for migration to Azure.

1. Open VS Code with all the prerequisites installed for the asset manager by changing the directory to the `asset-manager` directory and running `code .` in that directory.
1. In the Activity sidebar, open the **GitHub Copilot app modernization** extension pane.
1. In the **QUICKSTART** section, click **Start Assessment** to trigger the app assessment.

   ![Trigger Assessment](doc-media/trigger-assessment.png)

1. Wait for the assessment to be completed. This step could take several minutes.
1. Upon completion, an **Assessment Report** tab opens. This report provides a categorized view of cloud readiness issues and recommended solutions. Select the **Issues** tab to view proposed solutions and proceed with migration steps.

### Upgrade Runtime & Frameworks

1. In the **Issues** tab, find the **Java Upgrade** domain section. Check the checkbox next to the **Java Version is not the latest LTS** category, then click the **Create Plan** button (showing the count of selected categories) at the top of the Assessment Report.

    ![Java Upgrade](doc-media/java-upgrade.png)
1. The Copilot Chat panel will open with Agent Mode. The agent will check out a new branch and start upgrading the JDK version and Spring/Spring Boot framework. Click **Allow** for any requests from the agent.

> Note: The upgrading tool also supports upgrading to JDK 25 (the latest LTS version). To do this, click on the generated chat message, edit the target Java version to 25, and then click **Send** to apply the change.

### Migrate to Azure Database for PostgreSQL Flexible Server

Then you can migrate the sample Java application `asset-manager` to Azure.

> Note: We've set up a [workshop/java-upgrade](https://github.com/Azure-Samples/java-migration-copilot-samples/tree/workshop/java-upgrade/asset-manager) branch where the Java upgrade has already been completed. Feel free to switch to this branch if you'd like to skip ahead and continue with the rest of the workshop.

1. In the **Issues** tab, find the **Cloud Readiness** domain section. Check the checkbox next to the **PostgreSQL database found** category, then click the **Create Plan** button (showing the count of selected categories) at the top of the Assessment Report. When the agent asks which database service to migrate to, specify **Azure Database for PostgreSQL (Spring)**.

   ![Confirm Solution](doc-media/confirm-postgresql-solution.png)
1. The Copilot Chat panel will open with Agent Mode.
1. The Copilot Agent will analyze the project, generate and open **plan.md** and **progress.md**, then automatically proceed with the migration process.
1. The agent checks the version control system status and checks out a new branch for migration, then performs the code changes. Click **Allow** for any tool call requests from the agent.
1. When the code migration is complete, the agent will automatically run a **validation and fix iteration loop** which includes:
   - **CVE Validation**: Detects Common Vulnerabilities and Exposures in current dependencies and fixes them.
   - **Build Validation**: Attempts to resolve any build errors.
   - **Consistency Validation**: Analyzes the code for functional consistency.
   - **Test Validation**: Runs unit tests and automatically fixes any failures.
   - **Completeness Validation**: Catches migration items missed in the initial code migration and fixes them.
1. After all validations complete, the agent generates a **summary.md** as the final step.
1. Review the proposed code changes and click **Keep** to apply them.

### Migrate to Azure Blob Storage

1. In the **Issues** tab, find the **Storage Migration (AWS S3)** category. Check its checkbox, then click the **Create Plan** button (showing the count of selected categories). The agent will plan and execute the migration from AWS S3 to Azure Blob Storage.
1. The following steps are the same as the above PostgreSQL server migration.

### Migrate to Azure Service Bus

1. In the **Issues** tab, find the **Messaging Service Migration (Spring AMQP RabbitMQ)** category. Check its checkbox, then click the **Create Plan** button (showing the count of selected categories). The agent will plan and execute the migration from RabbitMQ to Azure Service Bus.
1. The following steps are the same as the above PostgreSQL server migration.

### Expose health endpoints using Custom Skills

In this section, you will use custom skills to expose health endpoints for your applications instead of writing code yourself. The following steps demonstrate how to create a custom skill with references and proper prompts.

> Note: Custom skills (My Skills) are not supported for the IntelliJ IDEA plugin. If you are using IntelliJ IDEA, you can skip this section.

1. In the Activity sidebar, open the **GitHub Copilot app modernization** extension pane. Hover over the **TASKS** section, and then select **Create a Custom Skill**.

   ![Create Custom Skill](doc-media/create-formula-from-source-control.png)
1. A **Create a Skill** form opens with the following fields. Fill them in as shown below:
   - **Skill Name**: `expose-health-endpoint`
   - **Skill Description**: `This skill helps add Spring Boot Actuator health endpoints for Azure Container Apps deployment readiness.`
   - **Skill Content**: `You are a Spring Boot developer assistant, follow the Spring Boot Actuator documentation to add basic health endpoints for Azure Container Apps deployment.`

1. Click **Add Resources** to add the Spring Boot Actuator official documentation as a resource. Paste the following link: `https://docs.spring.io/spring-boot/reference/actuator/endpoints.html`.

   ![Create a Skill form](doc-media/health-endpoint-task.png)
1. Click **Save** to create the skill. Your custom skill now appears in the **TASKS** > **My Skills** section.
1. Click **Run** to execute it.
1. The Copilot chat window opens in Agent Mode and automatically generates the migration plan, checks out a new branch, performs code changes, and runs the validation and fix iteration loop. Click **Allow** for any tool call requests from the agent.
1. Review the proposed code changes and click **Keep** to apply them.

### Containerize Applications

Now that you have successfully migrated your Java application to use Azure services, the next step is to prepare it for cloud deployment by containerizing both the web and worker modules. In this section, you will use **Containerization Tasks** to containerize your migrated applications.
> Note: If you encounter any issues with the previous migration step, you can directly proceed with the containerization step using the [workshop/expected](https://github.com/Azure-Samples/java-migration-copilot-samples/tree/workshop/expected/asset-manager) branch.

1. In the Activity sidebar, open the **GitHub Copilot app modernization** extension pane. In the **TASKS** section, expand **Common Tasks** > **Containerize Tasks** and click the run button for **Containerize Application**.
  
    ![Run Containerize Application task](doc-media/containerization-run-task.png)

1. A predefined prompt will be populated in the Copilot Chat panel with Agent Mode. Copilot Agent will start to analyze the workspace and to create a **containerization-plan.copiotmd** with the containerization plan.

    ![Containerization prompt and plan](doc-media/containerization-plan.png)
1. View the plan and collaborate with Copilot Agent as it follows the **Execution Steps** in the plan by clicking **Continue**/**Allow** in pop-up chat notifications to run commands. Some of the execution steps leverage agentic tools of **Container Assist**.

    <!-- ![Containerization execution steps](doc-media/containerization-execution-steps.png) -->
1. Copilot Agent will help generate Dockerfile, build Docker images and fix build errors if there are any. Click **Keep** to apply the generated code.

### Deploy to Azure

At this point, you have successfully migrated the sample Java application `asset-manager` to Azure Database for PostgreSQL (Spring), Azure Blob Storage, and Azure Service Bus, and exposed health endpoints via Spring Boot Actuator. Now, you can start the deployment to Azure.
> Note: If you encounter any issues with the previous migration step, you can directly proceed with the deployment step using the [workshop/expected](https://github.com/Azure-Samples/java-migration-copilot-samples/tree/workshop/expected/asset-manager) branch.

1. In the Activity sidebar, open the **GitHub Copilot app modernization** extension pane. In the **TASKS** section, expand **Common Tasks** > **Deployment Tasks**. Click the run button for **Provision Infrastructure and Deploy to Azure**.

    ![Run Deployment task](doc-media/deployment-run-task.png)
1. A predefined prompt will be populated in the Copilot Chat panel with Agent Mode. The default hosting Azure service is Azure Container Apps.To change the hosting service to **Azure Kubernetes Service** (AKS), click on the prompt in the Copilot Chat panel and edit the last sentence of the prompt to **Hosting service: AKS**.

    ![Deployment prompt](doc-media/deployment-prompt.png)
1. Click ****Continue**/**Allow** if pop-up notifications to let Copilot Agent analyze the project and create a deployment plan in **plan.copilotmd** with Azure resources architecture, recommended Azure resources for project and security configurations, and execution steps for deployment.

1. View the architecture diagram, resource configurations, and execution steps in the plan. Click **Keep** to save the plan and type in **Execute the plan** to start the deployment.

    ![Deployment execute](doc-media/deployment-execute.png)
1. When prompted, click **Continue**/**Allow** in chat notifications or type **y**/**yes** in terminal as Copilot Agent follows the plan and leverages agent tools to create and run provisioning and deployment scripts, fix potential errors, and finish the deployment. You can also check the deployment status in **progress.copilotmd**. **DO NOT interrupt** when provisioning or deployment scripts are running.

    ![Deployment progress](doc-media/deployment-progress.png)

> Note: If you encounter any issues with the deployment step, you can refer to the expected Copilot-generated deployment scripts in `/.azure` folder of the [workshop/deployment-expected](https://github.com/Azure-Samples/java-migration-copilot-samples/tree/workshop/deployment-expected/asset-manager) branch to compare your deployment scripts and troubleshoot the problems.

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
