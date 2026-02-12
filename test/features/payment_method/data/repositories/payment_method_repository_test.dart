import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/payment_method/data/models/payment_method_model.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/payment_method_repository.dart';

import '../../../../helpers/mock_supabase.dart';

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late PaymentMethodRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('user-123');

    repository = PaymentMethodRepository(client: mockClient);
  });

  Map<String, dynamic> _makePaymentMethod({
    String id = 'pm-1',
    String name = 'KB카드',
    int sortOrder = 1,
    String autoSaveMode = 'suggest',
    bool canAutoSave = true,
  }) {
    return {
      'id': id,
      'ledger_id': 'ledger-1',
      'owner_user_id': 'user-123',
      'name': name,
      'icon': 'credit_card',
      'color': '#6750A4',
      'is_default': false,
      'sort_order': sortOrder,
      'can_auto_save': canAutoSave,
      'auto_save_mode': autoSaveMode,
      'default_category_id': null,
      'auto_collect_source': 'sms',
      'created_at': '2024-01-01T00:00:00Z',
      'updated_at': '2024-01-01T00:00:00Z',
    };
  }

  group('PaymentMethodRepository - getPaymentMethods', () {
    test('가계부의 모든 결제수단 조회 시 정렬된 리스트를 반환한다', () async {
      final mockData = [_makePaymentMethod()];

      when(() => mockClient.from('payment_methods'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getPaymentMethods('ledger-1');
      expect(result, isA<List<PaymentMethodModel>>());
      expect(result.length, 1);
      expect(result[0].name, 'KB카드');
    });
  });

  group('PaymentMethodRepository - createPaymentMethod', () {
    test('결제수단 생성 시 sort_order가 자동으로 증가하며 생성된다', () async {
      final newPm = _makePaymentMethod(id: 'pm-new', name: '신한카드', sortOrder: 4);

      // from()이 여러 번 호출됨: select('sort_order')...maybeSingle(), insert()...select().single()
      // 첫 번째 호출: sort_order 조회 -> maybeSingle 반환
      // 두 번째 호출: insert -> select -> single 반환
      int callCount = 0;
      when(() => mockClient.from('payment_methods')).thenAnswer((_) {
        callCount++;
        if (callCount == 1) {
          // sort_order 조회
          return FakeSupabaseQueryBuilder(
            selectData: [{'sort_order': 3}],
            maybeSingleData: {'sort_order': 3},
            hasMaybeSingleData: true,
          );
        }
        // insert
        return FakeSupabaseQueryBuilder(
          selectData: [newPm],
          singleData: newPm,
        );
      });

      final result = await repository.createPaymentMethod(
          ledgerId: 'ledger-1', name: '신한카드');
      expect(result, isA<PaymentMethodModel>());
      expect(result.id, 'pm-new');
      expect(result.sortOrder, 4);
    });

    test('로그인되지 않은 경우 예외를 던진다', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      expect(
        () => repository.createPaymentMethod(
            ledgerId: 'ledger-1', name: 'KB카드'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('PaymentMethodRepository - getAutoSaveEnabledPaymentMethods', () {
    test('자동수집 활성화된 결제수단 조회 시 owner_user_id로 필터링한다', () async {
      final mockData = [_makePaymentMethod(autoSaveMode: 'suggest')];

      when(() => mockClient.from('payment_methods'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getAutoSaveEnabledPaymentMethods(
          'ledger-1', 'user-123');
      expect(result, isA<List<PaymentMethodModel>>());
      expect(result.length, 1);
      expect(result[0].autoSaveMode.toJson(), 'suggest');
    });
  });

  group('PaymentMethodRepository - updatePaymentMethod', () {
    test('결제수단 수정 시 제공된 필드만 업데이트한다', () async {
      final updated = _makePaymentMethod(name: '새 카드 이름');

      when(() => mockClient.from('payment_methods')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [updated], singleData: updated));

      final result =
          await repository.updatePaymentMethod(id: 'pm-1', name: '새 카드 이름');
      expect(result.name, '새 카드 이름');
    });
  });

  group('PaymentMethodRepository - deletePaymentMethod', () {
    test('결제수단 삭제 성공 시 정상 완료한다', () async {
      when(() => mockClient.from('payment_methods')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(selectData: [{'id': 'pm-1'}]));

      await repository.deletePaymentMethod('pm-1');
      // 에러 없이 완료되면 성공
    });

    test('결제수단 삭제 실패 시 예외를 던진다', () async {
      when(() => mockClient.from('payment_methods'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      expect(
        () => repository.deletePaymentMethod('pm-1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('PaymentMethodRepository - reorderPaymentMethods', () {
    test('결제수단 순서 변경 시 RPC 함수를 호출한다', () async {
      when(() => mockClient.rpc('batch_reorder_payment_methods',
              params: any(named: 'params')))
          .thenAnswer(
              (_) => FakePostgrestFilterBuilder<dynamic>(true));

      await repository.reorderPaymentMethods(['pm-3', 'pm-1', 'pm-2']);
      verify(() => mockClient.rpc('batch_reorder_payment_methods',
          params: any(named: 'params'))).called(1);
    });
  });
}
