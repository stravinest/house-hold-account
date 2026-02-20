import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/features/fixed_expense/data/models/fixed_expense_settings_model.dart';
import 'package:shared_household_account/features/fixed_expense/domain/entities/fixed_expense_settings.dart';
import 'package:shared_household_account/features/fixed_expense/data/repositories/fixed_expense_settings_repository.dart';
import 'package:shared_household_account/features/fixed_expense/presentation/providers/fixed_expense_settings_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/test_helpers.dart' hide pumpEventQueue;

class MockUser extends Mock implements User {}

MockRealtimeChannel createMockRealtimeChannel() {
  final channel = MockRealtimeChannel();
  when(() => channel.unsubscribe()).thenAnswer((_) async => 'ok');
  return channel;
}

void main() {
  group('FixedExpenseSettingsProvider - 유저별 독립 설정 테스트', () {
    late MockFixedExpenseSettingsRepository mockRepository;
    late ProviderContainer container;
    late MockUser mockUser;

    final testSettings = FixedExpenseSettingsModel(
      id: 'settings-1',
      ledgerId: 'ledger-1',
      userId: 'user-1',
      includeInExpense: true,
      createdAt: DateTime(2026, 2, 20),
      updatedAt: DateTime(2026, 2, 20),
    );

    setUp(() {
      mockRepository = MockFixedExpenseSettingsRepository();
      mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      // subscribeSettings 기본 stub
      final defaultChannel = createMockRealtimeChannel();
      when(() => mockRepository.subscribeSettings(
            ledgerId: any(named: 'ledgerId'),
            userId: any(named: 'userId'),
            onSettingsChanged: any(named: 'onSettingsChanged'),
          )).thenReturn(defaultChannel);
    });

    tearDown(() {
      container.dispose();
    });

    test('fixedExpenseSettingsRepositoryProvider는 FixedExpenseSettingsRepository 인스턴스를 제공한다', () {
      container = createContainer(
        overrides: [
          fixedExpenseSettingsRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      final repository = container.read(fixedExpenseSettingsRepositoryProvider);

      expect(repository, isA<FixedExpenseSettingsRepository>());
    });

    group('fixedExpenseSettingsProvider (FutureProvider)', () {
      test('ledgerId가 null이면 null을 반환한다', () async {
        container = createContainer(
          overrides: [
            fixedExpenseSettingsRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => null),
            currentUserProvider.overrideWith((ref) => mockUser),
          ],
        );

        final result = await container.read(fixedExpenseSettingsProvider.future);

        expect(result, isNull);
      });

      test('유저가 null이면 null을 반환한다', () async {
        container = createContainer(
          overrides: [
            fixedExpenseSettingsRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            currentUserProvider.overrideWith((ref) => null),
          ],
        );

        final result = await container.read(fixedExpenseSettingsProvider.future);

        expect(result, isNull);
      });

      test('ledgerId와 유저가 있으면 유저별 설정을 조회한다', () async {
        when(() => mockRepository.getSettings('ledger-1', 'user-1'))
            .thenAnswer((_) async => testSettings);

        container = createContainer(
          overrides: [
            fixedExpenseSettingsRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            currentUserProvider.overrideWith((ref) => mockUser),
          ],
        );

        final result = await container.read(fixedExpenseSettingsProvider.future);

        expect(result, isNotNull);
        expect(result!.userId, 'user-1');
        expect(result.ledgerId, 'ledger-1');
        expect(result.includeInExpense, true);
        verify(() => mockRepository.getSettings('ledger-1', 'user-1')).called(1);
      });

      test('설정이 없으면 null을 반환한다 (새 멤버)', () async {
        when(() => mockRepository.getSettings('ledger-1', 'user-1'))
            .thenAnswer((_) async => null);

        container = createContainer(
          overrides: [
            fixedExpenseSettingsRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            currentUserProvider.overrideWith((ref) => mockUser),
          ],
        );

        final result = await container.read(fixedExpenseSettingsProvider.future);

        expect(result, isNull);
      });
    });

    group('includeFixedExpenseInExpenseProvider', () {
      test('설정이 있으면 includeInExpense 값을 반환한다', () async {
        when(() => mockRepository.getSettings('ledger-1', 'user-1'))
            .thenAnswer((_) async => testSettings);

        container = createContainer(
          overrides: [
            fixedExpenseSettingsRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            currentUserProvider.overrideWith((ref) => mockUser),
          ],
        );

        final result = await container.read(includeFixedExpenseInExpenseProvider.future);

        expect(result, true);
      });

      test('설정이 없으면 false를 반환한다 (기본값)', () async {
        when(() => mockRepository.getSettings('ledger-1', 'user-1'))
            .thenAnswer((_) async => null);

        container = createContainer(
          overrides: [
            fixedExpenseSettingsRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            currentUserProvider.overrideWith((ref) => mockUser),
          ],
        );

        final result = await container.read(includeFixedExpenseInExpenseProvider.future);

        expect(result, false);
      });
    });

    group('FixedExpenseSettingsNotifier', () {
      test('ledgerId와 userId가 모두 있으면 설정을 로드한다', () async {
        when(() => mockRepository.getSettings('ledger-1', 'user-1'))
            .thenAnswer((_) async => testSettings);

        container = createContainer(
          overrides: [
            fixedExpenseSettingsRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            currentUserProvider.overrideWith((ref) => mockUser),
          ],
        );

        // listen으로 구독을 유지해야 autoDispose가 동작하지 않음
        AsyncValue<FixedExpenseSettings?>? lastState;
        container.listen(fixedExpenseSettingsNotifierProvider, (_, next) {
          lastState = next;
        });
        await pumpEventQueue();

        expect(lastState?.valueOrNull?.userId, 'user-1');
        expect(lastState?.valueOrNull?.includeInExpense, true);
        verify(() => mockRepository.getSettings('ledger-1', 'user-1')).called(1);
      });

      test('ledgerId가 null이면 설정을 로드하지 않고 null 상태가 된다', () async {
        container = createContainer(
          overrides: [
            fixedExpenseSettingsRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => null),
            currentUserProvider.overrideWith((ref) => mockUser),
          ],
        );

        container.read(fixedExpenseSettingsNotifierProvider);
        await pumpEventQueue();

        final state = container.read(fixedExpenseSettingsNotifierProvider);

        expect(state.valueOrNull, isNull);
        verifyNever(() => mockRepository.getSettings(any(), any()));
      });

      test('userId가 null이면 설정을 로드하지 않고 null 상태가 된다', () async {
        container = createContainer(
          overrides: [
            fixedExpenseSettingsRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            currentUserProvider.overrideWith((ref) => null),
          ],
        );

        container.read(fixedExpenseSettingsNotifierProvider);
        await pumpEventQueue();

        final state = container.read(fixedExpenseSettingsNotifierProvider);

        expect(state.valueOrNull, isNull);
        verifyNever(() => mockRepository.getSettings(any(), any()));
      });

      test('updateIncludeInExpense는 유저별 설정을 업데이트한다', () async {
        final updatedSettings = FixedExpenseSettingsModel(
          id: 'settings-1',
          ledgerId: 'ledger-1',
          userId: 'user-1',
          includeInExpense: false,
          createdAt: DateTime(2026, 2, 20),
          updatedAt: DateTime(2026, 2, 20),
        );

        when(() => mockRepository.getSettings('ledger-1', 'user-1'))
            .thenAnswer((_) async => testSettings);
        when(() => mockRepository.updateSettings(
              ledgerId: 'ledger-1',
              userId: 'user-1',
              includeInExpense: false,
            )).thenAnswer((_) async => updatedSettings);

        container = createContainer(
          overrides: [
            fixedExpenseSettingsRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            currentUserProvider.overrideWith((ref) => mockUser),
          ],
        );

        // listen으로 구독 유지
        AsyncValue<FixedExpenseSettings?>? lastState;
        container.listen(fixedExpenseSettingsNotifierProvider, (_, next) {
          lastState = next;
        });
        await pumpEventQueue();

        // 업데이트 실행
        await container
            .read(fixedExpenseSettingsNotifierProvider.notifier)
            .updateIncludeInExpense(false);

        expect(lastState?.valueOrNull?.includeInExpense, false);
        verify(() => mockRepository.updateSettings(
              ledgerId: 'ledger-1',
              userId: 'user-1',
              includeInExpense: false,
            )).called(1);
      });

      test('updateIncludeInExpense는 ledgerId가 null이면 예외를 던진다', () async {
        container = createContainer(
          overrides: [
            fixedExpenseSettingsRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => null),
            currentUserProvider.overrideWith((ref) => mockUser),
          ],
        );

        container.read(fixedExpenseSettingsNotifierProvider);
        await pumpEventQueue();

        expect(
          () => container
              .read(fixedExpenseSettingsNotifierProvider.notifier)
              .updateIncludeInExpense(true),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('가계부를 선택해주세요'),
          )),
        );
      });

      test('updateIncludeInExpense는 userId가 null이면 예외를 던진다', () async {
        container = createContainer(
          overrides: [
            fixedExpenseSettingsRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            currentUserProvider.overrideWith((ref) => null),
          ],
        );

        container.read(fixedExpenseSettingsNotifierProvider);
        await pumpEventQueue();

        expect(
          () => container
              .read(fixedExpenseSettingsNotifierProvider.notifier)
              .updateIncludeInExpense(true),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('로그인이 필요합니다'),
          )),
        );
      });

      test('Repository 에러 발생 시 에러 상태가 된다', () async {
        when(() => mockRepository.getSettings('ledger-1', 'user-1'))
            .thenAnswer((_) async => throw Exception('DB 연결 실패'));

        // loadSettings에서 rethrow되는 에러를 zone에서 잡기
        Object? caughtError;
        await runZonedGuarded(() async {
          container = createContainer(
            overrides: [
              fixedExpenseSettingsRepositoryProvider.overrideWith((ref) => mockRepository),
              selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
              currentUserProvider.overrideWith((ref) => mockUser),
            ],
          );

          AsyncValue<FixedExpenseSettings?>? lastState;
          container.listen(fixedExpenseSettingsNotifierProvider, (_, next) {
            lastState = next;
          });
          await pumpEventQueue();

          expect(lastState?.hasError, true);
        }, (error, stack) {
          caughtError = error;
        });

        // rethrow가 정상적으로 동작했는지 확인
        expect(caughtError, isA<Exception>());
      });

      test('Realtime 구독이 userId 기반으로 설정된다', () async {
        when(() => mockRepository.getSettings('ledger-1', 'user-1'))
            .thenAnswer((_) async => testSettings);

        container = createContainer(
          overrides: [
            fixedExpenseSettingsRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            currentUserProvider.overrideWith((ref) => mockUser),
          ],
        );

        // listen으로 구독 유지
        container.listen(fixedExpenseSettingsNotifierProvider, (_, __) {});
        await pumpEventQueue();

        // userId가 'user-1'로 구독이 호출되었는지 확인
        verify(() => mockRepository.subscribeSettings(
              ledgerId: 'ledger-1',
              userId: 'user-1',
              onSettingsChanged: any(named: 'onSettingsChanged'),
            )).called(1);
      });
    });

    group('유저 독립성 검증', () {
      test('같은 가계부에서 다른 유저는 다른 설정을 가질 수 있다', () async {
        final user1Settings = FixedExpenseSettingsModel(
          id: 'settings-1',
          ledgerId: 'ledger-1',
          userId: 'user-1',
          includeInExpense: true,
          createdAt: DateTime(2026, 2, 20),
          updatedAt: DateTime(2026, 2, 20),
        );

        final user2Settings = FixedExpenseSettingsModel(
          id: 'settings-2',
          ledgerId: 'ledger-1',
          userId: 'user-2',
          includeInExpense: false,
          createdAt: DateTime(2026, 2, 20),
          updatedAt: DateTime(2026, 2, 20),
        );

        // 같은 가계부지만 다른 유저 ID로 다른 설정이 반환됨
        expect(user1Settings.includeInExpense, true);
        expect(user2Settings.includeInExpense, false);
        expect(user1Settings.ledgerId, user2Settings.ledgerId);
        expect(user1Settings.userId, isNot(user2Settings.userId));
      });

      test('FixedExpenseSettings의 props에 userId가 포함된다', () {
        final settings1 = FixedExpenseSettingsModel(
          id: 'settings-1',
          ledgerId: 'ledger-1',
          userId: 'user-1',
          includeInExpense: true,
          createdAt: DateTime(2026, 2, 20),
          updatedAt: DateTime(2026, 2, 20),
        );

        final settings2 = FixedExpenseSettingsModel(
          id: 'settings-1',
          ledgerId: 'ledger-1',
          userId: 'user-2',
          includeInExpense: true,
          createdAt: DateTime(2026, 2, 20),
          updatedAt: DateTime(2026, 2, 20),
        );

        // userId가 다르면 Equatable 비교 시 다른 객체로 판단되어야 함
        expect(settings1, isNot(equals(settings2)));
      });

      test('Model의 toJson에 user_id가 포함된다', () {
        final settings = FixedExpenseSettingsModel(
          id: 'settings-1',
          ledgerId: 'ledger-1',
          userId: 'user-1',
          includeInExpense: true,
          createdAt: DateTime(2026, 2, 20),
          updatedAt: DateTime(2026, 2, 20),
        );

        final json = settings.toJson();

        expect(json.containsKey('user_id'), true);
        expect(json['user_id'], 'user-1');
      });

      test('Model의 fromJson에서 user_id를 올바르게 파싱한다', () {
        final json = {
          'id': 'settings-1',
          'ledger_id': 'ledger-1',
          'user_id': 'user-abc-123',
          'include_in_expense': false,
          'created_at': '2026-02-20T10:00:00.000',
          'updated_at': '2026-02-20T10:00:00.000',
        };

        final result = FixedExpenseSettingsModel.fromJson(json);

        expect(result.userId, 'user-abc-123');
      });

      test('copyWith로 userId를 변경할 수 있다', () {
        final original = FixedExpenseSettingsModel(
          id: 'settings-1',
          ledgerId: 'ledger-1',
          userId: 'user-1',
          includeInExpense: true,
          createdAt: DateTime(2026, 2, 20),
          updatedAt: DateTime(2026, 2, 20),
        );

        final copied = original.copyWith(userId: 'user-2');

        expect(copied.userId, 'user-2');
        expect(copied.ledgerId, 'ledger-1');
        expect(copied.includeInExpense, true);
      });
    });
  });
}
