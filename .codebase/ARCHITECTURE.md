# 아키텍처 개요

## 기술 스택

| 구분 | 기술 |
|------|------|
| Framework | Fastify 5.x |
| Database | MongoDB 7.x |
| Language | TypeScript 5.x (ESM) |
| Test | Jest 30.x |
| Runtime | Node.js |

## 레이어 구조

```
┌─────────────────────────────────────┐
│           Router Layer              │
│      (router/*/index.ts)            │
│   - 라우트 정의 및 스키마 검증      │
├─────────────────────────────────────┤
│         Handler Layer               │
│       (router/*/*.ts)               │
│   - HTTP 요청/응답 처리             │
│   - 쿠키 관리, 토큰 발급            │
├─────────────────────────────────────┤
│          Service Layer              │
│  (services/, router/*/service/)     │
│   - 비즈니스 로직                   │
│   - 도메인 규칙 적용                │
├─────────────────────────────────────┤
│        Repository Layer             │
│     (router/*/repository/)          │
│   - 데이터 접근 로직                │
│   - CRUD 연산                       │
├─────────────────────────────────────┤
│         Database Layer              │
│         (db/mongodb.ts)             │
│   - MongoDB 연결 관리               │
└─────────────────────────────────────┘
```

## 디렉토리 구조

```
src/
├── services/                  # 프로젝트 전체 공통 서비스
│   └── token.service.ts       # JWT 토큰 페이로드 (전역)
│
├── worker/                    # BullMQ 워커 시스템
│   ├── index.ts               # 워커 시작점
│   ├── redisConnection.ts     # Redis 연결
│   ├── analysisQueue.ts       # 분석 큐 정의
│   ├── processAnalysis.ts     # 분석 작업 처리
│   └── processFileItem.ts     # 개별 파일 처리
│
└── router/                    # 도메인별 라우터
    ├── auth/                  # auth 도메인
    │   ├── index.ts           # 라우터 등록
    │   ├── login.ts           # 로그인 핸들러
    │   ├── logout.ts          # 로그아웃 핸들러
    │   ├── refresh.ts         # 토큰 갱신 핸들러
    │   ├── register.ts        # 회원가입 핸들러
    │   ├── socket.ts          # 소켓 토큰 핸들러
    │   ├── repository/        # DB 접근 레이어
    │   ├── schema/            # 요청/응답 스키마
    │   └── service/           # 비즈니스 로직
    │
    ├── case/                  # case 도메인
    │   ├── index.ts
    │   ├── repository/
    │   ├── schema/
    │   └── service/
    │
    └── file/                  # file 도메인
        ├── index.ts           # 라우터 등록
        ├── upload.ts          # 파일 업로드 (TUS)
        ├── analyze.ts         # 분석 요청
        ├── getAnalysis.ts     # 분석 결과 조회
        ├── getAnalysisLogs.ts # 분석 로그 조회
        ├── detailGroup.ts     # FileGroup 상세
        ├── cleanup.ts         # PENDING 정리
        ├── repository/        # DB 접근 레이어
        ├── schema/            # 요청/응답 스키마
        └── service/           # 비즈니스 로직
```

## 의존성 흐름

```
router/{domain}/*.ts (핸들러)
       ↓
router/{domain}/service/*.ts (도메인 서비스)
       ↓
router/{domain}/repository/*.ts (저장소)
       ↓
services/*.ts (프로젝트 공통 서비스)
       ↓
db/, errors/, plugins/, utils/ (인프라)
```

**규칙**:
- 상위 레이어는 하위 레이어만 의존
- 같은 레벨 레이어 간 직접 의존 금지
- 순환 의존성 금지
- 핸들러는 도메인 서비스를 사용
- 도메인 서비스는 저장소와 프로젝트 공통 서비스를 사용

## 주요 컴포넌트

### 1. Fastify App

- **역할**: HTTP 서버 및 플러그인 관리
- **위치**: `src/app.ts`
- **주요 기능**:
  - 플러그인 등록 (JWT, Rate Limit)
  - 도메인 라우터 마운트
  - 에러 핸들러 설정

### 2. Router

- **역할**: 도메인별 API 엔드포인트 정의
- **위치**: `src/router/*/index.ts`
- **주요 기능**:
  - 라우트 경로 및 메서드 정의
  - 요청/응답 스키마 검증
  - Rate Limit 설정

### 3. Handler

- **역할**: HTTP 요청 처리 및 응답 구성
- **위치**: `src/router/*/*.ts` (예: `login.ts`, `register.ts`)
- **주요 기능**:
  - 요청 데이터 추출
  - 서비스 호출
  - 쿠키/토큰 관리
  - 응답 반환

### 4. Service

- **역할**: 비즈니스 로직 처리
- **위치**:
  - `src/services/*.ts` (프로젝트 공통)
  - `src/router/*/service/*.ts` (도메인 서비스)
- **주요 기능**:
  - 도메인 규칙 적용
  - 저장소 호출
  - 데이터 변환

### 5. Repository

- **역할**: 데이터 접근 추상화
- **위치**: `src/router/*/repository/*.ts`
- **주요 기능**:
  - CRUD 연산
  - 쿼리 구성
  - 에러 변환

### 6. Schema

- **역할**: 요청/응답 유효성 검증 스키마
- **위치**: `src/router/*/schema/*.ts`
- **주요 기능**:
  - 요청 바디 스키마 정의
  - 응답 스키마 정의
  - TypeBox 기반 타입 추론

## 인증/인가 흐름

### 로그인 흐름

```
1. POST /auth/login
2. Handler (login.ts): 요청 데이터 추출
3. Service (auth.service.ts): 사용자 인증 처리 (processLogin)
4. Repository (auth.repository.ts): DB에서 사용자 조회 및 비밀번호 검증
5. Handler: JWT 토큰 생성 및 쿠키 설정
6. Response: accessToken 반환
```

### 토큰 검증 흐름

```
1. Request: Cookie에서 토큰 추출
2. JWT Plugin: 토큰 검증
3. Handler: 사용자 정보 활용
```

### 토큰 갱신 흐름

```
1. POST /auth/refresh
2. Handler (refresh.ts): refreshToken 검증
3. Service (user.service.ts): 사용자 상태 확인 (validateUserForRefresh)
4. Handler: 새 accessToken 발급
```

## 에러 처리 전략

### AppError

모든 애플리케이션 에러는 `AppError`를 사용합니다.

```typescript
throw new AppError(ErrorCodeCollection.AUTH_USER_NOT_FOUND, {
  statusCode: 401,
  userId,
});
```

### 에러 코드 관리

```
src/errors/errorCodes/
├── common.ts    # 공통 에러
├── http.ts      # HTTP 관련 에러
└── auth.ts      # 인증 관련 에러
```

### 에러 응답 형식

```json
{
  "statusCode": 401,
  "code": "AUTH_001",
  "error": "Unauthorized",
  "message": "사용자를 찾을 수 없습니다."
}
```

## 보안

### 비밀번호 해싱

- **알고리즘**: Argon2id
- **위치**: `src/utils/hashPwd.ts`

### Rate Limiting

- **로그인**: 5회/분
- **토큰 갱신**: 10회/분
- **위치**: `src/plugins/rateLimit.ts`

### JWT 토큰

- **Access Token**: 짧은 만료 시간
- **Refresh Token**: 긴 만료 시간, HttpOnly 쿠키
- **위치**: `src/plugins/jwt.ts`

## 외부 연동

| 서비스 | 용도 | 연동 방식 |
|--------|------|----------|
| MongoDB | 데이터 저장 | Native Driver |
| Redis | 작업 큐 | BullMQ (ioredis) |
| Garage S3 | 파일 저장 | AWS SDK |
| Parser Server | 파일 분석 | HTTP API |
| Slack | 알림 전송 | Webhook |

## Worker 시스템 (BullMQ)

비동기 파일 분석 작업을 처리하는 워커 시스템입니다.

### 아키텍처

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   API Server    │────▶│   Redis Queue   │◀────│     Worker      │
│  (Fastify)      │     │   (BullMQ)      │     │  (processAnalysis)
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │                                               │
        ▼                                               ▼
┌─────────────────┐                           ┌─────────────────┐
│    MongoDB      │◀──────────────────────────│   Parser Server │
│  (분석 상태)    │                           │  (파일 분석)    │
└─────────────────┘                           └─────────────────┘
```

### 분석 작업 흐름

```
1. POST /file/groups/:groupId/analyze
2. Service: 분석 작업 생성 (PENDING)
3. Service: enqueueAnalysis() 호출
4. Redis Queue: 작업 대기
5. Worker: 작업 수신 → 상태 IN_PROGRESS
6. Worker: Promise.allSettled로 파일 병렬 처리
7. Worker: 각 파일 → S3 다운로드 → Parser 서버 전송
8. Worker: 결과 집계 → 상태 COMPLETED/PARTIAL_SUCCESS/FAILED
```

### 에러 처리

- **재시도**: 3회, 지수 백오프 (2초, 4초, 8초)
- **Graceful Shutdown**: SIGTERM/SIGINT 처리
- **로그 실패 격리**: 로그 생성 실패해도 분석 작업 계속

### 워커 실행

```bash
# 별도 프로세스로 실행
npx ts-node --esm src/worker/index.ts
```
