# Play Store P0 Checklist — stav 2026-07-10

**Vetva:** `main` @ `67c2bda` (P1 migrácia + emulator scripts)  
**Supabase live:** `kpsnwpuydqqojwmrnkdy` (`bizagent-app-2026`)

---

## P0 technické (kód + CI)

| # | Položka | Stav | Dôkaz |
|---|---------|------|-------|
| 1 | `delete-account` edge function | ✅ | `supabase/functions/delete-account/index.ts` |
| 2 | `delete-account` deploynutá | ✅ | deploy 2026-07-10 |
| 3 | Klient volá `delete-account` | ✅ | `auth_repository.dart` |
| 4 | UI mazania účtu | ✅ | `settings_screen.dart` |
| 5 | Soft delete → Supabase | ✅ | AGENT B |
| 6 | Export → Supabase | ✅ | `SupabaseExportDataSource` |
| 7 | Watched companies → Supabase | ✅ | AGENT B |
| 8 | Notifikácie → Supabase | ✅ | `features/tools/services/monitoring_service.dart` |
| 9 | Číslovanie faktúr → Supabase | ✅ | `SupabaseInvoiceNumberingRepository` + RPC |
| 10 | `FirebaseAuth` v user-data path | ✅ | 0× |
| 11 | `flutter test --dart-define=PLAY_MVP=false` | ✅ | 380+ passed |
| 12 | CI `PLAY_MVP=false` | ✅ | `.github/workflows/test.yml` |
| 13 | AAB release build + Supabase defines | ✅ | `build_release_aab.sh` |
| 14 | Emulator run scripts | ✅ | `run_with_supabase.sh`, `attach_android.sh` |
| 15 | Play upload helper | ✅ | `scripts/prepare_play_upload.sh` |
| 16 | E2E logcat checklist | ✅ | `scripts/e2e_login_checklist.sh` |

---

## P0 manuálne (Play Console + infra)

| # | Položka | Stav | Akcia |
|---|---------|------|-------|
| 17 | Google OAuth na Supabase | ⚠️ | `bash scripts/configure_google_oauth_supabase.sh` + redirect URI v Google Console |
| 18 | Edge function secrets (MISTRAL/Gemini) | ⚠️ | Supabase Dashboard → Edge Functions → Secrets |
| 19 | Deploy `invoice_counters` migrácie | ⚠️ | `supabase db push` alebo merge migration na live |
| 20 | Privacy Policy URL | ⚠️ | https://web-one-beta-76.vercel.app/privacy.html |
| 21 | Account deletion URL | ⚠️ | https://web-one-beta-76.vercel.app/delete-account.html |
| 22 | Live E2E test (login → faktúra → delete) | ⚠️ | `bash scripts/e2e_login_checklist.sh` + manuálny checklist |
| 23 | Demo účet pre Play review | ⚠️ | `DEMO_ACCOUNT_SECRETS.txt` |
| 24 | Rotácia leaked secrets | ⚠️ | git history — demo heslo + API keys |
| 25 | Firebase `google-services.json` | ⚠️ | `sk.bizagent.app` v `bizagent-live-2026` |
| 26 | Play Console nový listing | ⚠️ | `sk.bizagent.app` — internal track |
| 27 | Upload AAB | ⚠️ | `bash scripts/prepare_play_upload.sh` |

---

## Firestore dlh (P1 — zostáva)

| Súbor | Účel |
|-------|------|
| `company_lookup_service.dart` | IČO cache |
| `categorization_service.dart` | Kategórie výdavkov |
| `firestore_export_data_source.dart` | Legacy (zmazať) |
| `functions/src/batchRefreshWatched.ts` | Backend monitoring |

Detail: `docs/DATALAYER_DEBT.md`

---

## Manuálny QA (5 krokov pred uploadom)

1. **Registrácia / Google login** — `bash scripts/run_with_supabase.sh`
2. **Vytvor faktúru** — číslo `2026/001` formát (Supabase counter)
3. **Soft delete** → Kôš → Obnoviť
4. **Export ZIP**
5. **Zmazať účet** — Nastavenia → potvrdenie

---

## Readiness skóre

| Oblasť | Skóre |
|--------|-------|
| Kód + testy | **94/100** |
| Supabase infra | **80/100** |
| Play metadata | **60/100** |
| **Celkom P0** | **82/100** |

**Verdikt:** GO internal testing po dokončení manuálnych položiek 17–27.