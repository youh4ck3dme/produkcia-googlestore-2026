# BizAgent — 3 Refresh Prompty pre Cursor

Použi **v tomto poradí**. Každý prompt spúšťaj v **Agent mode** s otvoreným workspace:

```
/Users/erikbabcan/Projects/02_Products/bizagent
```

Pravidlá pre agenta pri každom prompte:
- Spúšťaj príkazy sám — neodporúčaj mi ich.
- Nevymýšľaj — ak niečo nevieš overiť, označ ako HYPOTÉZA.
- Každý nález: **KRITICKÉ / VYSOKÉ / STREDNÉ / NÍZKE** + konkrétna oprava.
- Na konci: **GO / REWORK / NO-GO** pre danú oblasť.

---

## REFRESH 1 — Integrita repozitára a duplicity

```
Si release engineer. Workspace je JEDINÝ kanonický BizAgent:

/Users/erikbabcan/Projects/02_Products/bizagent

Úloha: Over, že nikde v projekte ani v jeho okolí nie je zmätok z duplicitných kópií, zlého git stavu alebo skrytých secretov.

Preskúmaj:
1. git status, git remote, aktuálny HEAD, či je main sync s origin
2. pubspec.yaml version vs android versionCode/versionName vs ios CFBundle
3. applicationId / bundle ID konzistencia (android + ios + firebase)
4. Existenciu a obsah: CANONICAL_SOURCE.md — porovnaj s realitou na disku
5. Či v tomto repozitári nie sú: .jks, keystore, API keys v kóde, service_role, hardcoded secrets
6. dart_defines/supabase.json — musí byť v .gitignore a .cursorignore, nie v gite
7. Porovnaj checksum/HEAD s týmito cestami (iba fakt, nie merge):
   - ~/Projects/02_Products/produkcia-googlestore-2026
   - ~/Documents/.../bizagent-production
   - ~/Projects/01_Clients/bizagent-production-build
8. Nájdi orphan súbory, broken symlinks, prázdne priečinky, duplicitné MainActivity

Spusti:
- flutter pub get
- flutter analyze
- git ls-files | rg -i 'secret|password|api_key|\.jks|keystore' || true
- rg -l 'service_role|SUPABASE_SERVICE|GEMINI_API|sk-' lib/ functions/ --glob '!*.example*' || true

Výstup:
1. Verdict integrita (1 veta)
2. Tabuľka nálezov (závažnosť, súbor, problém, fix)
3. Zoznam súborov na okamžité zmazanie alebo presun
4. Príkazy ktoré si spustil a ich výsledok
5. GO/REWORK/NO-GO

Ak nájdeš kritický secret v gite — navrhni rotáciu, nie len „daj do gitignore“.
```

---

## REFRESH 2 — Kód, testy, build a runtime

```
Si senior Flutter architekt + QA lead. Projekt: BizAgent (SZČO app, SK trh).

Úloha: Over, že kód je konzistentný, testy sú zelené a build pipeline nedá falošný pocit hotovosti.

Preskúmaj podľa dostupnosti:
- lib/ (router, auth, invoices, expenses, billing, supabase vrstva, demo mode)
- test/ + integration_test/
- functions/ (Firebase Cloud Functions)
- supabase/ (migrations, edge functions, RLS)
- firestore.rules, firestore.indexes.json
- android/app/build.gradle.kts, AndroidManifest.xml
- ios/Runner/Info.plist, ExportOptions.plist
- .github/workflows/*.yml

Spusti a reportuj výsledok:
- flutter pub get
- flutter analyze
- flutter test
- cd functions && npm ci && npm test (ak existuje)
- dart format --set-exit-if-changed lib test (ak zlyhá, uveď počet súborov)

Skontroluj logicky:
1. Firebase + Supabase dual stack — je jasné čo je default? Nie sú konflikty v auth_repository?
2. PlayReleaseScope / demo mode — je demo blokované v release?
3. OCR flow — kIsWeb guard, camera permissions
4. Offline Hive + Firestore/Supabase sync — konfliktné cesty
5. IAP / subscription_guard — edge cases
6. Account deletion flow — existuje end-to-end?
7. Sú failing/skipped testy oprávnené alebo maskujú bug?

Výstup:
1. Test matrix (príkaz | passed | failed | skipped)
2. Top 10 rizík v kóde (s citáciou súboru)
3. P0 opravy pred ďalším vývojom (max 7)
4. Čo je hotové vs čo je iba scaffold
5. GO/REWORK/NO-GO

Nepoužívaj „všetko vyzerá dobre“. Ak test preskočí 19 testov, vysvetli prečo a či je to OK.
```

---

## REFRESH 3 — Store, bezpečnosť, GDPR a release realita

```
Si App Store reviewer + Google Play policy expert + security engineer.

Projekt: BizAgent — mobilná appka pre slovenské SZČO (faktúry, výdavky, DPH limit, OCR, AI).

Úloha: Nájdi VŠETKO, čo by spôsobilo rejection, security incident alebo právny problém pri release.

Preskúmaj:
- docs/GOOGLE_PLAY_SUBMISSION.md, RELEASE_CHECKLIST.md, PRIVACY_POLICY.md
- legal/ priečinok
- android/ signing config (key.properties.example — nie reálne klúče)
- in_app_purchase implementáciu
- permissions v AndroidManifest + Info.plist (camera, mic, biometrics, notifications)
- GDPR: export dát, vymazanie účtu, privacy policy URL
- AI: Gemini/Mistral — sú kľúče len server-side?
- Firestore rules + Supabase RLS — IDOR, user-scoped data
- Crashlytics / Analytics — PII leakage
- Deep links / OAuth redirect URI

Simuluj checklist:
| Politika | Stav | Bloker? | Fix |
Apple App Store | ? | ? | ? |
Google Play | ? | ? | ? |
GDPR / SK legislatíva | ? | ? | ? |
Account deletion | ? | ? | ? |
Subscriptions | ? | ? | ? |
Sensitive data | ? | ? | ? |

Spusti ak je možné:
- rg 'TODO|FIXME|HACK|XXX' lib/ functions/ docs/ --glob '!node_modules/*'
- flutter build apk --debug (iba over že build nepadne; netreba upload)
- skontroluj či google-services.json package_name sedí s applicationId

Výstup:
1. Release readiness skóre 0–100
2. Kritické blokery (musia byť fixnuté pred uploadom)
3. P1 pred verejným release
4. Presný zoznam chýbajúcich store assetov (screenshots, privacy URL, demo account…)
5. GO / REWORK / NO-GO pre Play Store a App Store zvlášť

Buď brutálne úprimný. Pekný UI neber ako „pass“.
```

---

## Odporúčaný postup

| Deň | Prompt | Trvanie |
|-----|--------|---------|
| 1 | REFRESH 1 — Integrita | ~15 min |
| 1 | REFRESH 2 — Kód & testy | ~30 min |
| 2 | REFRESH 3 — Store & security | ~30 min |

Po všetkých troch: spoločný GO/NO-GO a P0 zoznam na implementáciu.