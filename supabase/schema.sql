-- ============================================================
-- BizAgent — Supabase schéma (migrácia z Firestore)
-- Kanonická verzia pre produkciu: supabase/migrations/*.sql
-- (GitHub integrácia aplikuje migrácie pri merge do main).
-- Ručný fallback: Supabase SQL editor alebo `supabase db push`.
--
-- Princíp: každá tabuľka má user_id = auth.uid() a RLS politiku,
-- ktorá dovolí prístup IBA vlastníkovi. Doménové dáta sú v `data jsonb`
-- (zachováva InvoiceModel/ExpenseModel.toMap()), navrch indexované stĺpce
-- pre zoradenie a soft-delete.
-- ============================================================

-- Rozšírenia
create extension if not exists "pgcrypto";

-- ----------------------------------------------------------------
-- INVOICES  (users/{uid}/invoices)
-- ----------------------------------------------------------------
create table if not exists public.invoices (
  id          text primary key,
  user_id     uuid not null references auth.users (id) on delete cascade,
  data        jsonb not null default '{}'::jsonb,
  date_issued timestamptz,
  status      text,
  is_deleted  boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index if not exists invoices_user_idx on public.invoices (user_id, date_issued desc);
create index if not exists invoices_user_deleted_idx on public.invoices (user_id, is_deleted);

-- ----------------------------------------------------------------
-- EXPENSES  (users/{uid}/expenses)
-- ----------------------------------------------------------------
create table if not exists public.expenses (
  id          text primary key,
  user_id     uuid not null references auth.users (id) on delete cascade,
  data        jsonb not null default '{}'::jsonb,
  date        timestamptz,
  is_deleted  boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index if not exists expenses_user_idx on public.expenses (user_id, date desc);

-- ----------------------------------------------------------------
-- USER SETTINGS  (users/{uid}/settings/{docId})
-- jeden riadok na používateľa
-- ----------------------------------------------------------------
create table if not exists public.user_settings (
  user_id     uuid primary key references auth.users (id) on delete cascade,
  data        jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);

-- ----------------------------------------------------------------
-- BIZBOT MESSAGES  (users/{uid}/bizbot_threads/main/messages)
-- ----------------------------------------------------------------
create table if not exists public.bizbot_messages (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  thread_id   text not null default 'main',
  text        text not null,
  is_user     boolean not null default false,
  created_at  timestamptz not null default now()
);
create index if not exists bizbot_user_thread_idx
  on public.bizbot_messages (user_id, thread_id, created_at);

-- ----------------------------------------------------------------
-- AI REPORTS  (nahlásené odpovede AI) — pôvodne top-level ai_reports
-- ----------------------------------------------------------------
create table if not exists public.ai_reports (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  message_id  text,
  excerpt     text,
  created_at  timestamptz not null default now()
);

-- ----------------------------------------------------------------
-- NOTIFICATIONS  (users/{uid}/notifications)
-- ----------------------------------------------------------------
create table if not exists public.notifications (
  id          text primary key,
  user_id     uuid not null references auth.users (id) on delete cascade,
  data        jsonb not null default '{}'::jsonb,
  read        boolean not null default false,
  created_at  timestamptz not null default now()
);
create index if not exists notifications_user_idx
  on public.notifications (user_id, created_at desc);

-- ----------------------------------------------------------------
-- WATCHED COMPANIES  (users/{uid}/watched_companies)
-- ----------------------------------------------------------------
create table if not exists public.watched_companies (
  ico         text not null,
  user_id     uuid not null references auth.users (id) on delete cascade,
  data        jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now(),
  primary key (user_id, ico)
);

-- ----------------------------------------------------------------
-- TRASH / SOFT DELETE  (generický kôš: {collection}/{uid}/items/{itemId})
-- ----------------------------------------------------------------
create table if not exists public.trash_items (
  id          text not null,
  user_id     uuid not null references auth.users (id) on delete cascade,
  collection  text not null,
  data        jsonb not null default '{}'::jsonb,
  deleted_at  timestamptz not null default now(),
  primary key (user_id, collection, id)
);

-- ----------------------------------------------------------------
-- PUBLIC CACHE: companies / company_snapshots (verejný lookup cache)
-- Čítanie verejné, zápis len service_role (edge function / server).
-- ----------------------------------------------------------------
create table if not exists public.companies (
  ico         text primary key,
  data        jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);
create table if not exists public.company_snapshots (
  ico         text primary key,
  data        jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
alter table public.invoices          enable row level security;
alter table public.expenses          enable row level security;
alter table public.user_settings     enable row level security;
alter table public.bizbot_messages   enable row level security;
alter table public.ai_reports        enable row level security;
alter table public.notifications     enable row level security;
alter table public.watched_companies enable row level security;
alter table public.trash_items       enable row level security;
alter table public.companies         enable row level security;
alter table public.company_snapshots enable row level security;

-- Vlastník (auth.uid()) má plný prístup k svojim riadkom.
do $$
declare t text;
begin
  foreach t in array array[
    'invoices','expenses','user_settings','bizbot_messages',
    'ai_reports','notifications','watched_companies','trash_items'
  ]
  loop
    execute format($f$
      drop policy if exists %1$s_owner_all on public.%1$s;
      create policy %1$s_owner_all on public.%1$s
        for all
        using (user_id = auth.uid())
        with check (user_id = auth.uid());
    $f$, t);
  end loop;
end $$;

-- Verejný cache: čítanie pre prihlásených, zápis len service_role.
drop policy if exists companies_read on public.companies;
create policy companies_read on public.companies
  for select using (auth.role() = 'authenticated');

drop policy if exists company_snapshots_read on public.company_snapshots;
create policy company_snapshots_read on public.company_snapshots
  for select using (auth.role() = 'authenticated');

-- ============================================================
-- STORAGE bucket pre bločky (receipts) — vytvor v dashboarde alebo:
--   insert into storage.buckets (id, name, public) values ('receipts','receipts', false);
-- RLS na storage.objects: cesta začína "<auth.uid()>/".
-- ============================================================
insert into storage.buckets (id, name, public)
values ('receipts', 'receipts', false)
on conflict (id) do nothing;

drop policy if exists receipts_owner_all on storage.objects;
create policy receipts_owner_all on storage.objects
  for all
  using (bucket_id = 'receipts' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'receipts' and (storage.foldername(name))[1] = auth.uid()::text);
