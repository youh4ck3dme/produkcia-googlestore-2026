# AGENT C — Integrity audit fixes (2026-07-10)

## Vykonané opravy

| # | Nález | Akcia | Stav |
|---|-------|-------|------|
| 1 | Demo heslo v gite | Redigované v MD; skripty čítajú `DEMO_ACCOUNT_SECRETS.txt` | ✅ |
| 2 | API kľúče v docs | `FIREBASE_GEMINI.md`, `QUICK_DEPLOY.md` → interaktívny `secrets:set` | ✅ |
| 3 | `docs/aaa.md` leak | `git rm docs/aaa.md` | ✅ |
| 4 | `.firebaserc` default | `default` → `bizagent-live-2026` | ✅ |
| 5 | `CANONICAL_SOURCE.md` | Sibling repo = sync, nie zastaraný | ✅ |
| 6 | iOS bundle v docs | `DEPLOYMENT.md` opravené na `com.bizagent.bizagent` | ✅ |
| 7 | Secrets guide | `docs/SECRETS_HYGIENE.md` + `DEMO_ACCOUNT_SECRETS.txt.example` | ✅ |

## Tvoja manuálna akcia (mimo git)

1. **Rotuj** demo heslo vo Firebase Auth (staré bolo v git histórii)
2. **Rotuj** GEMINI / ICOAtlas kľúče ak boli live v docs
3. Vytvor lokálne:
   ```bash
   cp DEMO_ACCOUNT_SECRETS.txt.example DEMO_ACCOUNT_SECRETS.txt
   # vyplň nové heslo po rotácii
   ```
4. `firebase use live` pred každým deployom
5. Build AAB: `./build_release_aab.sh`

## Git história

Redakcia v working tree **neodstraňuje** staré secrety z histórie. Pred verejným release zváž:

```bash
# len ak máš backup a koordináciu s tímom
# git filter-repo alebo BFG na demo password + docs keys
```

## Ďalší krok

Paralelne spusti **AGENT A** + **AGENT B** z `docs/ORCHESTRATION_PLAY_LAUNCH.md` (split-brain Supabase migrácia).