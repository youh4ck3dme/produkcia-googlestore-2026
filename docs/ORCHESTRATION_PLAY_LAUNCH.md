# BizAgent — Orchestrácia 3 agentov → Google Play TOP SK

**Dátum:** 2026-07-10  
**Verdikt auditu:** REWORK  
**Cieľ:** Jeden Supabase-first produkt bez split-brain, zelené testy, Play Store ready

---

## Cieľová architektúra (blueprint)

```
┌─────────────────────────────────────────────────────────┐
│  Flutter App (sk.bizagent.app)                          │
│  Auth: Supabase Auth ONLY (Firebase Auth = ODSTRÁNIŤ)    │
│  Data: Supabase Postgres + RLS + Storage                │
│  Local: Hive (offline cache, sync → Supabase)           │
│  AI: Supabase Edge Functions (Gemini/Mistral server-side)│
│  Billing: Play Billing + server verify (P1)             │
└─────────────────────────────────────────────────────────┘
         │                              │
         ▼                              ▼
┌─────────────────┐          ┌──────────────────────────┐
│ Supabase        │          │ Firebase (LEN ak nutné)  │
│ - auth.users    │          │ - Crashlytics            │
│ - invoices      │          │ - Analytics (voliteľné)  │
│ - expenses      │          │ - FCM (ak nie Supabase)  │
│ - trash_items   │          │ Firestore = DEPRECATED   │
│ - watched_co.   │          └──────────────────────────┘
│ - notifications │
│ Edge Functions: │
│ - delete-account│
│ - generate-content│
└─────────────────┘
```

**Pravidlo:** Žiadny `FirebaseAuth.instance` ani `FirebaseFirestore` v user-data path. Firestore len ak explicitne označené DEPRECATED s migration ticketom.

---

## Rozdelenie agentov (bez kolízií)

| Agent | Kde beží | Vlastní | Nesmie meniť |
|-------|----------|---------|--------------|
| **AGENT A** | Cursor #1 | `supabase/`, `functions/` (Firebase legacy), CI workflows | `lib/features/invoices/*`, `lib/features/export/*` |
| **AGENT B** | Cursor #2 | `lib/` (data layer migrácia), `test/` pre dotknuté moduly | `supabase/functions/*`, `.github/workflows/*` |
| **AGENT C** | Grok (ty + ja) | Review, merge plán, integration testy, Play checklist, konflikty | Implementuje len ak A/B blokovaní |

### Poradie vĺn

```
Vlna 1 (paralelne):  AGENT A + AGENT B
Vlna 2 (sekvencia):  AGENT C review + fix konfliktov
Vlna 3 (paralelne):  AGENT B (E2E testy) + AGENT A (functions npm test)
Vlna 4:              AGENT C → GO/NO-GO Play
```

### Git vetvy (odporúčané)

```
main
├── feat/supabase-backend-p0      ← AGENT A
├── feat/supabase-datalayer-p0    ← AGENT B
└── (merge cez AGENT C review)
```

---

## Definícia hotovo (Google Play SK)

- [ ] `delete-account` edge function funguje + integration test
- [ ] Soft delete / koš → `trash_items` + `is_deleted` v Supabase
- [ ] Export číta Supabase, nie Firestore
- [ ] Watched companies → Supabase `watched_companies`
- [ ] 0× `FirebaseAuth` v user-data services (grep proof)
- [ ] `flutter test` s `PLAY_MVP=false`: 0 failed
- [ ] `functions npm test` zelený
- [ ] `android_release.yml` testuje s `PLAY_MVP=false`
- [ ] AAB build prejde
- [ ] Privacy policy URL live + account deletion v app

---

# PROMPT — AGENT A (Cursor #1)
## Backend + Supabase Edge + CI

Skopíruj celý blok do **nového Cursor Agent chatu** s workspace `bizagent`.

```
# AGENT A — BizAgent Supabase Backend P0

Si backend engineer. Workspace: /Users/erikbabcan/Projects/02_Products/bizagent
Vetva: feat/supabase-backend-p0 (vytvor ak neexistuje)

## Kontext
Audit 2026-07-10: REWORK. Klient volá `delete-account` ale funkcia neexistuje.
Firestore moduly sú legacy. Cieľ = Supabase-first backend.

## Tvoja zóna (iba tieto cesty)
- supabase/functions/**
- supabase/migrations/** (nové migrácie OK)
- functions/** (Firebase — oprav test_functions.js, pridaj npm test)
- .github/workflows/**
- scripts/verify_supabase_live.sh, setup_supabase_ci.sh
- docs/BACKEND_MIGRATION.md (vytvor)

## NESMIEŠ meniť
- lib/** (okrem ak import path v komentári — žiadne Dart zmeny)
- test/** (okrem test/fixtures pre backend ak nutné)

## Úlohy P0

### 1. Edge Function `delete-account`
Vytvor `supabase/functions/delete-account/index.ts`:
- Auth: over `Authorization: Bearer <user JWT>`
- Cascade delete pre user_id z tabuliek:
  invoices, expenses, user_settings, bizbot_messages, ai_reports,
  notifications, watched_companies, trash_items
- Zmaž receipt súbory zo Storage (bucket receipts, prefix user_id/)
- Na konci: `auth.admin.deleteUser(userId)` cez service role
- Vráť JSON `{ ok: true, deleted: { ...counts } }`
- Rate limit / idempotency (druhý call = 404 alebo ok)

### 2. Storage policies
Over/vytvor RLS pre storage bucket `receipts` — user vidí len svoj prefix.

### 3. Firebase functions cleanup
- Oprav `functions/test_functions.js` — správne Admin SDK volania
- Pridaj do `functions/package.json`: `"test": "node test_functions.js"`
- Dokumentuj: Firebase `deleteUserData` = legacy, Supabase = canonical

### 4. CI zosúladenie
- `android_release.yml`: flutter test s `--dart-define=PLAY_MVP=false`
- `test.yml`: over že supabase smoke beží keď secrets existujú
- Pridaj job step: `cd functions && npm ci && npm test`

## Acceptance criteria
- [ ] `supabase functions serve delete-account` lokálne odpovie (mock OK)
- [ ] `npm test` v functions/ exit 0
- [ ] Žiadny secret v diff
- [ ] docs/BACKEND_MIGRATION.md mapuje staré Firebase → nové Supabase

## Výstup
1. Zoznam zmienených súborov
2. Príkazy ktoré si spustil + výsledok
3. Čo potrebuje AGENT B v lib/ aby to fungovalo end-to-end
4. Riziká

Spúšťaj príkazy sám. Nevymýšľaj. Ak Supabase CLI nie je linknuté, uveď presný setup krok.
```

---

# PROMPT — AGENT B (Cursor #2)
## Flutter Data Layer migrácia Firestore → Supabase

```
# AGENT B — BizAgent Flutter Data Layer P0

Si senior Flutter architekt. Workspace: /Users/erikbabcan/Projects/02_Products/bizagent
Vetva: feat/supabase-datalayer-p0 (vytvor ak neexistuje)

## Kontext
Split-brain: invoices/expenses v Supabase, ale soft delete, export, watched companies,
numbering, notifikácie stále používajú Firestore + FirebaseAuth.

## Tvoja zóna (iba tieto cesty)
- lib/core/services/soft_delete_service.dart
- lib/features/export/**
- lib/features/tools/services/watched_companies_service.dart
- lib/features/invoices/providers/invoices_provider.dart (soft delete path)
- lib/features/invoices/** (numbering ak existuje firestore repo)
- lib/core/services/monitoring_service.dart + features/tools duplicate
- lib/features/settings/screens/trash_screen.dart (ak existuje)
- test/** pre dotknuté moduly
- lib/core/supabase/** (rozšír ak treba)

## NESMIEŠ meniť
- supabase/functions/**
- .github/workflows/**
- functions/**

## Úlohy P0

### 1. SoftDeleteService → Supabase
Nahraď Firestore implementáciu:
- `is_deleted=true` na invoices/expenses
- zápis do `trash_items` (collection, id, data, deleted_at)
- `restore` / `permanentDelete` z trash_items
- Aktualizuj `invoices_provider.dart` — jeden data path

### 2. Export → SupabaseExportDataSource
- Nový `supabase_export_data_source.dart` implementuje `ExportDataSource`
- `export_provider.dart` používa Supabase UID z `authStateProvider`
- Odstráň závislosť na FirestoreExportDataSource v default path
- Test: unit test s fake supabase store

### 3. WatchedCompaniesService
- `_uid` z Supabase session, NIE FirebaseAuth
- CRUD na `watched_companies` tabuľku cez existujúci supabase_table_store
- Aktualizuj testy

### 4. Firestore audit
Spusti: `rg "FirebaseFirestore|FirebaseAuth" lib/ -l`
Pre každý hit: migruj alebo označ `@Deprecated('P1-migrate')` s issue v docs/DATALAYER_DEBT.md

### 5. Testy
- Unit testy pre nový soft delete + export + watched
- Priprav `test/integration/account_deletion_flow_test.dart` (skip ak live env chýba)
- Všetky testy musia prejsť: `flutter test`

## Acceptance criteria
- [ ] `rg FirebaseAuth lib/features/tools lib/features/export lib/core/services/soft_delete` = 0 matches
- [ ] flutter analyze bez nových error
- [ ] flutter test: 0 failed
- [ ] docs/DATALAYER_DEBT.md — čo zostáva na P1

## Výstup
1. Pred/after tabuľka Firestore → Supabase
2. Zoznam súborov
3. Závislosti na AGENT A (edge functions, migrácie)
4. Manuálny QA checklist (5 krokov v app)

Spúšťaj príkazy sám. Zachovaj PlayReleaseScope a demo guards.
```

---

# PROMPT — AGENT C (Grok — orchestrátor + review)
## Pre mňa (tretí agent) — daj mi tento prompt v ďalšom chate

```
# AGENT C — BizAgent Orchestrátor + Play Store Gate

Si release orchestrátor. Sleduješ 2 paralelné vetvy:
- feat/supabase-backend-p0 (AGENT A)
- feat/supabase-datalayer-p0 (AGENT B)

Workspace: /Users/erikbabcan/Projects/02_Products/bizagent

## Tvoja úloha
1. Počkaj na reporty od A a B (alebo prečítaj ich diff)
2. Skontroluj konflikty — najmä auth_repository, export_provider, CI
3. Spusti merge review:
   - flutter pub get && flutter analyze && flutter test --dart-define=PLAY_MVP=false
   - cd functions && npm test
   - rg "FirebaseAuth|FirebaseFirestore" lib/ --glob "!*test*"
4. Vytvor docs/PLAY_STORE_P0_CHECKLIST.md s aktuálnym stavom
5. Rozhodni GO / REWORK / NO-GO pre Google Play upload

## P1 backlog (nezabudni zaradiť)
- IAP server-side verify (Play Developer API)
- Invoice numbering purely Supabase (sekvencie / RPC)
- Offline conflict resolution (updated_at)
- Privacy policy URL + Data Safety form mapping
- Demo account pre Play review

## Výstup
- Merge plán (poradie, konfliktné súbory)
- Finálny P0 zoznam s vlastníkom
- Play Store readiness skóre 0-100
- 10 implementačných úloh na najbližších 7 dní

Buď brutálne úprimný. Ak A a B rozbili build, povedz čo revertnúť.
```

---

## Koordinačný protokol (pre teba)

### Pred štartom
1. Otvor **2 Cursor okná** (alebo 2 Agent chaty v tom istom workspace)
2. Agent A → vetva `feat/supabase-backend-p0`
3. Agent B → vetva `feat/supabase-datalayer-p0`
4. Ty → pošli mi reporty alebo napíš „AGENT C, reviewuj“

### Po vlne 1
```bash
# Ty alebo ja spustíme:
cd ~/Projects/02_Products/bizagent
git fetch
git merge feat/supabase-backend-p0   # alebo PR
git merge feat/supabase-datalayer-p0
flutter test --dart-define=PLAY_MVP=false
```

### Signály medzi agentmi

| A dokončil | B potrebuje vedieť |
|------------|-------------------|
| `delete-account` deployed | Môže testovať settings → delete flow |
| storage policies | receipt upload/delete funguje |
| CI PLAY_MVP=false | B spúšťa rovnaký príkaz lokálne |

| B dokončil | A potrebuje vedieť |
|------------|-------------------|
| žiadny Firestore v export | Firebase functions môžu byť označené legacy |
| trash_items používané | delete-account musí mazať trash_items |

---

## Bonus: 4. refresh prompt (po P0)

Keď A+B+C skončia, spusti v Cursor:

```
# REFRESH 4 — Post-migration Play Store dry run

Over že split-brain je mŕtvy:
- rg FirebaseAuth lib/ (0 v production path)
- Account deletion E2E (live alebo emulator)
- flutter build appbundle --release
- Play checklist 100% P0 položiek

Výstup: GO/NO-GO + screenshot checklist pre Play Console.
```

---

## Časový odhad

| Vlna | Agent | Odhad |
|------|-------|-------|
| 1 | A + B paralelne | 4–8 hod |
| 2 | C review | 1–2 hod |
| 3 | fix + test | 2–4 hod |
| 4 | AAB + Play metadata | 1 deň |

**Celkom P0:** ~2–3 dni focused work → potom Play internal testing.