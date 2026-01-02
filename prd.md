# PRD: 공유 가계부 앱 (Shared Household Account)

## 프로젝트 개요

### 목적
- 개인 및 그룹(가족/커플/룸메이트)이 함께 사용할 수 있는 공유 가계부 앱 개발
- '쉬운 가계부' 앱의 핵심 기능을 기반으로 공유 기능을 추가한 Flutter + Supabase 앱

### 기술 스택
- **프론트엔드**: Flutter (iOS/Android 크로스플랫폼)
- **백엔드**: Supabase (PostgreSQL + Auth + Realtime + Storage)
- **상태관리**: Riverpod
- **로컬 저장소**: SharedPreferences / Hive

---

## 핵심 요구사항

### 1. 사용자 인증 (Authentication)
- [ ] 이메일/비밀번호 회원가입 및 로그인
- [ ] 소셜 로그인 (Google, Apple)
- [ ] 비밀번호 재설정
- [ ] 자동 로그인 (토큰 저장)
- [ ] 프로필 관리 (이름, 프로필 이미지)

### 2. 가계부 관리 (Ledger Management)
- [ ] 개인 가계부 생성/수정/삭제
- [ ] 공유 가계부 생성/수정/삭제
- [ ] 가계부 간 전환 기능
- [ ] 가계부별 통화 설정 (KRW, USD 등)

### 3. 수입/지출 기록 (Transaction)
- [ ] 수입/지출 구분 입력
- [ ] 금액 입력 (계산기 내장)
- [ ] 날짜/시간 선택
- [ ] 카테고리 선택
- [ ] 메모 입력
- [ ] 반복 거래 설정 (일/주/월)
- [ ] 거래 수정/삭제
- [ ] 사진 첨부 (영수증 등)

### 4. 카테고리 관리 (Category)
- [ ] 기본 카테고리 제공 (식비, 교통, 쇼핑 등)
- [ ] 사용자 정의 카테고리 추가/수정/삭제
- [ ] 카테고리 아이콘 및 색상 설정
- [ ] 수입/지출별 카테고리 분리

### 5. 캘린더 뷰 (Calendar View)
- [ ] 월별 캘린더 표시
- [ ] 일별 수입/지출 합계 표시
- [ ] 날짜 선택 시 해당 일 거래 목록 표시
- [ ] 월별 합계 (수입/지출/잔액)

### 6. 통계 및 차트 (Statistics)
- [ ] 카테고리별 지출 원형 차트
- [ ] 월별 수입/지출 추세 막대 그래프
- [ ] 기간별 통계 (주/월/연)
- [ ] 전월 대비 비교

### 7. 예산 관리 (Budget)
- [ ] 월별 예산 설정
- [ ] 카테고리별 예산 설정
- [ ] 예산 대비 사용률 표시
- [ ] 예산 초과 알림

### 8. 공유 기능 (핵심 차별점)
- [ ] 가계부 멤버 초대 (이메일/링크)
- [ ] 멤버 권한 관리 (소유자/편집자/조회자)
- [ ] 실시간 데이터 동기화 (Supabase Realtime)
- [ ] 멤버별 거래 기록자 표시
- [ ] 멤버 활동 알림

### 9. 검색 및 필터
- [ ] 키워드 검색 (메모, 카테고리)
- [ ] 기간별 필터
- [ ] 카테고리별 필터
- [ ] 금액 범위 필터

### 10. 설정 (Settings)
- [ ] 알림 설정
- [ ] 테마 설정 (라이트/다크)
- [ ] 데이터 백업/복원
- [ ] 계정 삭제

---

## 성공 기준

### 기능적 성공 기준
- [ ] 앱 설치 후 5분 이내 첫 거래 기록 가능
- [ ] 가계부 공유 초대 후 30초 이내 실시간 동기화 확인
- [ ] 오프라인 상태에서도 기본 기록 기능 사용 가능
- [ ] 1000건 이상 거래에서도 부드러운 스크롤 성능

### 기술적 성공 기준
- [ ] Supabase 무료 플랜 제약 내 운영 (500MB DB, 1GB Storage)
- [ ] 앱 Cold Start 3초 이내
- [ ] 크래시율 1% 미만
- [ ] 테스트 커버리지 70% 이상

---

## 제약사항

### Supabase 무료 플랜 제약
- 데이터베이스: 500MB
- 스토리지: 1GB
- 월간 활성 사용자: 50,000
- 실시간 연결: 200 동시 연결

### 대응 전략
- 이미지 압축 후 업로드 (최대 500KB)
- 오래된 데이터 아카이빙 정책
- 효율적인 쿼리 및 인덱싱

---

## 데이터베이스 스키마 (초안)

### users (Supabase Auth 확장)
- id (uuid, PK)
- email
- display_name
- avatar_url
- created_at

### ledgers (가계부)
- id (uuid, PK)
- name
- currency (KRW, USD 등)
- owner_id (FK -> users)
- is_shared
- created_at

### ledger_members (가계부 멤버)
- id (uuid, PK)
- ledger_id (FK -> ledgers)
- user_id (FK -> users)
- role (owner/editor/viewer)
- joined_at

### categories (카테고리)
- id (uuid, PK)
- ledger_id (FK -> ledgers)
- name
- icon
- color
- type (income/expense)
- is_default

### transactions (거래)
- id (uuid, PK)
- ledger_id (FK -> ledgers)
- category_id (FK -> categories)
- user_id (FK -> users, 기록자)
- amount
- type (income/expense)
- date
- memo
- image_url
- is_recurring
- recurring_type (daily/weekly/monthly)
- created_at

### budgets (예산)
- id (uuid, PK)
- ledger_id (FK -> ledgers)
- category_id (FK -> categories, nullable)
- amount
- month (YYYY-MM)

---

## 화면 구성 (초안)

1. **스플래시 화면**
2. **로그인/회원가입 화면**
3. **메인 화면** (캘린더 + 거래 목록)
4. **거래 입력 화면** (바텀시트)
5. **통계 화면**
6. **예산 화면**
7. **가계부 관리 화면**
8. **공유 멤버 관리 화면**
9. **설정 화면**
10. **프로필 화면**

---

## 마일스톤

### Phase 1: 기본 기능 (2주)
- 프로젝트 셋업 (Flutter + Supabase)
- 사용자 인증
- 개인 가계부 CRUD
- 거래 CRUD
- 캘린더 뷰

### Phase 2: 카테고리 및 통계 (1주)
- 카테고리 관리
- 통계 차트

### Phase 3: 공유 기능 (2주)
- 공유 가계부
- 멤버 초대/관리
- 실시간 동기화
- 알림

### Phase 4: 고급 기능 (1주)
- 예산 관리
- 검색/필터
- 반복 거래

### Phase 5: 마무리 (1주)
- 테스트 및 버그 수정
- 성능 최적화
- 배포 준비
