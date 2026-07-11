-- Enable Supabase Realtime for user-owned tables (fixes RealtimeSubscribeException).
do $$
declare
  t text;
begin
  foreach t in array array[
    'invoices',
    'expenses',
    'user_settings',
    'bizbot_messages',
    'ai_reports',
    'notifications',
    'watched_companies',
    'trash_items'
  ]
  loop
    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = t
    ) then
      execute format(
        'alter publication supabase_realtime add table public.%I',
        t
      );
    end if;
  end loop;
end $$;