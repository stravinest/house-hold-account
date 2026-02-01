# 자동수집 기능 카드사/지역화폐 감지 키워드 수정

## TL;DR

> **Quick Summary**: Flutter 가계부 앱의 자동수집 기능에서 잘못된 카드사 앱 패키지명을 수정하고, 누락된 경기도 지역화폐 개별 항목을 추가합니다.
> 
> **Deliverables**:
> - 카드사 앱 패키지명 수정 (롯데/NH농협/BC카드)
> - 경기지역화폐 패키지명 수정 및 개별 지역화폐 항목 추가
> - SMS 발신번호 업데이트
> 
> **Estimated Effort**: Short (~20분)
> **Parallel Execution**: YES - 4 waves
> **Critical Path**: Task 1-4 (병렬) → Task 5 (검증)

---

## Context

### Original Request
Flutter 가계부 앱의 자동수집 기능에서 각 카드사/지역화폐의 감지 키워드가 잘못되어 있어 수정이 필요합니다.

### Interview Summary
**Key Discussions**:
- SMS 발신번호: 웹 검색 정보 우선, 기존 번호도 호환성 유지
- 작업 방식: 모든 파일 한 번에 수정
- 테스트 전략: flutter analyze만 실행

**Research Findings**:
- 롯데카드 패키지명: `com.lcacApp` (디지로카)
- NH농협카드 패키지명: `nh.smart.nhallonepay` (NH올원페이)
- BC카드 패키지명: `kvp.jjy.MispAndroid320` (ISP/페이북)
- 경기지역화폐 패키지명: `gov.gyeonggi.ggcard` (공식 앱)
- `financial_service_template.dart`에는 이미 7개 지역화폐 템플릿이 정의됨

---

## Work Objectives

### Core Objective
자동수집 기능이 각 카드사와 지역화폐의 SMS/Push 알림을 정확하게 감지할 수 있도록 패키지명과 키워드를 수정합니다.

### Concrete Deliverables
- `default_format_generator.dart`: 패키지명 수정 + 지역화폐 6개 항목 추가
- `korean_financial_patterns.dart`: SMS 발신번호 업데이트
- `notification_listener_wrapper.dart`: 패키지명 대소문자 수정
- `sms_parsing_service.dart`: 발신번호 업데이트

### Definition of Done
- [ ] `flutter analyze` 오류 없음
- [ ] 모든 카드사 패키지명이 실제 앱과 일치
- [ ] 모든 경기도 지역화폐 개별 항목 존재

### Must Have
- 롯데카드 패키지명: `com.lcacApp`
- NH농협카드 패키지명: `nh.smart.nhallonepay`
- BC카드 패키지명: `kvp.jjy.MispAndroid320`
- 경기지역화폐 패키지명: `gov.gyeonggi.ggcard`
- 지역화폐 개별 항목: 용인와이페이, 행복화성, 고양페이, 부천페이, 서울사랑상품권, 인천이음페이

### Must NOT Have (Guardrails)
- 기존 SMS 발신번호 제거 금지 (호환성 유지)
- 다른 기능 수정 금지
- 테스트 코드 수정 불필요

---

## Verification Strategy (MANDATORY)

### Test Decision
- **Infrastructure exists**: YES (flutter analyze)
- **User wants tests**: Manual-only (flutter analyze)
- **Framework**: flutter analyze

### Automated Verification

각 TODO 완료 후 `flutter analyze`로 검증합니다.

```bash
# Agent 실행:
flutter analyze lib/features/payment_method/data/services/default_format_generator.dart
flutter analyze lib/features/payment_method/data/services/korean_financial_patterns.dart
flutter analyze lib/features/payment_method/data/services/notification_listener_wrapper.dart
flutter analyze lib/features/payment_method/data/services/sms_parsing_service.dart
# Assert: "No issues found!"
```

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately - 독립적 수정):
├── Task 1: default_format_generator.dart 수정
├── Task 2: korean_financial_patterns.dart 수정
├── Task 3: notification_listener_wrapper.dart 수정
└── Task 4: sms_parsing_service.dart 수정

Wave 2 (After Wave 1):
└── Task 5: flutter analyze 전체 검증
```

### Dependency Matrix

| Task | Depends On | Blocks | Can Parallelize With |
|------|------------|--------|---------------------|
| 1 | None | 5 | 2, 3, 4 |
| 2 | None | 5 | 1, 3, 4 |
| 3 | None | 5 | 1, 2, 4 |
| 4 | None | 5 | 1, 2, 3 |
| 5 | 1, 2, 3, 4 | None | None (final) |

---

## TODOs

- [ ] 1. default_format_generator.dart 패키지명 수정 및 지역화폐 추가

  **What to do**:
  - 롯데카드 `pushPackage`: `com.lotte.lottesmartpay` → `com.lcacApp`
  - NH농협카드 `pushPackage`: `nh.smart.card` → `nh.smart.nhallonepay`
  - BC카드 `pushPackage`: `com.bccard.bcpaybooc` → `kvp.jjy.MispAndroid320`
  - 수원페이/경기지역화폐 `pushPackage`: `com.thepayglobal.gyeonggipay` → `gov.gyeonggi.ggcard`
  - 지역화폐 6개 항목 추가:
    - 용인와이페이 (smsKeywords: ['용인와이페이', '용인페이', '경기지역화폐', '용인시'], pushPackage: 'gov.gyeonggi.ggcard')
    - 행복화성 (smsKeywords: ['행복화성', '화성페이', '경기지역화폐', '화성시'], pushPackage: 'gov.gyeonggi.ggcard')
    - 고양페이 (smsKeywords: ['고양페이', '경기지역화폐', '고양시'], pushPackage: 'gov.gyeonggi.ggcard')
    - 부천페이 (smsKeywords: ['부천페이', '경기지역화폐', '부천시'], pushPackage: 'gov.gyeonggi.ggcard')
    - 서울사랑상품권 (smsKeywords: ['서울사랑', '서울상품권', '서울페이', '제로페이'], pushPackage: 별도앱)
    - 인천이음페이 (smsKeywords: ['인천이음', '이음페이'], pushPackage: 별도앱)

  **Must NOT do**:
  - 기존 키워드 제거 금지
  - 다른 카드사 수정 금지

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 단순 문자열 교체 작업
  - **Skills**: []
    - 특별한 스킬 불필요

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 2, 3, 4)
  - **Blocks**: Task 5
  - **Blocked By**: None

  **References**:
  - `lib/features/payment_method/data/services/default_format_generator.dart:36-79` - 카드사 패키지명 위치
  - `lib/features/payment_method/data/services/default_format_generator.dart:67-79` - 지역화폐 섹션

  **Acceptance Criteria**:
  ```bash
  # Agent 실행:
  flutter analyze lib/features/payment_method/data/services/default_format_generator.dart
  # Assert: "No issues found!"
  
  # 패키지명 확인:
  grep -c "com.lcacApp" lib/features/payment_method/data/services/default_format_generator.dart
  # Assert: 1 이상
  
  grep -c "gov.gyeonggi.ggcard" lib/features/payment_method/data/services/default_format_generator.dart
  # Assert: 1 이상
  
  grep -c "용인와이페이" lib/features/payment_method/data/services/default_format_generator.dart
  # Assert: 1 이상
  ```

  **Commit**: YES
  - Message: `fix(payment_method): 카드사 패키지명 수정 및 지역화폐 개별 항목 추가`
  - Files: `lib/features/payment_method/data/services/default_format_generator.dart`

---

- [ ] 2. korean_financial_patterns.dart SMS 발신번호 업데이트

  **What to do**:
  - KB국민카드 senderPatterns: 기존 유지 + `1588-1688` 형식 호환
  - 신한카드 senderPatterns: `15447000` 추가
  - 삼성카드 senderPatterns: `15888700` 추가
  - 현대카드 senderPatterns: `15886474` 추가
  - BC카드 senderPatterns: `15884000` 추가

  **Must NOT do**:
  - 기존 발신번호 제거 금지

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 단순 배열 요소 추가 작업
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 3, 4)
  - **Blocks**: Task 5
  - **Blocked By**: None

  **References**:
  - `lib/features/payment_method/data/services/korean_financial_patterns.dart:70-98` - 카드사 senderPatterns 위치
  - `lib/features/payment_method/data/services/korean_financial_patterns.dart:341-446` - 지역화폐 패턴

  **Acceptance Criteria**:
  ```bash
  # Agent 실행:
  flutter analyze lib/features/payment_method/data/services/korean_financial_patterns.dart
  # Assert: "No issues found!"
  
  grep -c "15447000" lib/features/payment_method/data/services/korean_financial_patterns.dart
  # Assert: 1 이상
  ```

  **Commit**: NO (Task 1과 그룹)

---

- [ ] 3. notification_listener_wrapper.dart 패키지명 수정

  **What to do**:
  - `_financialAppPackagesLower`에서 `com.lcacapp` → `com.lcacApp` (대소문자 수정)
  - 필요시 누락된 패키지명 추가

  **Must NOT do**:
  - 기존 패키지 제거 금지
  - 로직 변경 금지

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 단순 문자열 수정
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2, 4)
  - **Blocks**: Task 5
  - **Blocked By**: None

  **References**:
  - `lib/features/payment_method/data/services/notification_listener_wrapper.dart:61-106` - _financialAppPackagesLower 위치
  - 라인 81: `'com.lcacapp'` → `'com.lcacApp'`

  **Acceptance Criteria**:
  ```bash
  # Agent 실행:
  flutter analyze lib/features/payment_method/data/services/notification_listener_wrapper.dart
  # Assert: "No issues found!"
  
  grep -c "com.lcacApp" lib/features/payment_method/data/services/notification_listener_wrapper.dart
  # Assert: 1 이상
  ```

  **Commit**: NO (Task 1과 그룹)

---

- [ ] 4. sms_parsing_service.dart 발신번호 동기화

  **What to do**:
  - `FinancialSmsSenders.senderPatterns`에서 SMS 발신번호 업데이트
  - Task 2에서 수정한 내용과 동기화:
    - 신한카드: `15447000` 추가
    - 삼성카드: `15888700` 추가
    - 현대카드: `15886474` 추가
    - BC카드: `15884000` 추가

  **Must NOT do**:
  - 기존 발신번호 제거 금지

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 단순 배열 요소 추가
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2, 3)
  - **Blocks**: Task 5
  - **Blocked By**: None

  **References**:
  - `lib/features/payment_method/data/services/sms_parsing_service.dart:72-104` - senderPatterns 위치

  **Acceptance Criteria**:
  ```bash
  # Agent 실행:
  flutter analyze lib/features/payment_method/data/services/sms_parsing_service.dart
  # Assert: "No issues found!"
  ```

  **Commit**: NO (Task 1과 그룹)

---

- [ ] 5. flutter analyze 전체 검증

  **What to do**:
  - 전체 프로젝트 lint 검사 실행
  - 오류 발생 시 수정

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 단순 검증 작업
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2 (sequential)
  - **Blocks**: None (final)
  - **Blocked By**: Tasks 1, 2, 3, 4

  **References**:
  - 모든 수정된 파일

  **Acceptance Criteria**:
  ```bash
  # Agent 실행:
  flutter analyze
  # Assert: "No issues found!" 또는 수정 대상 파일에 오류 없음
  ```

  **Commit**: YES (모든 변경사항 포함)
  - Message: `fix(payment_method): 카드사/지역화폐 감지 키워드 및 패키지명 수정`
  - Files: 
    - `lib/features/payment_method/data/services/default_format_generator.dart`
    - `lib/features/payment_method/data/services/korean_financial_patterns.dart`
    - `lib/features/payment_method/data/services/notification_listener_wrapper.dart`
    - `lib/features/payment_method/data/services/sms_parsing_service.dart`

---

## Commit Strategy

| After Task | Message | Files | Verification |
|------------|---------|-------|--------------|
| 5 | `fix(payment_method): 카드사/지역화폐 감지 키워드 및 패키지명 수정` | 4개 파일 | flutter analyze |

---

## Success Criteria

### Verification Commands
```bash
flutter analyze  # Expected: No issues found!

# 패키지명 검증
grep "com.lcacApp" lib/features/payment_method/data/services/default_format_generator.dart
grep "nh.smart.nhallonepay" lib/features/payment_method/data/services/default_format_generator.dart
grep "kvp.jjy.MispAndroid320" lib/features/payment_method/data/services/default_format_generator.dart
grep "gov.gyeonggi.ggcard" lib/features/payment_method/data/services/default_format_generator.dart

# 지역화폐 개별 항목 검증
grep "용인와이페이" lib/features/payment_method/data/services/default_format_generator.dart
grep "행복화성" lib/features/payment_method/data/services/default_format_generator.dart
grep "고양페이" lib/features/payment_method/data/services/default_format_generator.dart
grep "부천페이" lib/features/payment_method/data/services/default_format_generator.dart
```

### Final Checklist
- [ ] 롯데카드 패키지명 `com.lcacApp` 적용됨
- [ ] NH농협카드 패키지명 `nh.smart.nhallonepay` 적용됨
- [ ] BC카드 패키지명 `kvp.jjy.MispAndroid320` 적용됨
- [ ] 경기지역화폐 패키지명 `gov.gyeonggi.ggcard` 적용됨
- [ ] 지역화폐 6개 개별 항목 추가됨
- [ ] SMS 발신번호 업데이트됨
- [ ] flutter analyze 오류 없음
