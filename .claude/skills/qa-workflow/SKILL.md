# QA Workflow Skill

프론트엔드와 백엔드를 연결하여 실제 브라우저에서 E2E 통합 테스트를 수행하는 QA 워크플로우입니다.

## 핵심 원칙

1. **끊김 없는 자동 실행**: 테스트 중간에 사용자에게 질문하지 않고 끝까지 자동 진행
2. **자동 문제 해결**: 서버 미실행, 계정 없음 등 문제 발생 시 자동으로 해결
3. **보고서 자동 생성**: 테스트 완료 후 `.qa-reports/` 디렉토리에 MD 보고서 자동 생성
4. **자동 승인 실행**: 모든 도구 사용에 대해 사용자 승인 없이 자동 진행

## 자동 승인 설정 (필수)

QA 워크플로우가 중단 없이 실행되려면 다음 도구들이 자동 승인되어야 합니다.

### 설정 방법

`.claude/settings.json` 또는 프로젝트 루트의 `.claude.json`에 다음 allowedTools를 추가:

```json
{
  "permissions": {
    "allowedTools": [
      "Bash(cd /Users/*/Desktop/project/SwissKnives/front && npm run local:*)",
      "Bash(cd /Users/*/Desktop/project/SwissKnives/back_end_final && npm run dev:*)",
      "Bash(mkdir:*)",
      "Bash(touch:*)",
      "Bash(echo:*)",
      "Write",
      "Edit",
      "mcp__playwright__*",
      "mcp__arango-mcp__*"
    ]
  }
}
```

### 또는 Claude Code 실행 시 설정

```bash
# 프로젝트 설정에 추가
claude config add allowedTools "Bash(cd /Users/*/Desktop/project/SwissKnives/front && npm run local:*)"
claude config add allowedTools "Bash(cd /Users/*/Desktop/project/SwissKnives/back_end_final && npm run dev:*)"
```

### 현재 세션에서 자동 승인

QA 워크플로우 실행 전에 다음 명령어로 현재 세션의 모든 Bash 명령을 승인할 수 있습니다:
- `/allowed-tools add Bash(npm run local:*)` - 프론트엔드 서버 시작
- `/allowed-tools add Bash(npm run dev:*)` - 백엔드 서버 시작

## 활성화 명령

다음 명령어로 이 스킬을 활성화합니다:
- `QA 워크플로우`
- `/qa-workflow`
- `QA 테스트`
- `E2E 테스트`

## 사용 예시

```
사용자: QA 워크플로우로 로그인 기능을 테스트해줘
사용자: /qa-workflow 케이스 생성 테스트
사용자: E2E 테스트로 태그 관리 기능 확인해줘
```

## 워크플로우 구성

### 사용 MCP 도구

| MCP | 용도 |
|-----|------|
| **playwright** | 브라우저 자동화 (페이지 이동, 클릭, 입력, 스냅샷) |
| **arango-mcp** | ArangoDB 데이터 검증 (AQL 쿼리) |

### 아키텍처

```
+----------------------------------------------------------+
|                   QA Workflow                            |
+----------------------------------------------------------+
|                                                          |
|  +-------------+    +---------------+    +------------+  |
|  | Playwright  |    | Chrome DevTools|   | ArangoDB   |  |
|  |    MCP      |    |     MCP        |   |    MCP     |  |
|  +------+------+    +-------+-------+    +-----+------+  |
|         |                   |                  |         |
|         v                   v                  v         |
|  +--------------------------------------------------+   |
|  |              테스트 시나리오 실행                   |   |
|  +--------------------------------------------------+   |
|                           |                              |
|         +-----------------+------------------+           |
|         v                                    v           |
|  +--------------+                    +--------------+    |
|  |  Frontend    | <---- API 호출 --> |   Backend    |    |
|  |  :5173       |                    |   :3000      |    |
|  +--------------+                    +--------------+    |
|                                             |            |
|                                      +--------------+    |
|                                      |  ArangoDB    |    |
|                                      |  :8541       |    |
|                                      +--------------+    |
+----------------------------------------------------------+
```

## 실행 단계 (자동 진행)

### Phase 1: 환경 확인 및 자동 설정

1. **서버 상태 확인** (자동)
   ```bash
   lsof -i :3000  # 백엔드 서버
   lsof -i :5173  # 프론트엔드 서버
   ```

2. **서버 미실행 시 자동 시작** (질문 없이 진행)
   - 백엔드: `npm run dev` (back_end_final/) - 백그라운드 실행
   - 프론트엔드: `npm run local` (front/) - 백그라운드 실행

### Phase 2: 테스트 데이터 준비 (자동)

1. **테스트 계정 확인/생성** (자동)
   - 계정: `admin_test` / `test1234`
   - ArangoDB에서 계정 존재 여부 확인
   - 없으면 `npx tsx scripts/createTestUser.ts` 자동 실행

2. **필요 데이터 준비** (자동)
   - 테스트 시나리오에 필요한 데이터 ArangoDB에 자동 삽입

### Phase 3: 브라우저 테스트 실행 (자동)

1. **Playwright로 브라우저 열기**
2. **로그인 수행**
3. **테스트 시나리오 실행**
4. **모든 단계 자동 진행** - 중간에 멈추지 않음

### Phase 4: 결과 검증 및 보고서 생성

1. **UI 검증** - 스냅샷 분석
2. **네트워크 검증** - API 호출, 에러 확인
3. **데이터 검증** - DB 상태 확인
4. **보고서 자동 생성** - `.qa-reports/qa-report-{timestamp}.md`

## 보고서 자동 생성

테스트 완료 후 `.qa-reports/` 디렉토리에 MD 보고서가 자동 생성됩니다.

### 보고서 저장 위치

```
.qa-reports/
├── qa-report-2025-12-31-login.md
├── qa-report-2025-12-31-case-create.md
└── ...
```

### 보고서 구조

```markdown
# QA 테스트 보고서: [테스트명]

## 테스트 개요
- 테스트 일시
- 테스트 대상
- 테스트 환경

## 테스트 결과 요약
| 항목 | 상태 | 설명 |
|------|------|------|
| ... | Pass/Fail | ... |

## 발견된 이슈
### Critical (심각)
### High (높음)
### Medium (중간)
### Low (낮음)

## 콘솔 에러
## 네트워크 오류
## 권장 조치 사항
```

## 테스트 계정 정보

| 항목 | 값 |
|------|-----|
| ID | `admin_test` |
| Password | `QaTest2025!@#Secure` |
| 권한 | ADMIN |

> **주의**: 비밀번호가 `test1234`와 같이 유출된 비밀번호일 경우 "비밀번호 변경" 팝업이 표시되어 테스트가 중단됩니다.

## 설정 파일

### vite.config.ts (프론트엔드 프록시)

```typescript
proxy: {
  '/api': {
    target: 'http://localhost:3000',
    changeOrigin: true,
  },
}
```

### .mcp.json (ArangoDB 연결)

```json
{
  "arango-mcp": {
    "env": {
      "ARANGO_URL": "http://localhost:8541",
      "ARANGO_DB": "bitz"
    }
  }
}
```

## 주요 Playwright MCP 명령어

| 명령어 | 용도 |
|--------|------|
| `browser_navigate` | 페이지 이동 |
| `browser_snapshot` | 페이지 상태 스냅샷 |
| `browser_click` | 요소 클릭 |
| `browser_type` | 텍스트 입력 |
| `browser_fill_form` | 폼 필드 일괄 입력 |
| `browser_wait_for` | 대기 |
| `browser_network_requests` | 네트워크 요청 확인 |
| `browser_console_messages` | 콘솔 메시지 확인 |

## 주요 ArangoDB MCP 명령어

| 명령어 | 용도 |
|--------|------|
| `arango_query` | AQL 쿼리 실행 |
| `arango_insert` | 문서 삽입 |
| `arango_update` | 문서 업데이트 |
| `arango_remove` | 문서 삭제 |
| `arango_list_collections` | 컬렉션 목록 |

## 테스트 시나리오 예시

### 로그인 테스트

```yaml
시나리오: 로그인 기능 테스트
단계:
  1. http://localhost:5173 접속
  2. ID 입력: admin_test
  3. Password 입력: test1234
  4. 로그인 버튼 클릭
  5. /page/case/list로 리다이렉트 확인
  6. 사용자 정보 표시 확인
검증:
  - URL이 /page/case/list로 변경
  - 콘솔에 에러 없음
  - 네트워크 요청 성공 (200)
```

### 케이스 생성 테스트

```yaml
시나리오: 케이스 생성 테스트
전제: 로그인 완료
단계:
  1. "케이스 생성" 버튼 클릭
  2. 케이스명 입력
  3. 태그 선택 (선택사항)
  4. 생성 버튼 클릭
  5. 목록에서 생성된 케이스 확인
검증:
  - 케이스가 목록에 표시
  - DB에 케이스 데이터 존재
```

## 자동 문제 해결

워크플로우는 다음 문제들을 자동으로 해결합니다:

| 문제 | 자동 해결 방법 |
|------|---------------|
| 백엔드 서버 미실행 | `npm run dev` 백그라운드 실행 |
| 프론트엔드 서버 미실행 | `npm run local` 백그라운드 실행 |
| 테스트 계정 없음 | `npx tsx scripts/createTestUser.ts` 실행 |
| 프록시 설정 오류 | vite.config.ts 자동 수정 |
| 의존성 누락 | `npm install` 자동 실행 |

## 트러블슈팅

### 프록시 연결 실패

**증상**: API 요청이 외부 서버로 전송됨
**자동 해결**: `front/vite.config.ts`에서 프록시 타겟을 `http://localhost:3000`으로 변경

### 로그인 실패 (401)

**증상**: AUTH_INVALID_CREDENTIALS 에러
**자동 해결**:
1. ArangoDB에서 계정 확인
2. 계정 없으면 자동 생성
3. 비밀번호 해시 자동 갱신

### React Hook 에러

**증상**: Invalid hook call 경고
**원인**: React 버전 충돌 또는 중복 인스턴스
**영향**: 기능에는 영향 없음 (경고 수준)
**보고서**: Warning 섹션에 기록됨

## 전용 Agent

QA 워크플로우는 다음 전용 agent들을 사용합니다:

### qa-tester
- **역할**: 브라우저 테스트 자동화
- **특징**:
  - Playwright MCP로 브라우저 제어
  - 중간에 질문 없이 자동 진행
  - 테스트 결과 JSON 형식으로 수집
- **위치**: `.claude/agents/qa-tester.md`

### qa-reporter
- **역할**: 테스트 결과 분석 및 보고서 생성
- **특징**:
  - 이슈 심각도 자동 분류 (Critical/High/Medium/Low)
  - 권장 조치 사항 자동 생성
  - MD 보고서 자동 작성
- **위치**: `.claude/agents/qa-reporter.md`

### Agent 실행 순서

```
[Main Orchestrator]
    |
    +-> [qa-tester] 테스트 실행
    |       - 브라우저 테스트
    |       - 결과 데이터 수집
    |       - JSON 결과 반환
    |
    +-> [qa-reporter] 보고서 생성
            - 결과 분석
            - 이슈 분류
            - MD 보고서 작성
```

## 관련 파일

| 파일 | 위치 | 용도 |
|------|------|------|
| vite.config.ts | front/ | 프록시 설정 |
| .mcp.json | back_end_final/ | MCP 서버 설정 |
| createTestUser.ts | scripts/ | 테스트 계정 생성 |
| .env | back_end_final/ | 환경 변수 |
| .qa-reports/ | back_end_final/ | QA 보고서 저장 |
| qa-tester.md | .claude/agents/ | 테스트 실행 에이전트 |
| qa-reporter.md | .claude/agents/ | 보고서 생성 에이전트 |
