# Super admin (test unlock)

Super-admin má odomknuté všetky Pro funkcie a žiadny paywall. Zdroj pravdy je **Supabase Auth `app_metadata`** (klient to nemôže meniť).

## Flag v JWT / user objekte

Buď:

```json
{ "role": "super_admin" }
```

alebo:

```json
{ "is_super_admin": true }
```

Flutter mapuje toto na `UserModel.isSuperAdmin` → `SubscriptionGuard` + `BillingService` (`activePlanId: super_admin`).

## Grant pre larsenevans@proton.me

1. Účet musí existovať (aspoň raz sa prihlásiť / zaregistrovať).
2. Spusti v **Supabase SQL Editor**:

```sql
update auth.users
set raw_app_meta_data =
  coalesce(raw_app_meta_data, '{}'::jsonb)
  || '{"role":"super_admin","is_super_admin":true}'::jsonb
where email = 'larsenevans@proton.me';
```

3. Overenie:

```sql
select id, email, raw_app_meta_data
from auth.users
where email = 'larsenevans@proton.me';
```

4. **Odhlás sa a znova prihlás** (alebo obnov session), aby JWT obsahoval nové `app_metadata`.

## Odvolanie

```sql
update auth.users
set raw_app_meta_data =
  (coalesce(raw_app_meta_data, '{}'::jsonb) - 'role' - 'is_super_admin')
where email = 'larsenevans@proton.me';
```

Potom opäť re-login.

## IČO Atlas bez VPS (lokálne)

```bash
cd ~/Projects/02_Products/ico-atlas
php artisan serve --host=127.0.0.1 --port=8081

# v bizagent:
flutter run --dart-define=ICOATLAS_BASE_URL=http://127.0.0.1:8081
```

(Port 8080 na tomto Macu často zaberá Node.)
