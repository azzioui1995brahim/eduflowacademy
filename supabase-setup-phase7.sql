-- ============================================================
-- Edu Flow Academy — Phase 7: phone number on staff/reception
-- accounts, captured at signup. Prep work for SMS notifications
-- (actual sending needs a paid SMS provider account — not wired
-- up yet, this just makes sure the number is collected and
-- stored so it's ready the moment that provider is chosen).
-- Paste into Supabase Dashboard -> SQL Editor -> New query -> Run.
-- Safe to re-run. Requires Phase 1 to have been run already.
-- ============================================================

-- 1. Add the column.
alter table public.profiles
  add column if not exists phone text;

-- 2. Capture it at signup, same way full_name/requested_role
-- already are — signup.html will pass phone in the same
-- options.data payload.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, requested_role, phone)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'requested_role',
    new.raw_user_meta_data ->> 'phone'
  );
  return new;
end;
$$;

-- No RLS change needed: phone rides on the existing profiles row,
-- already covered by the Phase 1 select/update policies (own row,
-- or admin). protect_role_status() only guards role/status, so
-- editing phone works the same as editing full_name already does.
