-- ============================================================
-- Edu Flow Academy — Phase 9: reception can now permanently
-- delete student records too (previously admin-only). Reception
-- already has full create/edit/print access to students — this
-- extends the same "students_delete" policy from Phase 5 to also
-- cover the receptionist role.
-- Paste into Supabase Dashboard -> SQL Editor -> New query -> Run.
-- Safe to re-run. Requires Phase 5 to have been run already.
-- ============================================================

drop policy if exists "students_delete" on public.students;
create policy "students_delete"
  on public.students for delete
  to authenticated
  using (public.is_admin() or public.current_role() = 'receptionist');
