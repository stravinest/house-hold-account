# Task: 자산(Asset) 관리 기능 구현

## 메타 정보
- 생성일: 2026-01-12
- 상태: 계획 수립 완료
- 예상 소요 시간: 4일

## 관련 문서
- PRD: prd.md

---

## Phase 1: 데이터베이스 스키마 설계 및 마이그레이션 (0.5일)

### 작업 목표
- transactions 테이블에 is_asset, maturity_date 컬럼 추가
- 예산 기능 제거 (budgets 테이블, 관련 RLS 정책)
- 데이터 무결성 보장

### 작업 항목

#### 1.1 마이그레이션 파일 작성 (난이도: ⭐, 1시간)
- [ ] **파일**: `supabase/migrations/014_add_asset_features.sql`
- [ ] **내용**:
  ```sql
  -- 1. transactions 테이블에 자산 관련 컬럼 추가
  ALTER TABLE transactions
  ADD COLUMN is_asset BOOLEAN DEFAULT FALSE,
  ADD COLUMN maturity_date DATE;
  
  -- 2. is_asset 인덱스 추가 (성능 최적화)
  CREATE INDEX IF NOT EXISTS idx_transactions_is_asset 
  ON transactions(is_asset) WHERE is_asset = TRUE;
  
  -- 3. maturity_date 인덱스 추가
  CREATE INDEX IF NOT EXISTS idx_transactions_maturity_date 
  ON transactions(maturity_date) WHERE maturity_date IS NOT NULL;
  
  -- 4. budgets 테이블 삭제 (예산 기능 제거)
  DROP TABLE IF EXISTS budgets CASCADE;
  ```

#### 1.2 마이그레이션 테스트 (난이도: ⭐, 30분)
- [ ] Supabase 콘솔에서 마이그레이션 실행
- [ ] transactions 테이블 스키마 확인
- [ ] 기존 데이터 무결성 확인 (저축 타입 거래 정상 조회)

#### 1.3 RLS 정책 검토 (난이도: ⭐, 30분)
- [ ] transactions 테이블 RLS 정책이 is_asset 컬럼에도 적용되는지 확인
- [ ] 필요시 정책 업데이트 (현재는 별도 정책 불필요 예상)

**예상 소요 시간**: 2시간  
**의존성**: 없음  
**산출물**: `014_add_asset_features.sql`

---

## Phase 2: Domain 및 Data 레이어 구현 (1일)

### 작업 목표
- Transaction 엔티티 확장 (is_asset, maturity_date)
- AssetRepository 구현 (자산 집계 로직)
- AssetStatistics 모델 정의

### 작업 항목

#### 2.1 Transaction 엔티티 확장 (난이도: ⭐, 30분)
- [ ] **파일**: `lib/features/transaction/domain/entities/transaction.dart`
- [ ] **수정 내용**:
  ```dart
  class Transaction {
    // 기존 필드...
    final bool isAsset;
    final DateTime? maturityDate;
    
    // getter 추가
    bool get isAssetTransaction => type == 'saving' && isAsset == true;
  }
  ```
- [ ] `fromJson`, `copyWith` 메서드 업데이트

#### 2.2 Asset 통계 엔티티 정의 (난이도: ⭐, 1시간)
- [ ] **파일**: `lib/features/asset/domain/entities/asset_statistics.dart` (신규)
- [ ] **내용**:
  ```dart
  class AssetStatistics {
    final int totalAmount;           // 총 자산
    final int monthlyChange;         // 이번 달 변동
    final List<MonthlyAsset> monthly; // 월별 자산 (6개월)
    final List<CategoryAsset> byCategory; // 카테고리별 자산
  }
  
  class MonthlyAsset {
    final int year;
    final int month;
    final int amount;
  }
  
  class CategoryAsset {
    final String categoryId;
    final String categoryName;
    final String? categoryIcon;
    final String? categoryColor;
    final int amount;
    final List<AssetItem> items; // 개별 자산 항목
  }
  
  class AssetItem {
    final String id;
    final String title;
    final int amount;
    final DateTime? maturityDate;
  }
  ```

#### 2.3 AssetRepository 구현 (난이도: ⭐⭐⭐, 4시간)
- [ ] **파일**: `lib/features/asset/data/repositories/asset_repository.dart` (신규)
- [ ] **메서드**:
  ```dart
  class AssetRepository {
    final SupabaseClient _client;
    
    // 총 자산 계산 (저축 타입 누적 합계)
    Future<int> getTotalAssets({required String ledgerId});
    
    // 이번 달 변동 계산
    Future<int> getMonthlyChange({
      required String ledgerId,
      required int year,
      required int month,
    });
    
    // 월별 자산 변화 (최근 6개월)
    Future<List<MonthlyAsset>> getMonthlyAssets({
      required String ledgerId,
      int months = 6,
    });
    
    // 카테고리별 자산 집계
    Future<List<CategoryAsset>> getAssetsByCategory({
      required String ledgerId,
    });
  }
  ```
- [ ] **쿼리 구현**:
  ```sql
  -- 총 자산: 저축 타입 거래 누적 합계
  SELECT COALESCE(SUM(amount), 0) as total
  FROM transactions
  WHERE ledger_id = ? AND type = 'saving' AND is_asset = TRUE
  
  -- 월별 자산: 각 월말 기준 누적 합계
  WITH RECURSIVE months AS (
    SELECT date_trunc('month', CURRENT_DATE - INTERVAL '5 months') AS month_start
    UNION ALL
    SELECT month_start + INTERVAL '1 month'
    FROM months
    WHERE month_start < date_trunc('month', CURRENT_DATE)
  )
  SELECT 
    EXTRACT(YEAR FROM m.month_start) as year,
    EXTRACT(MONTH FROM m.month_start) as month,
    COALESCE(SUM(t.amount), 0) as amount
  FROM months m
  LEFT JOIN transactions t ON 
    t.ledger_id = ? AND
    t.type = 'saving' AND
    t.is_asset = TRUE AND
    t.date <= (m.month_start + INTERVAL '1 month' - INTERVAL '1 day')
  GROUP BY m.month_start
  ORDER BY m.month_start
  ```

#### 2.4 Repository 테스트 (난이도: ⭐⭐, 2시간)
- [ ] **파일**: `test/features/asset/data/repositories/asset_repository_test.dart`
- [ ] 테스트 케이스:
  - 총 자산 계산 정확성
  - 월별 변동 계산 정확성
  - 카테고리별 집계 정확성
  - 빈 데이터 처리

**예상 소요 시간**: 7.5시간  
**의존성**: Phase 1 완료  
**산출물**: Asset 관련 Entity, Repository

---

## Phase 3: Presentation 레이어 구현 (2일)

### 작업 목표
- Asset 화면 UI 구현 (Line 차트, Donut 차트, 리스트)
- AddTransactionSheet 수정 (만기일 입력)
- home_page.dart 수정 (예산 탭 → 자산 탭)

### 작업 3.1: Asset Provider 구현 (난이도: ⭐⭐, 2시간)

#### 3.1.1 AssetProvider 작성
- [ ] **파일**: `lib/features/asset/presentation/providers/asset_provider.dart` (신규)
- [ ] **내용**:
  ```dart
  @riverpod
  Future<AssetStatistics> assetStatistics(AssetStatisticsRef ref) async {
    final ledgerId = ref.watch(selectedLedgerIdProvider);
    if (ledgerId == null) throw Exception('No ledger selected');
    
    final repository = ref.read(assetRepositoryProvider);
    
    final total = await repository.getTotalAssets(ledgerId: ledgerId);
    final change = await repository.getMonthlyChange(
      ledgerId: ledgerId,
      year: DateTime.now().year,
      month: DateTime.now().month,
    );
    final monthly = await repository.getMonthlyAssets(ledgerId: ledgerId);
    final byCategory = await repository.getAssetsByCategory(ledgerId: ledgerId);
    
    return AssetStatistics(
      totalAmount: total,
      monthlyChange: change,
      monthly: monthly,
      byCategory: byCategory,
    );
  }
  ```

### 작업 3.2: Line 차트 구현 (난이도: ⭐⭐⭐, 3시간)

#### 3.2.1 AssetLineChart 위젯 작성
- [ ] **파일**: `lib/features/asset/presentation/widgets/asset_line_chart.dart` (신규)
- [ ] **참고**: `lib/features/statistics/presentation/widgets/trend_tab/trend_bar_chart.dart`
- [ ] **fl_chart 사용**:
  ```dart
  LineChart(
    LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: monthlyAssets.map((m) => FlSpot(x, y)).toList(),
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          dotData: FlDotData(show: true),
        ),
      ],
      titlesData: FlTitlesData(...), // 월 레이블
      borderData: FlBorderData(...),
      gridData: FlGridData(...),
    ),
  )
  ```

### 작업 3.3: Donut 차트 구현 (난이도: ⭐⭐, 1.5시간)

#### 3.3.1 AssetDonutChart 위젯 작성
- [ ] **파일**: `lib/features/asset/presentation/widgets/asset_donut_chart.dart` (신규)
- [ ] **참고**: `lib/features/statistics/presentation/widgets/category_tab/category_donut_chart.dart`
- [ ] 카테고리별 비율 표시
- [ ] 중앙에 총 자산 표시

### 작업 3.4: 카테고리별 리스트 구현 (난이도: ⭐⭐, 2시간)

#### 3.4.1 AssetCategoryList 위젯 작성
- [ ] **파일**: `lib/features/asset/presentation/widgets/asset_category_list.dart` (신규)
- [ ] 카테고리별 그룹화
- [ ] 각 카테고리 내 개별 자산 항목 표시
- [ ] 만기일 표시 (있는 경우)

### 작업 3.5: AssetPage 통합 (난이도: ⭐⭐, 2시간)

#### 3.5.1 AssetPage 작성
- [ ] **파일**: `lib/features/asset/presentation/pages/asset_page.dart` (신규)
- [ ] **레이아웃**:
  ```dart
  Column(
    children: [
      _AssetSummaryCard(statistics), // 총 자산 + 변동
      SizedBox(height: 16),
      AssetLineChart(monthly: statistics.monthly),
      SizedBox(height: 16),
      AssetDonutChart(byCategory: statistics.byCategory),
      SizedBox(height: 16),
      AssetCategoryList(byCategory: statistics.byCategory),
    ],
  )
  ```
- [ ] RefreshIndicator 추가

### 작업 3.6: 거래 추가 시트 수정 (난이도: ⭐⭐, 2시간)

#### 3.6.1 AddTransactionSheet 수정
- [ ] **파일**: `lib/features/transaction/presentation/widgets/add_transaction_sheet.dart`
- [ ] 저축 타입 선택 시:
  - [ ] 만기 체크박스 추가
  - [ ] 만기일 입력 필드 추가 (DatePicker)
  - [ ] 만기일 입력 시 반복 주기 종료일 자동 설정
- [ ] UI 수정:
  ```dart
  if (_type == 'saving') ...[
    CheckboxListTile(
      title: Text('자산으로 등록 (만기 설정)'),
      value: _isAsset,
      onChanged: (value) {
        setState(() => _isAsset = value ?? false);
      },
    ),
    if (_isAsset) ...[
      ListTile(
        title: Text('만기일'),
        subtitle: Text(_maturityDate != null 
          ? DateFormat('yyyy-MM-dd').format(_maturityDate!) 
          : '선택 안함'),
        onTap: _selectMaturityDate,
      ),
    ],
  ],
  ```

#### 3.6.2 TransactionRepository 수정
- [ ] **파일**: `lib/features/transaction/data/repositories/transaction_repository.dart`
- [ ] `createTransaction` 메서드에 `isAsset`, `maturityDate` 파라미터 추가
- [ ] Supabase 저장 로직 업데이트

### 작업 3.7: home_page.dart 수정 (난이도: ⭐, 30분)

#### 3.7.1 예산 탭을 자산 탭으로 교체
- [ ] **파일**: `lib/features/ledger/presentation/pages/home_page.dart`
- [ ] BudgetTabView → AssetTabView 교체
- [ ] NavigationDestination 아이콘 변경:
  ```dart
  NavigationDestination(
    icon: Icon(Icons.account_balance), // 자산
    selectedIcon: Icon(Icons.account_balance),
    label: '',
  ),
  ```

### 작업 3.8: Budget 기능 제거 (난이도: ⭐, 1시간)

#### 3.8.1 파일 삭제
- [ ] `lib/features/budget/` 전체 폴더 삭제
- [ ] 관련 import 제거

#### 3.8.2 라우팅 업데이트
- [ ] `lib/config/router.dart`에서 budget 관련 라우트 제거 (있는 경우)

**예상 소요 시간**: 14시간 (2일)  
**의존성**: Phase 2 완료  
**산출물**: Asset 화면, 수정된 거래 추가 시트

---

## Phase 4: 통합 및 테스트 (0.5일)

### 작업 목표
- 전체 플로우 테스트
- 버그 수정
- 코드 리뷰

### 작업 항목

#### 4.1 기능 테스트 (난이도: ⭐⭐, 2시간)
- [ ] 저축 거래 추가 → 자산으로 등록 → 만기일 설정
- [ ] 자산 탭에서 Line 차트 확인
- [ ] 자산 탭에서 Donut 차트 확인
- [ ] 카테고리별 리스트 확인
- [ ] 총 자산 계산 정확성 확인

#### 4.2 에지 케이스 테스트 (난이도: ⭐⭐, 1.5시간)
- [ ] 자산이 없는 경우 (빈 상태 표시)
- [ ] 카테고리가 하나만 있는 경우
- [ ] 만기일이 없는 자산
- [ ] 음수 자산 (출금) 처리

#### 4.3 코드 품질 검사 (난이도: ⭐, 30분)
- [ ] `flutter analyze` 실행 (0 issues)
- [ ] 주석 정리
- [ ] 네이밍 일관성 확인

**예상 소요 시간**: 4시간  
**의존성**: Phase 3 완료  
**산출물**: 완성된 자산 기능

---

## 전체 파일 구조

### 신규 파일
```
lib/features/asset/
├── domain/
│   └── entities/
│       └── asset_statistics.dart
├── data/
│   └── repositories/
│       └── asset_repository.dart
└── presentation/
    ├── pages/
    │   └── asset_page.dart
    ├── widgets/
    │   ├── asset_line_chart.dart
    │   ├── asset_donut_chart.dart
    │   ├── asset_category_list.dart
    │   └── asset_summary_card.dart
    └── providers/
        └── asset_provider.dart

supabase/migrations/
└── 014_add_asset_features.sql
```

### 수정 파일
```
lib/features/transaction/
├── domain/entities/transaction.dart
├── data/repositories/transaction_repository.dart
└── presentation/widgets/add_transaction_sheet.dart

lib/features/ledger/presentation/pages/home_page.dart
```

### 삭제 파일
```
lib/features/budget/ (전체 폴더)
```

---

## 체크리스트 요약

### Phase 1: DB 설계 (0.5일)
- [ ] 마이그레이션 파일 작성
- [ ] 마이그레이션 실행 및 테스트
- [ ] RLS 정책 검토

### Phase 2: Domain/Data (1일)
- [ ] Transaction 엔티티 확장
- [ ] AssetStatistics 엔티티 정의
- [ ] AssetRepository 구현
- [ ] Repository 테스트

### Phase 3: Presentation (2일)
- [ ] AssetProvider 구현
- [ ] AssetLineChart 위젯
- [ ] AssetDonutChart 위젯
- [ ] AssetCategoryList 위젯
- [ ] AssetPage 통합
- [ ] AddTransactionSheet 수정
- [ ] home_page.dart 수정
- [ ] Budget 기능 제거

### Phase 4: 통합/테스트 (0.5일)
- [ ] 기능 테스트
- [ ] 에지 케이스 테스트
- [ ] 코드 품질 검사

---

## 주의사항

### 기술적 고려사항
1. **누적 합계 계산**: 월별 자산은 각 월말까지의 누적 합계로 계산
2. **저축 vs 자산**: `type='saving' AND is_asset=TRUE`로 구분
3. **만기일 연동**: 만기일 설정 시 `recurring_end_date` 자동 설정
4. **카테고리**: 자산 카테고리는 `type='saving'` 카테고리 활용

### 성능 최적화
1. 인덱스 활용 (is_asset, maturity_date)
2. 월별 자산 계산 시 CTE 사용
3. Provider 캐싱 활용

### UI/UX
1. Line 차트는 최근 6개월만 표시 (성능)
2. Donut 차트는 상위 5개 + 기타 (가독성)
3. 빈 상태 처리 (자산이 없을 때)
4. 만기일은 선택 사항 (필수 아님)

---

## 예상 리스크 및 대응

### 리스크 1: 누적 합계 쿼리 성능
**대응**: 인덱스 추가, 월별 집계 테이블 고려 (추후)

### 리스크 2: Line 차트 구현 복잡도
**대응**: fl_chart 공식 예제 참고, 기존 Bar 차트 로직 재사용

### 리스크 3: Budget 기능 사용자 존재
**대응**: 현재 사용자 없음 가정, 만약 있다면 마이그레이션 계획 수립

---

## 완료 기준

✅ 모든 Phase의 체크리스트 완료  
✅ `flutter analyze` 0 issues  
✅ 기능 테스트 통과  
✅ 자산 탭이 정상 작동  
✅ 만기일 설정이 반복 주기와 연동됨
