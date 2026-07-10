# Datalayer debt — zostávajúci Firestore / Firebase

AGENT B (P0) migroval na Supabase:
- `SoftDeleteService` → `trash_items` + `is_deleted`
- Export → `SupabaseExportDataSource`
- `WatchedCompaniesService` + `WatchedCompaniesScreen`

## Stále na Firestore (P1+)

| Modul | Súbor | Poznámka |
|-------|-------|----------|
| Notifikácie | `lib/core/services/monitoring_service.dart`, `notification_bell.dart` | `notifications` tabuľka existuje v schéme |
| IČO lookup cache | `lib/core/services/company_lookup_service.dart` | `companies`, `company_snapshots` v Supabase |
| Číslovanie faktúr | `lib/features/invoices/data/firestore_invoice_numbering_repository.dart` | Presunúť do `user_settings` alebo samostatnej tabuľky |
| Kategorizácia výdavkov | `lib/features/expenses/services/categorization_service.dart` | Pravidlá v `user_settings` |
| Monitoring firiem (backend) | `lib/features/tools/services/monitoring_service.dart` | Firebase Functions `batchRefreshWatched` |
| Legacy export | `firestore_export_data_source.dart` | Nepoužívané po AGENT B, zmazať v P1 |

## Firebase Functions (legacy)

- `deleteUserData` — GDPR legacy; kanonické mazanie: `supabase/functions/delete-account`
- `generateContent`, `analyzeReceipt`, `lookupCompany` — postupná migrácia na Supabase edge functions

## Supabase projekt

- **Live:** `kpsnwpuydqqojwmrnkdy` (`bizagent-app-2026`, eu-central-1)
- Edge functions: `delete-account`, `generate-content`