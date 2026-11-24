-- =========================================================
-- 100번 새벽기도 · Supabase 스키마
-- Supabase 대시보드 > SQL Editor 에 통째로 붙여넣고 Run
-- (처음 한 번만 실행하세요. 다시 실행하면 "already exists" 에러가 나요)
-- =========================================================

-- 1) 테이블 ------------------------------------------------
create table public.profiles (
  id          uuid primary key references auth.users on delete cascade,
  nickname    text not null check (char_length(nickname) between 1 and 12),
  created_at  timestamptz not null default now()
);

-- 회차: 100개를 채우면 그 회차가 완성되고, 가족 누구나 다음 회차를 시작할 수 있어요
create table public.rounds (
  id            bigint generated always as identity primary key,
  number        int  not null unique,                                   -- 1, 2, 3 ...
  started_on    date not null,                                          -- 한국 날짜
  completed_on  date,                                                   -- null = 진행 중
  started_by    uuid references public.profiles(id) on delete set null
);
create unique index one_active_round on public.rounds ((true)) where completed_on is null;   -- 진행 중인 회차는 항상 1개
insert into public.rounds (number, started_on) values (1, (now() at time zone 'Asia/Seoul')::date);

create table public.prayers (
  id          bigint generated always as identity primary key,
  round_id    bigint not null references public.rounds(id),
  slot        int  not null check (slot between 1 and 100),         -- 회차 안에서 몇 번째 촛불인지
  user_id     uuid not null references public.profiles(id) on delete cascade,
  prayed_on   date not null,                                        -- 한국 날짜
  created_at  timestamptz not null default now(),
  constraint prayers_round_slot_key unique (round_id, slot),
  unique (user_id, prayed_on)                                       -- 1인 하루 1회 (회차 상관없이)
);

-- 가족 코드: 이 코드를 아는 사람만 가입할 수 있어요
create table public.app_settings (
  id           int primary key default 1 check (id = 1),
  family_code  text not null
);
-- ↓ SQL Editor에 붙여넣은 뒤 여기서만 실제 코드로 바꾸세요. 이 파일(공개 저장소)에는 실제 코드를 저장하지 마세요
insert into public.app_settings (family_code) values ('CHANGE_ME');


-- 2) 가족 여부 확인 함수 ------------------------------------
create or replace function public.is_member()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from profiles where id = auth.uid());
$$;


-- 3) RLS: 가족만 읽기, 쓰기는 함수로만 ------------------------
alter table public.profiles     enable row level security;
alter table public.prayers      enable row level security;
alter table public.rounds       enable row level security;
alter table public.app_settings enable row level security;   -- 정책 없음 = 아무도 직접 못 읽음

create policy "family reads profiles" on public.profiles
  for select to authenticated using (public.is_member());

create policy "me updates my nickname" on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

create policy "family reads prayers" on public.prayers
  for select to authenticated using (public.is_member());

create policy "family reads rounds" on public.rounds
  for select to authenticated using (public.is_member());

-- 직접 수정은 닉네임 컬럼만 (id, created_at 은 못 바꾸게)
revoke insert, update, delete on public.profiles from anon, authenticated;
grant update (nickname) on public.profiles to authenticated;
revoke insert, update, delete on public.prayers      from anon, authenticated;
revoke insert, update, delete on public.rounds       from anon, authenticated;
revoke all                    on public.app_settings from anon, authenticated;


-- 4) 가족 가입 (닉네임 + 가족 코드) --------------------------
create or replace function public.join_family(p_nickname text, p_code text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  if (select family_code from app_settings where id = 1) = 'CHANGE_ME' then
    raise exception 'code_not_set';   -- 가족 코드를 안 바꿨으면 아무도 가입 못 함
  end if;
  if p_code is distinct from (select family_code from app_settings where id = 1) then
    raise exception 'wrong_code';
  end if;
  insert into profiles (id, nickname) values (auth.uid(), left(trim(p_nickname), 12))
  on conflict (id) do update set nickname = excluded.nickname;
end $$;


-- 5) 촛불 켜기: 진행 중인 회차 안에서 다음 번호 ---------------
create or replace function public.light_candle()
returns public.prayers language plpgsql security definer set search_path = public as $$
declare
  v_today date := (now() at time zone 'Asia/Seoul')::date;
  v_round rounds;
  v_count int;
  v_row   prayers;
begin
  if not public.is_member() then raise exception 'not_member'; end if;

  -- 두 사람이 동시에 눌러도 번호가 겹치지 않게 잠금
  lock table prayers in share row exclusive mode;

  -- 하루 1번은 회차와 상관없이
  if exists (select 1 from prayers where user_id = auth.uid() and prayed_on = v_today) then
    raise exception 'already_today';
  end if;

  select * into v_round from rounds where completed_on is null for update;
  if not found then raise exception 'completed'; end if;

  select count(*) into v_count from prayers where round_id = v_round.id;
  if v_count >= 100 then raise exception 'completed'; end if;

  insert into prayers (round_id, slot, user_id, prayed_on)
  values (v_round.id, v_count + 1, auth.uid(), v_today)
  returning * into v_row;

  -- 100번째를 넣는 순간 회차 완성
  if v_count + 1 >= 100 then
    update rounds set completed_on = v_today where id = v_round.id;
  end if;

  return v_row;
end $$;

-- 6) 새 회차 시작: 진행 중인 회차가 없을 때만 ----------------
create or replace function public.start_round()
returns public.rounds language plpgsql security definer set search_path = public as $$
declare
  v_row rounds;
begin
  if not public.is_member() then raise exception 'not_member'; end if;

  -- 두 사람이 동시에 눌러도 회차는 1개만 생기게 잠금
  lock table rounds in exclusive mode;

  if exists (select 1 from rounds where completed_on is null) then
    raise exception 'round_in_progress';
  end if;

  insert into rounds (number, started_on, started_by)
  values (coalesce((select max(number) from rounds), 0) + 1,
          (now() at time zone 'Asia/Seoul')::date,
          auth.uid())
  returning * into v_row;

  return v_row;
end $$;

revoke all on function public.is_member()             from public, anon;
revoke all on function public.join_family(text, text) from public, anon;
revoke all on function public.light_candle()          from public, anon;
revoke all on function public.start_round()           from public, anon;
grant execute on function public.is_member()             to authenticated;
grant execute on function public.join_family(text, text) to authenticated;
grant execute on function public.light_candle()          to authenticated;
grant execute on function public.start_round()           to authenticated;


-- 7) 실시간 동기화 -------------------------------------------
alter publication supabase_realtime add table public.prayers, public.profiles, public.rounds;


-- (참고) 모든 회차를 지우고 처음부터 시작하고 싶을 때:
-- truncate public.prayers, public.rounds restart identity;
-- insert into public.rounds (number, started_on) values (1, (now() at time zone 'Asia/Seoul')::date);
