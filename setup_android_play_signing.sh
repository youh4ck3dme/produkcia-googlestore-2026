#!/usr/bin/env bash
set -euo pipefail

# Creates a NEW Android upload keystore + key.properties for Google Play.
# - Writes keystore to: android/app/upload-keystore.jks
# - Writes secrets to:  android/key.properties   (gitignored)
# - Writes a local backup view to: android/KEYSTORE_SECRETS.txt (gitignored)
#
# IMPORTANT:
# - Do NOT commit any of the generated files.
# - For Play Store, enable "Play App Signing" and use this as the *upload* key.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

if [[ ! -f "pubspec.yaml" ]]; then
  echo "ERROR: Run this script from the Flutter project root (where pubspec.yaml exists)."
  exit 1
fi

KEYSTORE_PATH="android/app/upload-keystore.jks"
KEY_PROPS_PATH="android/key.properties"
SECRETS_PATH="android/KEYSTORE_SECRETS.txt"
ALIAS="bizagent-upload"

mkdir -p "android/app"

# Delete old artifacts (user asked for fresh start).
rm -f "$KEYSTORE_PATH" "$KEY_PROPS_PATH" "$SECRETS_PATH"

STORE_PASS="$(openssl rand -base64 32 | tr -d '\n')"
KEY_PASS="$STORE_PASS"

# Generate keystore (non-interactive).
keytool -genkeypair \
  -keystore "$KEYSTORE_PATH" \
  -storetype JKS \
  -storepass "$STORE_PASS" \
  -keypass "$KEY_PASS" \
  -alias "$ALIAS" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -dname "CN=BizAgent, OU=BizAgent, O=BizAgent, L=Bratislava, ST=BA, C=SK" \
  -noprompt >/dev/null

# Write key.properties used by Gradle (storeFile is resolved from android/app/).
cat > "$KEY_PROPS_PATH" <<EOF
storeFile=upload-keystore.jks
storePassword=$STORE_PASS
keyAlias=$ALIAS
keyPassword=$KEY_PASS
EOF

# Write a local "human readable" copy for you (still secret; gitignored).
cat > "$SECRETS_PATH" <<EOF
Android upload keystore generated.

Keystore path:
  $KEYSTORE_PATH

Gradle config path:
  $KEY_PROPS_PATH

Alias:
  $ALIAS

storePassword / keyPassword:
  (stored in $KEY_PROPS_PATH)

Next:
  flutter build appbundle --release
  Output: build/app/outputs/bundle/release/app-release.aab
EOF

chmod 600 "$KEYSTORE_PATH" "$KEY_PROPS_PATH" "$SECRETS_PATH" || true

echo "OK: Created fresh Android upload keystore + android/key.properties"
echo " - $KEYSTORE_PATH"
echo " - $KEY_PROPS_PATH"
echo "Secrets note: $SECRETS_PATH (do not share)"

