# 성능 분석 결과

## 분석 개요

| 항목 | 내용 |
|------|------|
| **분석 대상** | 앱 반응성, 쿼리 최적화, 렌더링 성능 |
| **분석 일자** | 2026-02-01 |
| **종합 점수** | 88/100 |

---

## 1. 데이터베이스 성능

### 1.1 인덱스 최적화

**평가: 우수 (90%)**

**주요 복합 인덱스:**
- `idx_transactions_ledger_id_date`: 월별 조회 최적화
- `idx_transactions_asset_lookup`: 자산 조회 최적화
- `idx_pending_transactions_ledger_status`: 상태별 조회

**누락된 인덱스 (6개):**
- transactions.user_id
- payment_methods.default_category_id
- recurring_templates.fixed_expense_category_id
- pending_transactions.payment_method_id
- pending_transactions.parsed_category_id
- merchant_category_rules.category_id

**영향:**
- 사용자별 거래 조회 시 Full Scan 가능
- 성능 저하 예상: 거래 1000건 이상 시

### 1.2 N+1 쿼리

**평가: 우수 (95%)**

- TransactionRepository: JOIN 사용 ✅
- StatisticsRepository: N+1 최적화 완료 ✅
- ShareRepository: createInvite 연속 쿼리 (개선 가능)

### 1.3 RLS 성능

**평가: 양호 (85%)**

- 대부분 정책에 `(select auth.uid())` 최적화 적용
- profiles RLS는 SECURITY DEFINER 함수로 순환 참조 해결

---

## 2. Flutter 렌더링 성능

### 2.1 불필요한 재빌드

**평가: 양호 (80%)**

**우수 사례:**
- `const` 생성자 적극 사용
- Riverpod Provider 적절한 분리

**개선 필요:**
- 일부 긴 파일에서 StatefulWidget 남용
- Consumer 범위 최소화 권장

### 2.2 리스트 렌더링

**평가: 우수 (90%)**

**우수 사례:**
```dart
ListView.builder(
  itemCount: transactions.length,
  itemBuilder: (context, index) => ...
)
```

**페이지네이션:**
- Supabase `.range()` 사용 (양호)
- 무한 스크롤 미구현 (개선 가능)

---

## 3. 메모리 관리

### 3.1 Listener 해제

**평가: 우수 (95%)**

**우수 사례:**
```dart
@override
void dispose() {
  _controller.dispose();
  _subscription?.cancel();
  super.dispose();
}
```

### 3.2 캐싱

**평가: 양호 (80%)**

- Riverpod 자동 캐싱 활용
- 이미지 캐싱: `cached_network_image` 사용
- 일부 통계 데이터 캐싱 개선 가능

---

## 4. 네트워크 최적화

### 4.1 배치 요청

**평가: 개선 필요 (70%)**

**문제:**
- createInvite에서 연속 5회 쿼리

**권장:**
```sql
-- RPC 함수로 통합
CREATE OR REPLACE FUNCTION create_invite_with_validation(...)
RETURNS ...
AS $$
BEGIN
  -- 모든 검증을 한 번에 수행
END;
$$ LANGUAGE plpgsql;
```

### 4.2 실시간 구독

**평가: 우수 (90%)**

- Supabase Realtime 적절히 사용
- 불필요한 구독 없음

---

## 5. 앱 시작 시간

### 평가: 양호 (85%)

**분석:**
- Firebase 초기화: 필수
- Supabase 초기화: 가벼움
- SharedPreferences 로딩: 빠름

**개선 가능:**
- Splash 화면 최적화
- 지연 로딩 (Lazy Loading) 적용

---

## 6. 종합 평가

```
=====================================
  성능 분석 종합 점수: 88/100
=====================================

  DB 인덱싱:        90점  (6개 누락)
  N+1 쿼리:         95점  (대부분 최적화)
  Flutter 렌더링:   80점  (재빌드 최적화)
  메모리 관리:      95점  (Listener 해제)
  네트워크:         70점  (배치 요청)
  앱 시작:          85점  (지연 로딩)
=====================================
```

---

## 7. 권장 조치 사항

### Priority 1 (즉시)
1. **FK 인덱스 추가 (6개)**
   - transactions.user_id 우선

### Priority 2 (이번 주)
1. **createInvite RPC 함수 통합**
2. **통계 데이터 캐싱 개선**

### Priority 3 (이번 달)
1. **무한 스크롤 구현**
2. **지연 로딩 적용**
3. **성능 모니터링 설정**

---

**작성일**: 2026-02-01
**작성자**: Claude Code
**버전**: 1.0
