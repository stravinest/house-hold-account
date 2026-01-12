# 현황 분석 결과

## 수정 대상: 고정비 체크 시 카테고리 UI 통합

### 요청 내용
1. "고정비로 등록" 체크 시 기존 "카테고리" 섹션이 고정비 카테고리로 교체
2. 선택 안함 옵션 제공
3. 고정비 카테고리도 FilterChip 스타일로 표시
4. 추가/삭제 기능 제공

### 관련 파일
- lib/features/transaction/presentation/widgets/add_transaction_sheet.dart
- lib/features/transaction/presentation/widgets/recurring_settings_widget.dart
- lib/features/fixed_expense/presentation/providers/fixed_expense_category_provider.dart
- lib/features/fixed_expense/data/repositories/fixed_expense_category_repository.dart

### 현재 UI/UX 상태

#### 현재 동작
1. 사용자가 반복 설정에서 "고정비로 등록" 체크
2. 고정비 카테고리 드롭다운이 반복 설정 위젯 내에 표시
3. 기존 "카테고리" 섹션은 그대로 유지됨 (두 카테고리 선택 영역 존재)

#### 문제점
- 고정비 카테고리가 DropdownButtonFormField로 일반 카테고리와 UI 불일치
- 고정비 카테고리 추가/삭제가 설정 페이지에서만 가능
- 고정비 체크 시 기존 카테고리 섹션과 별도로 드롭다운이 추가되어 혼란

### 요구되는 변경

#### add_transaction_sheet.dart
1. `_buildCategoryGrid` 메서드 수정
   - `_recurringSettings.isFixedExpense` 체크
   - true면 고정비 카테고리 목록 표시
   - false면 일반 카테고리 목록 표시

2. 고정비 카테고리 추가/삭제 기능 구현
   - `_showAddFixedExpenseCategoryDialog()` 메서드 추가
   - `_deleteFixedExpenseCategory()` 메서드 추가

3. 상태 관리
   - `_selectedFixedExpenseCategory` 상태 추가
   - 고정비 체크 시 일반 카테고리 선택 해제
   - 고정비 체크 해제 시 고정비 카테고리 선택 해제

#### recurring_settings_widget.dart
1. 고정비 카테고리 드롭다운 제거 (더 이상 필요 없음)
2. 고정비 체크 상태만 전달

### 식별된 엣지 케이스
1. 일반 카테고리 선택 후 고정비 체크 시: 일반 카테고리 선택 해제
2. 고정비 카테고리 선택 후 고정비 체크 해제 시: 고정비 카테고리 선택 해제
3. 고정비 카테고리가 0개일 때: 추가 버튼만 표시
4. 거래 수정 시: 기존 고정비 카테고리 표시
5. 반복 설정 해제 시: 고정비 상태도 해제

### 의존성
- RecurringSettings.isFixedExpense: 고정비 체크 상태
- fixedExpenseCategoriesProvider: 고정비 카테고리 목록 제공
- fixedExpenseCategoryNotifierProvider: 고정비 카테고리 CRUD
