# AGENT C — Orchestrátor + Play Store Gate

**Dátum:** 2026-07-10  
**Vetva:** `main` @ `fb218dc`  
**Verdikt:** **GO — internal testing** | **REWORK — production upload**

---

## Merge plán (vykonané)

```
main ← feat/supabase-datalayer-p0  (fast-forward, obsahuje aj AGENT A)
```

| Vetva | Commit | Obsah |
|-------|--------|-------|
| `feat/supabase-backend-p0` | `d487142` | delete-account, CI, secrets hygiene |
| `feat/supabase-datalayer-p0` | `fb218dc` | trash, export, watched companies |
| **`main`** | `fb218dc` | A+B zlúčené |

Žiadne merge konflikty.

---

## Testy (AGENT C run)

| Príkaz | Výsledok |
|--------|----------|
| `flutter test --dart-define=PLAY_MVP=false` | **380 passed, 5 skipped, 0 failed** |
| `cd functions && npm test` | **all smoke checks passed** |
| `flutter analyze` | **0 errors** (10 info) |
| `flutter build appbundle --release` | **✓ app-release.aab (141.5 MB)** |

---

## Firestore / FirebaseAuth audit

### P0 cieľové cesty (musí byť 0)

```bash
rg FirebaseAuth lib/features/tools lib/features/export lib/core/services/soft_delete
# → 0 matches ✅
```

### Zostávajúci Firestore (P1 dlh — 7 súborov)

| Súbor | Kategória |
|-------|-----------|
| `company_lookup_service.dart` | IČO cache |
| `core/services/monitoring_service.dart` | Notifikácie |
| `features/tools/services/monitoring_service.dart` | Monitoring backend |
| `shared/widgets/notification_bell.dart` | Notifikácie UI |
| `firestore_invoice_numbering_repository.dart` | Číslovanie |
| `categorization_service.dart` | Výdavky |
| `firestore_export_data_source.dart` | Legacy (nepoužívané) |

`FirebaseAuth`: **0× v produkčnom kóde** (len komentár).

---

## P0 checklist — zhrnutie

| Oblasť | Hotové | Chýba |
|--------|--------|-------|
| Kód migrácia A+B | 13/13 | — |
| CI / testy / AAB | 4/4 | — |
| Supabase infra | 2/4 | OAuth, edge secrets |
| Play metadata | 0/5 | Privacy URL, demo account, live deletion test, secret rotation, Play listing |

**Readiness skóre: 78/100** — detail `docs/PLAY_STORE_P0_CHECKLIST.md`

---

## GO / NO-GO rozhodnutie

### ✅ GO — Internal Testing (Play Console closed track)

Môžeš nahrať AAB na **internal testing** po dokončení:

1. Google OAuth na `kpsnwpuydqqojwmrnkdy`
2. Edge function secrets
3. Privacy policy URL (`web/privacy.html` → host)
4. Jednorazový live test: registrácia + zmazanie účtu

### ⚠️ REWORK — Production / Open testing

Pred otvoreným testovaním alebo produkciou:

- Rotácia secrets z git history
- Live account deletion overený na novom Supabase
- Firestore P1 migrácia (notifikácie, číslovanie) — odporúčané, nie hard blocker
- IAP server-side verify (P1)
- Data Safety form v Play Console

### ❌ NO-GO — ak

- OAuth nie je nastavený → login nefunguje
- `dart_defines/supabase.json` chýba pri builde → auth padá
- Privacy URL nie je verejná → Play odmietne listing

---

## 10 úloh na najbližších 7 dní

| # | Úloha | Vlastník | Priorita |
|---|-------|----------|----------|
| 1 | Nastaviť Google OAuth na novom Supabase | Ty | P0 |
| 2 | Nahrať `web/privacy.html` + `delete-account.html` na verejnú URL | Ty | P0 |
| 3 | Live test: login → faktúra → delete account | Ty | P0 |
| 4 | Rotovať demo heslo + API keys (git history leak) | Ty | P0 |
| 5 | Play Console: nový listing `sk.bizagent.app` + internal track upload | Ty | P0 |
| 6 | Demo účet pre Play review (`DEMO_ACCOUNT_SECRETS.txt`) | Ty | P0 |
| 7 | Migrovať notifikácie z Firestore → Supabase | Dev | P1 |
| 8 | Migrovať invoice numbering → Supabase RPC/sekvencia | Dev | P1 |
| 9 | Zmazať `firestore_export_data_source.dart` | Dev | P1 |
| 10 | IAP server-side verify (Play Developer API) | Dev | P1 |

---

## Príkazy pre teba (copy-paste)

```bash
cd ~/Projects/02_Products/bizagent

# Push merged main
git push origin main

# Spusti app proti live Supabase
flutter run --dart-define-from-file=dart_defines/supabase.json

# Release AAB (keystore už máš)
./build_release_aab.sh
# alebo: build/app/outputs/bundle/release/app-release.aab už existuje
```