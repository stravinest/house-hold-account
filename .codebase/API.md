# API 엔드포인트

## 기본 정보

- **Base URL**: `/api`
- **인증**: Bearer Token (JWT)
- **Content-Type**: `application/json`

## 엔드포인트 목록

### 인증 (Auth)

| 메서드 | 경로 | 설명 | 인증 |
|--------|------|------|------|
| POST | `/auth/login` | 로그인 | X |
| POST | `/auth/register` | 회원가입 | X |
| POST | `/auth/refresh` | 토큰 갱신 | O |
| POST | `/auth/logout` | 로그아웃 | O |
| POST | `/auth/socket-token` | 소켓 토큰 발급 | O |

### 케이스 (Case)

| 메서드 | 경로 | 설명 | 인증 |
|--------|------|------|------|
| GET | `/case/list` | 케이스 목록 | O |
| GET | `/case/:caseId` | 케이스 상세 | O |
| POST | `/case` | 케이스 생성 | O |
| PUT | `/case/:caseId/links` | 링크 관리 | O |
| PUT | `/case/:caseId/permission` | 권한 관리 | O |

### 파일 (File)

| 메서드 | 경로 | 설명 | 인증 |
|--------|------|------|------|
| POST | `/file/upload` | 파일 업로드 (TUS) | O |
| POST | `/file/groups/:groupId/analyze` | 분석 요청 | O |
| GET | `/file/groups/:groupId/analyze/:analysisId` | 분석 결과 조회 | O |
| GET | `/file/groups/:groupId/analyze/:analysisId/logs` | 분석 로그 조회 | O |
| GET | `/file/groups/:groupId/detail` | FileGroup 상세 조회 | O |
| DELETE | `/file/cleanup` | PENDING 상태 정리 | O (Admin) |

## 공통 응답 형식

### 성공 응답
```json
{
  "success": true,
  "data": { ... },
  "message": "성공 메시지"
}
```

### 에러 응답
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "에러 메시지"
  }
}
```

## 에러 코드

| 코드 | HTTP 상태 | 설명 |
|------|----------|------|
| `UNAUTHORIZED` | 401 | 인증 필요 |
| `FORBIDDEN` | 403 | 권한 없음 |
| `NOT_FOUND` | 404 | 리소스 없음 |
| `VALIDATION_ERROR` | 400 | 유효성 검사 실패 |
| `INTERNAL_ERROR` | 500 | 서버 내부 오류 |

## 라우트 파일 위치

- 메인 라우터: `src/app.ts`
- 인증 라우트: `src/router/auth/index.ts`
- 케이스 라우트: `src/router/case/index.ts`
- 파일 라우트: `src/router/file/index.ts`
