# 디렉토리 구조

## 프로젝트 루트

```
back_end_final/
├── src/                    # 소스 코드
│   ├── app.ts              # Fastify 앱 설정
│   ├── services/           # 공통 서비스
│   ├── router/             # 라우터 (도메인별)
│   ├── worker/             # BullMQ 워커 시스템
│   ├── db/                 # 데이터베이스 레이어
│   ├── errors/             # 커스텀 에러 정의
│   ├── plugins/            # Fastify 플러그인
│   ├── types/              # 전역 타입 정의
│   └── utils/              # 유틸리티 함수
├── test/                   # 테스트 코드
├── .codebase/              # 코드베이스 문서
└── .claude/                # Claude Code 설정
```

## 주요 디렉토리 설명

### `src/services/`

프로젝트 전체에서 사용하는 공통 서비스입니다.

```
src/services/
├── index.ts                # barrel export
└── token.service.ts        # JWT 토큰 페이로드 (전역)
```

### `src/router/`

도메인별 라우터와 관련 코드를 관리합니다.

```
src/router/
├── auth/                        # auth 도메인
│   ├── index.ts                 # 라우터 등록
│   ├── login.ts                 # 로그인 핸들러
│   ├── logout.ts                # 로그아웃 핸들러
│   ├── refresh.ts               # 토큰 갱신 핸들러
│   ├── register.ts              # 회원가입 핸들러
│   ├── socket.ts                # 소켓 토큰 핸들러
│   │
│   ├── repository/              # DB 접근
│   │   └── auth.repository.ts   # (login, findByLoginId, createUser)
│   │
│   ├── schema/                  # 스키마 모음
│   │   ├── index.ts             # barrel export
│   │   ├── login.schema.ts      # 로그인 스키마
│   │   ├── logout.schema.ts     # 로그아웃 스키마
│   │   ├── refresh.schema.ts    # 토큰 갱신 스키마
│   │   ├── register.schema.ts   # 회원가입 스키마
│   │   └── socket.schema.ts     # 소켓 토큰 스키마
│   │
│   └── service/                 # 서비스
│       ├── auth.service.ts      # 인증 공통 로직
│       ├── register.service.ts  # 회원가입 로직
│       └── user.service.ts      # 사용자 조회
│
├── case/                        # case 도메인
│   ├── index.ts                 # 라우터 등록
│   ├── create.ts                # 케이스 생성 핸들러
│   ├── detail.ts                # 케이스 상세 핸들러
│   ├── list.ts                  # 케이스 목록 핸들러
│   ├── links.ts                 # 링크 관리 핸들러
│   ├── permission.ts            # 권한 관리 핸들러
│   │
│   ├── repository/              # DB 접근
│   │   └── case.repository.ts
│   │
│   ├── schema/                  # 스키마 모음
│   │   └── *.schema.ts
│   │
│   └── service/                 # 서비스
│       └── case.service.ts
│
└── file/                        # file 도메인
    ├── index.ts                 # 라우터 등록
    ├── upload.ts                # 파일 업로드 핸들러 (TUS)
    ├── analyze.ts               # 분석 요청 핸들러
    ├── getAnalysis.ts           # 분석 결과 조회 핸들러
    ├── getAnalysisLogs.ts       # 분석 로그 조회 핸들러
    ├── detailGroup.ts           # FileGroup 상세 핸들러
    ├── cleanup.ts               # PENDING 정리 핸들러
    │
    ├── repository/              # DB 접근
    │   ├── index.ts             # barrel export
    │   ├── fileGroup.repository.ts
    │   ├── fileItem.repository.ts
    │   ├── analysis.repository.ts
    │   ├── analysisLog.repository.ts
    │   └── user.repository.ts
    │
    ├── schema/                  # 스키마 모음
    │   ├── index.ts
    │   ├── analyze.schema.ts
    │   ├── getAnalysis.schema.ts
    │   ├── getAnalysisLogs.schema.ts
    │   ├── detailGroup.schema.ts
    │   └── cleanup.schema.ts
    │
    └── service/                 # 서비스
        ├── index.ts
        ├── analysis.service.ts
        └── fileGroup.service.ts
```

### `src/db/`

데이터베이스 연결 및 타입 정의입니다.

```
src/db/
├── mongodb.ts              # MongoDB 연결 관리
├── collections.ts          # 컬렉션 이름 상수
└── types/                  # DB 타입 정의
    ├── index.ts
    ├── enums.ts            # Enum 타입
    ├── common.ts           # 공통 타입
    └── core/               # 핵심 엔티티 타입
        ├── user.ts
        └── permission.ts
```

### `src/errors/`

커스텀 에러 정의 및 처리입니다.

```
src/errors/
├── index.ts                # barrel export
├── AppError.ts             # 커스텀 에러 클래스
├── errorHandlers.ts        # Fastify 에러 핸들러
├── findCodeToError.ts      # 에러 코드 조회
└── errorCodes/             # 에러 코드 정의
    ├── index.ts
    ├── common.ts
    ├── http.ts
    └── auth.ts
```

### `src/plugins/`

Fastify 플러그인입니다.

```
src/plugins/
├── jwt.ts                  # JWT 인증 플러그인
└── rateLimit.ts            # Rate Limiting 플러그인
```

### `src/utils/`

공통 유틸리티 함수입니다.

```
src/utils/
├── hashPwd.ts              # Argon2 비밀번호 해싱
├── slackBot.ts             # Slack 알림
├── filePermission.ts       # 파일 권한 검증
└── garageS3Client.ts       # S3 클라이언트 (Garage)
```

### `src/worker/`

BullMQ 기반 비동기 작업 처리 시스템입니다.

```
src/worker/
├── index.ts                # 워커 시작점
├── redisConnection.ts      # Redis 연결 설정
├── analysisQueue.ts        # 분석 작업 큐 정의
├── processAnalysis.ts      # 분석 작업 처리 (메인)
├── processFileItem.ts      # 개별 파일 처리
└── utils/
    └── analysisLogger.ts   # 분석 로그 유틸리티
```

### `src/types/`

전역 TypeScript 타입 정의입니다.

```
src/types/
└── fastify-jwt.d.ts        # Fastify JWT 타입 확장
```

## 파일 네이밍 규칙

| 유형 | 패턴 | 예시 |
|------|------|------|
| 라우터 | `index.ts` | `router/auth/index.ts` |
| 핸들러 | `{action}.ts` | `login.ts`, `create.ts` |
| 스키마 | `schema/{action}.schema.ts` | `schema/login.schema.ts` |
| 공통 서비스 | `service/{domain}.service.ts` | `service/auth.service.ts` |
| 개별 서비스 | `service/{action}.service.ts` | `service/register.service.ts` |
| 저장소 | `repository/{domain}.repository.ts` | `repository/auth.repository.ts` |
| 테스트 | `{target}.test.ts` | `auth.repository.login.test.ts` |
| barrel | `index.ts` | 각 폴더별 export |

## 테스트 구조

테스트는 `src/router` 구조를 미러링합니다.

```
test/
├── router/
│   ├── auth/
│   │   ├── handler/             # 핸들러 테스트
│   │   │   └── login.test.ts
│   │   ├── repository/          # 리포지토리 테스트
│   │   │   ├── auth.repository.login.test.ts
│   │   │   └── auth.repository.register.test.ts
│   │   └── service/             # 서비스 테스트
│   │       └── register.service.test.ts
│   ├── case/
│   │   └── service/
│   │       └── case.service.test.ts
│   └── file/
│       ├── repository/          # 리포지토리 테스트
│       │   ├── fileGroup.repository.test.ts
│       │   ├── fileItem.repository.test.ts
│       │   ├── analysis.repository.test.ts
│       │   └── analysisLog.repository.test.ts
│       └── service/             # 서비스 테스트
│           ├── analysis.service.test.ts
│           └── fileGroup.service.test.ts
└── utils/
    └── filePermission.test.ts   # 권한 유틸리티 테스트
```
