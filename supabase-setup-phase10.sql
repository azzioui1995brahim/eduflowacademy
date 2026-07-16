-- ============================================================
-- Edu Flow Academy — Phase 10: the "Accompagnement educatif &
-- therapie" formations (Psychomotricite, Psychologue,
-- Orthophoniste, Educatrice specialisee, accompagnement enfants
-- autistes, accompagnement enfants trisomiques) can now be
-- created as real classes too, same as the Phase 8 professional
-- formations.
-- Paste into Supabase Dashboard -> SQL Editor -> New query -> Run.
-- Safe to re-run. Requires Phase 8 to have been run already.
-- ============================================================

alter table public.classes
  drop constraint if exists classes_subject_check;

alter table public.classes
  add constraint classes_subject_check check (
    subject in (
      'fr','en','es','de',
      'drone','ia','infographie','ecommerce','marketing_digital','bureautique','secourisme',
      'psychomotricite','psychologue','orthophoniste','educatrice_specialisee',
      'enfants_autistes','enfants_trisomiques'
    )
  );
