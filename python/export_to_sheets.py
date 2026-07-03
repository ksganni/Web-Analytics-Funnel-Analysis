# Exporting CSV results to Google Sheets for Looker Studio

import os
import gspread
import pandas as pd
from pathlib import Path
from dotenv import load_dotenv
import numpy as np

load_dotenv()
SHEET_ID = os.getenv("GOOGLE_SHEET_ID")
OUTPUT_DIR = Path(__file__).parent.parent / "outputs"

# Tab names in the Google Sheet (one per query result CSV)
SHEET_TABS = {
    "user_acquisition.csv": "User Acquisition",
    "funnel_analysis.csv": "Funnel Analysis",
    "session_behavior.csv": "Session Behavior",
    "conversion_by_channel.csv": "Conversion by Channel",
}


def get_gspread_client():
    """Authenticating gspread using service account credentials."""
    from google.oauth2.service_account import Credentials

    SCOPES = [
        "https://www.googleapis.com/auth/spreadsheets",
        "https://www.googleapis.com/auth/drive",
    ]

    creds = Credentials.from_service_account_file(
        os.getenv("GOOGLE_APPLICATION_CREDENTIALS"),
        scopes=SCOPES
    )

    return gspread.authorize(creds)


def export_csv_to_sheet(gc, sheet_id: str, csv_file: str, tab_name: str):
    """Reading a CSV and writing it to a specific tab in Google Sheets."""

    csv_path = OUTPUT_DIR / csv_file
    if not csv_path.exists():
        print(f"  Skipping {csv_file} — file not found. Run run_queries.py first.")
        return

    # Reading CSV into DataFrame
    df = pd.read_csv(csv_path)

    # Fixing NaN / Inf values (Google Sheets cannot accept them)
    df = df.replace([np.nan, np.inf, -np.inf], "")

    # Opening the Google Sheet
    spreadsheet = gc.open_by_key(sheet_id)

    # Trying to get existing tab, or creating a new one
    try:
        worksheet = spreadsheet.worksheet(tab_name)
        worksheet.clear()
    except gspread.exceptions.WorksheetNotFound:
        worksheet = spreadsheet.add_worksheet(title=tab_name, rows=1000, cols=20)

    # Writing headers + data to the sheet
    data = [df.columns.tolist()] + df.values.tolist()
    worksheet.update(data)

    print(f"  Exported {csv_file} → Sheet tab: '{tab_name}' ({len(df)} rows)")


def main():
    print("Connecting to Google Sheets...")
    gc = get_gspread_client()

    for csv_file, tab_name in SHEET_TABS.items():
        export_csv_to_sheet(gc, SHEET_ID, csv_file, tab_name)

    print(f"\nDone. Open your sheet: https://docs.google.com/spreadsheets/d/{SHEET_ID}")


if __name__ == "__main__":
    main()
