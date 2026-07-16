-- ============================================================
-- Edu Flow Academy — Phase 11: payments can now record which
-- subject/formation and which period (e.g. "Juillet 2026") they
-- cover, shown on the printable receipt alongside the remaining
-- balance.
-- Paste into Supabase Dashboard -> SQL Editor -> New query -> Run.
-- Safe to re-run. Requires Phase 3 (payments table) already run.
-- ============================================================

alter table public.payments
  add column if not exists subject text,
  add column if not exists period text;

-- No CHECK constraint on subject: it should track whatever subject
-- codes classes.subject currently allows, and that list keeps
-- growing (Phase 8, Phase 10, ...). Keeping it a plain nullable
-- text column avoids a matching migration every time a new
-- formation is added.
