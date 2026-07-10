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
for f in android/app/google-services.json android/app/src/debug/google-services.json android/app/src/release/google-services.json; do
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
DEBUG_SHA_LC_EXPORT="$DEBUG_SHA_LC" python3 - <<'PY'
import json
import os
from pathlib import Path

issues = []
ok = []

debug_sha = os.environ.get("DEBUG_SHA_LC_EXPORT", "")

web_client = ""
supabase = Path("dart_defines/supabase.json")
if supabase.exists():
    web_client = json.load(open(supabase)).get("GOOGLE_WEB_CLIENT_ID", "")

def load_pkg(path: Path):
    if not path.exists():
        return None
    data = json.load(open(path))
    for c in data.get("client", []):
        if c["client_info"]["android_client_info"]["package_name"] == "sk.bizagent.app":
            return data["project_info"]["project_number"], c.get("oauth_client", [])
    return None

main = load_pkg(Path("android/app/google-services.json"))
dbg = load_pkg(Path("android/app/src/debug/google-services.json"))
rel = load_pkg(Path("android/app/src/release/google-services.json"))

if main and main[0] != "90348815049":
    issues.append(
        "android/app/google-services.json je STARÝ (542280140779). Spusti: git pull && "
        "bash scripts/setup_google_signin_firebase.sh"
    )
elif main and main[0] == "90348815049":
    ok.append("android/app/google-services.json → gifted-mountain (90348815049)")

for label, cfg in (("debug", dbg), ("release", rel)):
    if not cfg:
        issues.append(f"chýba android/app/src/{label}/google-services.json")
        continue
    pn, oauth = cfg
    if pn != "90348815049":
        issues.append(f"{label} google-services.json má zlý project_number: {pn}")
    else:
        ok.append(f"{label} build → gifted-mountain")
    web_ids = [o["client_id"] for o in oauth if o.get("client_type") == 3]
    if web_client and web_client not in web_ids:
        issues.append(f"{label}: GOOGLE_WEB_CLIENT_ID nie je v oauth_client (type 3)")

if web_client.startswith("90348815049-"):
    ok.append("GOOGLE_WEB_CLIENT_ID je v tom istom GCP projekte ako Firebase OAuth")
else:
    issues.append("GOOGLE_WEB_CLIENT_ID nie je z projektu 90348815049")

print("=== Výsledok ===")
for line in ok:
    print(f"  ✓ {line}")
for line in issues:
    print(f"  ✗ {line}")

if not issues:
    print("")
    print("Konfigurácia vyzerá OK. Debug/release buildy používajú src/*/google-services.json.")
    print("Ak Google login zlyhá po výbere účtu, over Supabase Google provider:")
    print("  bash scripts/configure_google_oauth_supabase.sh")
else:
    print("")
    print("Oprava:")
    print("  git pull origin main")
    print("  bash scripts/setup_google_signin_firebase.sh")
    print("  flutter clean && bash scripts/run_with_supabase.sh")
PY