# Data Pipeline for Product Analytics

This library automates the deployment process for Google Cloud Platform (GCP) needed for a data pipeline for product analytics. It's designed to streamline the setup of essential resources such as Cloud Storage, BigQuery datasets, Cloud Functions, and more, reducing manual effort and ensuring consistency across deployments.

## Features

- **Configurable Deployment Options**: The script allows users to specify deployment options such as deploying to BigQuery, Cloud Storage, App Engine, Cloud Functions, or all services at once.
- **Dynamic Configuration**: Utilizes dynamic configuration based on user-provided parameters such as project ID, key file path, deployment options, and client details.
- **Resource Creation and Configuration**: Automatically creates and configures GCP resources including BigQuery datasets, Cloud Storage buckets, App Engine services, Cloud Functions, and necessary API services.
- **Service Activation**: Checks for enabled GCP services and activates them if necessary to ensure smooth deployment.
- **Function Deployment**: Automates the deployment of Cloud Functions with appropriate triggers and configurations.
- **Scheduled Tasks**: Sets up scheduled tasks (using Cloud Scheduler) for executing Cloud Functions at specified intervals.

## Prerequisites

Before running the script, ensure the following:

- You have generated a service key in your Google Cloud project with the following roles attached (the JSON key should be stored in the the folder service-key):
    - Editor
    - App Engine Admin
    - Cloud Build Editor
    - Cloud Functions Admin
    - Cloud Run Admin
    - Cloud Scheduler Admin
    - Storage Admin
    - Artifact Registry Administrator
    - Service Account User
    - Service Usage Admin

- Google Cloud SDK (`gcloud`) is installed and authenticated with the appropriate credentials.
- AppEngine was activated in your Google Cloud Prohect (an application was created).

## Usage

1. Clone this repository to your local machine.
2. Customize the deployment parameters in the script according to your project requirements. Ensure you provide the necessary arguments when running the script.
3. Run the script in a Bash environment:

    ```bash
    ./deployer.sh PROJECT_ID KEY_FILE_PATH DEPLOY_OPTION CLIENT_NAME
    ```

    Replace `PROJECT_ID`, `KEY_FILE_PATH`, `DEPLOY_OPTION`, and `CLIENT_NAME` with your actual values.

## Deployment Options

- `all`: Deploys all available services.
- `bigquery`: Deploys BigQuery dataset, when it needs an update.
- `storage`: Deploys Cloud Storage bucket, when it needs an update.
- `appengine`: Deploys App Engine services, when they need an update.
- `functions`: Deploys Cloud Functions, when they need an update.


## Other options

 - CLIENT_NAME: the name of the your product or of the client for which you are deploying the service
 - KEY_FILE_PATH the name of the JSON file that is stored in the service-key folder
 - PROJECT_ID the id of your Google Cloud Project 