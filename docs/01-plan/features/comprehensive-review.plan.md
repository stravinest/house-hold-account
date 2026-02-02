# Plan: 프로젝트 종합 리뷰 (Comprehensive Review)

## 1. 목표 (Objective)

공유 가계부 앱 프로젝트 전체에 대한 종합적인 품질 검토 및 개선 방향 수립

### 리뷰 범위
- **성능 (Performance)**: 앱 반응성, 데이터 로딩, 쿼리 최적화
- **코드 품질 (Code Quality)**: 아키텍처 준수, 중복 코드, 네이밍, 테스트 커버리지
- **버그 가능성 (Bug Risks)**: Race condition, 에러 처리, 엣지케이스
- **DB 설계 (Database Design)**: 스키마 구조, 인덱스, RLS 정책
- **디자인/UX**: UI 일관성, 접근성, 사용자 경험
- **보안 (Security)**: 인증/인가, 데이터 보호, 취약점

## 2. 배경 (Background)

### 현재 상황
- Flutter 기반 크로스플랫폼 가계부 앱 (Supabase 백엔드)
- Clean Architecture + Feature-first 구조
- 45개의 마이그레이션 파일 (복잡한 DB 스키마)
- SMS/Push 자동수집, 푸시 알림, 위젯 등 다양한 기능

### 주요 관심사
1. **복잡도 증가**: 45개 마이그레이션, 다수의 Feature 모듈
2. **성능 우려**: RLS 중첩, N+1 쿼리 가능성
3. **코드 일관성**: 여러 개발 세션을 거치며 스타일 불일치 가능성
4. **보안 검증**: RLS 정책, 권한 체크 누락 확인 필요

## 3. 성공 기준 (Success Criteria)

### 정량적 기준
- [ ] 주요 화면 로딩 시간 < 500ms
- [ ] DB 쿼리 인덱스 커버리지 > 90%
- [ ] Critical/High 보안 이슈 0건
- [ ] 코드 중복률 < 5%

### 정성적 기준
- [ ] 모든 Feature가 Clean Architecture 준수
- [ ] 에러 처리 일관성 확보
- [ ] UX 흐름이 직관적이고 일관됨
- [ ] RLS 정책이 모든 민감 테이블에 적용됨

## 4. 제약사항 (Constraints)

### 기술적 제약
- Flutter 3.10.3, Dart SDK ^3.10.3
- Supabase 백엔드 (PostgreSQL)
- Android 전용 기능 (SMS 수집)

### 시간적 제약
- 기존 기능 동작 유지 (Breaking Changes 최소화)
- 점진적 개선 (Big Bang 리팩토링 지양)

### 리소스 제약
- 자동화된 테스트 부족 (수동 검증 위주)

## 5. 범위 (Scope)

### 포함 (In Scope)
1. **성능 분석**
   - 주요 Repository 쿼리 분석
   - DB 인덱스 효율성 검토
   - 불필요한 재렌더링 탐지

2. **코드 품질 검토**
   - Clean Architecture 준수 여부
   - Provider/Repository 계층 분리
   - 중복 코드 및 dead code 탐지
   - i18n 하드코딩 검출

3. **버그 리스크 분석**
   - Race condition (SMS/Push 중복 처리 등)
   - 에러 처리 누락 (try-catch without rethrow)
   - Null safety 위반 가능성
   - 비동기 처리 (`mounted` 체크 누락)

4. **DB 설계 검증**
   - RLS 정책 완전성
   - Foreign Key 인덱싱
   - 트랜잭션 처리 (RPC 함수 활용)
   - 마이그레이션 롤백 가능성

5. **디자인/UX 검토**
   - DESIGN_SYSTEM.md 준수 여부
   - 색상/간격 하드코딩 탐지
   - 접근성 (Semantics, 터치 영역)
   - 일관된 에러 메시지

6. **보안 검토**
   - RLS 정책 누락 테이블 확인
   - SQL Injection 가능성 (동적 쿼리)
   - 민감 정보 로깅 (`debugPrint` 프로덕션 빌드)
   - 권한 체크 누락 (SMS, 알림 등)

### 제외 (Out of Scope)
- 새로운 기능 추가
- UI 디자인 재작업
- 전체 리팩토링 (점진적 개선만)
- iOS 지원 (현재 Android 전용)

## 6. 접근 방법 (Approach)

### Phase 1: 자동화된 정적 분석 (1일)
- `flutter analyze` 실행 및 경고 해결
- `dart format` 일관성 체크
- Glob/Grep으로 패턴 기반 이슈 탐지
  - 하드코딩된 문자열 (i18n 누락)
  - `debugPrint` in production
  - `mounted` 체크 누락
  - try-catch without rethrow

### Phase 2: DB 스키마 및 성능 분석 (1일)
- 모든 마이그레이션 파일 리뷰
- RLS 정책 완전성 매트릭스 작성
- 인덱스 누락 테이블 식별
- RPC 함수 트랜잭션 검증

### Phase 3: 코드 아키텍처 검토 (2일)
- Feature별 Clean Architecture 준수 확인
- Repository 계층 일관성
- Provider 상태 관리 패턴
- 중복 코드 탐지 (유사 위젯, 로직)

### Phase 4: 버그 리스크 분석 (1일)
- SMS/Push 자동수집 Race condition
- 비동기 에러 전파 경로 확인
- 엣지케이스 시나리오 매핑
- 메모리 누수 가능성 (Listener 해제)

### Phase 5: UX/디자인 일관성 검토 (1일)
- DESIGN_SYSTEM.md 대비 하드코딩 탐지
- 에러 메시지 일관성
- 접근성 체크리스트
- 다크모드 호환성

### Phase 6: 보안 감사 (1일)
- RLS 정책 매트릭스 완성
- 권한 플로우 검증
- 민감 정보 로깅 제거
- 입력 검증 (SQL Injection, XSS)

### Phase 7: 리포트 작성 및 우선순위화 (1일)
- 발견된 이슈 분류 (Critical/High/Medium/Low)
- 개선 로드맵 작성
- Quick Wins 식별
- 기술 부채 관리 계획

## 7. 위험 요소 (Risks)

### 기술적 위험
- **복잡도**: 45개 마이그레이션 분석 시간 소요
- **테스트 부족**: 자동 테스트 없어 회귀 위험
- **RLS 중첩**: 성능 영향 측정 어려움

### 완화 방안
- 우선순위 기반 샘플링 (모든 파일 리뷰 대신 대표 Feature)
- 자동화된 패턴 탐지 (Grep/Glob)
- Supabase 대시보드로 쿼리 성능 모니터링

## 8. 의존성 (Dependencies)

### 선행 조건
- 프로젝트 빌드 가능 상태
- Supabase 프로젝트 접근 권한
- DESIGN_SYSTEM.md 존재

### 외부 의존성
- Supabase 쿼리 로그 (성능 분석)
- Flutter DevTools (성능 프로파일링)

## 9. 타임라인 (Timeline)

| Phase | 작업 | 예상 시간 |
|-------|------|-----------|
| 1 | 정적 분석 | 1일 |
| 2 | DB 분석 | 1일 |
| 3 | 아키텍처 검토 | 2일 |
| 4 | 버그 리스크 | 1일 |
| 5 | UX/디자인 | 1일 |
| 6 | 보안 감사 | 1일 |
| 7 | 리포트 작성 | 1일 |
| **Total** | | **8일** |

## 10. 체크리스트 (Checklist)

### 사전 준비
- [x] `.bkit-memory.json` 확인
- [x] 프로젝트 파일 구조 파악
- [ ] `flutter analyze` 실행
- [ ] DESIGN_SYSTEM.md 리뷰

### Phase별 체크리스트
#### Phase 1: 정적 분석
- [ ] 린트 경고 목록 생성
- [ ] i18n 하드코딩 패턴 탐지
- [ ] debugPrint 프로덕션 사용 탐지
- [ ] mounted 체크 누락 탐지

#### Phase 2: DB 분석
- [ ] RLS 정책 매트릭스 작성
- [ ] 인덱스 누락 확인
- [ ] RPC 함수 트랜잭션 검증
- [ ] 마이그레이션 롤백 가능성

#### Phase 3: 아키텍처
- [ ] Feature별 Clean Architecture 준수
- [ ] Repository 계층 일관성
- [ ] Provider 패턴 일관성
- [ ] 중복 코드 탐지

#### Phase 4: 버그 리스크
- [ ] Race condition 시나리오
- [ ] 에러 전파 경로
- [ ] 엣지케이스 매핑
- [ ] 메모리 누수 가능성

#### Phase 5: UX/디자인
- [ ] 디자인 토큰 사용 확인
- [ ] 에러 메시지 일관성
- [ ] 접근성 체크리스트
- [ ] 다크모드 호환성

#### Phase 6: 보안
- [ ] RLS 정책 완전성
- [ ] 권한 플로우 검증
- [ ] 민감 정보 로깅
- [ ] 입력 검증

#### Phase 7: 리포트
- [ ] 이슈 분류 (Critical/High/Medium/Low)
- [ ] 개선 로드맵
- [ ] Quick Wins 목록
- [ ] 기술 부채 계획

## 11. 예상 산출물 (Deliverables)

1. **종합 리뷰 리포트** (`docs/04-report/comprehensive-review.report.md`)
   - 발견된 이슈 목록 (분류별)
   - 우선순위 기반 개선 로드맵
   - Quick Wins 목록

2. **분석 문서** (`docs/03-analysis/comprehensive-review.analysis.md`)
   - 성능 병목 지점
   - 코드 품질 메트릭
   - 보안 취약점 목록

3. **디자인 문서** (`docs/02-design/comprehensive-review.design.md`)
   - 개선 방안 상세 설계
   - 아키텍처 다이어그램
   - 리팩토링 계획

4. **실행 가능한 TODO 목록**
   - Critical 이슈 즉시 수정 항목
   - Medium/Low 이슈 점진적 개선 항목

## 12. 승인 및 다음 단계

### 승인 기준
- [ ] 리뷰 범위가 명확히 정의됨
- [ ] 타임라인이 현실적임
- [ ] 예상 산출물이 구체적임

### 다음 단계
1. Plan 승인 후 → Design 문서 작성
2. Design 승인 후 → 실제 분석 실행 (Do)
3. 분석 완료 후 → Gap Analysis (Check)
4. 개선 필요 시 → 반복 개선 (Act)
5. 최종 → 완료 리포트 생성

---

**작성일**: 2026-02-01
**작성자**: Claude Code
**버전**: 1.0
**상태**: Draft (승인 대기)
