-- ============================================================
--  Tezkor Klaviatura — Supabase baza sozlamasi
--  Supabase > SQL Editor > shu kodni qo'yib "Run" bosing.
-- ============================================================

-- 1) Ruxsat etilgan emaillar (faqat shular kira oladi)
create table if not exists allowed_emails (
  email text primary key,
  added_at timestamptz default now()
);

-- 2) Foydalanuvchi profili (ball, natijalar)
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  name text,
  points int default 0,
  best_wpm int default 0,
  lessons_done int default 0,
  baseline_wpm int,
  baseline_acc int,
  latest_wpm int,
  latest_acc int,
  updated_at timestamptz default now()
);

-- 3) Har bir mashq natijasi tarixi
create table if not exists scores (
  id bigserial primary key,
  user_id uuid references auth.users(id) on delete cascade,
  wpm int,
  accuracy int,
  created_at timestamptz default now()
);

-- 4) Guruhlar
create table if not exists groups (
  id bigserial primary key,
  name text not null,
  teacher_email text,
  created_at timestamptz default now()
);

-- 5) Guruh a'zolari
create table if not exists group_members (
  id bigserial primary key,
  group_id bigint references groups(id) on delete cascade,
  email text
);

-- ============================================================
--  Xavfsizlik (RLS) — MVP uchun sodda siyosatlar
-- ============================================================
alter table allowed_emails enable row level security;
alter table profiles enable row level security;
alter table scores enable row level security;
alter table groups enable row level security;
alter table group_members enable row level security;

-- Kirgan foydalanuvchi whitelistni o'qiy oladi (tekshirish uchun)
create policy "read_allowed" on allowed_emails for select to authenticated using (true);

-- Reyting: hamma kirganlar barcha profillarni ko'ra oladi
create policy "read_profiles" on profiles for select to authenticated using (true);
-- O'z profilini yozish/yangilash
create policy "upsert_own_profile" on profiles for insert to authenticated with check (auth.uid() = id);
create policy "update_own_profile" on profiles for update to authenticated using (auth.uid() = id);

-- O'z natijasini yozish, o'qish
create policy "insert_own_score" on scores for insert to authenticated with check (auth.uid() = user_id);
create policy "read_own_score" on scores for select to authenticated using (auth.uid() = user_id);

-- Guruhlar: kirganlar ko'ra oladi (yozishni admin dashboard yoki keyin tightening orqali)
create policy "read_groups" on groups for select to authenticated using (true);
create policy "read_group_members" on group_members for select to authenticated using (true);

-- ============================================================
--  Boshlang'ich admin/o'quvchi emaillarini qo'shish (o'zingiznikiga o'zgartiring)
-- ============================================================
insert into allowed_emails (email) values
  ('ganisher@gmail.com'),
  ('oquvchi1@gmail.com')
on conflict (email) do nothing;

-- ESLATMA: allowed_emails va groups jadvallariga YOZISH (qo'shish/o'chirish) ni
-- boshida Supabase dashboard'idan yoki service_role kalit bilan qiling.
-- Saytdan admin yozishini xohlasangiz, keyin admin emaili uchun alohida
-- "insert/delete" policy qo'shamiz (auth.jwt() ->> 'email' tekshiruvi bilan).
