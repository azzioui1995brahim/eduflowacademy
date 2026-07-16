-- ============================================================
-- Edu Flow Academy — Phase 2: students, classes, enrollments
-- Paste this ENTIRE file into Supabase Dashboard -> SQL Editor
-- -> New query -> Run. Safe to re-run (IF NOT EXISTS / OR REPLACE).
-- Requires supabase-setup.sql (Phase 1) to have been run already.
-- ============================================================

-- 1. Students — real, persistent student records (distinct from the
-- anonymous placement-test rows in `results`).
create sequence if not exists public.student_code_seq;

create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  student_code text unique,
  full_name text not null,
  birth_date date,
  phone text,
  email text,
  guardian_name text,
  guardian_phone text,
  notes text,
  status text not null default 'active' check (status in ('active','inactive')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null
);

create or replace function public.assign_student_code()
returns trigger
language plpgsql
as $$
begin
  if new.student_code is null then
    new.student_code := 'EFA-' || lpad(nextval('public.student_code_seq')::text, 5, '0');
  end if;
  return new;
end;
$$;

drop trigger if exists students_assign_code on public.students;
create trigger students_assign_code
  before insert on public.students
  for each row execute function public.assign_student_code();

drop trigger if exists students_set_updated_at on public.students;
create trigger students_set_updated_at
  before update on public.students
  for each row execute function public.set_updated_at();  -- reuses Phase 1's function

-- 2. Classes — the course catalog. subject uses short codes (fr/en/es/de)
-- rather than results.subject's French words, so Spanish/Dutch have a
-- home and every page can share one label map (see EDUFLOW_SUBJECT_LABELS
-- in eduflow-auth.js).
create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  subject text not null check (subject in ('fr','en','es','de')),
  level text,
  teacher_id uuid references public.profiles(id) on delete set null,
  room text,
  capacity int not null default 12 check (capacity > 0),
  schedule jsonb not null default '[]'::jsonb,  -- [{"day":"lundi","start":"18:00","end":"19:30"}]
  status text not null default 'active' check (status in ('active','archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null
);

drop trigger if exists classes_set_updated_at on public.classes;
create trigger classes_set_updated_at
  before update on public.classes
  for each row execute function public.set_updated_at();

-- 3. Enrollments — student <-> class. 'waitlisted' is included now so a
-- future waitlist phase needs zero schema changes.
create table if not exists public.enrollments (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  status text not null default 'active' check (status in ('active','completed','dropped','waitlisted')),
  enrolled_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null
);

-- One active/waitlisted enrollment per student per class; dropped/completed
-- history can still accumulate multiple rows.
create unique index if not exists enrollments_active_unique
  on public.enrollments (student_id, class_id)
  where status in ('active','waitlisted');

create index if not exists idx_classes_teacher on public.classes(teacher_id);
create index if not exists idx_classes_subject_status on public.classes(subject, status);
create index if not exists idx_enrollments_student on public.enrollments(student_id);
create index if not exists idx_enrollments_class on public.enrollments(class_id);
create index if not exists idx_students_status on public.students(status);

-- 4. Helper: current user's role, without tripping profiles' own RLS.
create or replace function public.current_role()
returns text
language sql
security definer
set search_path = public
stable
as $$
  select role from public.profiles where id = auth.uid() and status = 'active';
$$;

-- 4b. Extend Phase 1's profiles policy: receptionist needs to see staff/admin
-- names to show teacher assignments on the class catalog. Additional
-- permissive policies are OR'd together, so this only ever widens access,
-- never narrows the Phase 1 policy already in place.
drop policy if exists "profiles_select_receptionist" on public.profiles;
create policy "profiles_select_receptionist"
  on public.profiles for select
  to authenticated
  using (public.current_role() = 'receptionist' and role in ('staff','admin'));

-- 5. Row Level Security.
alter table public.students enable row level security;
alter table public.classes enable row level security;
alter table public.enrollments enable row level security;

-- students: admin full; receptionist full; staff sees only students
-- enrolled in a class they teach.
drop policy if exists "students_select" on public.students;
create policy "students_select"
  on public.students for select
  to authenticated
  using (
    public.is_admin()
    or public.current_role() = 'receptionist'
    or exists (
      select 1 from public.enrollments e join public.classes c on c.id = e.class_id
      where e.student_id = students.id and c.teacher_id = auth.uid() and e.status = 'active'
    )
  );

drop policy if exists "students_insert" on public.students;
create policy "students_insert"
  on public.students for insert
  to authenticated
  with check (public.is_admin() or public.current_role() = 'receptionist');

drop policy if exists "students_update" on public.students;
create policy "students_update"
  on public.students for update
  to authenticated
  using (public.is_admin() or public.current_role() = 'receptionist')
  with check (public.is_admin() or public.current_role() = 'receptionist');
-- No DELETE policy: students are deactivated (status='inactive'), never removed.

-- classes: admin full CRUD; receptionist read-only catalog; staff sees
-- only their own classes.
drop policy if exists "classes_select" on public.classes;
create policy "classes_select"
  on public.classes for select
  to authenticated
  using (public.is_admin() or public.current_role() = 'receptionist' or teacher_id = auth.uid());

drop policy if exists "classes_insert" on public.classes;
create policy "classes_insert"
  on public.classes for insert
  to authenticated
  with check (public.is_admin());

drop policy if exists "classes_update" on public.classes;
create policy "classes_update"
  on public.classes for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());
-- No DELETE policy: classes are archived (status='archived'), never removed.

-- enrollments: admin + receptionist create/manage; staff sees only
-- enrollments for classes they teach.
drop policy if exists "enrollments_select" on public.enrollments;
create policy "enrollments_select"
  on public.enrollments for select
  to authenticated
  using (
    public.is_admin()
    or public.current_role() = 'receptionist'
    or exists (select 1 from public.classes c where c.id = enrollments.class_id and c.teacher_id = auth.uid())
  );

drop policy if exists "enrollments_insert" on public.enrollments;
create policy "enrollments_insert"
  on public.enrollments for insert
  to authenticated
  with check (public.is_admin() or public.current_role() = 'receptionist');

drop policy if exists "enrollments_update" on public.enrollments;
create policy "enrollments_update"
  on public.enrollments for update
  to authenticated
  using (public.is_admin() or public.current_role() = 'receptionist')
  with check (public.is_admin() or public.current_role() = 'receptionist');
-- No DELETE policy: drop a student via status='dropped', never remove the row.
