# Play Reviewer Account (Supabase)

Google Play reviewer sa prihlasuje cez **Supabase Auth** (email + heslo), nie Firebase.

## Údaje účtu

| Pole | Hodnota |
|------|---------|
| **Email** | `bizagent@bizagent.sk` |
| **Password** | Lokálne v `.play_reviewer_password` (gitignored) |
| **Supabase project** | `kpsnwpuydqqojwmrnkdy` |

## Vytvorenie / obnovenie účtu a seed dát

```bash
# Vyžaduje: supabase CLI (logged in), dart_defines/supabase.json
bash scripts/seed_play_reviewer_account.sh
```

Skript:

1. Vytvorí alebo aktualizuje používateľa v Supabase Auth (`email_confirm: true`)
2. Vygeneruje heslo do `.play_reviewer_password` (pri prvom behu) alebo ho znovu použije
3. Seedne 2 faktúry, 1 výdavok, 1 notifikáciu a `user_settings` s IČO/DIČ
4. Overí REST sign-in a počet riadkov v tabuľkách

**Rotácia hesla po review:**

```bash
bash scripts/seed_play_reviewer_account.sh --force-password
```

Potom aktualizuj heslo v Google Play Console → App access.

## Overenie

### REST (automaticky v skripte)

Skript na konci overí `POST /auth/v1/token?grant_type=password` a SELECT na `invoices`, `expenses`, `notifications`, `user_settings`.

### Manuálne v aplikácii

```bash
./build_release_aab.sh
# nainštaluj AAB na zariadenie/emulátor, prihlás sa:
#   Email: bizagent@bizagent.sk
#   Password: (obsah .play_reviewer_password)
```

Release build **neobsahuje** Demo Mode triple-tap (`PlayReleaseScope.playMvp=true`). Reviewer sa spolieha na seed dáta v Supabase, nie na skryté gesto.

### Supabase Dashboard

1. [Authentication → Users](https://supabase.com/dashboard/project/kpsnwpuydqqojwmrnkdy/auth/users) — user `bizagent@bizagent.sk`
2. Table Editor — riadky v `invoices`, `expenses`, `notifications`, `user_settings` pre `user_id` reviewera

## Google Play Console

Text pre App access skopíruj z [PLAY_APP_ACCESS_NOTES.md](./PLAY_APP_ACCESS_NOTES.md).

## Riešenie problémov

| Problém | Riešenie |
|---------|----------|
| `invalid url` / chýba supabase.json | `cp dart_defines/supabase.example.json dart_defines/supabase.json` a doplň kľúče |
| `service_role` sa nepodarilo načítať | `supabase login` a over project ref |
| Sign-in HTTP 401 | Spusti seed znova; `--force-password` ak heslo v Play Console nesedí |
| Prázdna app po prihlásení | Spusti seed znova — dáta sa upsertujú idempotentne |

## Bezpečnosť

- Heslo je verejné v Play Console počas review — po schválení rotuj: `--force-password`
- `.play_reviewer_password` nikdy necommituj
- Účet je len pre Google Play review, nie pre produkčných zákazníkov

## Súvisiace dokumenty

- [PLAY_APP_ACCESS_NOTES.md](./PLAY_APP_ACCESS_NOTES.md) — copy-paste pre Play Console
- [GOOGLE_PLAY_UPLOAD_CHECKLIST.md](../GOOGLE_PLAY_UPLOAD_CHECKLIST.md) — finálny upload checklist
