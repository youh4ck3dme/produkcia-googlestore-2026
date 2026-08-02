create table if not exists public.entitlements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  product_id text not null,
  purchase_token text,
  granted_at timestamptz default now(),
  expires_at timestamptz,
  is_active boolean default true,
  unique(user_id, product_id)
);

alter table public.entitlements enable row level security;

create policy "Users read own entitlements"
  on public.entitlements for select
  using (auth.uid() = user_id);
