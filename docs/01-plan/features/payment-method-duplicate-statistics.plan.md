# Plan: 결제수단 중복 관리 및 통계 표시 개선

**Feature ID**: `payment-method-duplicate-statistics`
**작성일**: 2026-02-01
**작성자**: AI Assistant
**PDCA Phase**: Plan

---

## 1. 문제 정의 (Problem Statement)

### 1.1 현상 분석

현재 프로젝트의 결제수단 관리 시스템에서 다음과 같은 문제가 발견되었습니다:

1. **자동수집 결제수단과 공유 결제수단의 중복 가능성**
   - 사용자가 '수원페이'를 공유 결제수단으로 등록
   - 동시에 자동수집 기능이 활성화된 '수원페이'를 자동수집 결제수단으로 등록
   - 두 개의 결제수단이 별도로 관리되지만, 통계 화면에서 구분이 불명확

2. **통계 탭의 결제수단별 통계 표시 문제**
   - 현재 `statistics_repository.dart`의 `getPaymentMethodStatistics()`는 `payment_method_id`로만 그룹화
   - 동일한 이름의 결제수단이 중복 등록된 경우 하나로 합산되어 표시될 위험
   - 자동수집 결제수단과 공유 결제수단을 구분하는 뱃지가 없음

### 1.2 데이터베이스 구조 분석

**현재 상태 (2026-01-25 기준)**:

```sql
-- 043_fix_payment_method_unique_constraint.sql 적용됨
-- 공유 결제수단: (ledger_id, name) UNIQUE
-- 자동수집 결제수단: (ledger_id, owner_user_id, name) UNIQUE
```

**핵심 발견**:
- 자동수집 결제수단(`can_auto_save=true`)과 공유 결제수단(`can_auto_save=false`)은 **별도의 UNIQUE constraint**를 가짐
- 따라서 동일한 가계부에서 '수원페이' 공유 결제수단과 '수원페이' 자동수집 결제수단이 **동시에 존재 가능**
- 각 결제수단은 고유한 `id`를 가지므로 데이터베이스 레벨에서는 문제 없음

### 1.3 UI/통계 레벨 문제

**문제점**:
1. 통계 조회 시 `payment_method_id`가 다르므로 별도로 집계됨
2. 하지만 사용자는 '수원페이'가 두 번 나타나는 이유를 알기 어려움
3. 어떤 것이 자동수집용이고, 어떤 것이 공유용인지 구분 불가

**예상 시나리오**:
```
통계 화면:
1위: 수원페이 - 150,000원 (40%)  <- 자동수집 결제수단
2위: KB Pay - 100,000원 (27%)
3위: 수원페이 - 50,000원 (13%)   <- 공유 결제수단
```

사용자는 '왜 수원페이가 두 개야?'라고 혼란스러울 것입니다.

---

## 2. 목표 (Objectives)

### 2.1 기능 목표

1. **통계 화면에서 결제수단 유형 명확히 구분**
   - 자동수집 결제수단에 '자동수집' 뱃지 표시
   - 공유 결제수단에 '공유' 뱃지 표시

2. **동일 이름 결제수단의 별도 집계 유지**
   - 현재 동작 유지: 각 결제수단은 별도로 집계
   - 사용자가 혼란스러워하지 않도록 시각적 구분 제공

3. **사용자 경험 개선**
   - 각 결제수단의 용도를 한눈에 파악 가능
   - 필요시 자동수집 결제수단과 공유 결제수단을 통합 조회하는 옵션 제공 (선택사항)

### 2.2 성공 기준

- [ ] 통계 화면에서 자동수집 결제수단과 공유 결제수단을 뱃지로 구분 가능
- [ ] 동일 이름의 결제수단이 두 개 표시될 때 사용자가 혼란스러워하지 않음
- [ ] 기존 통계 집계 로직 유지 (breaking change 없음)
- [ ] 다국어 지원 (한국어/영어)

---

## 3. 범위 (Scope)

### 3.1 포함 사항 (In Scope)

1. **통계 화면 개선**
   - `PaymentMethodStatistics` 엔티티에 `canAutoSave` 필드 추가
   - `payment_method_list.dart`에 뱃지 UI 추가
   - `payment_method_donut_chart.dart`에 범례 뱃지 추가

2. **통계 Repository 수정**
   - `getPaymentMethodStatistics()` 쿼리 수정: `payment_methods(name, icon, color, can_auto_save)` 조회
   - `PaymentMethodStatistics` 모델에 `canAutoSave` 필드 추가

3. **UI 컴포넌트 개선**
   - 자동수집 뱃지: '자동수집' 텍스트 또는 아이콘
   - 공유 뱃지: '공유' 텍스트 또는 아이콘
   - 뱃지 스타일: 작은 칩 형태, 색상 구분

4. **다국어 지원**
   - `app_ko.arb`: `statisticsPaymentMethodAutoSave`, `statisticsPaymentMethodShared`
   - `app_en.arb`: 동일

### 3.2 제외 사항 (Out of Scope)

1. **결제수단 통합 기능**
   - 자동수집 결제수단과 공유 결제수단을 하나로 합산하는 기능 (향후 추가 가능)

2. **결제수단 중복 방지 로직**
   - 현재 시스템은 의도적으로 두 개의 결제수단을 허용 (DB 설계 상 정상)

3. **결제수단 관리 페이지 수정**
   - 결제수단 추가/수정 페이지는 현재 기능 유지

---

## 4. 기술 조사 결과 (Technical Investigation)

### 4.1 현재 코드 분석

**통계 Repository (`statistics_repository.dart:408-477`)**:
```dart
Future<List<PaymentMethodStatistics>> getPaymentMethodStatistics({
  required String ledgerId,
  required int year,
  required int month,
  required String type,
}) async {
  final response = await _client
      .from('transactions')
      .select('amount, payment_method_id, payment_methods(name, icon, color)')
      .eq('ledger_id', ledgerId)
      .eq('type', type)
      .gte('date', startDate.toIso8601String().split('T').first)
      .lte('date', endDate.toIso8601String().split('T').first);
  // ... 그룹화 로직
}
```

**문제점**:
- `can_auto_save` 필드를 조회하지 않음
- 따라서 UI에서 뱃지 표시 불가능

**해결 방안**:
```dart
.select('amount, payment_method_id, payment_methods(name, icon, color, can_auto_save)')
```

### 4.2 데이터 모델 설계

**PaymentMethodStatistics 엔티티 수정 필요**:

```dart
class PaymentMethodStatistics extends Equatable {
  final String paymentMethodId;
  final String paymentMethodName;
  final String paymentMethodIcon;
  final String paymentMethodColor;
  final bool canAutoSave; // 추가 필요
  final int amount;
  final double percentage;

  const PaymentMethodStatistics({
    required this.paymentMethodId,
    required this.paymentMethodName,
    required this.paymentMethodIcon,
    required this.paymentMethodColor,
    required this.canAutoSave, // 추가
    required this.amount,
    required this.percentage,
  });
}
```

### 4.3 UI 구조 분석

**PaymentMethodList (`payment_method_list.dart:46-130`)**:
- 현재: 순위, 결제수단명, 비율, 금액 표시
- 추가: 결제수단명 옆에 뱃지 추가

**뱃지 UI 예시**:
```dart
Row(
  children: [
    Text(item.paymentMethodName),
    const SizedBox(width: 4),
    if (item.canAutoSave)
      _AutoSaveBadge()
    else
      _SharedBadge(),
  ],
)
```

### 4.4 기술 스택

- **Flutter**: UI 구현
- **Riverpod**: 상태 관리
- **Supabase**: 데이터 조회
- **i18n**: 다국어 지원

---

## 5. 구현 전략 (Implementation Strategy)

### 5.1 단계별 접근

#### Phase 1: 데이터 모델 수정
1. `PaymentMethodStatistics` 엔티티에 `canAutoSave` 필드 추가
2. `statistics_repository.dart`에서 `can_auto_save` 조회 추가
3. 기존 코드 호환성 유지 (기본값 설정)

#### Phase 2: UI 컴포넌트 개발
1. 뱃지 위젯 생성 (`_PaymentMethodBadge`)
2. `payment_method_list.dart`에 뱃지 적용
3. `payment_method_donut_chart.dart`에 범례 뱃지 적용 (선택사항)

#### Phase 3: 다국어 지원
1. `app_ko.arb`, `app_en.arb`에 번역 키 추가
2. 뱃지 텍스트에 i18n 적용

#### Phase 4: 테스트 및 검증
1. 자동수집 결제수단 + 공유 결제수단 동시 존재 시나리오 테스트
2. 뱃지 표시 정상 동작 확인
3. 다크모드 호환성 확인

### 5.2 리스크 및 대응 방안

| 리스크 | 영향도 | 대응 방안 |
|--------|--------|-----------|
| 기존 통계 로직 변경으로 인한 버그 | 중 | 기존 로직 유지, 필드만 추가 |
| UI 레이아웃 깨짐 (뱃지 추가로 인한) | 하 | 반응형 레이아웃 적용, 뱃지 크기 최소화 |
| 다국어 번역 누락 | 하 | 번역 키 체크리스트 작성 |

---

## 6. 의존성 및 제약사항 (Dependencies & Constraints)

### 6.1 의존성

1. **Supabase 테이블 구조**
   - `payment_methods.can_auto_save` 컬럼 존재 (이미 존재함)

2. **Flutter 패키지**
   - `flutter_riverpod`: 상태 관리
   - `equatable`: 엔티티 비교

### 6.2 제약사항

1. **기존 API 호환성**
   - `PaymentMethodStatistics` 생성자 변경 시 기존 코드 영향 가능
   - 기본값 설정으로 호환성 유지

2. **UI 공간 제약**
   - 뱃지 추가 시 레이아웃 조정 필요
   - 작은 화면(모바일)에서도 가독성 유지 필요

---

## 7. 타임라인 (Timeline)

| 단계 | 예상 작업량 | 순서 |
|------|-------------|------|
| Phase 1: 데이터 모델 수정 | 1 | 1 |
| Phase 2: UI 컴포넌트 개발 | 2 | 2 |
| Phase 3: 다국어 지원 | 1 | 3 |
| Phase 4: 테스트 및 검증 | 1 | 4 |

---

## 8. 성과 측정 (Success Metrics)

### 8.1 정량적 지표

- [ ] 통계 화면 로딩 시간 변화 없음 (기존 대비 ±10% 이내)
- [ ] 뱃지 표시 정확도 100% (자동수집/공유 구분)

### 8.2 정성적 지표

- [ ] 사용자 혼란도 감소 (동일 이름 결제수단에 대한 이해도 향상)
- [ ] 뱃지 UI의 시각적 일관성 (디자인 시스템 준수)

---

## 9. 후속 작업 (Follow-up Tasks)

### 9.1 향후 개선 사항

1. **결제수단 통합 뷰 옵션**
   - 동일 이름의 결제수단을 하나로 합산하여 보기 (토글 옵션)

2. **결제수단 중복 경고**
   - 공유 결제수단 추가 시 동일 이름의 자동수집 결제수단이 있으면 경고 표시

3. **통계 필터 개선**
   - '자동수집만', '공유만', '전체' 필터 추가

---

## 10. 승인 및 검토 (Approval)

### 10.1 검토 항목

- [x] 문제 정의 명확성
- [x] 기술 조사 완료
- [x] 구현 전략 타당성
- [x] 리스크 대응 방안 수립

### 10.2 다음 단계

- **Design 단계**: 상세 설계 문서 작성 (`/pdca design payment-method-duplicate-statistics`)

---

**Plan 문서 작성 완료**
작성일: 2026-02-01
