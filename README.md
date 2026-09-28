# 100번 새벽기도

가족 6명이 새벽기도를 마칠 때마다 촛불을 하나씩 켜서, 함께 100개를 채우는 모바일 웹앱.

---

## 1. 기획

### 목적과 사용자
- 사용자: 가족 6명 (소수의 닫힌 그룹)
- 목적: 각자 새벽기도를 마친 뒤 기록하고, 서로의 기록을 보며 함께 100번을 완성
- 사용 환경: **모바일 전용** (홈 화면에 추가해서 앱처럼 사용). 데스크톱은 가운데 정렬된 모바일 폭(최대 520px)으로만 대응
- 원칙: 아주 간단하게. 기능을 늘리지 않는다

### 화면 흐름
```
카카오 로그인 → (첫 로그인만) 닉네임 + 가족 코드 입력 → 촛불 채우기 페이지
```
- 이미 가입한 사람은 로그인 후 바로 촛불 채우기 페이지로
- 로그인 상태는 유지 (다음에 열면 바로 메인)

### 화면별 내용

**① 로그인**
- 밤하늘 배경에 켜진 촛불 하나, 제목 "100번 새벽기도", 짧은 소개
- 하단에 카카오 로그인 버튼 (카카오 가이드 색 #FEE500)
- 카카오톡 인앱 브라우저로 열면 "브라우저로 열기" 안내가 뜸

**② 닉네임 설정**
- 가족들에게 보일 이름 입력 (최대 12자). 카카오 닉네임으로 미리 채워둠
- 가족 코드 입력 (가족만 가입할 수 있게)
- 메뉴에서 "이름 바꾸기"로 다시 진입 가능 (이때는 코드 입력 없음)

**③ 촛불 채우기 (메인)**
- 상단 고정 헤더: 제목, 진행 수(예: 37 / 100), 진행 바, 가족별 이름 칩(켠 횟수 + 오늘 켰으면 노란 점)
- 본문: **3열 × n행 격자**에 촛불 100개. 각 칸은 별이 있는 밤하늘 배경 + 물에 비친 반사
- **꺼진 촛불**: 색이 없는 회색, 낮은 opacity, 불꽃 없이 심지만. 아래에 번호
- **다음 차례 촛불**: 살짝 밝게 숨쉬는 효과 + "기도 켜기" 버튼
- **켜진 촛불**: 참고 이미지처럼 그라데이션 색이 번지고 흰 불꽃이 흔들림. 아래에 **날짜(예: 9.28 (월))와 켠 사람 이름**
- 켜는 순간: 불꽃이 올라오고 빛이 퍼지는 애니메이션 + 짧은 진동
- **100번째 촛불**: 격자 3칸을 모두 차지하는 넓은 칸. 파스텔 촛불 여러 개가 모여 있고(촛농이 흘러내리고 불꽃 뒤로 둥근 빛), 위에 큰 "100"과 성경말씀(이사야 60:1). 켜기 전에는 회색 촛불과 흐린 "100"만 보이고, 켜면 촛불이 하나씩 차례로 켜진 뒤 말씀이 나타남
- **100개 완성 시**: 헤더에 완성 메시지. 다 켜진 촛불을 밤에 3초간 보여준 뒤, 모든 격자 배경이 천천히 **화창한 낮 하늘**(파란 하늘 + 구름, 100번 칸엔 해)로 바뀜

### 규칙
- 가족 전체가 **하나의 100칸**을 함께 채운다 (개인별 100칸 아님)
- 촛불은 **1번부터 차례로** 켜진다 (칸을 골라서 켜지 않음)
- 한 사람은 **하루 1번**만 켤 수 있다. 날짜는 한국 시간 기준, 자정에 바뀜
- 오늘 이미 켰으면 버튼이 "오늘은 켰어요"로 비활성화 (앱을 켜둔 채 자정이 지나면 자동으로 풀림)
- 누군가 켜면 **다른 가족 화면에도 실시간으로** 불이 들어오고 "○○님이 촛불을 켰어요" 토스트
- 앱을 백그라운드에서 다시 열면 최신 상태로 새로고침

### 비주얼
- 참고 이미지: 밤하늘 + 물 위의 그라데이션 촛불 9종 3×3 격자
- 촛불 색은 9가지 그라데이션을 번호 순서대로 순환 (`PALETTE`)
- 촛불 높이는 칸마다 조금씩 다르게
- 폰트: Gowun Batang(제목, 숫자) + Noto Sans KR(본문)
- 항상 어두운 테마 (새벽/밤 콘셉트)
- `prefers-reduced-motion` 대응
- 불꽃 흔들림은 화면에 보이는 칸만 재생 (구형 폰 배려)

### 결정 사항 (바꿀 수 있음)
처음 기획에 명시되지 않아 임의로 정한 부분:
- 공동 100칸 / 순서대로 채움 / 1인 하루 1회
- 가족 코드로 가입 제한 (카카오 계정만 있으면 누구나 들어올 수 있는 문제 방지)
- 카카오 이메일 동의항목은 쓰지 않음 (비즈 앱 인증이 필요해서) — 아래 "문제 해결"의 KOE205 참고

### 하지 않는 것
- 푸시 알림, 기도 내용/메모 작성, 여러 가족 그룹, 촛불 취소·수정 (필요하면 DB에서 직접)

---

## 2. 기술 구성

- **프론트**: `index.html` 한 파일 (빌드 없음, 순수 HTML/CSS/JS)
- **백엔드**: Supabase — Auth(카카오 OAuth), Postgres, Realtime
- **라이브러리**: `@supabase/supabase-js@2` (CDN UMD)
- **데모 모드**: `CONFIG`가 비어 있으면 localStorage로 이 기기에서만 동작. 예시 가족 5명 기록이 들어가 있고 하루 1회 제한 없음. 메뉴의 "데모: 99번까지 채워 보기"로 마지막 칸을 바로 확인 가능
  - 설정값을 넣었는데 CDN을 못 불러오면 데모로 빠지지 않고 "서버 연결 도구를 불러오지 못했어요" 안내

### 파일
```
hope/
├── index.html             앱 전체 (화면, 로그인, 동기화, 데모 모드)
├── schema.sql             Supabase 테이블 · RLS · 함수 · Realtime
├── manifest.webmanifest   홈 화면에 추가할 때 앱 이름 · 아이콘
├── apple-touch-icon.png   iPhone 홈 화면 아이콘 (180)
├── icon-192.png           Android / 파비콘
├── icon-512.png           Android 큰 아이콘
└── README.md              이 문서
```

### 데이터
| 테이블 | 내용 |
|---|---|
| `profiles` | id(auth.users), nickname |
| `prayers` | slot(1~100, unique), user_id, prayed_on(한국 날짜), unique(user_id, prayed_on) |
| `app_settings` | family_code (1행, 클라이언트에서 직접 못 읽음) |

### 서버 함수 (RPC)
- `join_family(p_nickname, p_code)` — 가족 코드 확인 후 profile 생성
- `light_candle()` — 테이블 잠금 후 다음 slot 배정. 에러: `already_today`, `completed`, `not_member`
- `is_member()` — RLS용. 가입한 사람만 profiles/prayers 읽기 가능
- 쓰기는 RPC로만. 직접 수정은 본인 row의 `nickname` 컬럼만 허용 (컬럼 단위 grant)

### index.html 주요 함수
- `initReal()` / `initDemo()` — 모드별 시작
- `afterAuth()` — profile 있으면 메인, 없으면 닉네임 화면 (조회 실패 시엔 닉네임 화면으로 보내지 않음)
- `render()` — 격자·헤더·칩 상태 갱신
- `lightCandle()` → `realLight()`(RPC) 또는 `demoLight()`
- `subscribe()` — prayers INSERT, profiles 변경 실시간 구독
- `ignite(slot)` — 켜지는 애니메이션

---

## 3. 설치

### 3-1. Supabase
1. https://supabase.com 새 프로젝트 (Region: Seoul)
2. SQL Editor에 `schema.sql` 실행. SQL Editor에 붙여넣은 뒤 `'CHANGE_ME'`를 실제 가족 코드로 바꿔서 실행 (**파일에는 저장하지 않기** — 공개 저장소라서). 안 바꾸면 아무도 가입할 수 없음
3. Project Settings → API에서 `Project URL`, `anon public` 키 복사

### 3-2. 카카오
1. https://developers.kakao.com → 애플리케이션 추가
2. 앱 키 → `REST API 키` 복사
3. 카카오 로그인 활성화
4. Redirect URI: `https://<프로젝트ID>.supabase.co/auth/v1/callback`
5. 카카오 로그인 → 보안 → Client Secret 생성·활성화
6. 동의항목: 닉네임, 프로필 사진
7. 플랫폼 → Web에 배포 도메인 등록

### 3-3. Supabase에 카카오 연결
1. Authentication → Providers → Kakao 활성화
   - Client ID = REST API 키, Client Secret = 카카오 Client Secret
   - **Allow users without an email** 켜기
2. Authentication → URL Configuration: Site URL과 Redirect URLs에 배포 주소 (로컬이면 `http://localhost:3000`도)

> 콘솔 메뉴 이름은 바뀔 수 있어요. 위치가 다르면 각 서비스의 Kakao 로그인 문서를 확인하세요.

### 3-4. 설정값
`index.html` 스크립트 맨 위:
```js
const CONFIG = {
  SUPABASE_URL: 'https://abcdefgh.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGciOi...',
  GOAL: 100
};
```
anon 키는 공개돼도 되는 키. 데이터는 RLS + 가족 코드로 보호.

### 3-5. 배포
Netlify Drop(https://app.netlify.com/drop)에 폴더를 끌어다 놓거나 Vercel / GitHub Pages. 배포 주소를 카카오 Web 플랫폼과 Supabase URL 설정에 등록.
아이콘·manifest 파일도 같은 폴더에 함께 올려야 홈 화면 아이콘이 나와요.

### 3-6. 가족 공유
링크 + 가족 코드를 카톡으로 전달 → Safari/Chrome으로 열어서 **홈 화면에 추가**.
카톡에서 링크를 누르면 인앱 브라우저로 열리는데, 로그인 화면의 "브라우저로 열기" 버튼을 누르면 기본 브라우저로 넘어가요.

---

## 4. 자주 바꿀 것
- 목표 개수: `CONFIG.GOAL` + `schema.sql`의 `100` (check 제약, `light_candle`) 함께 수정
- 촛불 색: `PALETTE` (100번째 칸은 `FINALE_PALETTE`, 배치는 `FINALE_CANDLES`)
- 100번째 칸 말씀: `VERSE` (줄 단위 배열 + 출처)
- 가족 코드 변경: `update public.app_settings set family_code = '새코드' where id = 1;`
- 처음부터 다시: `truncate public.prayers restart identity;`

---

## 5. 문제 해결

| 증상 | 원인 · 해결 |
|---|---|
| 카카오 화면에 **KOE205** (잘못된 요청 / 동의항목 미설정) | Supabase가 카카오에 `account_email` 동의를 기본으로 함께 요청하는 경우가 있어요. 카카오 콘솔 → 동의항목에서 "카카오계정(이메일)"을 **선택 동의**로 켜야 하는데, 이 항목은 비즈 앱 전환이 필요해요. 사업자가 없어도 **개인 개발자 비즈 앱**으로 전환할 수 있어요 (앱 설정 → 비즈니스). |
| **KOE006** (등록되지 않은 Redirect URI) | 카카오 Redirect URI가 `https://<프로젝트ID>.supabase.co/auth/v1/callback`과 정확히 같은지 확인 |
| 로그인 후 다시 로그인 화면 | Supabase Redirect URLs에 배포 주소(끝의 `/` 포함 여부까지)가 등록됐는지 확인 |
| iPhone 홈 화면 앱에서 로그인 후 Safari로 튕김 | iOS 홈 화면 앱은 Safari와 저장소가 분리돼 있어요. 홈 화면 앱 **안에서** 카카오 로그인을 한 번 더 해 주세요. 계속 튕기면 `index.html`의 `apple-mobile-web-app-capable` 줄을 지워 Safari 탭으로 열리게 하면 확실해요 |
| 다른 가족이 켠 촛불이 바로 안 보임 | `schema.sql` 6번(Realtime publication)이 실행됐는지 확인. 앱을 닫았다 열면 어쨌든 최신으로 맞춰져요 |
