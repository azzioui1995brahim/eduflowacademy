-- ============================================================
-- Edu Flow Academy — Phase 12: every student deletion is now
-- automatically declared to admin via the existing messages/
-- inbox system (whether the deleter is admin or receptionist).
-- Paste into Supabase Dashboard -> SQL Editor -> New query -> Run.
-- Safe to re-run. Requires Phase 6 (messages) already run.
-- ============================================================

-- 1. 'admin' is now a valid target_role, so a declaration can be
-- aimed specifically at the administration (not just staff/
-- receptionist/everyone).
alter table public.messages
  drop constraint if exists messages_target_role_check;
alter table public.messages
  add constraint messages_target_role_check
  check (target_role in ('staff','receptionist','admin','all'));

-- 2. Receptionist can now insert a message too, but ONLY a
-- declaration aimed at admin — this is not general messaging
-- power, just enough for "I deleted X" to reach admin. Admin
-- keeps unrestricted send access as before.
drop policy if exists "messages_insert" on public.messages;
create policy "messages_insert"
  on public.messages for insert
  to authenticated
  with check (
    public.is_admin()
    or (public.current_role() = 'receptionist' and target_role = 'admin')
  );
