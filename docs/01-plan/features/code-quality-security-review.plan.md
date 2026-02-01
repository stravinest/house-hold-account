# 코드 품질 및 보안 리뷰 계획서

## 1. 개요

### 1.1 목적
- 프로젝트 전체에 대한 체계적인 코드 품질, 보안, 아키텍처 검증
- 잠재적 취약점 및 개선 사항 식별
- 프로덕션 배포 전 리스크 최소화

### 1.2 범위
- **Frontend (Flutter)**: 13개 feature 모듈
- **Backend (Supabase)**: 45개 마이그레이션, 2개 Edge Function
- **Infrastructure**: RLS 정책, Database Trigger, 인덱스 최적화
- **보안**: 인증/인가, 데이터 보호, API 보안

### 1.3 리뷰 기준
- OWASP Top 10 보안 취약점
- Flutter/Dart 베스트 프랙티스
- Clean Architecture 준수 여부
- 성능 최적화 기회
- 코드 일관성 및 유지보수성

---

## 2. 현황 분석

### 2.1 프로젝트 구조

#### Frontend (Flutter)
```
lib/features/
├── auth/              # 인증 (Google 로그인, 이메일 로그인)
├── ledger/            # 가계부 관리 (메인 화면)
├── transaction/       # 거래 기록 (수입/지출)
├── category/          # 카테고리 관리
├── payment_method/    # 결제수단 + SMS 자동수집 ⚠️ 복잡도 높음
├── notification/      # FCM 푸시 알림
├── share/             # 가계부 공유 (멤버 초대)
├── asset/             # 자산 관리 (예금, 주식 등)
├── fixed_expense/     # 고정 지출
├── statistics/        # 통계/차트
├── search/            # 거래 검색
├── settings/          # 사용자 설정
└── widget/            # 홈 위젯 (Android)
```

#### Backend (Supabase)
- **Migrations**: 45개 (RLS, 트리거, 인덱스 포함)
- **Edge Functions**:
  - `send-push-notification` (거래 알림)
  - `send-invite-notification` (초대 알림)
- **Database**: PostgreSQL + Realtime
- **Auth**: Supabase Auth + Google OAuth

### 2.2 주요 기능 복잡도 평가

| Feature | 복잡도 | 이유 | 우선순위 |
|---------|--------|------|----------|
| payment_method | 🔴 High | SMS 파싱, 자동수집, 중복 감지, Race condition | P0 |
| notification | 🟡 Medium | Edge Function, FCM, Database Trigger | P1 |
| share | 🟡 Medium | RLS 정책, 권한 관리, 초대 플로우 | P1 |
| auth | 🟡 Medium | OAuth, 세션 관리, 보안 | P0 |
| transaction | 🟢 Low | CRUD + Realtime | P2 |
| asset | 🟢 Low | CRUD + 카테고리별 관리 | P2 |
| 기타 | 🟢 Low | 단순 CRUD 또는 조회 | P3 |

### 2.3 알려진 이슈 및 기술 부채

1. **Race Condition 가능성**
   - `pending_transactions` 업데이트 중 동시성 이슈
   - SMS 자동수집 시 중복 거래 생성 가능성

2. **성능 관련**
   - 프로덕션 환경에서 debugPrint 제거 필요
   - 대량 데이터 조회 시 페이지네이션 미적용

3. **보안 관련**
   - Edge Function에서 민감한 에러 메시지 노출 가능성
   - SMS 파싱 데이터 검증 불완전

4. **코드 품질**
   - 하드코딩된 문자열 (i18n 누락)
   - 일부 파일에서 에러 처리 누락 (silent failure)

---

## 3. 리뷰 영역 정의

### 3.1 보안 리뷰 (Security Review)

#### 3.1.1 인증/인가 (Authentication & Authorization)
- [ ] Supabase Auth 설정 검증
- [ ] Google OAuth 구현 검증
- [ ] JWT 토큰 관리 (만료, 갱신)
- [ ] 세션 관리 (자동 로그아웃)

#### 3.1.2 데이터 보호 (Data Protection)
- [ ] RLS 정책 완전성 검증
  - `profiles`, `ledgers`, `transactions`, `payment_methods`, `pending_transactions` 등
- [ ] 민감 데이터 암호화 (결제수단 정보)
- [ ] 로그에서 민감 정보 노출 여부
- [ ] SQL Injection 취약점 (동적 쿼리)

#### 3.1.3 API 보안 (API Security)
- [ ] Edge Function 인증 검증 (`verify_jwt` 설정)
- [ ] CORS 설정 적절성
- [ ] Rate limiting 필요성 평가
- [ ] 에러 메시지에서 내부 정보 노출 방지

#### 3.1.4 모바일 앱 보안 (Mobile App Security)
- [ ] 민감한 환경변수 관리 (`.env` 보호)
- [ ] Android Manifest 권한 최소화
- [ ] SMS 수신 권한 악용 가능성 검증
- [ ] FCM 토큰 보안 (탈취 시나리오)

### 3.2 코드 품질 리뷰 (Code Quality Review)

#### 3.2.1 아키텍처 (Architecture)
- [ ] Clean Architecture 준수 여부
  - Domain/Data/Presentation 레이어 분리
  - 의존성 방향 (Domain ← Data ← Presentation)
- [ ] Feature-first 구조 일관성
- [ ] Riverpod Provider 설계 (순환 참조 방지)

#### 3.2.2 에러 처리 (Error Handling)
- [ ] try-catch에서 rethrow 누락 확인
- [ ] AsyncValue 에러 상태 처리
- [ ] 사용자 친화적 에러 메시지 (i18n)
- [ ] 네트워크 에러 핸들링 (타임아웃, 오프라인)

#### 3.2.3 비동기 처리 (Async Operations)
- [ ] `mounted` 체크 누락 확인
- [ ] Race condition 방지 (트랜잭션 사용)
- [ ] StreamSubscription 메모리 누수
- [ ] Future.wait 사용 시 에러 전파

#### 3.2.4 타입 안전성 (Type Safety)
- [ ] dynamic 타입 남용
- [ ] Null safety 위반 (!, as 캐스팅)
- [ ] Map 타입 대신 Model 클래스 사용
- [ ] Enum 타입 사용 일관성

#### 3.2.5 다국어 지원 (i18n)
- [ ] 하드코딩된 문자열 검색
- [ ] ARB 파일 번역 누락
- [ ] 에러 메시지 다국어 처리

### 3.3 성능 리뷰 (Performance Review)

#### 3.3.1 데이터베이스 (Database)
- [ ] N+1 쿼리 문제 (JOIN 최적화)
- [ ] 인덱스 누락 확인
- [ ] 대량 데이터 조회 시 페이지네이션
- [ ] Realtime subscription 과다 사용

#### 3.3.2 Flutter 성능 (Flutter Performance)
- [ ] 불필요한 위젯 빌드 (const 생성자)
- [ ] ListView.builder 대신 ListView 사용
- [ ] 이미지 캐싱 전략
- [ ] debugPrint 프로덕션 빌드 제거

#### 3.3.3 네트워크 (Network)
- [ ] API 호출 중복 방지 (debounce)
- [ ] 이미지 최적화 (압축, 리사이징)
- [ ] Offline-first 전략 평가

### 3.4 유지보수성 리뷰 (Maintainability Review)

#### 3.4.1 코드 일관성 (Code Consistency)
- [ ] 네이밍 컨벤션 (camelCase, PascalCase)
- [ ] 파일/폴더 구조 일관성
- [ ] 주석 스타일 (KDoc, JSDoc)

#### 3.4.2 테스트 커버리지 (Test Coverage)
- [ ] 단위 테스트 존재 여부
- [ ] 위젯 테스트 존재 여부
- [ ] E2E 테스트 (Maestro) 커버리지

#### 3.4.3 문서화 (Documentation)
- [ ] CLAUDE.md 최신성
- [ ] README.md 완성도
- [ ] 주요 함수 주석 (복잡한 로직)

---

## 4. 리뷰 방법론

### 4.1 자동화 도구 활용
1. **Flutter Analyze**: `flutter analyze`
2. **Dart Format**: `dart format --set-exit-if-changed .`
3. **Security Scan**: OWASP 체크리스트 기반 수동 검증
4. **Database Schema**: Supabase Studio에서 RLS 정책 검증

### 4.2 수동 코드 리뷰
1. **파일별 검증**:
   - 각 feature의 핵심 파일 (provider, repository, service) 집중 검토
2. **플로우별 검증**:
   - 중요 사용자 플로우 (로그인, 거래 생성, SMS 자동수집, 공유) end-to-end 검증
3. **보안 시나리오 테스트**:
   - 권한 우회 시도, SQL Injection, XSS 등

### 4.3 우선순위 기반 접근
- **P0 (Critical)**: 보안 취약점, 데이터 손실 가능성
- **P1 (High)**: 성능 이슈, Race condition
- **P2 (Medium)**: 코드 품질, 유지보수성
- **P3 (Low)**: 스타일, 주석, 문서화

---

## 5. 검증 항목 체크리스트

### 5.1 보안 체크리스트

#### OWASP Top 10 (2021)
- [ ] A01: Broken Access Control (RLS 정책)
- [ ] A02: Cryptographic Failures (민감 데이터 암호화)
- [ ] A03: Injection (SQL Injection, XSS)
- [ ] A04: Insecure Design (권한 설계)
- [ ] A05: Security Misconfiguration (환경변수, CORS)
- [ ] A06: Vulnerable Components (의존성 취약점)
- [ ] A07: Authentication Failures (세션 관리)
- [ ] A08: Software and Data Integrity (Edge Function 검증)
- [ ] A09: Security Logging (민감 정보 로그)
- [ ] A10: Server-Side Request Forgery (Edge Function SSRF)

### 5.2 Flutter 베스트 프랙티스 체크리스트
- [ ] Provider dispose 누락 확인
- [ ] BuildContext 비동기 사용 시 mounted 체크
- [ ] StatefulWidget vs StatelessWidget 적절성
- [ ] Key 사용 적절성 (ListView 등)
- [ ] const 생성자 활용 극대화

### 5.3 데이터베이스 체크리스트
- [ ] Foreign Key 제약 조건 완전성
- [ ] Index 성능 최적화
- [ ] Trigger 로직 정확성
- [ ] RLS 정책 빈틈 없음
- [ ] Migration 롤백 가능성

---

## 6. 결과물 (Deliverables)

### 6.1 Design 문서
`docs/02-design/features/code-quality-security-review.design.md`
- 발견된 이슈 상세 분석
- 우선순위별 분류 (P0/P1/P2/P3)
- 각 이슈별 영향도 및 해결 방안

### 6.2 Analysis 문서
`docs/03-analysis/code-quality-security-review.analysis.md`
- 리뷰 결과 요약 (통과/실패 항목)
- Match Rate 계산 (목표: ≥90%)
- 개선 전후 비교

### 6.3 Report 문서
`docs/04-report/code-quality-security-review.report.md`
- 전체 리뷰 종합 보고서
- 즉시 조치 필요 항목 (Action Items)
- 장기 개선 로드맵

---

## 7. 일정 및 마일스톤

### Phase 1: Plan (현재)
- ✅ 리뷰 계획서 작성

### Phase 2: Design (다음 단계)
- 🔄 자동화 도구 실행 (flutter analyze)
- 🔄 보안 취약점 수동 검증 (P0 우선)
- 🔄 코드 품질 검증 (P1/P2)
- 예상 시간: 2-3시간

### Phase 3: Do (구현)
- 발견된 이슈 수정 (우선순위 기반)
- 예상 시간: 이슈 개수에 따라 가변

### Phase 4: Check (검증)
- Gap analysis 실행
- Match Rate ≥90% 확인

### Phase 5: Act (개선)
- 미해결 이슈 재검토 및 수정
- 최종 보고서 작성

---

## 8. 리스크 및 제약사항

### 8.1 리스크
- **프로덕션 환경 영향**: 일부 보안 수정 시 기존 사용자 영향 가능
- **시간 제약**: 모든 이슈를 즉시 해결하기 어려울 수 있음
- **False Positive**: 자동화 도구의 오탐 가능성

### 8.2 제약사항
- 외부 의존성 (Supabase, Firebase) 제어 불가
- 레거시 코드 (초기 개발 시 기술 부채) 존재
- 테스트 커버리지 낮음 (현재)

---

## 9. 성공 기준

### 9.1 보안
- [ ] OWASP Top 10 항목 중 Critical 취약점 0건
- [ ] RLS 정책 모든 테이블 적용
- [ ] 민감 데이터 로그 노출 0건

### 9.2 코드 품질
- [ ] `flutter analyze` 에러 0건
- [ ] 하드코딩 문자열 ≤5건 (i18n 적용)
- [ ] Race condition 가능성 0건

### 9.3 성능
- [ ] N+1 쿼리 0건
- [ ] 필수 인덱스 100% 적용
- [ ] 프로덕션 debugPrint 0건

### 9.4 유지보수성
- [ ] 주요 함수 주석 커버리지 ≥80%
- [ ] 파일 구조 일관성 100%
- [ ] 네이밍 컨벤션 위반 ≤5건

---

## 10. 참고 자료

### 10.1 내부 문서
- `CLAUDE.md`: 프로젝트 개요 및 컨벤션
- `DESIGN_SYSTEM.md`: UI/UX 가이드라인
- `rust_string_handling_guide.md`: UTF-8 처리 주의사항

### 10.2 외부 자료
- [OWASP Top 10 (2021)](https://owasp.org/Top10/)
- [Flutter Security Best Practices](https://flutter.dev/docs/deployment/security)
- [Supabase RLS Documentation](https://supabase.com/docs/guides/auth/row-level-security)
- [Dart Effective Dart](https://dart.dev/guides/language/effective-dart)

---

**작성일**: 2026-02-01
**작성자**: AI Code Reviewer (Claude)
**버전**: 1.0
**상태**: Plan Phase ✅
