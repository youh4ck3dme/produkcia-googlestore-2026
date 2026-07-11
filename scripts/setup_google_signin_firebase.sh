#!/usr/bin/env bash
# BizAgent — Firebase gifted-mountain: Android app + SHA-1 pre Google Sign-In (debug)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT="gifted-mountain-476207-u4"
APP_ID="1:90348815049:android:eeab2630fb64fc2fd54318"
PACKAGE="sk.bizagent.app"

DEBUG_SHA=$(keytool -list -v -keystore "$HOME/.android/debug.keystore" -alias androiddebugkey -storepass android -keypass android 2>/dev/null | awk -F': ' '/SHA1:/{print $2}' | tr -d ' ')

echo "→ Firebase projekt: $PROJECT"
echo "→ Package: $PACKAGE"
echo "→ Debug SHA-1: $DEBUG_SHA"

if ! firebase apps:list --project="$PROJECT" 2>/dev/null | grep -q "$APP_ID"; then
  echo "→ Vytváram Firebase Android app…"
  firebase apps:create android "$PACKAGE" --package-name="$PACKAGE" --project="$PROJECT"
  APP_ID=$(firebase apps:list --project="$PROJECT" --json 2>/dev/null | python3 -c "import json,sys; apps=json.load(sys.stdin).get('result',[]); print(next((a['appId'] for a in apps if a.get('platform')=='ANDROID'), ''))")
fi

echo "→ App ID: $APP_ID"

echo "→ Registrujem debug SHA-1…"
firebase apps:android:sha:create "$APP_ID" "$DEBUG_SHA" --project="$PROJECT" 2>/dev/null || echo "  (SHA už existuje)"

if [[ -f android/key.properties ]]; then
  STORE=$(grep storeFile android/key.properties | cut -d= -f2)
  ALIAS=$(grep keyAlias android/key.properties | cut -d= -f2)
  PASS=$(grep storePassword android/key.properties | cut -d= -f2)
  UPLOAD_SHA=$(keytool -list -v -keystore "android/app/$STORE" -alias "$ALIAS" -storepass "$PASS" -keypass "$PASS" 2>/dev/null | awk -F': ' '/SHA1:/{print $2}' | tr -d ' ')
  if [[ -n "${UPLOAD_SHA:-}" ]]; then
    echo "→ Registrujem upload SHA-1…"
    firebase apps:android:sha:create "$APP_ID" "$UPLOAD_SHA" --project="$PROJECT" 2>/dev/null || echo "  (upload SHA už existuje)"
  fi
fi

OAUTH_JSON="$ROOT/android/app/src/debug/google-services.json"
mkdir -p android/app/src/debug android/app/src/release
rm -f "$OAUTH_JSON"
firebase apps:sdkconfig ANDROID "$APP_ID" --project="$PROJECT" -o "$OAUTH_JSON"

# Firebase sdkconfig často nemá Supabase web client — doplníme ho ručne pre oba build typy.
python3 - <<'PY'
import json
from pathlib import Path

web_client = "90348815049-e5faruj0mfvnn34m80k9b9b5upp9nn6v.apps.googleusercontent.com"
firebase_web = "90348815049-ireo2g7l3cq9ca1js4f736qpbm9dets0.apps.googleusercontent.com"
root = Path("android/app/src")

for variant in ("debug", "release"):
    path = root / variant / "google-services.json"
    if not path.exists():
        continue
    data = json.loads(path.read_text())
    client = data["client"][0]
    oauth = client.setdefault("oauth_client", [])
    if not any(o.get("client_id") == web_client for o in oauth):
        oauth.insert(0, {"client_id": web_client, "client_type": 3})
    invite = client.setdefault("services", {}).setdefault("appinvite_service", {})
    others = invite.setdefault("other_platform_oauth_client", [])
    for cid in (web_client, firebase_web):
        if not any(o.get("client_id") == cid for o in others):
            others.append({"client_id": cid, "client_type": 3})
    path.write_text(json.dumps(data, indent=2) + "\n")

# release = rovnaká OAuth konfigurácia ako debug (upload SHA je v Firebase)
release = root / "release" / "google-services.json"
debug = root / "debug" / "google-services.json"
if debug.exists():
    release.write_text(debug.read_text())
PY

echo ""
echo "✓ Debug:   android/app/src/debug/google-services.json"
echo "✓ Release: android/app/src/release/google-services.json"
echo ""
echo "Ďalší krok (ak chýba Android OAuth client_type=1 v JSON):"
echo "  1. Otvor: https://console.cloud.google.com/auth/clients?project=$PROJECT"
echo "  2. Create client → Android → package $PACKAGE + SHA-1 $DEBUG_SHA"
echo "  3. bash scripts/verify_google_signin.sh"
echo "  4. bash scripts/run_with_supabase.sh"

if command -v open >/dev/null 2>&1; then
  open "https://console.cloud.google.com/auth/clients?project=$PROJECT"
fi