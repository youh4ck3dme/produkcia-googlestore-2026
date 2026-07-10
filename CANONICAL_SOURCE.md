# BizAgent — kanonický zdroj (2026-07-10)

## Jediná pravda

**Otváraj a pracuj tu:**

```
/Users/erikbabcan/Projects/02_Products/bizagent
```

Git remote: `git@github.com:youh4ck3dme/produkcia-googlestore-2026.git`  
Aktuálny HEAD: `main` @ `9ea5c8c` (Supabase migrácia + rozšírené testy + CI)

## Kde boli skryté / duplicitné kópie

| Cesta | Stav | Poznámka |
|-------|------|----------|
| **`Projects/02_Products/bizagent`** | ✅ **KANONICKÁ** | Toto používaj |
| `Documents/.../bizagent-production` | Zdroj syncu | Novšia vetva `main` (+27 commitov oproti starej `produkcia-googlestore-2026`) |
| `Projects/02_Products/produkcia-googlestore-2026` | ✅ SYNC | Rovnaký commit ako `bizagent` (`main` @ `9ea5c8c`) — duplicita, nepoužívaj na vývoj |
| `Projects/01_Clients/bizagent-production-build` | ⚠️ Fork | 5 commitov web/demo fixov, **bez** Supabase migrácie |
| `Documents/BizAgent-main/final-bizagent-flutter-main` | 🗄️ Archív | Starší snapshot (feb 2026), bez git |
| `Projects/01_Clients/BizAgent-main-LASENEVANS` | 🗄️ Archív | Klientsky balík + WordPress pluginy |

## Čo má najlepšia verzia navyše

Oproti starej `produkcia-googlestore-2026`:

- **Supabase** (`supabase_flutter`, migrácie, edge functions, `dart_defines/`)
- **203** Dart súborov v `lib/` (vs 194)
- **94** test súborov (vs 69)
- CI workflow pre integračné testy + macOS/Android smoke
- `PlayReleaseScope` + async demo mode (Play review safe)

## Cursor

```bash
open -a Cursor ~/Projects/02_Products/bizagent/bizagent.code-workspace
```

Návod: `docs/CURSOR_SETUP.md`  
3 audit prompty: `docs/CURSOR_REFRESH_PROMPTS.md`

## Rýchly štart

```bash
cd ~/Projects/02_Products/bizagent
flutter pub get
cd functions && npm install && cd ..
flutter test
flutter run -d android   # alebo chrome / ios
```

## Supabase (voliteľné)

```bash
cp dart_defines/supabase.example.json dart_defines/supabase.json
# vyplň URL + anon key, potom:
flutter run --dart-define-from-file=dart_defines/supabase.json
```

## Pravidlo do budúcna

1. Nová práca **iba** v `Projects/02_Products/bizagent`
2. Po commite: `git push origin main`
3. Staré priečinky **neprepisuj** — sú historické; tento súbor je mapa