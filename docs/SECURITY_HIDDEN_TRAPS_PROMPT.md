# Prompt: Audit skrytých a neviditeľných pascí v kóde

Defenzívny prompt na copy-paste do Cursor / Grok / Claude Code pri review diffu, PR alebo celého repa.  
**Cieľ:** nájsť škodlivý alebo nebezpečný kód, ktorý nie je na prvý pohľad viditeľný.

---

## Ako použiť

1. Skopíruj celý blok **PROMPT** nižšie.
2. Pripoj: git diff, zoznam zmienených súborov, alebo konkrétnu vetvu.
3. Požiadaj: *„Vykonaj audit podľa tohto promptu. Výstup: tabuľka nálezov P0/P1/P2.“*

Voliteľné — rýchly lokálny scan pred AI review:

```bash
cd /Users/erikbabcan/Projects/02_Products/bizagent

# 1) Skrytý Unicode / zero-width v Dart/TS/JSON
rg -n '[\u200B-\u200D\uFEFF\u2060\u00AD]' lib/ supabase/ test/ android/ ios/ 2>/dev/null || true

# 2) Homoglyfy v identifikátoroch (podezrivé non-ASCII v .dart)
rg -n '[^\x00-\x7F]' lib/ --glob '*.dart' | head -50

# 3) Dynamické spúšťanie / obfuskácia
rg -n 'eval\(|Function\(|new Function|dart:mirrors|Isolate\.spawnUri|Process\.run|exec\(|child_process' lib/ supabase/ scripts/

# 4) Skryté URL / exfiltrácia
rg -n 'https?://(?!bizagent\.sk|supabase\.co|googleapis\.com|firebase|github\.com|icoatlas)' lib/ supabase/

# 5) Base64 bloky (často skryté payloady)
rg -n '[A-Za-z0-9+/]{80,}={0,2}' lib/ supabase/ --glob '*.{dart,ts,js}'

# 6) Časové / debug bomby
rg -n 'kDebugMode|kReleaseMode|DateTime\.now|202[0-9]-[0-9]{2}|assert\(|TODO.*remove|FIXME.*prod' lib/ supabase/

# 7) Secrets v komentároch / stringoch
git grep -nEi 'api[_-]?key|secret|password|token|bearer|sk-[a-z0-9]{10,}|AIza[0-9A-Za-z_-]{30,}' -- ':!*.lock' ':!docs/' ':!*.md'
```

---

## PROMPT (copy-paste)

```
Si senior security engineer a static-code auditor. Tvoja úloha je nájsť SKRYTÉ,
NEVIDITEĽNÉ alebo ĽAHKO PREHLIADNUTEĽNÉ pasce v kóde, ktoré môžu byť škodlivé
pre produkciu, používateľov alebo vývojára.

KONTEXT PROJEKTU:
- Flutter app BizAgent (SZČO, SK trh)
- Supabase Edge Functions (generate-content, delete-account, …)
- AI gateway: Qwen → Mistral → Gemini
- Repo: produkcia-googlestore-2026

PRAVIDLÁ AUDITU:
1. Predpokladaj zášť — hľadaj zámerne skryté veci, nie len „chyby“.
2. Každý nález musí mať: súbor:riadok, typ pasce, dôkaz (citácia kódu), dopad, oprava.
3. Neprezri: generované súbory (*.g.dart, build/, .dart_tool/) — ak nie sú v diffe.
4. Rozlišuj P0 (exploit/backdoor/secret leak) / P1 (vážne riziko) / P2 (code smell).
5. Ak nič nenájdeš, explicitne uveď oblasti, ktoré si skontroloval, a čo zostáva riziko.

OBLASTI — SKRYTÉ PASCE (povinný checklist):

A) NEVIDITEĽNÉ ZNAKY A OBFUSKÁCIA
- Zero-width spaces (U+200B–U+200D, FEFF, U+2060) v identifikátoroch, stringoch, importoch
- Homoglyfy (cyrilica/latinka): napr. `раssword` vs `password`, `аpiKey` vs `apiKey`
- Netypické Unicode v názvoch premenných, cestách súborov, JSON kľúčoch
- Base64 / hex / rot13 reťazce dekódované za behu
- Zbytočné reťazce rozdelené: `'ht'+'tp://evil.com'`, `String.fromCharCodes([...])`
- Minifikovaný jednoriadkový kód v inak čistých súboroch

B) BACKDOORY A PODMIENENÉ ŠKODLIVÉ SPRÁVANIE
- Vetvy len pre: konkrétny userId, email, IČO, build flavor, `kDebugMode`, `!kReleaseMode`
- Časové bomby: `if (DateTime.now().isAfter(...))` meniaca logiku auth/billing/export
- Feature flags / remote config bez dokumentácie, ktoré vypínajú auth alebo GDPR consent
- „Dočasný“ bypass paywallu, rate limitu, AI consentu, RLS
- Skryté admin endpointy bez RBAC v Edge Functions

C) EXFILTRÁCIA A SKRYTÁ SIEŤ
- HTTP volania na neznáme domény (mimo Supabase, Firebase, Google, icoatlas, oficiálne API)
- Webhooky v komentároch, README, testoch, ktoré sa reálne volajú
- Odosielanie PII/ promptov na inú URL než generate-content
- `dart:html` / `js` interop s `eval`, `document.write`, dynamický script load (web)
- Skryté `curl` / `fetch` v shell skriptoch, postinstall, CI bez review

D) TAJOMSTVÁ A KĽÚČE
- API kľúče v: komentároch, testoch, golden súboroch, `.example` súboroch s reálnymi hodnotami
- Hardcoded JWT, service role key, QWEN/MISTRAL/GEMINI keys v klientovi
- Logovanie tokenov, hesiel, OCR textu bločkov do console/Crashlytics
- `upload_certificate.pem`, keystore, key.properties mimo .gitignore

E) SUPABASE / EDGE FUNCTIONS
- `service_role` v klientovi alebo v Edge Function odpovedi
- Chýbajúca JWT validácia, CORS `*` s citlivými dátami
- Prompt injection bez limitu dĺžky / bez sanitizácie v generate-content
- Funkcie, ktoré mazú viac dát než sľubuje delete-account
- SQL/string concatenation namiesto parametrizovaných dotazov

F) FLUTTER / DART ŠPECIFIKÁ
- `SharedPreferences` / Hive ukladajúce auth tokeny bez šifrovania
- `ProviderScope` overrides v produkčnom main.dart
- Skryté `dart:io` File zápisy mimo app sandboxu
- Platform channels volajúce natívny kód bez review
- `// ignore:` komentáre potláčajúce security linty (use_build_context, avoid_print secrets)

G) ZÁVISLOSTI A BUILD PIPELINE
- Zmeny v pubspec.yaml / package.json s neznámymi git URL závislosťami
- postinstall / pre-commit hooky s network alebo file system side effects
- GitHub Actions s `curl | bash`, neauditované secrets, permissive `permissions: write-all`
- Zmenené `.gitignore` vylučujúce audit trail (napr. vypnutie gitleaks)

H) AI-GENEROVANÝ KÓD (špeciálne pre tento projekt)
- „Simulácia“ volaní, ktoré v release stále volajú reálne API
- Odstránený consent dialog len v jednej obrazovke, nie globálne
- Fallback provider chain presmerovaný na neautorizovaný endpoint
- Test mocky commitnuté s `when(...).thenReturn(realApiKey)` vzorom

VÝSTUPNÝ FORMÁT (presne dodrž):

## Súhrn
- P0: N
- P1: N  
- P2: N
- Verdikt: SAFE / NEEDS FIX / BLOCK MERGE

## Nálezy

| Priorita | Súbor:riadok | Typ pasce | Dôkaz | Dopad | Oprava |
|----------|--------------|-----------|-------|-------|--------|
| P0 | ... | ... | `...` | ... | ... |

## Prešli bez nálezu (explicitný zoznam)
- ...

## Odporúčané grep/scan príkazy pre maintainera
- ...

Začni auditom poskytnutého diffu / súborov. Ak diff nie je priložený, skenuj tieto kritické cesty:
lib/main.dart, lib/core/services/gemini_service.dart, lib/core/services/ai_consent_service.dart,
lib/features/auth/**, lib/features/billing/**, supabase/functions/**,
.github/workflows/**, scripts/**, android/app/build.gradle.kts, pubspec.yaml.
```

---

## BizAgent — známe legitímne výnimky (nehlásiť ako P0)

Tieto vzory sú v projekte zámerné — auditor ich má ignorovať, ak nie sú zmenené:

| Vzor | Kde | Prečo je OK |
|------|-----|-------------|
| `REPLACE_ME` v firebase_options | `lib/firebase_options.dart` | Placeholder, reálne keys mimo git |
| `generate-content` Edge Function | `supabase/functions/` | Jediný AI gateway, kľúče v Supabase secrets |
| `AiConsentService` | `lib/core/services/ai_consent_service.dart` | GDPR súhlas pred AI |
| `PlayReleaseScope` | `lib/core/config/play_release_scope.dart` | Play build feature flags |
| Demo mode triple-tap | dashboard | Dokumentované v README |

---

## Rýchly checklist pred release (30 s)

- [ ] `git grep` secrets — 0 reálnych kľúčov
- [ ] Žiadny nový `http://` endpoint mimo whitelistu
- [ ] Edge Functions: JWT required na všetkých mutáciách
- [ ] AI consent pred každým novým AI entry pointom
- [ ] `flutter analyze` bez nových `ignore` na security lintoch
- [ ] CI workflows: žiadny `curl | bash` z neznámeho URL

---

*Defenzívny dokument — na detekciu rizík, nie na vytváranie útokov.*