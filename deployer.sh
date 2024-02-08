#!/bin/bash

# Check that the user provided the necessary arguments
if [ "$#" -lt 4 ]; then
  echo "Usage: $0 PROJECT_ID KEY_FILE_PATH DEPLOY_OPTION CLIENT"
  exit 1
fi

# Assign the command-line arguments to variables
if [ "$#" -eq 4 ]; then
  PROJECT_ID=$1
  KEY_FILE_PATH=$2
  DEPLOY_OPTION=$3
  CLIENT=$4
fi

# Set the source and destination folder paths
SOURCE_FOLDER="code"
DESTINATION_FOLDER="code_to_deploy/$CLIENT"

# Configure your other resources
DATASET_ID="${CLIENT}_product_analytics"
BUCKET_NAME="${CLIENT}_data_collector"
REGION="europe-west1"
BQREGION="EU"
#REGION="us-central1"
#BQREGION="US"
SERVICE_ACCOUNT_EMAIL=$(jq -r '.client_email' $KEY_FILE_PATH)


# Copy the source folder to the destination if it doesn't exist yet
if [ -d "$DESTINATION_FOLDER" ]; then
  echo "Folder exists"
else
  echo "Folder does not exist. Copying it now"
  cp -R "$SOURCE_FOLDER" "$DESTINATION_FOLDER"
  # Find and replace the string in all files inside the destination folder
  TO_REPLACE="__BUCKET_NAME__"
  find "$DESTINATION_FOLDER" -type f -exec sed -i "s/$TO_REPLACE/$BUCKET_NAME/g" {} \;
  TO_REPLACE="__PROJECT_ID__"
  find "$DESTINATION_FOLDER" -type f -exec sed -i "s/$TO_REPLACE/$PROJECT_ID/g" {} \;
  TO_REPLACE="__REGION__"
  find "$DESTINATION_FOLDER" -type f -exec sed -i "s/$TO_REPLACE/$REGION/g" {} \;
  TO_REPLACE="__CLIENT__"
  find "$DESTINATION_FOLDER" -type f -exec sed -i "s/$TO_REPLACE/$CLIENT/g" {} \;
fi









# Authenticate as the service account
gcloud auth activate-service-account --key-file=$KEY_FILE_PATH

# Set the project
gcloud config set project $PROJECT_ID

#set the region
gcloud config set functions/region $REGION


##Check if services are enabled
# Set the service you want to check
SERVICE_NAME="cloudfunctions.googleapis.com"

# Check if the service is enabled
SERVICE_STATUS=$(gcloud services list --enabled --filter="config.name:$SERVICE_NAME" --format="value(config.name)")

if [ -z "$SERVICE_STATUS" ]; then
  echo "Service $SERVICE_NAME is not enabled, enabling it now..."
  gcloud services enable $SERVICE_NAME
else
  echo "Service $SERVICE_NAME is already enabled."
fi


# Set the service you want to check
SERVICE_NAME="cloudscheduler.googleapis.com"

# Check if the service is enabled
SERVICE_STATUS=$(gcloud services list --enabled --filter="config.name:$SERVICE_NAME" --format="value(config.name)")

if [ -z "$SERVICE_STATUS" ]; then
  echo "Service $SERVICE_NAME is not enabled, enabling it now..."
  gcloud services enable $SERVICE_NAME
else
  echo "Service $SERVICE_NAME is already enabled."
fi


# Set the service you want to check
SERVICE_NAME="run.googleapis.com"

# Check if the service is enabled
SERVICE_STATUS=$(gcloud services list --enabled --filter="config.name:$SERVICE_NAME" --format="value(config.name)")

if [ -z "$SERVICE_STATUS" ]; then
  echo "Service $SERVICE_NAME is not enabled, enabling it now..."
  gcloud services enable $SERVICE_NAME
else
  echo "Service $SERVICE_NAME is already enabled."
fi

# Set the service you want to check
SERVICE_NAME="appengine.googleapis.com"

# Check if the service is enabled
SERVICE_STATUS=$(gcloud services list --enabled --filter="config.name:$SERVICE_NAME" --format="value(config.name)")

if [ -z "$SERVICE_STATUS" ]; then
  echo "Service $SERVICE_NAME is not enabled, enabling it now..."
  gcloud services enable $SERVICE_NAME
else
  echo "Service $SERVICE_NAME is already enabled."
fi


# Set the service you want to check
SERVICE_NAME="cloudbuild.googleapis.com"

# Check if the service is enabled
SERVICE_STATUS=$(gcloud services list --enabled --filter="config.name:$SERVICE_NAME" --format="value(config.name)")

if [ -z "$SERVICE_STATUS" ]; then
  echo "Service $SERVICE_NAME is not enabled, enabling it now..."
  gcloud services enable $SERVICE_NAME
else
  echo "Service $SERVICE_NAME is already enabled."
fi


if [ "$DEPLOY_OPTION" = "bigquery" ] || [ "$DEPLOY_OPTION" = "all" ]; then

  # Create the BigQuery dataset
  bq --location=$BQREGION mk --dataset $PROJECT_ID:$DATASET_ID
fi



# Create the Cloud Storage bucket
if [ "$DEPLOY_OPTION" = "storage" ] || [ "$DEPLOY_OPTION" = "all" ]; then
  gsutil mb -l $BQREGION gs://$BUCKET_NAME/
  gsutil lifecycle set lifecycle-settings.json gs://$BUCKET_NAME/
fi




#Deploy appengine
if [ "$DEPLOY_OPTION" = "appengine" ] || [ "$DEPLOY_OPTION" = "all" ]; then

  # Describe the App Engine app
  if gcloud app describe --project $PROJECT_ID >/dev/null 2>&1; then
      echo "App Engine is already enabled."
  else
      echo "Enabling App Engine..."
      gcloud app create --project=$PROJECT_ID
  fi


  SERVICE_EXISTS=$(gcloud app services list --project $PROJECT_ID --format="value(SERVICE)" --filter="SERVICE=default")
  
  if [[ -z "$SERVICE_EXISTS" ]]; then
    echo "Default service doesn't exist. Deploying..."
    gcloud app deploy $DESTINATION_FOLDER/appengine/default/app.yaml --quiet
  fi

  gcloud app deploy $DESTINATION_FOLDER/appengine/analytics_data_collector/app.yaml --quiet
fi


# Deploy the Cloud Function for merge-ing files
if [ "$DEPLOY_OPTION" = "functions" ] || [ "$DEPLOY_OPTION" = "all" ]; then


# Deploy the Cloud Function for stripe
gcloud functions deploy ${CLIENT}_load_product_analytics_to_bigquery \
  --gen2 \
  --region=$REGION \
  --runtime python311 \
  --trigger-http \
  --no-allow-unauthenticated \
  --entry-point create_table_and_load_data \
  --source $DESTINATION_FOLDER/cloud_functions/load_product_analytics_to_bigquery/

URLBIGQUERY=$(gcloud functions describe ${CLIENT}_load_product_analytics_to_bigquery --format='value(serviceConfig.uri)')


gcloud scheduler jobs create http ${CLIENT}_load_product_analytics_to_bigquery \
  --location=$REGION \
  --schedule="0 3 * * *" \
  --http-method=GET \
  --uri=$URLBIGQUERY \
  --oidc-service-account-email=$SERVICE_ACCOUNT_EMAIL \
  --oidc-token-audience=$URLBIGQUERY \
  --attempt-deadline="360s"
fi

echo "Deployment complete!"
