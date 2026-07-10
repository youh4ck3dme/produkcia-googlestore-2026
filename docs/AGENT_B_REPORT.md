# AGENT B — Supabase datalayer P0

Branch: `feat/supabase-datalayer-p0`

## Migrácie

| Modul | Pred | Po |
|-------|------|-----|
| Soft delete / kôš | Firestore `soft_deleted_*` | `trash_items` + `invoices.is_deleted` |
| Export ZIP | `FirestoreExportDataSource` | `SupabaseExportDataSource` |
| Watched companies | Firestore + FirebaseAuth | `watched_companies` tabuľka + Supabase auth UID |
| Watched companies screen | Firestore global query | `WatchedCompaniesService.listWatched()` |

## Supabase projekt

- Ref: `kpsnwpuydqqojwmrnkdy` (`bizagent-app-2026`)
- URL: `https://kpsnwpuydqqojwmrnkdy.supabase.co`
- Functions deployed: `delete-account`, `generate-content`

## Testy

```
flutter test → 366 passed, 19 skipped, 0 failed
```

## Zostávajúci dlh

Pozri `docs/DATALAYER_DEBT.md` — notifikácie, IČO cache, číslovanie faktúr, categorization.