# Validating that query output files exist and have correct structure

import pytest
import pandas as pd
from pathlib import Path

OUTPUT_DIR = Path(__file__).parent.parent / "outputs"


def load_csv(filename: str) -> pd.DataFrame:
    """Loading a CSV from the outputs folder."""
    path = OUTPUT_DIR / filename
    if not path.exists():
        pytest.skip(f"{filename} not found — run run_queries.py first.")
    return pd.read_csv(path)


class TestUserAcquisition:
    """Testing for user acquisition query output."""

    def test_file_exists(self):
        assert (OUTPUT_DIR / "user_acquisition.csv").exists()

    def test_required_columns(self):
        df = load_csv("user_acquisition.csv")
        required = ["channel", "total_users", "total_sessions", "new_users"]
        for col in required:
            assert col in df.columns, f"Missing column: {col}"

    def test_no_negative_users(self):
        df = load_csv("user_acquisition.csv")
        assert (df["total_users"] >= 0).all(), "Negative user counts found"

    def test_new_user_pct_range(self):
        df = load_csv("user_acquisition.csv")
        assert (df["new_user_pct"] >= 0).all()
        assert (df["new_user_pct"] <= 100).all()


class TestFunnelAnalysis:
    """Testing for funnel analysis query output."""

    def test_file_exists(self):
        assert (OUTPUT_DIR / "funnel_analysis.csv").exists()

    def test_has_six_steps(self):
        df = load_csv("funnel_analysis.csv")
        assert len(df) == 6, f"Expected 6 funnel steps, got {len(df)}"

    def test_funnel_decreases(self):
        df = load_csv("funnel_analysis.csv").sort_values("funnel_step")
        sessions = df["sessions_at_step"].tolist()

        for i in range(1, len(sessions)):
            assert (
                sessions[i] <= sessions[i - 1]
            ), "Funnel steps should decrease"

    def test_conversion_rate_range(self):
        df = load_csv("funnel_analysis.csv")

        rates = df["step_conversion_rate_pct"].dropna()

        assert (rates >= 0).all()
        assert (rates <= 100).all()


class TestSessionBehavior:
    """Testing for session behavior query output."""

    def test_file_exists(self):
        assert (OUTPUT_DIR / "session_behavior.csv").exists()

    def test_bounce_rate_valid(self):
        df = load_csv("session_behavior.csv")
        assert df["bounce_rate_pct"].iloc[0] >= 0
        assert df["bounce_rate_pct"].iloc[0] <= 100

    def test_positive_session_duration(self):
        df = load_csv("session_behavior.csv")
        assert df["avg_session_duration_seconds"].iloc[0] >= 0
