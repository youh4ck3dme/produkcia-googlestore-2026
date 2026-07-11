-- Automatically enable RLS on every new table in public schema.
create or replace function public.rls_auto_enable()
returns event_trigger
language plpgsql
security definer
set search_path = pg_catalog
as $$
declare
  cmd record;
begin
  for cmd in
    select *
    from pg_event_trigger_ddl_commands()
    where command_tag in ('CREATE TABLE', 'CREATE TABLE AS')
  loop
    if cmd.schema_name = 'public' then
      execute format(
        'alter table if exists %s enable row level security',
        cmd.object_identity
      );
    end if;
  end loop;
end;
$$;

drop event trigger if exists rls_auto_enable_trigger;
create event trigger rls_auto_enable_trigger
  on ddl_command_end
  when tag in ('CREATE TABLE', 'CREATE TABLE AS')
  execute function public.rls_auto_enable();