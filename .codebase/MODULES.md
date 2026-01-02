# 주요 모듈

## 모듈 개요

프로젝트는 라우터 기반으로 구성되어 있으며, 도메인별로 명확하게 분리된 구조를 사용합니다.

```
src/
├── services/              # 프로젝트 전체 공통 서비스
├── worker/                # BullMQ 워커 시스템
└── router/                # 도메인별 라우터
    ├── auth/              # 인증 도메인
    │   ├── repository/    # DB 접근
    │   ├── schema/        # 스키마 정의
    │   └── service/       # 비즈니스 로직
    ├── case/              # 케이스 도메인
    │   ├── repository/
    │   ├── schema/
    │   └── service/
    └── file/              # 파일 도메인
        ├── repository/
        ├── schema/
        └── service/
```

## 프로젝트 공통 서비스 (services/)

모든 도메인에서 사용하는 공통 서비스입니다.

- **위치**: `src/services/`
- **주요 파일**:

  | 파일 | 설명 |
  |------|------|
  | `token.service.ts` | JWT 토큰 페이로드 생성 |

- **주요 함수**:
  - `createTokenPayload(user)`: DBUser에서 TokenPayload 생성
  - `TokenPayload` 타입 정의

## 도메인 라우터

### Auth 도메인 (인증)

- **역할**: 사용자 인증 및 토큰 관리
- **위치**: `src/router/auth/`

#### 구조

```
router/auth/
├── index.ts               # 라우터 등록
├── login.ts               # 로그인 핸들러
├── logout.ts              # 로그아웃 핸들러
├── refresh.ts             # 토큰 갱신 핸들러
├── register.ts            # 회원가입 핸들러
├── socket.ts              # 소켓 토큰 핸들러
├── repository/            # DB 접근 계층
│   └── auth.repository.ts
├── schema/                # 요청/응답 스키마
│   └── *.schema.ts
└── service/               # 비즈니스 로직
    ├── auth.service.ts
    ├── register.service.ts
    └── user.service.ts
```

#### 서비스 상세

| 파일 | 함수 | 설명 |
|------|------|------|
| `auth.service.ts` | `validateUserState()`, `processLogin()` | 사용자 상태 검증, 로그인 처리 |
| `user.service.ts` | `getUserById()`, `validateUserForRefresh()` | 사용자 조회, 갱신 검증 |
| `register.service.ts` | `registerUser()` | 회원가입 처리 |

#### 리포지토리 상세

| 파일 | 함수 | 설명 |
|------|------|------|
| `auth.repository.ts` | `login()`, `findByLoginId()`, `createUser()` | DB 접근 |

- **의존성**:
  - `@/services/` - 프로젝트 공통 서비스
  - `@/plugins/jwt` - JWT 플러그인
  - `@/errors/` - 에러 처리

### Case 도메인 (케이스 관리)

- **역할**: 케이스(사건) 생성 및 관리
- **위치**: `src/router/case/`

#### 구조

```
router/case/
├── index.ts               # 라우터 등록
├── create.ts              # 케이스 생성 핸들러
├── detail.ts              # 케이스 상세 핸들러
├── list.ts                # 케이스 목록 핸들러
├── links.ts               # 케이스 링크 핸들러
├── permission.ts          # 케이스 권한 핸들러
├── repository/            # DB 접근 계층
│   └── case.repository.ts
├── schema/                # 요청/응답 스키마
│   └── *.schema.ts
└── service/               # 비즈니스 로직
    ├── case.service.ts
    └── case-permission.service.ts
```

#### 서비스 상세

| 파일 | 함수 | 설명 |
|------|------|------|
| `case.service.ts` | 케이스 CRUD 로직 | 케이스 생성, 조회, 수정, 삭제 |
| `case-permission.service.ts` | 권한 관리 로직 | 케이스 접근 권한 관리 |

#### 리포지토리 상세

| 파일 | 함수 | 설명 |
|------|------|------|
| `case.repository.ts` | DB 접근 함수들 | 케이스 데이터 접근 |

- **의존성**:
  - `@/services/` - 프로젝트 공통 서비스
  - `@/plugins/jwt` - JWT 플러그인
  - `@/errors/` - 에러 처리

### File 도메인 (파일 관리)

- **역할**: 파일 업로드, 분석, FileGroup 관리
- **위치**: `src/router/file/`

#### 구조

```
router/file/
├── index.ts               # 라우터 등록
├── upload.ts              # 파일 업로드 핸들러 (TUS)
├── analyze.ts             # 분석 요청 핸들러
├── getAnalysis.ts         # 분석 결과 조회 핸들러
├── getAnalysisLogs.ts     # 분석 로그 조회 핸들러
├── detailGroup.ts         # FileGroup 상세 핸들러
├── cleanup.ts             # PENDING 정리 핸들러
├── repository/            # DB 접근 계층
│   ├── index.ts
│   ├── fileGroup.repository.ts
│   ├── fileItem.repository.ts
│   ├── analysis.repository.ts
│   ├── analysisLog.repository.ts
│   └── user.repository.ts
├── schema/                # 요청/응답 스키마
│   └── *.schema.ts
└── service/               # 비즈니스 로직
    ├── analysis.service.ts
    └── fileGroup.service.ts
```

#### 서비스 상세

| 파일 | 함수 | 설명 |
|------|------|------|
| `analysis.service.ts` | `processAnalyzeRequest()`, `getAnalysisResult()`, `getAnalysisLogs()` | 분석 요청/결과/로그 처리 |
| `fileGroup.service.ts` | `getFileGroupDetail()`, `processCleanup()` | FileGroup 조회, PENDING 정리 |

#### 리포지토리 상세

| 파일 | 함수 | 설명 |
|------|------|------|
| `fileGroup.repository.ts` | `findFileGroupById()`, `cleanupPendingFileGroups()` 등 | FileGroup DB 접근 |
| `fileItem.repository.ts` | `findFileItemsByGroupId()`, `findFileItemsByIds()` 등 | FileItem DB 접근 |
| `analysis.repository.ts` | `createAnalysis()`, `findAnalysisWithItems()` 등 | 분석 작업 DB 접근 |
| `analysisLog.repository.ts` | `createAnalysisLog()`, `findLogsByAnalysisId()` | 분석 로그 DB 접근 |

- **의존성**:
  - `@/utils/filePermission` - 권한 검증
  - `@/utils/garageS3Client` - S3 파일 접근
  - `@/worker/analysisQueue` - BullMQ 작업 큐
  - `@/errors/` - 에러 처리

## Worker 시스템 (BullMQ)

- **역할**: 비동기 파일 분석 작업 처리
- **위치**: `src/worker/`

### 구조

```
worker/
├── index.ts               # 워커 시작점 (Worker 인스턴스)
├── redisConnection.ts     # Redis 연결 설정
├── analysisQueue.ts       # 분석 작업 큐 정의
├── processAnalysis.ts     # 분석 작업 처리 (메인)
├── processFileItem.ts     # 개별 파일 처리
└── utils/
    └── analysisLogger.ts  # 분석 로그 유틸리티
```

### 주요 파일 설명

| 파일 | 역할 |
|------|------|
| `redisConnection.ts` | Redis 연결 관리 (ioredis) |
| `analysisQueue.ts` | 큐 정의, `enqueueAnalysis()` 함수 제공 |
| `processAnalysis.ts` | 분석 작업 조회, 병렬 파일 처리, 결과 집계 |
| `processFileItem.ts` | S3에서 파일 다운로드 → 파서 서버 전송 → 결과 처리 |
| `analysisLogger.ts` | 안전한 분석 로그 생성 (실패해도 작업 계속) |

### BullMQ 설정

```typescript
// 큐 옵션
{
  attempts: 3,                    // 재시도 3회
  backoff: { type: 'exponential', delay: 2000 },
  removeOnComplete: { count: 100, age: 86400 },
  removeOnFail: { count: 500 }
}
```

### 워커 실행

```bash
# 워커 별도 실행
npx ts-node --esm src/worker/index.ts
```

## 인프라 모듈

### Database (`src/db/`)

- **역할**: MongoDB 연결 및 타입 정의
- **주요 파일**:
  - `mongodb.ts` - 연결 관리
  - `collections.ts` - 컬렉션 상수
  - `types/` - DB 타입 정의

### Errors (`src/errors/`)

- **역할**: 에러 정의 및 처리
- **주요 파일**:
  - `AppError.ts` - 커스텀 에러 클래스
  - `errorHandlers.ts` - Fastify 에러 핸들러
  - `errorCodes/` - 에러 코드 정의

### Plugins (`src/plugins/`)

- **역할**: Fastify 플러그인 확장
- **주요 파일**:
  - `jwt.ts` - JWT 인증 (accessToken, refreshToken)
  - `rateLimit.ts` - 요청 제한

### Utils (`src/utils/`)

- **역할**: 공통 유틸리티
- **주요 파일**:
  - `hashPwd.ts` - Argon2 비밀번호 해싱
  - `slackBot.ts` - Slack 알림

## 모듈 의존성 다이어그램

```
┌──────────────────────────────────────────────┐
│                   Router                      │
│             (router/*/index.ts)               │
└─────────────────────┬────────────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────┐
│                  Handlers                     │
│         (router/*/*.ts - 핸들러 파일)          │
└─────────────────────┬────────────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────┐
│                  Services                     │
│          (router/*/service/*.ts)              │
└─────────────────────┬────────────────────────┘
                      │
          ┌───────────┴───────────┐
          ▼                       ▼
┌──────────────────────┐ ┌──────────────────────┐
│    프로젝트 공통      │ │     Repository       │
│  (services/*.ts)     │ │ (router/*/repository/│
│                      │ │  *.repository.ts)    │
└──────────────────────┘ └──────────┬───────────┘
                                    │
                                    ▼
                    ┌──────────────────────────────────────────────┐
                    │                  MongoDB                      │
                    │              (db/mongodb.ts)                  │
                    └──────────────────────────────────────────────┘
```

## 공통 모듈 사용

### 프로젝트 공통 서비스

```typescript
import { createTokenPayload, type TokenPayload } from '@/services/token.service.js';

const payload = createTokenPayload(user);
```

### 도메인 서비스

```typescript
import { processLogin, validateUserForRefresh } from './service/auth.service.js';

const { user, payload } = await processLogin(id, pwd);
```

### 리포지토리 사용

```typescript
import { login, findByLoginId } from './repository/auth.repository.js';

const user = await login(loginId, password);
```

### 에러 처리

```typescript
import { AppError, ErrorCodeCollection } from '@/errors/index.js';

throw new AppError(ErrorCodeCollection.AUTH_USER_NOT_FOUND, {
  statusCode: 401,
  userId,
});
```

### 비밀번호 해싱

```typescript
import { hashPassword, verifyPassword } from '@/utils/hashPwd.js';

const hashedPwd = await hashPassword(password);
const isValid = await verifyPassword(password, hashedPwd);
```

### DB 접근

```typescript
import { getDB } from '@/db/mongodb.js';
import { Collections } from '@/db/collections.js';

const db = await getDB();
const users = db.collection(Collections.USERS);
```
