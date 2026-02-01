import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/domain/entities/ledger.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('가계부 자동 선택 및 복원 로직 테스트', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('저장된 가계부 ID가 유효한 경우 복원되어야 함', () async {
      // Given: SharedPreferences에 저장된 가계부 ID
      const savedLedgerId = 'saved-ledger-id';
      SharedPreferences.setMockInitialValues({
        'current_ledger_id': savedLedgerId,
      });

      // When: restoreLedgerIdProvider 호출
      final restoredId = await container.read(restoreLedgerIdProvider.future);

      // Then: 저장된 ID가 복원됨
      expect(restoredId, equals(savedLedgerId));
    });

    test('저장된 가계부 ID가 없는 경우 null 반환', () async {
      // Given: 빈 SharedPreferences
      SharedPreferences.setMockInitialValues({});

      // When: restoreLedgerIdProvider 호출
      final restoredId = await container.read(restoreLedgerIdProvider.future);

      // Then: null 반환
      expect(restoredId, isNull);
    });

    test('selectedLedgerIdProvider 변경 시 SharedPreferences에 저장', () async {
      // Given: ledgerIdPersistenceProvider 구독
      container.read(ledgerIdPersistenceProvider);

      // When: selectedLedgerIdProvider 변경
      const newLedgerId = 'new-ledger-id';
      container.read(selectedLedgerIdProvider.notifier).state = newLedgerId;

      // Wait for async operation
      await Future.delayed(const Duration(milliseconds: 100));

      // Then: SharedPreferences에 저장됨
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('current_ledger_id');
      expect(savedId, equals(newLedgerId));
    });
  });

  group('Ledger 엔티티 테스트', () {
    test('ownerId가 올바르게 설정되어야 함', () {
      // Given: 가계부 엔티티 생성
      final ledger = Ledger(
        id: 'ledger-1',
        name: '내 가계부',
        currency: 'KRW',
        ownerId: 'user-123',
        isShared: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Then: ownerId가 올바르게 설정됨
      expect(ledger.ownerId, equals('user-123'));
      expect(ledger.isShared, isFalse);
    });

    test('공유 가계부는 isShared가 true여야 함', () {
      // Given: 공유 가계부 엔티티 생성
      final ledger = Ledger(
        id: 'ledger-2',
        name: '공유 가계부',
        currency: 'KRW',
        ownerId: 'user-123',
        isShared: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Then: isShared가 true
      expect(ledger.isShared, isTrue);
    });
  });

  group('복원 로직 시나리오 시뮬레이션', () {
    test('내 가계부 우선 선택 로직 검증', () {
      // Given: 여러 가계부 목록 (내 가계부 + 공유 가계부)
      const userId = 'user-123';
      final now = DateTime.now();
      final ledgers = [
        Ledger(
          id: 'shared-ledger',
          name: '공유 가계부',
          currency: 'KRW',
          ownerId: 'user-456', // 다른 사람 소유
          isShared: true,
          createdAt: now,
          updatedAt: now,
        ),
        Ledger(
          id: 'my-ledger',
          name: '내 가계부',
          currency: 'KRW',
          ownerId: userId, // 내 가계부
          isShared: false,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      // When: 내 가계부 찾기
      final myLedger = ledgers.firstWhere(
        (ledger) => ledger.ownerId == userId,
      );

      // Then: 내 가계부가 선택됨
      expect(myLedger.id, equals('my-ledger'));
      expect(myLedger.ownerId, equals(userId));
    });

    test('저장된 ID 유효성 검증 로직', () {
      // Given: 가계부 목록
      final now = DateTime.now();
      final ledgers = [
        Ledger(
          id: 'ledger-1',
          name: '가계부 1',
          currency: 'KRW',
          ownerId: 'user-123',
          isShared: false,
          createdAt: now,
          updatedAt: now,
        ),
        Ledger(
          id: 'ledger-2',
          name: '가계부 2',
          currency: 'KRW',
          ownerId: 'user-123',
          isShared: false,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      // When: 유효한 ID 검증
      const validId = 'ledger-1';
      final isValid = ledgers.any((ledger) => ledger.id == validId);

      // Then: 유효함
      expect(isValid, isTrue);

      // When: 무효한 ID 검증
      const invalidId = 'ledger-999';
      final isInvalid = ledgers.any((ledger) => ledger.id == invalidId);

      // Then: 무효함
      expect(isInvalid, isFalse);
    });

    test('가계부가 없을 때 폴백 처리', () {
      // Given: 빈 가계부 목록
      final ledgers = <Ledger>[];

      // When: 빈 목록 체크
      final isEmpty = ledgers.isEmpty;

      // Then: 비어있음
      expect(isEmpty, isTrue);
    });

    test('첫 번째 가계부 폴백 선택', () {
      // Given: 내 가계부가 없는 경우
      final now = DateTime.now();
      final ledgers = [
        Ledger(
          id: 'shared-ledger-1',
          name: '공유 가계부 1',
          currency: 'KRW',
          ownerId: 'user-456',
          isShared: true,
          createdAt: now,
          updatedAt: now,
        ),
        Ledger(
          id: 'shared-ledger-2',
          name: '공유 가계부 2',
          currency: 'KRW',
          ownerId: 'user-789',
          isShared: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      const userId = 'user-123';

      // When: 내 가계부 찾기 실패 → 첫 번째 가계부 선택
      try {
        ledgers.firstWhere((ledger) => ledger.ownerId == userId);
        fail('내 가계부가 있으면 안 됨');
      } catch (_) {
        // 내 가계부 없음 → 첫 번째 가계부 선택
        final firstLedger = ledgers.first;

        // Then: 첫 번째 가계부가 선택됨
        expect(firstLedger.id, equals('shared-ledger-1'));
      }
    });
  });
}
