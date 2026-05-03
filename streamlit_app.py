"""
Entry point for Streamlit Community Cloud.

Set the app’s Main file path to either:
  - streamlit_app.py   (this file, repo root), or
  - sql/dashboard/app.py

CSV data is loaded from sql/data/ — no database required for the public demo.
"""
from __future__ import annotations

import sys
from pathlib import Path

_root = Path(__file__).resolve().parent
_dashboard = _root / "sql" / "dashboard"
sys.path.insert(0, str(_dashboard))

from app import main  # noqa: E402

main()
