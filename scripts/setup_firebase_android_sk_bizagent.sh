#!/usr/bin/env bash
# Registruje sk.bizagent.app vo Firebase (bizagent-live-2026) a stiahne google-services.json.
# Používa gcloud auth (youh4ck3dme@gmail.com) — firebase login môže byť iný účet.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT_ID="bizagent-live-2026"
PACKAGE="sk.bizagent.app"
DISPLAY_NAME="BizAgent Play 2026"
OUT_JSON="android/app/google-services.json"

if ! command -v gcloud >/dev/null; then
  echo "ERROR: gcloud nie je nainštalovaný."
  exit 1
fi

ACCOUNT="$(gcloud config get-value account 2>/dev/null || true)"
echo "gcloud account: ${ACCOUNT}"
gcloud config set project "$PROJECT_ID" >/dev/null
gcloud auth application-default set-quota-project "$PROJECT_ID" >/dev/null 2>&1 || true

TOKEN="$(gcloud auth print-access-token)"
AUTH_HDR=(-H "Authorization: Bearer ${TOKEN}" -H "x-goog-user-project: ${PROJECT_ID}")

echo "Hľadám existujúcu Android app ${PACKAGE}..."
SEARCH="$(curl -sS "https://firebase.googleapis.com/v1beta1/projects/${PROJECT_ID}:searchApps?pageSize=100" "${AUTH_HDR[@]}")"
APP_ID="$(python3 - <<'PY' "$SEARCH" "$PACKAGE"
import json, sys
data = json.loads(sys.argv[1])
pkg = sys.argv[2]
for app in data.get("apps", []):
    if app.get("platform") == "ANDROID" and app.get("namespace") == pkg:
        print(app.get("appId", ""))
        break
PY
)"

if [[ -z "$APP_ID" ]]; then
  echo "Vytváram Firebase Android app ${PACKAGE}..."
  CREATE="$(curl -sS -X POST \
    "https://firebase.googleapis.com/v1beta1/projects/${PROJECT_ID}/androidApps" \
    "${AUTH_HDR[@]}" \
    -H "Content-Type: application/json" \
    -d "{\"packageName\":\"${PACKAGE}\",\"displayName\":\"${DISPLAY_NAME}\"}")"
  APP_ID="$(python3 - <<'PY' "$CREATE"
import json, sys
data = json.loads(sys.argv[1])
print(data.get("appId", "") or "")
PY
)"
  if [[ -z "$APP_ID" ]]; then
    OP_NAME="$(python3 - <<'PY' "$CREATE"
import json, sys
data = json.loads(sys.argv[1])
print(data.get("name", "") or "")
PY
)"
    if [[ -n "$OP_NAME" ]]; then
      echo "Firebase LRO — čakám na dokončenie..."
      for _ in $(seq 1 30); do
        sleep 2
        SEARCH="$(curl -sS "https://firebase.googleapis.com/v1beta1/projects/${PROJECT_ID}:searchApps?pageSize=100" "${AUTH_HDR[@]}")"
        APP_ID="$(python3 - <<'PY' "$SEARCH" "$PACKAGE"
import json, sys
data = json.loads(sys.argv[1])
pkg = sys.argv[2]
for app in data.get("apps", []):
    if app.get("platform") == "ANDROID" and app.get("namespace") == pkg:
        print(app.get("appId", ""))
        break
PY
)"
        [[ -n "$APP_ID" ]] && break
      done
    fi
  fi
  if [[ -z "$APP_ID" ]]; then
    echo "ERROR: Nepodarilo sa vytvoriť/nájsť app:"
    echo "$CREATE"
    exit 1
  fi
  echo "AppId: ${APP_ID}"
else
  echo "App už existuje: ${APP_ID}"
fi

# Upload keystore SHA-1 (Google Sign-In)
KEY_PROPS="android/key.properties"
KEYSTORE="android/app/upload-keystore.jks"
if [[ -f "$KEY_PROPS" && -f "$KEYSTORE" ]]; then
  STORE_PASS="$(grep '^storePassword=' "$KEY_PROPS" | cut -d= -f2- | tr -d '\r')"
  ALIAS="$(grep '^keyAlias=' "$KEY_PROPS" | cut -d= -f2- | tr -d '\r')"
  SHA1="$(keytool -list -v -keystore "$KEYSTORE" -alias "$ALIAS" -storepass "$STORE_PASS" 2>/dev/null | awk '/SHA1:/ {print $2}')"
  if [[ -n "$SHA1" ]]; then
    echo "Registrujem SHA-1 upload kľúča..."
    curl -sS -X POST \
      "https://firebase.googleapis.com/v1beta1/projects/${PROJECT_ID}/androidApps/${APP_ID}/sha" \
      "${AUTH_HDR[@]}" \
      -H "Content-Type: application/json" \
      -d "{\"shaHash\":\"${SHA1}\"}" >/dev/null || echo "WARN: SHA-1 možno už existuje"
  fi
else
  echo "WARN: Chýba keystore — spusti ./setup_android_play_signing.sh a znova tento skript pre SHA-1"
fi

echo "Sťahujem google-services.json..."
RAW="$(curl -sS \
  "https://firebase.googleapis.com/v1beta1/projects/${PROJECT_ID}/androidApps/${APP_ID}/config" \
  "${AUTH_HDR[@]}")"

python3 - <<'PY' "$RAW" "$OUT_JSON" "$PACKAGE"
import base64, json, sys
raw, out_path, pkg = sys.argv[1], sys.argv[2], sys.argv[3]
data = json.loads(raw)
if "configFileContents" in data:
    decoded = base64.b64decode(data["configFileContents"]).decode("utf-8")
    cfg = json.loads(decoded)
else:
    cfg = data
clients = cfg.get("client", [])
if not any(c.get("client_info", {}).get("android_client_info", {}).get("package_name") == pkg for c in clients):
    raise SystemExit(f"config neobsahuje {pkg}")
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
print(f"OK: {out_path}")
PY
echo "App ID: ${APP_ID}"
echo "Ďalej: aktualizuj lib/firebase_options.dart (flutterfire configure) alebo ručne android appId."
