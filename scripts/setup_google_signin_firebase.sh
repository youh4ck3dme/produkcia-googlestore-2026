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

mkdir -p android/app/src/debug
firebase apps:sdkconfig ANDROID "$APP_ID" --project="$PROJECT" -o android/app/src/debug/google-services.json

echo ""
echo "✓ Debug google-services.json: android/app/src/debug/google-services.json"
echo ""
echo "Ďalší krok (ak chýba Android OAuth client_type=1 v JSON):"
echo "  1. Otvor: https://console.cloud.google.com/auth/clients?project=$PROJECT"
echo "  2. Create client → Android → package $PACKAGE + SHA-1 $DEBUG_SHA"
echo "  3. bash scripts/verify_google_signin.sh"
echo "  4. bash scripts/run_with_supabase.sh"

if command -v open >/dev/null 2>&1; then
  open "https://console.cloud.google.com/auth/clients?project=$PROJECT"
fi