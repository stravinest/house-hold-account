# Plan: 통계 - 자동수집 결제수단 합산 기능

## 1. 개요

### 1.1 배경
공유 가계부에서 동일한 이름의 자동수집 결제수단(예: 사용자A의 'KB국민카드', 사용자B의 'KB국민카드')이 각각 별도로 표시됩니다. 현재는 UUID 기반 `payment_method_id`로 그룹화하기 때문에, 같은 이름이라도 다른 사용자 소유면 별개로 집계됩니다.

### 1.2 문제점
- 통계에서 'KB국민카드'가 2개로 표시됨 (A의 KB국민카드, B의 KB국민카드)
- 사용자 입장에서는 같은 결제수단으로 인식하는데 분리되어 혼란
- 전체 결제수단별 지출 비율 파악이 어려움

### 1.3 목표
자동수집 결제수단의 경우 **이름(name) 기준으로 합산**하여 통계에 표시

## 2. 현재 구현 분석

### 2.1 핵심 파일 및 로직

| 파일 | 역할 |
|------|------|
| `statistics_repository.dart:412-491` | 결제수단별 통계 계산 (getPaymentMethodStatistics) |
| `statistics_entities.dart` | PaymentMethodStatistics 엔티티 정의 |
| `payment_method_list.dart` | 통계 UI - 순위 리스트 표시 |
| `payment_method_donut_chart.dart` | 통계 UI - 도넛 차트 표시 |

### 2.2 현재 그룹화 로직

```dart
// statistics_repository.dart - 현재 구현
final Map<String, PaymentMethodStatistics> grouped = {};

for (final row in response as List) {
  final paymentMethodId = paymentMethodIdValue?.toString();

  // 문제: payment_method_id(UUID)를 그룹 키로 사용
  final String groupKey = paymentMethodId ?? '_no_payment_method_';

  if (grouped.containsKey(groupKey)) {
    // 동일 UUID만 합산됨
    grouped[groupKey] = grouped[groupKey]!.copyWith(
      amount: grouped[groupKey]!.amount + amount,
    );
  }
}
```

### 2.3 DB 스키마 (관련 필드)

```sql
-- payment_methods 테이블
- id: UUID (PK)
- ledger_id: UUID (FK)
- owner_user_id: UUID (FK to profiles)
- name: VARCHAR (결제수단 이름)
- can_auto_save: BOOLEAN (자동수집 지원 여부)
- auto_save_mode: VARCHAR (manual/suggest/auto)
```

## 3. 해결 방안

### 3.1 접근 방식

**자동수집 결제수단**은 `name` 기준으로 그룹화하고, **공유 결제수단**(직접입력)은 기존처럼 `payment_method_id` 기준 유지.

```
그룹화 로직:
- can_auto_save = true  → name 기준 그룹화
- can_auto_save = false → payment_method_id 기준 그룹화 (기존 동작)
```

### 3.2 그룹 키 생성 전략

```dart
// 제안하는 그룹 키 생성 로직
String getGroupKey(String? paymentMethodId, String? name, bool canAutoSave) {
  if (paymentMethodId == null) {
    return '_no_payment_method_';
  }

  if (canAutoSave && name != null) {
    // 자동수집: 이름 기준 (예: 'auto_KB국민카드')
    return 'auto_$name';
  }

  // 공유: UUID 기준 (기존 동작)
  return paymentMethodId;
}
```

### 3.3 UI 표시 고려사항

합산된 자동수집 결제수단 표시 시:
- 뱃지: "자동수집" (기존 유지)
- 색상: 첫 번째 발견된 결제수단의 색상 사용
- 아이콘: 첫 번째 발견된 결제수단의 아이콘 사용

## 4. 구현 계획

### 4.1 Phase 1: Repository 로직 수정

**파일**: `lib/features/statistics/data/repositories/statistics_repository.dart`

**변경 내용**:
1. `getPaymentMethodStatistics()` 메서드 수정
2. 그룹 키 생성 로직 변경 (can_auto_save 조건 추가)
3. 합산 시 첫 번째 발견된 메타데이터(색상, 아이콘) 유지

**예상 변경 라인**: 412-491 (약 80줄)

### 4.2 Phase 2: 엔티티 확인

**파일**: `lib/features/statistics/domain/entities/statistics_entities.dart`

**확인 내용**:
- PaymentMethodStatistics 엔티티에 추가 필드 필요 여부 확인
- mergedCount (합산된 결제수단 수) 필드 추가 고려

### 4.3 Phase 3: UI 업데이트 (선택사항)

**파일**: `lib/features/statistics/presentation/widgets/payment_method_tab/payment_method_list.dart`

**고려사항**:
- 합산된 결제수단임을 표시할 UI 추가 (예: "2명 사용 중")
- 현재는 필수 아님, 추후 개선 시 추가

## 5. 영향 범위

### 5.1 영향받는 기능
- 통계 > 결제수단 탭 - 도넛 차트
- 통계 > 결제수단 탭 - 순위 리스트

### 5.2 영향받지 않는 기능
- 결제수단 관리 페이지 (개별 표시 유지)
- 거래 생성/수정 시 결제수단 선택
- 자동수집 설정 페이지

### 5.3 하위 호환성
- 기존 데이터에 영향 없음 (DB 스키마 변경 불필요)
- 기존 거래 기록 유지

## 6. 테스트 시나리오

### 6.1 기본 시나리오
1. 사용자A: 'KB국민카드'로 10,000원 지출
2. 사용자B: 'KB국민카드'로 20,000원 지출
3. **예상 결과**: 통계에서 'KB국민카드' = 30,000원으로 표시

### 6.2 혼합 시나리오
1. 사용자A: 자동수집 'KB국민카드' 10,000원
2. 사용자B: 자동수집 'KB국민카드' 20,000원
3. 공유 결제수단 '현금' 15,000원
4. **예상 결과**:
   - KB국민카드: 30,000원 (자동수집 뱃지)
   - 현금: 15,000원 (공유 뱃지)

### 6.3 엣지 케이스
1. 자동수집 결제수단 이름에 특수문자 포함
2. 결제수단 없는 거래 (미지정)
3. 개인 가계부에서의 동작 (기존과 동일해야 함)

## 7. 위험 요소 및 대응

| 위험 | 영향도 | 대응 방안 |
|------|--------|-----------|
| 그룹 키 충돌 | 중 | 'auto_' 접두사로 명확히 구분 |
| 성능 저하 | 하 | 기존 O(n) 유지, 추가 쿼리 없음 |
| 색상/아이콘 불일치 | 하 | 첫 번째 발견된 값 사용 (일관성) |

## 8. 일정 (예상)

| 단계 | 작업 | 예상 |
|------|------|------|
| Phase 1 | Repository 로직 수정 | 핵심 작업 |
| Phase 2 | 엔티티 확인 및 수정 | 필요시만 |
| Phase 3 | UI 개선 (선택) | 추후 개선 |
| 테스트 | 시나리오 검증 | 필수 |

## 9. 참고 자료

- 마이그레이션: `043_fix_payment_method_unique_constraint.sql`
- 관련 Plan: `auto-collect-user-isolation-fix.plan.md`
- CLAUDE.md: SMS 자동수집 기능 섹션

---

**작성일**: 2026-02-05
**상태**: Plan 완료, Design 대기
