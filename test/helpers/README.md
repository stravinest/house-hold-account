# 테스트 헬퍼 가이드

프로젝트의 모든 테스트에서 사용할 수 있는 공통 테스트 헬퍼입니다.

## 파일 구조

```
test/helpers/
├── README.md                    # 이 문서
├── test_helpers.dart            # 통합 export 파일 (이것만 import하면 됨)
├── mock_supabase.dart          # Supabase 관련 Mock 클래스
├── mock_repositories.dart      # Repository Mock 클래스
├── mock_services.dart          # Service Mock 클래스
├── test_providers.dart         # Riverpod Provider 테스트 헬퍼
├── test_data_factory.dart      # 테스트 데이터 생성 Factory
└── example_usage_test.dart     # 사용 예시 테스트
```

## 사용 방법

### 1. Import

테스트 파일에서 다음과 같이 import합니다:

```dart
import '../helpers/test_helpers.dart';
```

### 2. 테스트 데이터 생성

`TestDataFactory`를 사용하여 간편하게 테스트 데이터를 생성할 수 있습니다.

```dart
test('거래 생성 테스트', () {
  // Given: 테스트 데이터 생성
  final ledger = TestDataFactory.ledger(name: '내 가계부');
  final category = TestDataFactory.category(name: '식비', icon: '🍔');
  final transaction = TestDataFactory.transaction(
    ledgerId: ledger.id,
    categoryId: category.id,
    amount: 50000,
    title: '점심 식사',
  );

  // When & Then
  expect(transaction.amount, equals(50000));
  expect(transaction.title, equals('점심 식사'));
});
```

### 3. Mock Repository 사용

`MockXxxRepository` 클래스를 사용하여 Repository를 mocking합니다.

```dart
import 'package:mocktail/mocktail.dart';

test('Repository mock 테스트', () {
  // Given: Mock Repository 생성
  final mockLedgerRepo = MockLedgerRepository();

  // When: stub 설정
  when(() => mockLedgerRepo.getLedger('test-id'))
      .thenAnswer((_) async => TestDataFactory.ledgerModel());

  // Then: Mock 사용
  final result = await mockLedgerRepo.getLedger('test-id');
  expect(result.id, equals('test-ledger-id'));
});
```

### 4. Mock Service 사용

Service도 동일한 방식으로 mocking할 수 있습니다.

```dart
test('Service mock 테스트', () {
  // Given: Mock Service 생성
  final mockSmsService = MockSmsParsingService();

  // When: stub 설정
  when(() => mockSmsService.parseSms(any()))
      .thenReturn(ParsedSmsData(...));

  // Then: Mock 사용
  final result = mockSmsService.parseSms('테스트 SMS');
  expect(result, isNotNull);
});
```

### 5. Riverpod Provider 테스트

Provider 테스트를 위한 다양한 헬퍼를 제공합니다.

#### ProviderContainer 생성

```dart
test('Provider 테스트', () {
  // Given: ProviderContainer 생성
  final container = createContainer(
    overrides: [
      myProvider.overrideWith((ref) => mockValue),
    ],
  );

  // When
  final value = container.read(myProvider);

  // Then
  expect(value, equals(mockValue));

  // Cleanup
  container.dispose();
});
```

#### AsyncValue 테스트

```dart
test('AsyncValue 상태 테스트', () {
  // Given
  final dataValue = AsyncValueTestHelpers.data(42);
  final loadingValue = AsyncValueTestHelpers.loading<int>();
  final errorValue = AsyncValueTestHelpers.error<int>(Exception('에러'));

  // Then
  expect(AsyncValueTestHelpers.isData(dataValue), isTrue);
  expect(AsyncValueTestHelpers.isLoading(loadingValue), isTrue);
  expect(AsyncValueTestHelpers.isError(errorValue), isTrue);
});
```

#### Provider 값 변화 추적

```dart
test('Provider 값 변화 추적', () {
  // Given
  final container = createContainer();
  final listener = ProviderListener<int>();

  // When: Provider 값 변화 감지
  container.listenTo(myProvider, listener);

  // Then: 변화 기록 확인
  expect(listener.callCount, equals(1));
  expect(listener.latest, equals(expectedValue));

  container.dispose();
});
```

### 6. Mock Supabase

Supabase 관련 클래스들의 Mock을 제공합니다.

```dart
test('Supabase mock 테스트', () {
  // Given: Mock Supabase 클래스
  final mockClient = MockSupabaseClient();
  final mockAuth = MockGoTrueClient();
  final mockUser = MockUser();

  // When: stub 설정
  when(() => mockClient.auth).thenReturn(mockAuth);
  when(() => mockAuth.currentUser).thenReturn(mockUser);
  when(() => mockUser.id).thenReturn('test-user-id');

  // Then
  expect(mockClient.auth.currentUser?.id, equals('test-user-id'));
});
```

## 사용 가능한 Mock 클래스

### Repository Mocks

- `MockLedgerRepository`
- `MockTransactionRepository`
- `MockCategoryRepository`
- `MockAssetRepository`
- `MockStatisticsRepository`
- `MockPaymentMethodRepository`
- `MockPendingTransactionRepository`
- `MockLearnedSmsFormatRepository`
- `MockLearnedPushFormatRepository`
- `MockShareRepository`
- `MockFcmTokenRepository`
- `MockNotificationSettingsRepository`
- `MockFixedExpenseCategoryRepository`
- `MockFixedExpenseSettingsRepository`

### Service Mocks

- `MockGoogleSignInService`
- `MockNotificationService`
- `MockFirebaseMessagingService`
- `MockLocalNotificationService`
- `MockSmsParsingService`
- `MockSmsListenerService`
- `MockSmsScannerService`
- `MockAutoSaveService`
- `MockCategoryMappingService`
- `MockDuplicateCheckService`
- `MockNativeNotificationSyncService`
- `MockDebugTestService`
- `MockAppBadgeService`
- `MockExportService`
- `MockWidgetDataService`

### Supabase Mocks

- `MockSupabaseClient`
- `MockGoTrueClient`
- `MockUser`
- `MockSession`
- `MockSupabaseQueryBuilder`
- `MockPostgrestFilterBuilder`
- `MockPostgrestTransformBuilder`
- `MockPostgrestBuilder`
- `MockRealtimeChannel`
- `MockRealtimeClient`
- `MockStorageFileApi`
- `MockSupabaseStorageClient`
- `MockAuthResponse`
- `MockUserResponse`

## TestDataFactory 메서드

### Ledger

```dart
TestDataFactory.ledger(
  id: 'custom-id',
  name: '나의 가계부',
  currency: 'KRW',
  ownerId: 'user-id',
  isShared: false,
);
```

### Transaction

```dart
TestDataFactory.transaction(
  id: 'transaction-id',
  ledgerId: 'ledger-id',
  amount: 50000,
  type: 'expense',
  title: '점심 식사',
  date: DateTime(2026, 2, 12),
);
```

### Category

```dart
TestDataFactory.category(
  name: '식비',
  icon: '🍔',
  color: '#FF5733',
  type: 'expense',
);
```

### PaymentMethod

```dart
TestDataFactory.paymentMethod(
  name: 'KB카드',
  icon: '💳',
  canAutoSave: true,
  autoSaveMode: AutoSaveMode.suggest,
);
```

### 여러 데이터 생성

```dart
// 5개의 거래 목록
final transactions = TestDataFactory.transactions(count: 5);

// 5개의 카테고리 목록
final categories = TestDataFactory.categories(count: 5, type: 'expense');
```

## 베스트 프랙티스

### 1. Mock 재사용

```dart
class MockLedgerRepositoryTest {
  late MockLedgerRepository mockRepo;

  setUp() {
    mockRepo = MockLedgerRepository();
  }

  tearDown() {
    reset(mockRepo);
  }
}
```

### 2. TestDataFactory 커스터마이징

```dart
// 프로젝트 특정 데이터 패턴이 있다면 확장 가능
class MyTestDataFactory extends TestDataFactory {
  static Transaction expenseTransaction({int amount = 10000}) {
    return TestDataFactory.transaction(
      type: 'expense',
      amount: amount,
      categoryId: 'expense-category-id',
    );
  }
}
```

### 3. Provider 테스트 패턴

```dart
test('Provider 테스트 템플릿', () async {
  // Given
  final container = createContainer();
  addTearDown(container.dispose); // 자동 cleanup

  // When
  final result = await container.read(myProvider.future);

  // Then
  expect(result, expectedValue);
});
```

## 예시 테스트 실행

```bash
flutter test test/helpers/example_usage_test.dart
```

## 문의 및 기여

새로운 Mock이나 헬퍼가 필요한 경우, `test/helpers/` 디렉토리에 추가하고 `test_helpers.dart`에서 export하세요.
