-- ============================================================
-- Edu Flow Academy — Correction: the academy teaches German, not
-- Dutch. Fixes classes.subject's CHECK constraint (fr/en/es/nl ->
-- fr/en/es/de) and migrates any existing 'nl' rows to 'de'.
-- Paste into Supabase Dashboard -> SQL Editor -> New query -> Run.
-- Safe to re-run.
-- ============================================================

-- Drop whatever the auto-generated CHECK constraint on subject is
-- named (found dynamically, since it wasn't given an explicit name
-- when the table was created).
do $$
declare
  con_name text;
begin
  select conname into con_name
  from pg_constraint
  where conrelid = 'public.classes'::regclass
    and contype = 'c'
    and pg_get_constraintdef(oid) like '%subject%';
  if con_name is not null then
    execute format('alter table public.classes drop constraint %I', con_name);
  end if;
end $$;

-- Migrate any existing rows BEFORE adding the new, stricter constraint --
-- otherwise the ADD CONSTRAINT below fails on old 'nl' rows.
update public.classes set subject = 'de' where subject = 'nl';
update public.classes set name = replace(name, 'Neerlandais', 'Allemand') where name ilike '%neerlandais%';

alter table public.classes
  add constraint classes_subject_check check (subject in ('fr','en','es','de'));
