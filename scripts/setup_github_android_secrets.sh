#!/usr/bin/env bash
# Nahraje lokálne Android signing súbory do GitHub Actions secrets
# pre .github/workflows/android_release.yml.
#
# Lokálne (gitignored):
#   android/app/upload-keystore.jks
#   android/key.properties
#
# GitHub (Settings → Secrets and variables → Actions):
#   ANDROID_KEYSTORE_BASE64
#   ANDROID_KEY_PROPERTIES
#
# Usage: ./scripts/setup_github_android_secrets.sh [--with-supabase]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

WITH_SUPABASE=false
for arg in "$@"; do
  case "$arg" in
    --with-supabase) WITH_SUPABASE=true ;;
    -h|--help)
      echo "Usage: ./scripts/setup_github_android_secrets.sh [--with-supabase]"
      echo ""
      echo "  --with-supabase  Sync SUPABASE_TEST_URL + SUPABASE_TEST_PUBLISHABLE_KEY"
      echo "                   z dart_defines/supabase.json (ak ešte nie sú v GitHube)"
      exit 0
      ;;
    *)
      echo "Neznámy argument: $arg" >&2
      exit 1
      ;;
  esac
done

KEYSTORE="android/app/upload-keystore.jks"
KEY_PROPS="android/key.properties"
DEFINES="dart_defines/supabase.json"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Chýba $1 — nainštaluj (napr. brew install gh)." >&2
    exit 1
  fi
}

need_cmd gh
need_cmd base64
need_cmd keytool
need_cmd python3

if [[ ! -f "$KEYSTORE" || ! -f "$KEY_PROPS" ]]; then
  echo "Chýba signing setup. Spusti najprv:" >&2
  echo "  ./setup_android_play_signing.sh" >&2
  exit 1
fi

STORE_PASS="$(grep -E '^storePassword=' "$KEY_PROPS" | cut -d= -f2-)"
KEY_ALIAS="$(grep -E '^keyAlias=' "$KEY_PROPS" | cut -d= -f2-)"
if [[ -z "$STORE_PASS" || -z "$KEY_ALIAS" ]]; then
  echo "android/key.properties musí obsahovať storePassword a keyAlias." >&2
  exit 1
fi

if ! keytool -list -keystore "$KEYSTORE" -storepass "$STORE_PASS" -alias "$KEY_ALIAS" >/dev/null 2>&1; then
  echo "Keystore a key.properties sa nezhodujú (zlé heslo alebo alias)." >&2
  exit 1
fi

echo "==> GitHub repo: $(gh repo view --json nameWithOwner -q .nameWithOwner)"
echo "==> ANDROID_KEYSTORE_BASE64 (z $KEYSTORE)"
base64 -i "$KEYSTORE" | gh secret set ANDROID_KEYSTORE_BASE64

echo "==> ANDROID_KEY_PROPERTIES (z $KEY_PROPS)"
gh secret set ANDROID_KEY_PROPERTIES < "$KEY_PROPS"

if [[ "$WITH_SUPABASE" == true ]]; then
  if [[ ! -f "$DEFINES" ]]; then
    echo "Chýba $DEFINES — preskočené --with-supabase." >&2
  else
    SUPABASE_URL=$(python3 -c "import json; print(json.load(open('$DEFINES'))['SUPABASE_URL'])")
    PUBLISHABLE_KEY=$(python3 -c "import json; print(json.load(open('$DEFINES'))['SUPABASE_PUBLISHABLE_KEY'])")
    echo "==> SUPABASE_TEST_URL + SUPABASE_TEST_PUBLISHABLE_KEY (z $DEFINES)"
    printf '%s' "$SUPABASE_URL" | gh secret set SUPABASE_TEST_URL
    printf '%s' "$PUBLISHABLE_KEY" | gh secret set SUPABASE_TEST_PUBLISHABLE_KEY
    # Aliasy pre firebase_hosting.yml (rovnaké hodnoty)
    printf '%s' "$SUPABASE_URL" | gh secret set SUPABASE_URL
    printf '%s' "$PUBLISHABLE_KEY" | gh secret set SUPABASE_PUBLISHABLE_KEY
  fi
fi

echo ""
echo "Hotovo. GitHub secrets pre android_release.yml:"
gh secret list | rg 'ANDROID_|SUPABASE(_TEST)?_(URL|PUBLISHABLE_KEY)' || true
echo ""
echo "Lokálne súbory zostávajú na mieste (gitignored):"
echo "  - $KEYSTORE"
echo "  - $KEY_PROPS"