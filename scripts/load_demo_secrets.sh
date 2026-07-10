#!/usr/bin/env bash
# Načíta DEMO_ACCOUNT_* z DEMO_ACCOUNT_SECRETS.txt v root projektu.
set -euo pipefail

_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_SECRETS_FILE="${DEMO_ACCOUNT_SECRETS_FILE:-$_ROOT/DEMO_ACCOUNT_SECRETS.txt}"

if [[ -f "$_SECRETS_FILE" ]]; then
  # shellcheck disable=SC1090
  set -a
  source "$_SECRETS_FILE"
  set +a
fi

if [[ -z "${DEMO_ACCOUNT_PASSWORD:-}" ]]; then
  echo "Chýba DEMO_ACCOUNT_PASSWORD. Skopíruj DEMO_ACCOUNT_SECRETS.txt.example → DEMO_ACCOUNT_SECRETS.txt" >&2
  exit 1
fi

export DEMO_ACCOUNT_EMAIL="${DEMO_ACCOUNT_EMAIL:-bizbizagent@bizbizagent.com}"
export DEMO_ACCOUNT_PASSWORD