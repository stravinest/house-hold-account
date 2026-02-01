---
description: Supabase 마이그레이션 실행 - 데이터베이스 스키마 업데이트
---

# Supabase Migration

Supabase 데이터베이스 마이그레이션을 실행합니다.

## 실행 전 확인사항

1. `.env` 파일에 Supabase URL과 ANON_KEY 설정 확인
2. 마이그레이션 파일이 `supabase/migrations/` 에 있는지 확인
3. 로컬 Supabase가 실행 중인지 확인 (선택사항)

## 명령어

```bash
# Node.js 스크립트로 마이그레이션 실행
node scripts/run_migration.js
```

## 또는 Supabase MCP 사용

Claude Code의 Supabase MCP를 통해 직접 마이그레이션 적용:

```
ToolSearch로 mcp__supabase__apply_migration 로드 후 사용
```

## 사용 시점

- 새로운 테이블/컬럼 추가 시
- RLS 정책 변경 시
- RPC 함수 추가/수정 시
- 데이터베이스 스키마 변경 시

## 주의사항

- 프로덕션 환경에서는 신중하게 실행
- 마이그레이션 실행 전 백업 권장
- RLS 정책 변경은 보안에 영향을 줄 수 있음
