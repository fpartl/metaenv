#!/bin/bash
# Development setup after a clone: the environment with pre-commit (uv) and its git hook. Safe to run again.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

uv sync
uv run pre-commit install
