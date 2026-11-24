-- =========================================================
-- 회차(2회차~) 기능 마이그레이션 — 이미 운영 중인 DB에 한 번만 실행
-- Supabase 대시보드 > SQL Editor 에 통째로 붙여넣고 Run
-- 기존 촛불 기록은 지우지 않고 1회차로 옮겨요.
-- (새로 설치하는 경우엔 이 파일 말고 schema.sql만 실행하면 돼요)
-- =========================================================
begin;

-- 1) 회차 테이블 --------------------------------------------
create table public.rounds (
  id            bigint generated always as identity primary key,
  number        int  not null unique,                                   -- 1, 2, 3 ...
  started_on    date not null,                                          -- 한국 날짜
  completed_on  date,                                                   -- null = 진행 중
  started_by    uuid references public.profiles(id) on delete set null
);
-- 진행 중인 회차는 항상 1개
create unique index one_active_round on public.rounds ((true)) where completed_on is null;

-- 2) prayers에 회차 연결 ------------------------------------
alter table public.prayers add column round_id bigint references public.rounds(id);

-- 3) 기존 기록을 1회차로 이관 --------------------------------
insert into public.rounds (number, started_on, completed_on)
select 1,
       coalesce(min(prayed_on), (now() at time zone 'Asia/Seoul')::date),
       case when count(*) >= 100 then max(prayed_on) end
from public.prayers;

update public.prayers set round_id = (select id from public.rounds where number = 1);
alter table public.prayers alter column round_id set not null;

-- 4) slot 유일성을 회차 안으로 -------------------------------
-- 기존 unique(slot) 제약은 이름과 상관없이 찾아서 지워요
do $$
declare c text;
begin
  select con.conname into c
  from pg_constraint con
  join pg_attribute att on att.attrelid = con.conrelid and att.attnum = any(con.conkey)
  where con.conrelid = 'public.prayers'::regclass and con.contype = 'u'
    and array_length(con.conkey, 1) = 1 and att.attname = 'slot';
  if c is not null then
    execute format('alter table public.prayers drop constraint %I', c);
  end if;
end $$;
alter table public.prayers add constraint prayers_round_slot_key unique (round_id, slot);
-- unique(user_id, prayed_on)는 그대로 → 회차 상관없이 하루 1번

-- 5) RLS: 가족만 읽기, 쓰기는 함수로만 ------------------------
alter table public.rounds enable row level security;
create policy "family reads rounds" on public.rounds
  for select to authenticated using (public.is_member());
revoke insert, update, delete on public.rounds from anon, authenticated;

-- 6) 촛불 켜기: 진행 중인 회차 안에서 다음 번호 -----------------
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

-- 7) 새 회차 시작 -------------------------------------------
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

revoke all on function public.light_candle() from public, anon;
revoke all on function public.start_round()  from public, anon;
grant execute on function public.light_candle() to authenticated;
grant execute on function public.start_round()  to authenticated;

-- 8) 실시간 동기화 -------------------------------------------
alter publication supabase_realtime add table public.rounds;

commit;
