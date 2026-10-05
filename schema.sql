-- ============================================================
-- arc.app.hub  スキーマ
-- Supabase の SQL Editor に全文を貼り付けて Run してください。
-- ============================================================

-- 講師(1名)を登録するテーブル
create table if not exists public.teachers (
  user_id uuid primary key references auth.users (id) on delete cascade
);

-- アプリ一覧
create table if not exists public.apps (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (char_length(name) between 1 and 80),
  url         text not null check (url ~* '^https?://'),
  description text not null default '' check (char_length(description) <= 200),
  category    text not null default '' check (char_length(category) <= 40),
  icon        text not null default '',
  tags        text[] not null default '{}',
  visible     boolean not null default true,
  sort_order  integer not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists apps_sort_idx on public.apps (sort_order, created_at);

-- 更新日時を自動で書き換える
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists apps_set_updated_at on public.apps;
create trigger apps_set_updated_at
  before update on public.apps
  for each row execute function public.set_updated_at();

-- ログイン中のユーザーが講師かどうかを判定する
create or replace function public.is_teacher()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.teachers where user_id = auth.uid()
  );
$$;

-- ------------------------------------------------------------
-- Row Level Security(権限設定)
-- ------------------------------------------------------------
alter table public.apps     enable row level security;
alter table public.teachers enable row level security;

-- 作り直しても動くよう、既存ポリシーを先に削除
drop policy if exists "apps_select"  on public.apps;
drop policy if exists "apps_insert"  on public.apps;
drop policy if exists "apps_update"  on public.apps;
drop policy if exists "apps_delete"  on public.apps;
drop policy if exists "teachers_self_select" on public.teachers;

-- 閲覧: 生徒は visible = true のみ / 講師は全件
create policy "apps_select" on public.apps
  for select using (visible = true or public.is_teacher());

-- 追加・更新・削除: 講師のみ
create policy "apps_insert" on public.apps
  for insert with check (public.is_teacher());

create policy "apps_update" on public.apps
  for update using (public.is_teacher()) with check (public.is_teacher());

create policy "apps_delete" on public.apps
  for delete using (public.is_teacher());

-- teachers: 自分の行だけ読める(管理画面での講師判定用)。書き込みポリシーは作らない。
create policy "teachers_self_select" on public.teachers
  for select using (user_id = auth.uid());


-- ------------------------------------------------------------
-- コンソールURL(講師専用)
-- ------------------------------------------------------------
create table if not exists public.app_consoles (
  app_id     uuid primary key references public.apps (id) on delete cascade,
  admin_url  text check (admin_url  is null or admin_url  ~* '^https?://'),
  lesson_url text check (lesson_url is null or lesson_url ~* '^https?://'),
  updated_at timestamptz not null default now()
);

alter table public.app_consoles enable row level security;

drop policy if exists "consoles_teacher_all" on public.app_consoles;
create policy "consoles_teacher_all" on public.app_consoles
  for all
  using (public.is_teacher())
  with check (public.is_teacher());

drop trigger if exists app_consoles_set_updated_at on public.app_consoles;
create trigger app_consoles_set_updated_at
  before update on public.app_consoles
  for each row execute function public.set_updated_at();
