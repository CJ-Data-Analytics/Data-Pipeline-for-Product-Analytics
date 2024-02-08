from google.cloud import bigquery, storage
from datetime import datetime, timedelta
import os

def create_table_and_load_data(request):
    client_bq = bigquery.Client()
    client_st = storage.Client()
    dataset_id = '__CLIENT___product_analytics'
    bucket_name = '__BUCKET_NAME__'

    # Extract the 'days' parameter from the GET request. Default to 1 if missing.
    days = request.args.get('days', default=1, type=int)
    # Compute the target date based on the 'days' parameter.
    target_date = (datetime.now() - timedelta(days=days)).strftime('%Y%m%d')

    folders_list = {
        'inapp_activity': [
            bigquery.SchemaField("timestamp", "TIMESTAMP"),
            bigquery.SchemaField("event", "STRING"),
            bigquery.SchemaField("type", "STRING"),
            bigquery.SchemaField("account_id", "STRING"),
            bigquery.SchemaField("user_id", "STRING"),
            bigquery.SchemaField("anon_id", "STRING"),
            bigquery.SchemaField("identity_details", "STRING"),
            bigquery.SchemaField("event_properties", "STRING"),
            bigquery.SchemaField("account_properties", "STRING"),
            bigquery.SchemaField("user_properties", "STRING"),
            bigquery.SchemaField("labels", "STRING"),
            bigquery.SchemaField("device_details", "STRING")
        ],
        'website_activity': [
            bigquery.SchemaField("timestamp", "TIMESTAMP"),
            bigquery.SchemaField("event", "STRING"),
            bigquery.SchemaField("type", "STRING"),
            bigquery.SchemaField("anon_id", "STRING"),
            bigquery.SchemaField("identity_details", "STRING"),
            bigquery.SchemaField("event_properties", "STRING"),
            bigquery.SchemaField("account_properties", "STRING"),
            bigquery.SchemaField("user_properties", "STRING"),
            bigquery.SchemaField("labels", "STRING"),
            bigquery.SchemaField("device_details", "STRING")
        ],
        'stripe': [
            bigquery.SchemaField("id", "STRING"),
            bigquery.SchemaField("object", "STRING"),
            bigquery.SchemaField("api_version", "STRING"),
            bigquery.SchemaField("created", "TIMESTAMP"),
            bigquery.SchemaField("data", "STRING"),
            bigquery.SchemaField("livemode", "STRING"),
            bigquery.SchemaField("pending_webhooks", "INTEGER"),
            bigquery.SchemaField("request", "STRING"),
            bigquery.SchemaField("type", "STRING")
        ]
    }

    for folder, schema in folders_list.items():
        try:
            specific_folder = f"{folder}/{target_date}"

            print(f"Checking folder {specific_folder}")

            table_id = specific_folder.replace("/", "_")

            dataset_ref = client_bq.dataset(dataset_id)
            table_ref = dataset_ref.table(table_id)

            try:
                client_bq.get_table(table_ref)
                table_exists = True
            except:
                table_exists = False

            if not table_exists:
                print("Table needs to be created")

                table = bigquery.Table(table_ref, schema=schema)
                table = client_bq.create_table(table)

                print("Table created")

            uri = f"gs://{bucket_name}/{specific_folder}/*.ndjson"

            print(f"Data sent to BigQuery from {uri}")

            job_config = bigquery.LoadJobConfig()
            job_config.source_format = bigquery.SourceFormat.NEWLINE_DELIMITED_JSON
            job_config.schema = schema

            load_job = client_bq.load_table_from_uri(uri, table_ref, job_config=job_config)

        except Exception as e:
            print(f"Error occurred with folder {folder}: {e}")

    return 'Tables created and data loading started.', 200
