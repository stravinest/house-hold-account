---
description: 코드 리뷰 후 커밋 - 품질 체크 후 안전하게 커밋
---

# Commit with Review

코드를 자동 리뷰한 후 안전하게 커밋합니다.

## 실행 순서

1. 변경 사항 확인
2. 코드 리뷰 실행
3. 린트 및 타입 체크
4. 커밋 메시지 작성
5. 커밋 실행

## 명령어

### 1. 변경 사항 확인

```bash
git status
git diff
```

### 2. 코드 리뷰

다음 중 하나 선택:

**옵션 A: senior-code-reviewer 에이전트 사용**
```
Task tool로 senior-code-reviewer 에이전트 실행
```

**옵션 B: 수동 린트 체크**
```bash
flutter analyze
dart format --set-exit-if-changed .
```

### 3. 커밋

```bash
# 변경된 파일 스테이징
git add <파일들>

# 커밋 (HEREDOC 사용)
git commit -m "$(cat <<'EOF'
<커밋 제목>

<커밋 본문>

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

## 커밋 메시지 가이드

### 제목 형식
```
<타입>: <간단한 설명> (50자 이내)
```

타입:
- `feat`: 새 기능
- `fix`: 버그 수정
- `refactor`: 리팩토링
- `style`: 코드 포맷팅
- `test`: 테스트 추가/수정
- `docs`: 문서 수정
- `chore`: 기타 (의존성 업데이트 등)

### 본문 형식
```
- 변경 사항 1
- 변경 사항 2
- 변경 사항 3

🤖 Generated with Claude Code
```

## 예시

```bash
git commit -m "$(cat <<'EOF'
feat: SMS 자동수집 중복 감지 기능 추가

- DuplicateCheckService 구현
- 24시간 이내 동일 금액/상호 거래 감지
- pending_transactions 테이블에 is_duplicate 컬럼 추가
- UI에 중복 경고 배지 표시

🤖 Generated with Claude Code

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

## 주의사항

- 민감한 정보(.env, 키 등)는 절대 커밋하지 않음
- 린트 에러가 있으면 커밋 전에 수정
- 커밋 메시지는 명확하고 구체적으로
