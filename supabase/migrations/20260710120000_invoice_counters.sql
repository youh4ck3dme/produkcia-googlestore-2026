-- Invoice numbering counters (replaces Firestore users/{uid}/counters/invoice_{year})

create table if not exists public.invoice_counters (
  user_id uuid not null references auth.users (id) on delete cascade,
  year    int not null,
  seq     int not null default 0,
  primary key (user_id, year)
);

alter table public.invoice_counters enable row level security;

drop policy if exists invoice_counters_owner on public.invoice_counters;
create policy invoice_counters_owner on public.invoice_counters
  for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create or replace function public.reserve_invoice_block(
  p_year int,
  p_block_size int
)
returns table (start_seq int, end_seq int)
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_current int;
  v_start int;
  v_end int;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;
  if p_block_size < 1 then
    raise exception 'block size must be >= 1';
  end if;

  insert into public.invoice_counters (user_id, year, seq)
  values (v_uid, p_year, 0)
  on conflict (user_id, year) do nothing;

  select c.seq into v_current
  from public.invoice_counters c
  where c.user_id = v_uid and c.year = p_year
  for update;

  v_start := v_current + 1;
  v_end := v_current + p_block_size;

  update public.invoice_counters
  set seq = v_end
  where user_id = v_uid and year = p_year;

  start_seq := v_start;
  end_seq := v_end;
  return next;
end;
$$;