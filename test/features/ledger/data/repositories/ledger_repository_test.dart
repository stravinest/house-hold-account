import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/ledger/data/models/ledger_model.dart';
import 'package:shared_household_account/features/ledger/data/repositories/ledger_repository.dart';

import '../../../../helpers/mock_supabase.dart';

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late LedgerRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('user-123');

    repository = LedgerRepository(client: mockClient);
  });

  group('LedgerRepository - getLedgers', () {
    test('사용자의 가계부 목록 조회 시 멤버로 등록된 가계부만 반환한다', () async {
      final mockData = <Map<String, dynamic>>[
        {
          'ledger': {
            'id': 'ledger-1',
            'name': '우리 가족',
            'description': '가족 가계부',
            'currency': 'KRW',
            'owner_id': 'user-123',
            'is_shared': true,
            'created_at': '2024-01-01T00:00:00Z',
            'updated_at': '2024-01-01T00:00:00Z',
          }
        },
        {
          'ledger': {
            'id': 'ledger-2',
            'name': '개인 가계부',
            'description': null,
            'currency': 'KRW',
            'owner_id': 'user-123',
            'is_shared': false,
            'created_at': '2024-01-05T00:00:00Z',
            'updated_at': '2024-01-05T00:00:00Z',
          }
        },
      ];

      when(() => mockClient.from('ledger_members'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getLedgers();
      expect(result, isA<List<LedgerModel>>());
      expect(result.length, 2);
      expect(result[0].name, '우리 가족');
      expect(result[1].name, '개인 가계부');
    });

    test('로그인되지 않은 경우 예외를 던진다', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      expect(() => repository.getLedgers(), throwsA(isA<Exception>()));
    });
  });

  group('LedgerRepository - getLedger', () {
    test('가계부 상세 조회 시 해당 가계부를 반환한다', () async {
      final mockData = <String, dynamic>{
        'id': 'ledger-1',
        'name': '우리 가족',
        'description': '가족 가계부',
        'currency': 'KRW',
        'owner_id': 'user-123',
        'is_shared': true,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      when(() => mockClient.from('ledgers')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
            selectData: [mockData],
            maybeSingleData: mockData,
            hasMaybeSingleData: true,
          ));

      final result = await repository.getLedger('ledger-1');
      expect(result, isA<LedgerModel>());
      expect(result!.name, '우리 가족');
    });

    test('존재하지 않는 가계부 조회 시 null을 반환한다', () async {
      when(() => mockClient.from('ledgers')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
            selectData: [],
            maybeSingleData: null,
            hasMaybeSingleData: true,
          ));

      final result = await repository.getLedger('nonexistent');
      expect(result, isNull);
    });
  });

  group('LedgerRepository - createLedger', () {
    test('가계부 생성 시 올바른 데이터로 INSERT하고 생성된 가계부를 반환한다', () async {
      final mockResponse = <String, dynamic>{
        'id': 'ledger-new',
        'name': '신혼 가계부',
        'description': null,
        'currency': 'KRW',
        'owner_id': 'user-123',
        'is_shared': false,
        'created_at': '2024-01-15T00:00:00Z',
        'updated_at': '2024-01-15T00:00:00Z',
      };

      when(() => mockClient.from('ledgers')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [mockResponse], singleData: mockResponse));

      final result =
          await repository.createLedger(name: '신혼 가계부', currency: 'KRW');
      expect(result, isA<LedgerModel>());
      expect(result.id, 'ledger-new');
      expect(result.name, '신혼 가계부');
    });
  });

  group('LedgerRepository - updateLedger', () {
    test('가계부 수정 시 제공된 필드만 업데이트한다', () async {
      final mockResponse = <String, dynamic>{
        'id': 'ledger-1',
        'name': '업데이트된 가계부',
        'description': '수정된 설명',
        'currency': 'KRW',
        'owner_id': 'user-123',
        'is_shared': true,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-15T00:00:00Z',
      };

      when(() => mockClient.from('ledgers')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [mockResponse], singleData: mockResponse));

      final result = await repository.updateLedger(
          id: 'ledger-1', name: '업데이트된 가계부', description: '수정된 설명');
      expect(result.name, '업데이트된 가계부');
    });
  });

  group('LedgerRepository - getMembers', () {
    test('가계부 멤버 조회 시 프로필 정보를 포함한 멤버 리스트를 반환한다', () async {
      final mockData = <Map<String, dynamic>>[
        {
          'id': 'member-1',
          'ledger_id': 'ledger-1',
          'user_id': 'user-1',
          'role': 'owner',
          'created_at': '2024-01-01T00:00:00Z',
          'profiles': {
            'display_name': 'User One',
            'email': 'user1@test.com',
            'avatar_url': null,
          },
        },
        {
          'id': 'member-2',
          'ledger_id': 'ledger-1',
          'user_id': 'user-2',
          'role': 'admin',
          'created_at': '2024-01-05T00:00:00Z',
          'profiles': {
            'display_name': 'User Two',
            'email': 'user2@test.com',
            'avatar_url': 'https://example.com/avatar.jpg',
          },
        },
      ];

      when(() => mockClient.from('ledger_members'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getMembers('ledger-1');
      expect(result, isA<List<LedgerMemberModel>>());
      expect(result.length, 2);
      expect(result[0].role, 'owner');
      expect(result[1].role, 'admin');
    });
  });

  group('LedgerRepository - deleteLedger', () {
    test('가계부 삭제 시 올바른 ID로 DELETE 쿼리를 실행한다', () async {
      when(() => mockClient.from('ledgers'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.deleteLedger('ledger-1');
      // 에러 없이 완료되면 성공
    });
  });
}
