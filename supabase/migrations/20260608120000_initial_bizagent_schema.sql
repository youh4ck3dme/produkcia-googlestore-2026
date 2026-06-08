-- BizAgent initial schema (Firestore → Supabase)
-- Applied automatically on merge to production branch via GitHub integration.

create extension if not exists "pgcrypto";

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

create table if not exists public.user_settings (
  user_id     uuid primary key references auth.users (id) on delete cascade,
  data        jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);

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

create table if not exists public.ai_reports (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  message_id  text,
  excerpt     text,
  created_at  timestamptz not null default now()
);

create table if not exists public.notifications (
  id          text primary key,
  user_id     uuid not null references auth.users (id) on delete cascade,
  data        jsonb not null default '{}'::jsonb,
  read        boolean not null default false,
  created_at  timestamptz not null default now()
);
create index if not exists notifications_user_idx
  on public.notifications (user_id, created_at desc);

create table if not exists public.watched_companies (
  ico         text not null,
  user_id     uuid not null references auth.users (id) on delete cascade,
  data        jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now(),
  primary key (user_id, ico)
);

create table if not exists public.trash_items (
  id          text not null,
  user_id     uuid not null references auth.users (id) on delete cascade,
  collection  text not null,
  data        jsonb not null default '{}'::jsonb,
  deleted_at  timestamptz not null default now(),
  primary key (user_id, collection, id)
);

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

drop policy if exists companies_read on public.companies;
create policy companies_read on public.companies
  for select using (auth.role() = 'authenticated');

drop policy if exists company_snapshots_read on public.company_snapshots;
create policy company_snapshots_read on public.company_snapshots
  for select using (auth.role() = 'authenticated');

insert into storage.buckets (id, name, public)
values ('receipts', 'receipts', false)
on conflict (id) do nothing;

drop policy if exists receipts_owner_all on storage.objects;
create policy receipts_owner_all on storage.objects
  for all
  using (bucket_id = 'receipts' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'receipts' and (storage.foldername(name))[1] = auth.uid()::text);
