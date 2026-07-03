import os
from pathlib import Path
from google.cloud import bigquery
from dotenv import load_dotenv
import pandas as pd
import google.auth

# Loading environment variables from .env file
load_dotenv()

print("PROJECT_ID:", os.getenv("GCP_PROJECT_ID"))
print("GOOGLE_APPLICATION_CREDENTIALS:", os.getenv("GOOGLE_APPLICATION_CREDENTIALS"))

credentials, detected_project = google.auth.default()

print("Credential type:", type(credentials))
print("Detected project:", detected_project)

# Getting project ID from environment
PROJECT_ID = os.getenv("GCP_PROJECT_ID")

# Initializing BigQuery client
client = bigquery.Client(
    project=PROJECT_ID,
    credentials=credentials
)

# Defining paths
SQL_DIR = Path(__file__).parent.parent / "sql"
OUTPUT_DIR = Path(__file__).parent.parent / "outputs"
OUTPUT_DIR.mkdir(exist_ok=True)

# Mapping of SQL files to output CSV filenames
QUERIES = {
    "01_user_acquisition.sql": "user_acquisition.csv",
    "02_funnel_analysis.sql": "funnel_analysis.csv",
    "03_session_behavior.sql": "session_behavior.csv",
    "04_conversion_by_channel.sql": "conversion_by_channel.csv",
}


def run_query(sql_file: str, output_file: str) -> pd.DataFrame:
    """Reading a SQL file, executing it in BigQuery, returning results as DataFrame."""

    # Reading SQL from file
    sql_path = SQL_DIR / sql_file
    with open(sql_path, "r") as f:
        query = f.read()

    print(f"Running: {sql_file}...")

    # Executing query
    query_job = client.query(query)

    # Waiting for it to finish and converting to pandas DataFrame
    df = query_job.to_dataframe()

    # Saving to CSV
    output_path = OUTPUT_DIR / output_file
    df.to_csv(output_path, index=False)
    print(f"  Saved → {output_path} ({len(df)} rows)")

    return df


def main():
    """Running all queries in sequence."""
    print(f"Connecting to BigQuery project: {PROJECT_ID}\n")

    results = {}
    for sql_file, output_file in QUERIES.items():
        results[sql_file] = run_query(sql_file, output_file)

    print("\nAll queries completed.")
    return results


if __name__ == "__main__":
    main()
