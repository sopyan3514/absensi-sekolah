-- Fondasi skema Supabase/PostgreSQL untuk aplikasi absensi sekolah.
-- Tinjau kebijakan RLS dan lakukan pengujian akses sebelum memasukkan data nyata.
create extension if not exists pgcrypto;

create table if not exists public.school_classes (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  level text not null,
  academic_year text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role text not null check (role in ('admin','guru')),
  class_id uuid references public.school_classes(id) on delete set null,
  created_at timestamptz not null default now(),
  check (role <> 'guru' or class_id is not null)
);

create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  nis text not null unique,
  full_name text not null,
  gender text not null check (gender in ('L','P')),
  class_id uuid not null references public.school_classes(id) on delete restrict,
  photo_path text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  attendance_date date not null,
  status text not null check (status in ('Hadir','Izin','Sakit','Alpa')),
  note text,
  marked_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(student_id, attendance_date)
);

create index if not exists students_class_id_idx on public.students(class_id);
create index if not exists attendance_date_idx on public.attendance(attendance_date);
create index if not exists attendance_student_date_idx on public.attendance(student_id, attendance_date);

alter table public.school_classes enable row level security;
alter table public.profiles enable row level security;
alter table public.students enable row level security;
alter table public.attendance enable row level security;

-- Helper functions avoid recursive RLS queries on profiles.
create or replace function public.current_role()
returns text language sql stable security definer set search_path = public
as $$ select role from public.profiles where id = auth.uid() $$;
create or replace function public.current_class_id()
returns uuid language sql stable security definer set search_path = public
as $$ select class_id from public.profiles where id = auth.uid() $$;

-- Classes: signed-in users can view classes; only admins can change them.
drop policy if exists "classes read authenticated" on public.school_classes;
create policy "classes read authenticated" on public.school_classes for select to authenticated using (true);
drop policy if exists "classes admin manage" on public.school_classes;
create policy "classes admin manage" on public.school_classes for all to authenticated using (public.current_role()='admin') with check (public.current_role()='admin');

-- Profiles: users can view their own profile; admins can manage all profiles.
drop policy if exists "profile read self or admin" on public.profiles;
create policy "profile read self or admin" on public.profiles for select to authenticated using (id=auth.uid() or public.current_role()='admin');
drop policy if exists "profile admin manage" on public.profiles;
create policy "profile admin manage" on public.profiles for all to authenticated using (public.current_role()='admin') with check (public.current_role()='admin');

-- Students: admins see all; teachers only their assigned class.
drop policy if exists "students read by role" on public.students;
create policy "students read by role" on public.students for select to authenticated using (public.current_role()='admin' or class_id=public.current_class_id());
drop policy if exists "students admin insert" on public.students;
create policy "students admin insert" on public.students for insert to authenticated with check (public.current_role()='admin');
drop policy if exists "students admin update" on public.students;
create policy "students admin update" on public.students for update to authenticated using (public.current_role()='admin') with check (public.current_role()='admin');
drop policy if exists "students admin delete" on public.students;
create policy "students admin delete" on public.students for delete to authenticated using (public.current_role()='admin');

-- Attendance: teachers can read/write attendance for their assigned class only.
drop policy if exists "attendance read by role" on public.attendance;
create policy "attendance read by role" on public.attendance for select to authenticated using (public.current_role()='admin' or exists(select 1 from public.students s where s.id=student_id and s.class_id=public.current_class_id()));
drop policy if exists "attendance insert by role" on public.attendance;
create policy "attendance insert by role" on public.attendance for insert to authenticated with check (public.current_role()='admin' or (marked_by=auth.uid() and exists(select 1 from public.students s where s.id=student_id and s.class_id=public.current_class_id())));
drop policy if exists "attendance update by role" on public.attendance;
create policy "attendance update by role" on public.attendance for update to authenticated using (public.current_role()='admin' or (marked_by=auth.uid() and exists(select 1 from public.students s where s.id=student_id and s.class_id=public.current_class_id()))) with check (public.current_role()='admin' or (marked_by=auth.uid() and exists(select 1 from public.students s where s.id=student_id and s.class_id=public.current_class_id())));
drop policy if exists "attendance delete admin" on public.attendance;
create policy "attendance delete admin" on public.attendance for delete to authenticated using (public.current_role()='admin');

-- Storage bucket `student-photos` harus dibuat lewat Dashboard Storage dan dikonfigurasi privat.
-- Jangan menaruh service_role key di browser.
