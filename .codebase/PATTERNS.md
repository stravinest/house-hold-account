# 코드 패턴 및 컨벤션

## 네이밍 규칙

### 파일명

| 유형 | 패턴 | 예시 |
|------|------|------|
| 라우터 | `index.ts` | `router/auth/index.ts` |
| 핸들러 | `{action}.ts` | `login.ts` |
| 스키마 | `schema/{action}.schema.ts` | `schema/login.schema.ts` |
| 공통 서비스 | `service/{domain}.service.ts` | `service/auth.service.ts` |
| 개별 서비스 | `service/{action}.service.ts` | `service/register.service.ts` |
| 저장소 | `repository/{domain}.repository.ts` | `repository/auth.repository.ts` |
| 테스트 | `{target}.test.ts` | `register.service.test.ts` |

### 변수/함수명

| 유형 | 패턴 | 예시 |
|------|------|------|
| 변수 | camelCase | `userId`, `isActive` |
| 핸들러 함수 | `{action}Handler` | `loginHandler` |
| 서비스 함수 | `{verb}{Entity}` | `processLogin`, `registerUser` |
| Repository 함수 | `{verb}` / `{verb}By{Field}` | `login`, `findByLoginId` |
| 인터페이스 | PascalCase | `TokenPayload`, `LoginRequest` |
| 상수 | UPPER_SNAKE_CASE | `Collections.USERS` |
| Enum | PascalCase | `DBEnumUserState` |

## 핸들러 패턴

Fastify Request/Reply를 사용하는 함수형 핸들러입니다.

```typescript
// src/router/auth/login.ts
import { FastifyReply, FastifyRequest } from 'fastify';
import { processLogin } from './service/index.js';
import { createTokenPayload } from '@/services/index.js';
import type { LoginRequest } from './schema/login.schema.js';

/**
 * 로그인 핸들러
 */
export async function loginHandler(
  request: FastifyRequest<{ Body: LoginRequest }>,
  reply: FastifyReply
) {
  const { id, pwd } = request.body;
  const { user, payload } = await processLogin(id, pwd);

  const accessToken = await reply.accessTokenSign(payload);
  reply.setCookie('accessToken', accessToken, request.server.cookieOptions);

  return { accessToken };
}
```

## 서비스 패턴

### 도메인 공통 서비스

여러 엔드포인트에서 재사용하는 로직입니다.

```typescript
// src/router/auth/service/auth.service.ts
import { login as loginRepo } from '../repository/auth.repository.js';
import { createTokenPayload, TokenPayload } from '@/services/index.js';
import type { DBUser } from '@/db/types/core/user.js';

/**
 * 로그인 처리 (인증 + payload 생성)
 */
export async function processLogin(
  id: string,
  pwd: string
): Promise<{ user: DBUser; payload: TokenPayload }> {
  const user = await loginRepo(id, pwd);
  const payload = createTokenPayload(user);
  return { user, payload };
}
```

### 개별 서비스

특정 엔드포인트에서만 사용하는 로직입니다.

```typescript
// src/router/auth/service/register.service.ts
import { findByLoginId, createUser } from '../repository/index.js';
import type { DBCreateUserInput } from '@/db/types/core/user.js';
import { AppError, ErrorCodeCollection } from '@/errors/index.js';

/**
 * 회원가입 처리
 */
export async function registerUser(input: DBCreateUserInput): Promise<{ userId: string }> {
  // 1. 중복 ID 체크
  const existingUser = await findByLoginId(input.loginId);
  if (existingUser) {
    throw new AppError(ErrorCodeCollection.AUTH_DUPLICATE_ID, {
      statusCode: 409,
      loginId: input.loginId,
    });
  }

  // 2. 사용자 생성
  const user = await createUser(input);
  return { userId: user.id };
}
```

## 스키마 패턴 (TypeBox)

런타임 검증과 TypeScript 타입을 동시에 제공합니다.

```typescript
// src/router/auth/schema/login.schema.ts
import { Type } from '@sinclair/typebox';

export const LoginRequestSchema = Type.Object({
  id: Type.String({ minLength: 1 }),
  pwd: Type.String({ minLength: 1 }),
});

export const LoginResponseSchema = Type.Object({
  accessToken: Type.String(),
});

// 타입 추론
export type LoginRequest = typeof LoginRequestSchema.static;
export type LoginResponse = typeof LoginResponseSchema.static;
```

## Repository 패턴

데이터베이스 접근을 담당합니다.

```typescript
// src/router/auth/repository/auth.repository.ts
import { getDB } from '@/db/mongodb.js';
import type { DBUser } from '@/db/types/core/user.js';
import { Collections } from '@/db/collections.js';
import { verifyPassword } from '@/utils/hashPwd.js';
import { AppError, ErrorCodeCollection } from '@/errors/index.js';

export async function login(loginId: string, pwd: string): Promise<DBUser> {
  const db = await getDB();
  const users = db.collection<DBUser>(Collections.USERS);

  const user = await users.findOne({ id: loginId });
  if (!user) {
    throw new AppError(ErrorCodeCollection.AUTH_INVALID_CREDENTIALS, {
      statusCode: 401,
      loginId
    });
  }

  const isValid = await verifyPassword(pwd, user.pwd);
  if (!isValid) {
    throw new AppError(ErrorCodeCollection.AUTH_INVALID_CREDENTIALS, {
      statusCode: 401,
      loginId
    });
  }

  return user;
}
```

## 에러 처리 패턴

AppError를 사용한 일관된 에러 처리입니다.

```typescript
// 에러 발생
throw new AppError(ErrorCodeCollection.AUTH_INVALID_CREDENTIALS, {
  statusCode: 401,
  loginId,
});

// 에러 전파 (서비스에서)
try {
  const result = await someOperation();
} catch (error) {
  if (error instanceof AppError) {
    throw error;  // 그대로 전파
  }
  throw new AppError(ErrorCodeCollection.INTERNAL_ERROR, error as Error, {
    statusCode: 500,
  });
}
```

## 라우터 패턴

Fastify 플러그인 형태의 라우터입니다.

```typescript
// src/router/auth/index.ts
import { FastifyInstance } from 'fastify';
import { loginHandler } from './login.js';
import { registerHandler } from './register.js';
import { LoginRequestSchema, LoginResponseSchema } from './schema/login.schema.js';
import { RegisterRequestSchema, RegisterResponseSchema } from './schema/register.schema.js';
import { authRateLimitConfig } from '@/plugins/rateLimit.js';

export async function authRouter(fastify: FastifyInstance) {
  fastify.post('/register', {
    schema: {
      body: RegisterRequestSchema,
      response: { 201: RegisterResponseSchema },
    },
  }, registerHandler);

  fastify.post('/login', {
    config: {
      rateLimit: authRateLimitConfig,
    },
    schema: {
      body: LoginRequestSchema,
      response: { 200: LoginResponseSchema },
    },
  }, loginHandler);
}
```

## Barrel Export 패턴

각 폴더의 `index.ts`에서 모듈을 re-export합니다.

```typescript
// src/router/auth/schema/index.ts
export { LoginRequestSchema, LoginResponseSchema, type LoginRequest } from './login.schema.js';
export { RegisterRequestSchema, RegisterResponseSchema, type RegisterRequest } from './register.schema.js';
```

```typescript
// src/router/auth/repository/index.ts
export { login, findByLoginId, createUser } from './auth.repository.js';
```

```typescript
// src/router/auth/service/index.ts
// Services
export { validateUserState, processLogin } from './auth.service.js';
export { getUserById, validateUserForRefresh } from './user.service.js';
```

## Import 순서

```typescript
// 1. Node.js 내장 모듈
import path from 'path';

// 2. 외부 패키지
import { FastifyInstance } from 'fastify';
import { Type } from '@sinclair/typebox';

// 3. 프로젝트 공통 모듈 (절대 경로)
import { createTokenPayload } from '@/services/index.js';
import { getDB } from '@/db/mongodb.js';
import { AppError } from '@/errors/index.js';

// 4. 도메인 내 모듈 (상대 경로)
import { processLogin } from './service/index.js';

// 5. 같은 레벨 모듈 (상대 경로)
import type { LoginRequest } from './schema/login.schema.js';
```

## 테스트 패턴

Jest + BDD 스타일 테스트입니다.

```typescript
describe('registerUser service', () => {
  describe('성공 케이스', () => {
    it('새로운 사용자를 생성하고 userId를 반환해야 함', async () => {
      // Arrange
      mockFindByLoginId.mockResolvedValue(null);
      mockCreateUser.mockResolvedValue(newUser);

      // Act
      const result = await registerUser(validInput);

      // Assert
      expect(result).toEqual({ userId: 'newuser' });
      expect(mockFindByLoginId).toHaveBeenCalledWith('newuser');
      expect(mockCreateUser).toHaveBeenCalledWith(validInput);
    });
  });
});
```
