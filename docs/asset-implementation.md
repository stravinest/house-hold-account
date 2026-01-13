# 자산 관리 기능 구현 완료

## 개요

저축(saving) 타입을 자산(asset) 타입으로 통합하고, 투자, 부동산 등 다양한 자산을 관리할 수 있는 기능을 추가했습니다.

## 주요 변경사항

### 1. 타입 변경: `saving` → `asset`

**거래 타입:**
- 기존: `income` (수입), `expense` (지출), `saving` (저축)
- 변경: `income` (수입), `expense` (지출), `asset` (자산)

### 2. 자산 카테고리 추가

**기본 카테고리:**
- 💰 정기예금
- 💵 적금
- 📊 주식
- 📈 펀드
- 🏠 부동산
- 🪙 암호화폐
- 📌 기타 자산

**카테고리 그룹:**
- 저축: 정기예금, 적금
- 투자: 주식, 펀드, 암호화폐
- 부동산: 부동산

### 3. 거래 추가 UI 개선

**자산 탭:**
- [지출] [수입] [자산] 3개 탭으로 구성
- 자산 선택 시 만기일 입력 가능
- 만기일이 있는 자산: 만기일 기준 알림
- 만기일이 없는 자산: 보유 중 표시

### 4. 자산 페이지 개선

**TabBar 추가:**
- 전체: 모든 자산 표시
- 저축: 정기예금, 적금
- 투자: 주식, 펀드, 암호화폐
- 부동산: 부동산

**표시 정보:**
- 카테고리별 아이콘 및 색상
- 만기일 남은 일수 / 보유 기간
- 카테고리별 총액 및 개별 자산 금액

## 데이터베이스 마이그레이션

### 015_convert_saving_to_asset.sql

```sql
UPDATE transactions SET type = 'asset' WHERE type = 'saving';
UPDATE categories SET type = 'asset' WHERE type = 'saving';
UPDATE recurring_templates SET type = 'asset' WHERE type = 'saving';

ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_type_check;
ALTER TABLE transactions ADD CONSTRAINT transactions_type_check 
  CHECK (type IN ('income', 'expense', 'asset'));

ALTER TABLE categories DROP CONSTRAINT IF EXISTS categories_type_check;
ALTER TABLE categories ADD CONSTRAINT categories_type_check 
  CHECK (type IN ('income', 'expense', 'asset'));

ALTER TABLE recurring_templates DROP CONSTRAINT IF EXISTS recurring_templates_type_check;
ALTER TABLE recurring_templates ADD CONSTRAINT recurring_templates_type_check 
  CHECK (type IN ('income', 'expense', 'asset'));

UPDATE transactions 
SET is_asset = true 
WHERE type = 'asset' AND is_asset IS NULL;
```

### 016_add_asset_categories.sql

모든 가계부에 기본 자산 카테고리 자동 생성

## 코드 변경사항

### 엔티티 수정

**Transaction:**
- `type` 주석: `// income, expense, asset`
- `bool get isAssetType => type == 'asset';`

**Category:**
- `type` 주석: `// income, expense, asset`
- `bool get isAssetType => type == 'asset';`

### 상수 추가

**AppConstants:**
```dart
static const String transactionTypeAsset = 'asset';
```

**AssetConstants (신규):**
```dart
static const Map<String, IconData> categoryIcons = {
  '정기예금': Icons.savings,
  '적금': Icons.account_balance,
  '주식': Icons.trending_up,
  '펀드': Icons.pie_chart,
  '부동산': Icons.home,
  '암호화폐': Icons.currency_bitcoin,
  '기타 자산': Icons.wallet,
};

static const Map<String, Color> categoryColors = { ... };

static IconData getCategoryIcon(String categoryName) { ... }
static Color getCategoryColor(String categoryName) { ... }
static String getCategoryGroup(String categoryName) { ... }
```

### UI 컴포넌트

**AddTransactionSheet:**
- 자산 타입 선택 시 만기일 입력 필드 표시
- `DateTime? _maturityDate` 상태 추가

**AssetPage:**
- TabBar 추가 (전체/저축/투자/부동산)
- 탭별 필터링 로직 구현

**AssetCategoryList:**
- AssetConstants의 아이콘/색상 사용
- 만기일/보유기간 표시 개선

## 사용자 가이드

### 자산 추가 방법

1. 홈 화면에서 + 버튼 터치
2. [자산] 탭 선택
3. 카테고리 선택 (정기예금, 주식 등)
4. 금액 및 제목 입력
5. 만기일이 있는 경우 만기일 선택 (선택사항)
6. 저장

### 자산 조회 방법

1. 하단 네비게이션 [자산] 탭 이동
2. 상단 탭으로 필터링
   - 전체: 모든 자산
   - 저축: 정기예금, 적금
   - 투자: 주식, 펀드, 암호화폐
   - 부동산: 부동산
3. 카테고리별로 그룹화되어 표시

### 만기일 관리

- 만기일이 있는 자산: "만기 N일 남음" 표시
- 만기가 지난 자산: "만기 N일 지남" 표시
- 만기일이 없는 자산: "보유 중" 표시

## 향후 개선 사항 (미구현)

### 자산 알림 기능
- 만기일 7일 전 푸시 알림
- 보유 기간 1년 기념 알림

### 자산 통계 개선
- 자산 타입별 비중 차트
- 월별 자산 증감 상세 내역
- 연평균 자산 증가율

### 자산 목표 설정
- 목표 자산액 설정
- 진행률 표시
- 목표 달성 예상 시기

## 테스트

### 수동 테스트 항목

1. 자산 추가
   - [ ] 각 카테고리별 자산 추가 가능
   - [ ] 만기일 설정/미설정 모두 가능
   - [ ] 자산 추가 후 자산 페이지에 표시 확인

2. 자산 조회
   - [ ] 전체 탭에 모든 자산 표시
   - [ ] 저축/투자/부동산 탭별 필터링 정상 작동
   - [ ] 아이콘 및 색상 정상 표시
   - [ ] 만기일/보유기간 정상 표시

3. 통계
   - [ ] 총 자산 금액 정확히 표시
   - [ ] 카테고리별 분포 도넛 차트 정상 작동
   - [ ] 자산 변화 라인 차트 정상 작동

### 빌드 테스트

```bash
flutter analyze
# 결과: 20 issues (경고만, 에러 없음)

flutter pub run build_runner build --delete-conflicting-outputs
# 결과: 성공 (9초, 6개 outputs)
```

## 참고사항

- 기존 저축 데이터는 자동으로 자산으로 마이그레이션됨
- 모든 가계부에 자동으로 기본 자산 카테고리 생성
- UI 텍스트 "저축"이 모두 "자산"으로 변경됨
