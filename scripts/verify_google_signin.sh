#!/usr/bin/env bash
# BizAgent — diagnostika Google Sign-In (SHA-1, client IDs, Supabase)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== BizAgent Google Sign-In diagnostika ==="
echo ""

DEBUG_SHA=$(keytool -list -v -keystore "$HOME/.android/debug.keystore" -alias androiddebugkey -storepass android -keypass android 2>/dev/null | awk -F': ' '/SHA1:/{gsub(/ /,":",$2); print toupper($2)}' | tr -d ':')
DEBUG_SHA_LC=$(echo "$DEBUG_SHA" | tr '[:upper:]' '[:lower:]')
echo "Debug keystore SHA-1: $DEBUG_SHA_LC"

if [[ -f android/key.properties ]]; then
  STORE=$(grep storeFile android/key.properties | cut -d= -f2)
  ALIAS=$(grep keyAlias android/key.properties | cut -d= -f2)
  PASS=$(grep storePassword android/key.properties | cut -d= -f2)
  UPLOAD_SHA=$(keytool -list -v -keystore "android/app/$STORE" -alias "$ALIAS" -storepass "$PASS" -keypass "$PASS" 2>/dev/null | awk -F': ' '/SHA1:/{gsub(/ /,":",$2); print toupper($2)}' | tr -d ':')
  UPLOAD_SHA_LC=$(echo "$UPLOAD_SHA" | tr '[:upper:]' '[:lower:]')
  echo "Upload keystore SHA-1:  $UPLOAD_SHA_LC"
fi

echo ""
echo "dart_defines/supabase.json:"
python3 - <<'PY'
import json
from pathlib import Path
p = Path("dart_defines/supabase.json")
if p.exists():
    d = json.load(open(p))
    print("  GOOGLE_WEB_CLIENT_ID:", d.get("GOOGLE_WEB_CLIENT_ID", "(missing)"))
else:
    print("  (missing dart_defines/supabase.json)")
PY

echo ""
for f in android/app/google-services.json android/app/src/debug/google-services.json; do
  if [[ -f "$f" ]]; then
    echo "$f:"
    python3 - <<PY
import json
from pathlib import Path
data = json.load(open("$f"))
pn = data["project_info"]["project_number"]
for c in data.get("client", []):
    pkg = c["client_info"]["android_client_info"]["package_name"]
    if pkg != "sk.bizagent.app":
        continue
    print(f"  project_number: {pn}")
    for o in c.get("oauth_client", []):
        cid = o["client_id"]
        ct = o.get("client_type")
        sha = o.get("android_info", {}).get("certificate_hash", "-")
        print(f"  oauth client_type={ct} sha={sha}")
        print(f"    {cid}")
PY
  fi
done

echo ""
echo "Firebase gifted-mountain SHA (ak je nakonfigurovaný):"
if command -v firebase >/dev/null 2>&1; then
  firebase apps:android:sha:list 1:90348815049:android:eeab2630fb64fc2fd54318 --project=gifted-mountain-476207-u4 2>/dev/null || echo "  (Firebase app/SHA ešte nie je vytvorený)"
fi

echo ""
echo "Očakávané:"
echo "  • Android OAuth (client_type=1) musí mať SHA = debug keystore"
echo "  • GOOGLE_WEB_CLIENT_ID musí byť Web client (client_type=3) v tom istom GCP projekte"
echo "  • Supabase Google provider musí používať rovnaký Web client ID + secret"
echo ""
echo "Oprava debug buildu:"
echo "  bash scripts/setup_google_signin_firebase.sh"
echo "  bash scripts/run_with_supabase.sh"