# Supabase 설정 가이드

이 문서는 공유 가계부 앱의 Supabase 백엔드 설정 방법을 설명합니다.

## 프로젝트 정보

| 항목 | 값 |
|------|-----|
| Project ID | `qcpjxxgnqdbngyepevmt` |
| Dashboard | https://supabase.com/dashboard/project/qcpjxxgnqdbngyepevmt |
| API URL | https://qcpjxxgnqdbngyepevmt.supabase.co |
| Schema | `house` |

---

## 1. Edge Functions

### 배포된 함수 목록

| 함수명 | 용도 | verify_jwt |
|--------|------|-----------|
| `send-invite-notification` | 가계부 초대 시 푸시 알림 발송 | false |
| `send-push-notification` | 거래 변경 시 공유 멤버에게 푸시 알림 발송 | false |

### Edge Function Secrets 설정

Supabase Dashboard에서 설정 필요:
- **경로**: Dashboard > Edge Functions > Manage Secrets

#### FIREBASE_SERVICE_ACCOUNT (필수)

Firebase Console에서 Service Account JSON을 발급받아 설정합니다.

**발급 방법**:
1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 선택
3. 프로젝트 설정 (톱니바퀴) > 서비스 계정 탭
4. "새 비공개 키 생성" 클릭
5. JSON 파일 다운로드

**설정 방법**:
1. Supabase Dashboard > Edge Functions > Manage Secrets
2. "New Secret" 클릭
3. Name: `FIREBASE_SERVICE_ACCOUNT`
4. Value: 다운로드한 JSON 파일 전체 내용 붙여넣기

**JSON 형식 예시**:
```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "xxxxx",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@your-project-id.iam.gserviceaccount.com",
  "client_id": "123456789",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  ...
}
```

---

## 2. Database Webhooks

거래 변경 시 자동으로 푸시 알림을 발송하려면 Database Webhook 설정이 필요합니다.

### transactions 테이블 Webhook

| 항목 | 값 |
|------|-----|
| Name | `transaction-push-notification` |
| Table | `house.transactions` |
| Events | INSERT, UPDATE, DELETE |
| Type | Supabase Edge Function |
| Function | `send-push-notification` |
| HTTP Method | POST |
| Timeout | 5000ms |

**설정 방법**:
1. Dashboard > Database > Webhooks
2. "Create a new hook" 클릭
3. 위 설정값 입력
4. Save

---

## 3. Authentication 설정

Dashboard에서 수동 설정 필요 (MCP 미지원)

### URL Configuration

| 설정 | 값 | 용도 |
|------|-----|------|
| Site URL | `https://your-production-url.com` | 기본 리다이렉트 URL |
| Redirect URLs | `sharedhousehold://auth-callback` | 이메일 인증 딥링크 |

### Email Provider

| 설정 | 값 |
|------|-----|
| Enable email signup | ON |
| Confirm email | ON |

---

## 4. Realtime 설정

실시간 동기화가 필요한 테이블:

| 테이블 | 용도 |
|--------|------|
| `transactions` | 거래 실시간 동기화 |
| `categories` | 카테고리 변경 동기화 |
| `ledger_members` | 멤버 변경 동기화 |

**설정 방법**:
1. Dashboard > Database > Replication
2. 위 테이블들에 대해 Realtime 활성화

---

## 5. 테이블 구조

### 핵심 테이블

| 테이블 | 용도 | 주요 컬럼 |
|--------|------|----------|
| `profiles` | 사용자 프로필 | id, email, display_name, color, avatar_url |
| `ledgers` | 가계부 | id, name, owner_id, is_shared, currency |
| `ledger_members` | 가계부 멤버 | ledger_id, user_id, role (owner/admin/member) |
| `categories` | 카테고리 | ledger_id, name, type (income/expense/asset), color |
| `transactions` | 거래 내역 | ledger_id, category_id, amount, type, date, title |
| `budgets` | 예산 | ledger_id, category_id, amount, year, month |
| `ledger_invites` | 초대 | ledger_id, invitee_email, status |
| `fcm_tokens` | FCM 토큰 | user_id, token, device_type |
| `notification_settings` | 알림 설정 | user_id, shared_ledger_change_enabled 등 |
| `push_notifications` | 알림 기록 | user_id, type, title, body, is_read |
| `payment_methods` | 결제수단 | ledger_id, name, type |
| `fixed_expenses` | 고정지출 | ledger_id, category_id, amount, day_of_month |
| `assets` | 자산 | ledger_id, category_id, name, amount, type |
| `asset_goals` | 자산 목표 | ledger_id, title, target_amount, current_amount |

### 트리거 목록

| 트리거 | 테이블 | 함수 | 동작 |
|--------|--------|------|------|
| `on_auth_user_created` | auth.users | `handle_new_user()` | 회원가입 시 profiles + 기본 가계부 자동 생성 |
| `on_ledger_created` | ledgers | `handle_new_ledger()` | 가계부 생성 시 owner를 멤버로 등록 |
| `on_ledger_created_categories` | ledgers | `handle_new_ledger_categories()` | 가계부 생성 시 기본 카테고리 생성 |
| `on_auth_user_created_notification_settings` | auth.users | `handle_new_user_notification_settings()` | 회원가입 시 기본 알림 설정 생성 |
| `enforce_member_limit` | ledger_members | `check_member_limit()` | 멤버 추가 시 최대 2명 제한 |
| `cleanup_fcm_tokens_trigger` | fcm_tokens | `cleanup_duplicate_fcm_tokens()` | FCM 토큰 중복 방지 |

### RLS 정책 요약

| 테이블 | SELECT | INSERT | UPDATE | DELETE |
|--------|--------|--------|--------|--------|
| profiles | 모든 사용자 | 본인만 | 본인만 | - |
| ledgers | 멤버만 | owner_id=본인 | 소유자만 | 소유자만 |
| ledger_members | 같은 가계부 멤버 | 소유자/관리자/초대받은자 | 소유자만 | 소유자 or 본인 |
| categories | 멤버만 | 소유자/관리자 | 소유자/관리자 | 소유자/관리자 |
| transactions | 멤버만 | 멤버 | 멤버 | 멤버 |
| budgets | 멤버만 | 소유자/관리자 | 소유자/관리자 | 소유자/관리자 |
| fcm_tokens | 본인만 | 본인만 | 본인만 | 본인만 |
| notification_settings | 본인만 | 본인만 | 본인만 | - |

---

## 6. FCM 토큰 관리

### 토큰 수명주기

| 시점 | 동작 |
|------|------|
| 로그인 | `FirebaseMessagingService.initialize()` - 토큰 등록 |
| 토큰 갱신 | `onTokenRefresh` 스트림 구독 - 자동 업데이트 |
| 로그아웃 | `FirebaseMessagingService.deleteToken()` - 토큰 삭제 |
| 알림 발송 실패 | Edge Function에서 UNREGISTERED 토큰 자동 삭제 |

### 중복 방지

- **앱 레벨**: `FcmTokenRepository.saveFcmToken()` - DELETE 후 UPSERT
- **DB 레벨**: `cleanup_duplicate_fcm_tokens` 트리거 - 다른 사용자의 동일 토큰 삭제

---

## 7. 기본 카테고리

가계부 생성 시 자동으로 생성되는 기본 카테고리:

**지출**: 식비, 교통, 쇼핑, 생활, 통신, 의료, 문화, 교육, 기타 지출

**수입**: 급여, 부업, 용돈, 이자, 기타 수입

**자산**: 정기예금, 적금, 주식, 펀드, 부동산, 암호화폐, 기타 자산

---

## 8. 마이그레이션

### 실행 방법

```bash
# MCP 도구 사용 (Claude Code)
mcp_supabase_apply_migration(name="026_description", query="SQL 쿼리")

# 검증
mcp_supabase_list_tables(schemas=["house"])
```

### 파일 위치

`supabase/migrations/` 디렉토리에 순차 번호로 생성 (예: 026_description.sql)

---

## 9. 문제 해결

### Edge Function 401 에러

- **원인**: `verify_jwt: true` 설정
- **해결**: Edge Function 재배포 시 `verify_jwt: false` 설정

### Edge Function 404 에러

- **원인**: Edge Function 미배포
- **해결**: Supabase MCP로 Edge Function 배포

### FCM 알림 미발송

1. `FIREBASE_SERVICE_ACCOUNT` Secret 설정 확인
2. FCM 토큰 존재 여부 확인 (`fcm_tokens` 테이블)
3. 알림 설정 확인 (`notification_settings` 테이블)
4. Edge Function 로그 확인 (Dashboard > Edge Functions > Logs)

### Firebase Cloud Messaging API 활성화

Google Cloud Console에서 API 활성화 필요:
1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 프로젝트 선택
3. APIs & Services > Library
4. "Firebase Cloud Messaging API" 검색
5. Enable 클릭
