# [Azure] Key Vault monitoring framework  
![Schubergphilis.png](icon/schubergphilis.png =500x)  
Microsoft [Azure] Key Vault monitoring framework based on Azure Function, Powershell, Event Grid and OpsGenie.

# Website
- Visit Schuberg Philis official web page https://schubergphilis.com/
- To read the story about this project, please visit: MEDIUM

# Disclaimer
- Schuberg Philis has designed and implemented this solution for its customers.
- For the demo purposes, we have stripped out(removed) all non-generic(sensitive) information from the solutuion, such as code blocks, subscription IDs, etc.

# Overview
- With the available option of utilizing the Key Vault events through the desired automation engine, we have designed and implemented the Key Vault monitoring framework.
- The framework is capable of:
1. Monitoring all entities that can be stored in the Key Vault, at the moment they are: Keys, Secrets, and Certificates.
2. Raising alerts via OpsGenie - this can be refined in order to fit your pager duty system.
3. Dealing with re-occurrence/reminders, raising the alert more than once - on daily basis, so you do not forget about your expiries.
- We wrote/created the whole structure of the deployment/pipeline utilizing the Azure DevOps logic, in order to reflect Microsoft principles.

# Deployment
- We assume that you have in place your Azure subscription and Azure DevOps organization.
- To deploy the Key Vault monitoring framework into your environment, you can follow these steps.
1. Initialize a new repository in your Azure DevOps organization.
2. Create a service connection between your Azure ecosystem(subscription/resource group) and your Azure DevOps organization, make sure your service principal has proper rights in order to deploy resources.
3. Clone this repository.
4. Configure new upstream(origin) of the cloned repository, to point to the repository that you have previously initialized, or you can copy files between repositories - if you find that easier.
5. Commit and push the changes.
6. In the Azure DevOps portal, navigate to Pipelines, create a new pipeline, select Azure Repos Git, select your repository, select existing YAML pipeline(file), choose /_ci/azure-pipelines.yaml and save the pipeline.
7. Click on a run pipeline, you will be prompted to fill in some parameters, we have set some defaults that should be adjusted for your environment.
    - connectedServiceName: Fill the name of the service connection that you created in step 2.
    - resourceGroupName: Name of the resource group where the resources will be provisioned.
    - environment: Environment name, you can leave this as a prd001(default), this parameter is used to construct the resource names.
    - resourceName: Base name for the services which will be provisioned, adjust this to something else, because the storage account with the same name, already exists(example).
    - opsGenieWebhook: Webhook of your OpsGenie integration, this should be the same URI as for your Azure Monitor Metric alerts.
        - Example: https://api.opsgenie.com/v1/json/azure?apiKey=GUID
8. Run the pipeline, take an apple, and enjoy the magic, especially if you like green color.

# Action
- In order to receive the expiry alert related to some entity, you can either
    1. Create a Key Vault Key and set the expiry date, between now and 30 days in advance.
    2. Create a Key Vault Secret and set the expiry date, between now and 30 days in advance.
    3. Create/Upload a Key Vault Certificate and set the expiry day, between now and 30 days in advance.
- After the expiry event is detected and forwarded through the Event Grid subscription, the Azure Function will kick-off and send the formatted alert to the OpsGenie.
- Please have a look at the OpsGenie section.
- The successfully raised alert will look like:  
![OpsGenieAlert.png](/icon/opsGenieAlert.png =500x)

# Pipeline overview
- If you're more into reading the pipeline code, please skip this section.  
- Multiple components are comprising the pipeline, we have utilized Powershell helpers, ARM templates and YAML sytnax to achieve the goal.  
- The pipeline is defined into two stages.  

## Build stage
    - Scans source(Powershell) code via PSScrypt Analyzer tool.
    - Archives source code, both Azure Function code and Powershell helper module.
    - Publishes the package/artifact, so that next stage can consume it.

## Deploy stage
    - Does some variable magic to construct the names of the services which will be deployed, you can check variables folder inside the stages folder, to get more context.
    - Deploys the Key Vault, where the OpsGenie webhook will be stored, and the same Key Vault will subscribe its events to the(see further) Azure Function.
    - Deploys Key Vault secret - OpsGenie webhook is deployed as a secret, and the secret is later on referenced throug the app configuration.
    - Deploys the Azure Function app.
        - Storage account where function app runtime files will be stored, as well as the storage table which will be used for the event/state tracking.
        - App service plan - server power which will host our function app.
        - Auto scale settings, some basic scaling settings for our app service plan.
        - Azure Function - as a main component of this step.
        - Artifact that was generated during the Build stage, is being picked up and deployed as function app code.
    - Deploys Key Vault access policy, object ID / function app principal is authorized to retrieve secrets from the Key Vault, in order to consume the OpsGenie webhook.
    - Deploys app service settings, some Powershell configuration parameters, such as runtime version and Key Vault reference.
    - Deploys Event Grid subscription, creates the connection between Key Vault and Azure Function, so that Key Vault events are being forwarded to the proper endpoint.

# OpsGenie overview
- The whole solution is heavily pointing to the OpsGenie integration, and all Powershell helpers which are written are quite specific.
- By reverse-engineering the Powershell helpers and looking into your OpsGenie integration, you can build the solution that best suits your needs.
- With this in mind, we can give you some guidelines how you canb configure your OpsGenie integration, but not the full-picture, since some parts are confidential.
- We have configured our integration to parse the Azure Monitor Metric alerts and extract specific infromations, like below, Powershell helpers are written to reflect/fit the same spectrum of information.  
![OpsGenieIntegration.png](/icon/opsGenieIntegration.png =500x)