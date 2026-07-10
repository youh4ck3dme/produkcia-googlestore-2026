# Datalayer debt — zostávajúci Firestore / Firebase

**Aktualizované:** 2026-07-10 @ `main` (P1 partial)

## P0 — hotové (AGENT B)

- `SoftDeleteService` → `trash_items` + `is_deleted`
- Export → `SupabaseExportDataSource`
- `WatchedCompaniesService` + `WatchedCompaniesScreen`

## P1 — hotové v tejto vlne

| Modul | Predtým | Teraz |
|-------|---------|-------|
| Notifikácie | Firestore `notifications` | `MonitoringService` → Supabase `notifications` |
| Číslovanie faktúr | Firestore counters + SharedPrefs `FA-N` | `SupabaseInvoiceNumberingRepository` + RPC `reserve_invoice_block` |
| Legacy monitoring | `lib/core/services/monitoring_service.dart` | **zmazané** (duplicita) |

## Stále na Firestore (P1+)

| Modul | Súbor | Poznámka |
|-------|-------|----------|
| IČO lookup cache | `lib/core/services/company_lookup_service.dart` | `companies`, `company_snapshots` v Supabase |
| Kategorizácia výdavkov | `lib/features/expenses/services/categorization_service.dart` | Pravidlá v `user_settings` |
| Monitoring firiem (backend) | `functions/src/batchRefreshWatched.ts` | Firebase batch → Supabase cron/edge |
| Legacy export | `firestore_export_data_source.dart` | Nepoužívané, zmazať |
| Legacy numbering | `firestore_invoice_numbering_repository.dart` | `@Deprecated`, nahradené Supabase |

## Firebase Functions (legacy)

- `deleteUserData` — GDPR legacy; kanonické: `supabase/functions/delete-account`
- `generateContent`, `analyzeReceipt`, `lookupCompany` — postupná migrácia na Supabase edge

## Supabase projekt

- **Live:** `kpsnwpuydqqojwmrnkdy` (`bizagent-app-2026`, eu-central-1)
- Edge functions: `delete-account`, `generate-content`
- Migrácia: `20260710120000_invoice_counters.sql` (deploy pred produkciou)