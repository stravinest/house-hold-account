# Phase 3: 상세 구현 계획

## 목표
AssetCategoryList를 CategoryRankingList 스타일로 redesign - 순위/백분율/Progress Bar + 접기/펼치기 기능

## 요구사항
- **옵션 C**: 하이브리드 (순위 헤더 + 접기/펼치기)
- **만기일**: 표시하지 않음
- **범위**: 한 번에 전체 redesign

## 현재 구조 분석

### AssetCategoryList (현재)
```dart
// 2-level 구조
Column(
  children: byCategory.map((category) {
    return Column([
      // 카테고리 헤더
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row([
          Text(category.categoryName), // 카테고리명
          Text('${amount} 원'),        // 총액
        ]),
      ),
      // 개별 아이템들
      ...category.items.map((item) {
        return ListTile(
          title: Text(item.title),
          subtitle: Text(dateInfo),    // 만기일 정보 (제거)
          trailing: Text('${amount} 원'),
        );
      }),
      Divider(),
    ]);
  }),
);
```

### CategoryRankingList (참조)
```dart
// 1-level 구조
ListView.separated(
  itemBuilder: (context, index) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column([
        Row([
          // 순위
          SizedBox(width: 24, child: Text('$rank')),
          SizedBox(width: 12),
          // 카테고리명
          Expanded(child: Text(category.categoryName)),
          // 백분율
          Text('${percentage.toStringAsFixed(1)}%'),
          SizedBox(width: 12),
          // 금액
          Text('${numberFormat.format(amount)}원'),
        ]),
        SizedBox(height: 8),
        // Progress Bar
        LinearProgressIndicator(value: percentage/100),
      ]),
    );
  },
);
```

## 구현 계획

### 1. 데이터 모델 변경점
- `CategoryAsset` → `AssetStatistics.byCategory` 그대로 사용
- 총액 계산: `AssetStatistics.totalAmount` 사용 (int → double 변환 필요)
- 백분율 계산: `(category.amount / totalAmount) * 100`

### 2. UI 구조 변경

#### A. 랭킹 계산
```dart
// byCategory를 amount 기준으로 정렬
final sortedCategories = byCategory
  ..sort((a, b) => b.amount.compareTo(a.amount));

// 랭킹 부여
for (int i = 0; i < sortedCategories.length; i++) {
  final rank = i + 1;
  // ...
}
```

#### B. ExpansionTile 구조
```dart
ExpansionTile(
  // 기본 접힘 상태
  initiallyExpanded: false,
  // 헤더: 순위/카테고리명/백분율/금액/Progress Bar
  title: Row([...]),
  // 내용: 개별 자산 아이템들 (만기일 제외)
  children: category.items.map((item) => ListTile(...)),
)
```

#### C. 순위 표시
```dart
// 1-3위: primary 색상, 볼드
// 그 외: onSurfaceVariant 색상, 일반
Text(
  '$rank',
  style: TextStyle(
    fontWeight: FontWeight.bold,
    color: rank <= 3 ? theme.colorScheme.primary
                     : theme.colorScheme.onSurfaceVariant,
  ),
)
```

#### D. Progress Bar
```dart
ClipRRect(
  borderRadius: BorderRadius.circular(4),
  child: LinearProgressIndicator(
    value: percentage / 100,
    backgroundColor: theme.colorScheme.surfaceContainerHighest,
    valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
    minHeight: 6,
  ),
)
```

### 3. 색상 파싱
```dart
Color _parseColor(String? colorString) {
  if (colorString == null) return Colors.grey;
  try {
    final colorValue = int.parse(colorString.replaceFirst('#', '0xFF'));
    return Color(colorValue);
  } catch (e) {
    return Colors.grey;
  }
}
```

### 4. 위젯 구조 변경

#### 현재: StatelessWidget
#### 변경: ConsumerWidget (총액 계산을 위해 AssetStatistics 필요)

### 5. 매개변수 변경
```dart
// 현재
class AssetCategoryList extends StatelessWidget {
  final List<CategoryAsset> byCategory;

  const AssetCategoryList({super.key, required this.byCategory});
}

// 변경
class AssetCategoryList extends ConsumerWidget {
  final AssetStatistics assetStatistics;

  const AssetCategoryList({super.key, required this.assetStatistics});
}
```

### 6. 호출부 변경 필요
- `lib/features/asset/presentation/pages/asset_page.dart`에서 호출 방식 변경

## 구현 순서

### Phase 4: 실행 계획
1. **AssetCategoryList 위젯 수정**
   - ConsumerWidget으로 변경
   - 매개변수 변경 (List<CategoryAsset> → AssetStatistics)
   - _parseColor 헬퍼 메서드 추가
   - 랭킹 계산 로직 추가
   - ExpansionTile 구조로 변경
   - Progress Bar 추가
   - 만기일 정보 제거

2. **호출부 수정**
   - asset_page.dart에서 호출 방식 변경

3. **테스트 및 검증**
   - UI 정상 표시 확인
   - 접기/펼치기 기능 확인
   - 순위/백분율/Progress Bar 표시 확인

## 파일 영향도

### 수정 파일
- `lib/features/asset/presentation/widgets/asset_category_list.dart` (전체 재작성)
- `lib/features/asset/presentation/pages/asset_page.dart` (호출 방식 변경)

### 영향 없는 파일
- 데이터 모델 (`asset_statistics.dart`)
- Repository 및 Provider

## 잠재적 문제점

### 1. 총액 계산
- `AssetStatistics.totalAmount`는 int, CategoryAsset.amount도 int
- 백분율 계산 시 double 변환 필요

### 2. 색상 파싱
- CategoryAsset.categoryColor가 null일 수 있음
- 기본 색상 (Colors.grey) 제공 필요

### 3. ExpansionTile 초기 상태
- `initiallyExpanded: false`로 설정하여 기본 접힘 상태 유지
