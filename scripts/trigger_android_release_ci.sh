#!/usr/bin/env bash
# Spustí GitHub Actions workflow android_release.yml (workflow_dispatch).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Chýba $1" >&2
    exit 1
  }
}

need_cmd gh

echo "==> Overenie GitHub secrets"
MISSING=""
for name in ANDROID_KEYSTORE_BASE64 ANDROID_KEY_PROPERTIES SUPABASE_TEST_URL SUPABASE_TEST_PUBLISHABLE_KEY; do
  if ! gh secret list 2>/dev/null | awk '{print $1}' | grep -qx "$name"; then
    MISSING="$MISSING $name"
  fi
done
if [[ -n "$MISSING" ]]; then
  echo "Chýbajú secrets:$MISSING"
  echo "Spusti: ./scripts/setup_github_android_secrets.sh --with-supabase"
  exit 1
fi

echo "==> Spúšťam Android Release workflow"
gh workflow run android_release.yml --ref "$(git branch --show-current)"
echo ""
echo "Sleduj beh:"
echo "  gh run watch --workflow=android_release.yml"
echo ""
echo "Po úspechu stiahni AAB:"
echo "  gh run download --workflow=android_release.yml -n app-release-bundle -D build/ci-artifacts"