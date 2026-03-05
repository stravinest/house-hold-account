import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/fixed_expense/data/models/fixed_expense_settings_model.dart';
import 'package:shared_household_account/features/fixed_expense/data/repositories/fixed_expense_settings_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/mock_supabase.dart';

void main() {
  late MockSupabaseClient mockClient;
  late FixedExpenseSettingsRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    repository = FixedExpenseSettingsRepository(client: mockClient);
  });

  group('FixedExpenseSettingsRepository - getSettings', () {
    test('가계부의 고정비 설정을 조회한다', () async {
      final mockData = {
        'id': 'settings-1',
        'ledger_id': 'ledger-1',
        'user_id': 'user-1',
        'include_in_expense': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      when(() => mockClient.from('fixed_expense_settings')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          maybeSingleData: mockData,
          hasMaybeSingleData: true,
        ),
      );

      final result = await repository.getSettings('ledger-1', 'user-1');

      expect(result, isA<FixedExpenseSettingsModel>());
      expect(result!.ledgerId, 'ledger-1');
      expect(result.includeInExpense, true);
    });

    test('설정이 없는 경우 null을 반환한다', () async {
      when(() => mockClient.from('fixed_expense_settings')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          maybeSingleData: null,
          hasMaybeSingleData: true,
        ),
      );

      final result = await repository.getSettings('ledger-1', 'user-1');

      expect(result, isNull);
    });
  });

  group('FixedExpenseSettingsRepository - updateSettings', () {
    test('고정비 설정 업데이트 시 upsert로 처리된다', () async {
      final mockResponse = {
        'id': 'settings-1',
        'ledger_id': 'ledger-1',
        'user_id': 'user-1',
        'include_in_expense': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      when(() => mockClient.from('fixed_expense_settings')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(singleData: mockResponse),
      );

      final result = await repository.updateSettings(
        ledgerId: 'ledger-1',
        userId: 'user-1',
        includeInExpense: false,
      );

      expect(result, isA<FixedExpenseSettingsModel>());
      expect(result.includeInExpense, false);
    });

    test('설정이 없는 경우 새로 생성된다', () async {
      final mockResponse = {
        'id': 'settings-new',
        'ledger_id': 'ledger-2',
        'user_id': 'user-1',
        'include_in_expense': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      when(() => mockClient.from('fixed_expense_settings')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(singleData: mockResponse),
      );

      final result = await repository.updateSettings(
        ledgerId: 'ledger-2',
        userId: 'user-1',
        includeInExpense: true,
      );

      expect(result.id, 'settings-new');
      expect(result.ledgerId, 'ledger-2');
    });

    test('업데이트 실패 시 에러를 전파한다', () async {
      when(() => mockClient.from('fixed_expense_settings')).thenAnswer(
        (_) => throw Exception('Update failed'),
      );

      expect(
        () => repository.updateSettings(
          ledgerId: 'ledger-1',
          userId: 'user-1',
          includeInExpense: true,
        ),
        throwsException,
      );
    });
  });

  group('FixedExpenseSettingsRepository - subscribeSettings', () {
    test('실시간 구독 채널이 생성된다', () {
      final mockChannel = MockRealtimeChannel();

      when(() => mockClient.channel('fixed_expense_settings_changes_ledger-1_user-1'))
          .thenReturn(mockChannel);

      when(() => mockChannel.onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'house',
            table: 'fixed_expense_settings',
            filter: any(named: 'filter'),
            callback: any(named: 'callback'),
          )).thenReturn(mockChannel);

      when(() => mockChannel.subscribe()).thenReturn(mockChannel);

      final channel = repository.subscribeSettings(
        ledgerId: 'ledger-1',
        userId: 'user-1',
        onSettingsChanged: () {},
      );

      expect(channel, isA<RealtimeChannel>());
    });

    test('구독 콜백이 정상적으로 실행된다', () {
      var callbackInvoked = false;
      final mockChannel = MockRealtimeChannel();

      when(() => mockClient.channel('fixed_expense_settings_changes_ledger-1_user-1'))
          .thenReturn(mockChannel);

      when(() => mockChannel.onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'house',
            table: 'fixed_expense_settings',
            filter: any(named: 'filter'),
            callback: any(named: 'callback'),
          )).thenReturn(mockChannel);

      when(() => mockChannel.subscribe()).thenReturn(mockChannel);

      repository.subscribeSettings(
        ledgerId: 'ledger-1',
        userId: 'user-1',
        onSettingsChanged: () {
          callbackInvoked = true;
        },
      );

      expect(callbackInvoked, false);
    });

    test('Postgres 변경 이벤트 발생 시 onSettingsChanged 콜백이 호출된다', () {
      // Given: 콜백 캡처를 위한 변수
      var callbackInvokedCount = 0;
      final mockChannel = MockRealtimeChannel();
      void Function(PostgresChangePayload)? capturedCallback;

      when(() => mockClient.channel('fixed_expense_settings_changes_ledger-1_user-1'))
          .thenReturn(mockChannel);

      when(() => mockChannel.onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'house',
            table: 'fixed_expense_settings',
            filter: any(named: 'filter'),
            callback: any(named: 'callback'),
          )).thenAnswer((invocation) {
        capturedCallback = invocation.namedArguments[#callback]
            as void Function(PostgresChangePayload);
        return mockChannel;
      });

      when(() => mockChannel.subscribe()).thenReturn(mockChannel);

      // When: 구독 등록
      repository.subscribeSettings(
        ledgerId: 'ledger-1',
        userId: 'user-1',
        onSettingsChanged: () {
          callbackInvokedCount++;
        },
      );

      // Then: 캡처된 콜백을 직접 호출하면 onSettingsChanged가 실행된다
      expect(capturedCallback, isNotNull);
      capturedCallback!(PostgresChangePayload.fromPayload({
        'schema': 'house',
        'table': 'fixed_expense_settings',
        'commit_timestamp': '2024-01-01T00:00:00Z',
        'eventType': 'UPDATE',
        'new': <String, dynamic>{},
        'old': <String, dynamic>{},
        'errors': null,
      }));
      expect(callbackInvokedCount, 1);
    });

    test('getSettings 조회 실패 시 에러를 전파한다', () async {
      // Given: 예외를 발생시키는 Fake
      when(() => mockClient.from('fixed_expense_settings')).thenAnswer(
        (_) => throw Exception('DB connection failed'),
      );

      // When & Then
      expect(
        () => repository.getSettings('ledger-1', 'user-1'),
        throwsException,
      );
    });
  });
}
