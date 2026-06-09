#!/usr/bin/env bash
# Zapíše dart_defines/supabase.ci.json z env (CI secrets).
set -euo pipefail

OUT="${1:-dart_defines/supabase.ci.json}"

if [[ -z "${SUPABASE_TEST_URL:-}" || -z "${SUPABASE_TEST_PUBLISHABLE_KEY:-}" ]]; then
  exit 0
fi

mkdir -p "$(dirname "$OUT")"
python3 -c "
import json, os, sys
path = sys.argv[1]
json.dump(
    {
        'SUPABASE_URL': os.environ['SUPABASE_TEST_URL'],
        'SUPABASE_PUBLISHABLE_KEY': os.environ['SUPABASE_TEST_PUBLISHABLE_KEY'],
        'GOOGLE_WEB_CLIENT_ID': os.environ.get('GOOGLE_WEB_CLIENT_ID', ''),
    },
    open(path, 'w'),
    indent=2,
)
print(f'Wrote {path}')
" "$OUT"
