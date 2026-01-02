# QA 테스트 보고서: {{TEST_NAME}}

## 테스트 개요

| 항목 | 내용 |
|------|------|
| 테스트 일시 | {{TIMESTAMP}} |
| 테스트 대상 | {{TEST_TARGET}} |
| 테스트 환경 | Frontend: localhost:5173, Backend: localhost:3000 |
| 테스트 계정 | admin_test |

## 테스트 결과 요약

| 항목 | 상태 | 설명 |
|------|------|------|
| 서버 연결 | {{SERVER_STATUS}} | 백엔드/프론트엔드 서버 상태 |
| 로그인 | {{LOGIN_STATUS}} | 인증 성공 여부 |
| 페이지 로드 | {{PAGE_LOAD_STATUS}} | 메인 페이지 로드 |
| API 호출 | {{API_STATUS}} | API 응답 상태 |
| 콘솔 에러 | {{CONSOLE_STATUS}} | JavaScript 에러 여부 |

### 전체 결과: {{OVERALL_RESULT}}

---

## 발견된 이슈

### Critical (심각)
{{CRITICAL_ISSUES}}

### High (높음)
{{HIGH_ISSUES}}

### Medium (중간)
{{MEDIUM_ISSUES}}

### Low (낮음)
{{LOW_ISSUES}}

---

## 콘솔 에러

```
{{CONSOLE_ERRORS}}
```

## 네트워크 오류

| URL | 상태 | 메시지 |
|-----|------|--------|
{{NETWORK_ERRORS}}

---

## 테스트 단계별 결과

### 1. 환경 확인
{{STEP_1_RESULT}}

### 2. 로그인
{{STEP_2_RESULT}}

### 3. 테스트 시나리오 실행
{{STEP_3_RESULT}}

### 4. 결과 검증
{{STEP_4_RESULT}}

---

## 권장 조치 사항

{{RECOMMENDATIONS}}

---

## 스크린샷

{{SCREENSHOTS}}

---

*이 보고서는 QA 워크플로우에 의해 자동 생성되었습니다.*
