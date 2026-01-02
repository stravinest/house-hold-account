# 데이터베이스 스키마

> 이 문서는 템플릿입니다. 프로젝트에 맞게 내용을 채워주세요.

## 개요

- **DBMS**: PostgreSQL / MySQL / MongoDB
- **ORM**: TypeORM / Prisma / Sequelize
- **연결 설정**: `src/config/database.ts`

## 엔티티 목록

### User (사용자)

| 컬럼 | 타입 | 설명 | 제약조건 |
|------|------|------|----------|
| id | UUID | 기본키 | PK |
| email | VARCHAR(255) | 이메일 | UNIQUE, NOT NULL |
| password | VARCHAR(255) | 비밀번호 (해시) | NOT NULL |
| name | VARCHAR(100) | 이름 | NOT NULL |
| created_at | TIMESTAMP | 생성일시 | DEFAULT NOW() |
| updated_at | TIMESTAMP | 수정일시 | DEFAULT NOW() |

### [엔티티명]

| 컬럼 | 타입 | 설명 | 제약조건 |
|------|------|------|----------|
| - | - | - | - |

## 엔티티 관계 (ERD)

```
┌─────────┐       ┌─────────┐
│  User   │ 1───N │  Post   │
└─────────┘       └─────────┘
     │
     │ 1
     │
     N
┌─────────┐
│ Comment │
└─────────┘
```

## 관계 설명

| 관계 | 설명 |
|------|------|
| User 1:N Post | 사용자는 여러 게시글을 작성할 수 있음 |
| User 1:N Comment | 사용자는 여러 댓글을 작성할 수 있음 |

## 인덱스

| 테이블 | 인덱스명 | 컬럼 | 용도 |
|--------|----------|------|------|
| User | idx_user_email | email | 이메일 조회 |
| Post | idx_post_user_id | user_id | 사용자별 게시글 조회 |

## 마이그레이션

마이그레이션 파일 위치: `src/migrations/`

```bash
# 마이그레이션 실행
npm run migration:run

# 마이그레이션 롤백
npm run migration:revert
```

## 모델 파일 위치

- User: `src/models/user.model.ts`
- Post: `src/models/post.model.ts`
