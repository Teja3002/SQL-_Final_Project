
from __future__ import annotations

import sys
from pathlib import Path

_root = Path(__file__).resolve().parent
_dashboard = _root / "sql" / "dashboard"
sys.path.insert(0, str(_dashboard))

from app import main  # noqa: E402

main()
