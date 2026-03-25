import os
import json
import glob
from google.cloud import bigquery, storage
from google.oauth2 import service_account

# ── Auth ──────────────────────────────────────────────────────────────────
sa_info      = json.loads(os.environ["GC_SERVICE_ACCOUNT"])
credentials  = service_account.Credentials.from_service_account_info(sa_info)

project_id   = os.environ["GC_PROJECT_ID"]
location     = os.environ["GC_LOCATION"]
bucket_name  = os.environ["GC_BUCKET_NAME"]
dataset_id   = os.environ["GC_EXTERNAL_DATASET"]

bq_client    = bigquery.Client(project=project_id, credentials=credentials, location=location)
gcs_client   = storage.Client(project=project_id, credentials=credentials)
bucket       = gcs_client.bucket(bucket_name)

# ── File type config ──────────────────────────────────────────────────────
FILE_CONFIG = {
    ".csv": ",",
    ".txt": "|",
}

# ── Explicit schema overrides (for files where autodetect fails) ──────────
SCHEMA_OVERRIDES = {
    "iso_country_codes": [
        bigquery.SchemaField("iso_alpha_2", "STRING"),
        bigquery.SchemaField("iso_alpha_3", "STRING"),
        bigquery.SchemaField("country_name", "STRING"),
    ]
}

# ── Discover files directly from mounted volume ───────────────────────────
all_files = glob.glob("/external-data/**/*.*", recursive=True) + \
            glob.glob("/external-data/*.*")
all_files = list(set(all_files))

supported_files = [f for f in all_files if os.path.splitext(f)[1].lower() in FILE_CONFIG]

if not supported_files:
    print("[!] No supported files (.csv, .txt) found in /external-data/")

# ── Process each file ─────────────────────────────────────────────────────
for local_path in supported_files:
    filename   = os.path.basename(local_path)
    ext        = os.path.splitext(filename)[1].lower()
    table_name = os.path.splitext(filename)[0]
    delimiter  = FILE_CONFIG[ext]
    gcs_path   = f"external-data/{filename}"
    gcs_uri    = f"gs://{bucket_name}/{gcs_path}"
    table_ref  = f"{project_id}.{dataset_id}.{table_name}"

    # Upload to GCS ───────────────────────────────────────────────────────
    blob = bucket.blob(gcs_path)
    blob.upload_from_filename(local_path)
    print(f"[✓] Uploaded  '{filename}'  →  {gcs_uri}")

    # Build job config ────────────────────────────────────────────────────
    explicit_schema = SCHEMA_OVERRIDES.get(table_name)
    job_config = bigquery.LoadJobConfig(
        source_format      = bigquery.SourceFormat.CSV,
        field_delimiter    = delimiter,
        skip_leading_rows  = 1,
        autodetect         = explicit_schema is None,
        schema             = explicit_schema,
        write_disposition  = bigquery.WriteDisposition.WRITE_TRUNCATE,
        create_disposition = bigquery.CreateDisposition.CREATE_IF_NEEDED,
        column_name_character_map = "V1"
    )

    load_job = bq_client.load_table_from_uri(
        gcs_uri,
        table_ref,
        job_config=job_config,
    )
    load_job.result()
    print(f"[✓] Loaded    {gcs_uri}  →  '{table_ref}'  (delimiter='{delimiter}')")

print("\n[✓] All files processed.")