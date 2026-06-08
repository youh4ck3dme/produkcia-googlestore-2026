#!/usr/bin/env bash
# BizAgent — deploy Flutter web na Vercel (produkcia).
#
# Prvýkrát: npx vercel@latest login && npx vercel@latest link
# Deploy:   ./scripts/deploy_vercel.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
# Vercel CLI v54+ vyžaduje --scope v neinteraktívnom režime (viac tímov).
VERCEL_SCOPE="${VERCEL_SCOPE:-h4ck3d}"
# Statický deploy z build/web — projekt bez remote Flutter buildu (nie bizagent-production).
VERCEL_PROJECT="${VERCEL_PROJECT:-produkcia-googlestore-2026}"
PREVIEW=false
for arg in "$@"; do
  [ "$arg" = "--preview" ] && PREVIEW=true
done

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

die() { echo -e "${RED}✗${NC} $*" >&2; exit 1; }
ok() { echo -e "${GREEN}✓${NC} $*"; }

FLUTTER_WEB_FLAGS=(
  --release
  --base-href "/"
  --dart-define=PLAY_MVP=true
  --web-resources-cdn
  --no-wasm-dry-run
)

command -v flutter >/dev/null || die "Flutter nie je v PATH."

if ! npx --yes vercel@latest whoami >/dev/null 2>&1; then
  die "Nie si prihlásený. Spusti: npx vercel@latest login"
fi

# Deploy z build/web (kratšia cesta — vyhne sa ENAMETOOLONG pri link z rootu).
WEB_DIR="$ROOT/build/web"

echo ""
echo "1/4 flutter pub get + analyze"
flutter pub get
dart analyze lib

echo ""
echo "2/4 flutter build web (CDN CanvasKit)"
flutter build web "${FLUTTER_WEB_FLAGS[@]}"
[ -f "build/web/index.html" ] || die "build zlyhal"

echo ""
echo "3/4 trim + optimalizácia (< 100 MB limit)"
bash scripts/trim_web_build.sh

SIZE_MB=$(du -sm build/web | cut -f1)
echo "   Veľkosť build/web: ${SIZE_MB} MB"
if [ "$SIZE_MB" -gt 95 ]; then
  echo -e "${YELLOW}!${NC} Blízko 100 MB limitu — zváž kompresiu assets/images/*.png"
fi

echo ""
echo "4/4 vercel deploy (len build/web, archive=tgz, project=${VERCEL_PROJECT})"
DEPLOY_ARGS=(--yes --archive=tgz --scope "$VERCEL_SCOPE" --project "$VERCEL_PROJECT")
[ "$PREVIEW" = false ] && DEPLOY_ARGS+=(--prod)

# Upload IBA build/web — nie celý repo; cwd build/web kvôli Vercel link path limitom
(cd "$WEB_DIR" && npx --yes vercel@latest deploy . "${DEPLOY_ARGS[@]}")

echo ""
ok "Deploy hotový!"
if [ "$PREVIEW" = false ]; then
  case "$VERCEL_PROJECT" in
    produkcia-googlestore-2026) echo "   https://produkcia-googlestore-2026.vercel.app" ;;
    bizagent-production) echo "   https://bizagent-production-h4ck3d.vercel.app" ;;
    web) echo "   https://web-h4ck3d.vercel.app" ;;
    *) echo "   Skontroluj production URL vo Vercel dashboarde pre: $VERCEL_PROJECT" ;;
  esac
fi
echo ""
echo "Firebase Auth — pridaj Vercel doménu (raz):"
echo "  https://console.firebase.google.com/project/bizagent-live-2026/authentication/settings"
