# Android Release AAB — lokálne aj CI (A→Z)

**Package:** `sk.bizagent.app` · **Firebase:** `gifted-mountain-476207-u4` · **Supabase:** `kpsnwpuydqqojwmrnkdy`

## 1. Lokálne súbory (gitignored)

| Súbor | Účel |
|-------|------|
| `android/app/upload-keystore.jks` | Upload keystore pre Play App Signing |
| `android/key.properties` | `storeFile`, heslá, alias |
| `dart_defines/supabase.json` | `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `GOOGLE_WEB_CLIENT_ID` |

Vytvorenie signing:

```bash
./setup_android_play_signing.sh
cp dart_defines/supabase.example.json dart_defines/supabase.json
# doplň Supabase hodnoty z dashboardu
```

## 2. GitHub Secrets (jednorazovo)

```bash
chmod +x scripts/setup_github_android_secrets.sh
./scripts/setup_github_android_secrets.sh --with-supabase
```

| Secret | Zdroj |
|--------|-------|
| `ANDROID_KEYSTORE_BASE64` | `upload-keystore.jks` |
| `ANDROID_KEY_PROPERTIES` | `key.properties` |
| `SUPABASE_TEST_URL` | `supabase.json` → URL |
| `SUPABASE_TEST_PUBLISHABLE_KEY` | `supabase.json` → key |
| `SUPABASE_URL` / `SUPABASE_PUBLISHABLE_KEY` | alias (hosting workflow) |

## 3. Lokálny release build

```bash
./scripts/verify_repo_and_release.sh
./build_release_aab.sh
# výstup: build/app/outputs/bundle/release/app-release.aab
```

## 4. CI build (GitHub Actions)

**Workflow:** `.github/workflows/android_release.yml`

**Spustenie:**

- Tag `v*` (napr. `git tag v1.0.1 && git push origin v1.0.1`)
- Manuálne: `./scripts/trigger_android_release_ci.sh`

**CI kroky:**

1. `run_core_tests.sh`
2. `dart_defines/supabase.ci.json` zo secrets
3. Dekódovanie keystore + `key.properties`
4. `flutter build appbundle --obfuscate --split-debug-info=build/symbols`
5. Overenie `supabase.co` v `libapp.so`
6. Artefakty: `app-release-bundle`, `app-release-symbols`

**Stiahnuť AAB z CI:**

```bash
gh run list --workflow=android_release.yml
gh run download <RUN_ID> -n app-release-bundle -D build/ci-artifacts
```

## 5. Pred uploadom do Play Console

```bash
./scripts/verify_repo_and_release.sh --require-aab
bash scripts/seed_play_reviewer_account.sh   # Play reviewer účet v Supabase
```

## 6. Checklist GO/NO-GO

- [ ] `applicationId` = `sk.bizagent.app`
- [ ] `targetSdk` = 35
- [ ] AAB obsahuje Supabase URL (strings grep)
- [ ] GitHub secrets × 4 nastavené
- [ ] Play reviewer účet v Supabase (nie Firebase)
- [ ] Privacy URL live: `https://bizagent.sk/privacy-policy.html`