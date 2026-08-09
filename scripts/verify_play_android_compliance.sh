#!/usr/bin/env bash
# Play Android compliance gate — permissions, SDK, AI assets, release build smoke.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
ok() { echo -e "${GREEN}✓${NC} $*"; }
fail() { echo -e "${RED}✗${NC} $*"; exit 1; }

MANIFEST="android/app/src/main/AndroidManifest.xml"
GRADLE="android/app/build.gradle.kts"

echo "BizAgent Play Android compliance"
echo "================================="

[[ -f "$MANIFEST" ]] || fail "Chýba $MANIFEST"

if grep -q 'android.permission.READ_EXTERNAL_STORAGE"' "$MANIFEST" \
  && ! grep -q 'READ_EXTERNAL_STORAGE" tools:node="remove"' "$MANIFEST"; then
  fail "READ_EXTERNAL_STORAGE stále deklarované (bez remove)"
fi
ok "Žiadne broad storage permissions v manifeste"

grep -q 'useAndroidPhotoPicker\|ReceiptImagePicker\|configureAndroidPhotoPicker' lib/core/services/receipt_image_picker.dart \
  || fail "Chýba Photo Picker helper"
ok "Android Photo Picker helper prítomný"

grep -q 'aiGeneratedLabel\|AiGeneratedLabel' lib/shared/widgets/ai_generated_label.dart \
  || fail "Chýba AI generated label widget"
ok "AI transparency label widget"

[[ -f supabase/functions/generate-content/safety.ts ]] \
  || fail "Chýba generate-content safety.ts"
ok "AI safety filters (edge function)"

[[ -f web/.well-known/assetlinks.json ]] \
  || fail "Chýba web/.well-known/assetlinks.json"
grep -q 'sk.bizagent.app' web/.well-known/assetlinks.json \
  || fail "assetlinks.json nemá sk.bizagent.app"
ok "Digital Asset Links JSON"

grep -q 'autoVerify="true"' "$MANIFEST" || fail "Chýba android:autoVerify App Links"
ok "Android App Links intent-filter"

TARGET_SDK=$(grep -E 'targetSdk\s*=' "$GRADLE" | head -1 | grep -oE '[0-9]+' || true)
[[ -n "$TARGET_SDK" && "$TARGET_SDK" -ge 35 ]] || fail "targetSdk < 35 ($TARGET_SDK)"
ok "targetSdk = $TARGET_SDK"

echo ""
echo "Spúšťam unit testy (Play subset)..."
flutter test \
  test/core/services/receipt_image_picker_test.dart \
  test/shared/widgets/ai_generated_label_test.dart \
  test/core/services/gemini_service_test.dart \
  test/features/ai_tools/biz_bot_prompt_test.dart \
  --dart-define=PLAY_MVP=true >/tmp/play_compliance_test.log 2>&1 \
  || { tail -30 /tmp/play_compliance_test.log; fail "Unit testy zlyhali"; }
ok "Unit testy PASS"

echo ""
echo "Kontrola web buildu (Supabase embed)..."
JS="build/web/main.dart.js"
if [[ -f "$JS" ]] && grep -q 'kpsnwpuydqqojwmrnkdy' "$JS"; then
  ok "Web build obsahuje Supabase URL"
elif [[ -f "$JS" ]]; then
  fail "Web build BEZ Supabase — spusti: bash scripts/build_web_release.sh && firebase deploy --only hosting"
else
  echo "  (preskočené — chýba build/web; pred deployom: bash scripts/build_web_release.sh)"
fi

echo ""
ok "Play Android compliance PASS"