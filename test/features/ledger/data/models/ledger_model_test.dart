import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/data/models/ledger_model.dart';
import 'package:shared_household_account/features/ledger/domain/entities/ledger.dart';

void main() {
  group('LedgerModel', () {
    final testCreatedAt = DateTime(2026, 2, 12, 10, 0, 0);
    final testUpdatedAt = DateTime(2026, 2, 12, 11, 0, 0);

    final ledgerModel = LedgerModel(
      id: 'test-id',
      name: '우리 가족 가계부',
      description: '가족 공용 가계부입니다',
      currency: 'KRW',
      ownerId: 'owner-id',
      isShared: true,
      createdAt: testCreatedAt,
      updatedAt: testUpdatedAt,
    );

    test('Ledger 엔티티를 확장한다', () {
      expect(ledgerModel, isA<Ledger>());
    });

    group('fromJson', () {
      test('JSON에서 올바르게 역직렬화된다', () {
        final json = {
          'id': 'json-id',
          'name': '회사 경비',
          'description': '회사 경비 가계부',
          'currency': 'USD',
          'owner_id': 'owner-id',
          'is_shared': false,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = LedgerModel.fromJson(json);

        expect(result.id, 'json-id');
        expect(result.name, '회사 경비');
        expect(result.description, '회사 경비 가계부');
        expect(result.currency, 'USD');
        expect(result.ownerId, 'owner-id');
        expect(result.isShared, false);
        expect(result.createdAt, DateTime.parse('2026-02-12T10:00:00.000'));
        expect(result.updatedAt, DateTime.parse('2026-02-12T11:00:00.000'));
      });

      test('description이 null일 때 올바르게 처리한다', () {
        final json = {
          'id': 'json-id',
          'name': '개인 가계부',
          'description': null,
          'currency': 'KRW',
          'owner_id': 'owner-id',
          'is_shared': false,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = LedgerModel.fromJson(json);

        expect(result.description, null);
      });

      test('다양한 날짜 형식을 파싱한다', () {
        final json1 = {
          'id': 'json-id',
          'name': '가계부',
          'currency': 'KRW',
          'owner_id': 'owner-id',
          'is_shared': false,
          'created_at': '2026-02-12T10:00:00.000Z',
          'updated_at': '2026-02-12T11:00:00.000Z',
        };

        final json2 = {
          'id': 'json-id',
          'name': '가계부',
          'currency': 'KRW',
          'owner_id': 'owner-id',
          'is_shared': false,
          'created_at': '2026-02-12T10:00:00',
          'updated_at': '2026-02-12T11:00:00',
        };

        final result1 = LedgerModel.fromJson(json1);
        final result2 = LedgerModel.fromJson(json2);

        expect(result1.createdAt.year, 2026);
        expect(result1.createdAt.month, 2);
        expect(result1.createdAt.day, 12);
        expect(result2.createdAt.year, 2026);
      });
    });

    group('toJson', () {
      test('JSON으로 올바르게 직렬화된다', () {
        final json = ledgerModel.toJson();

        expect(json['id'], 'test-id');
        expect(json['name'], '우리 가족 가계부');
        expect(json['description'], '가족 공용 가계부입니다');
        expect(json['currency'], 'KRW');
        expect(json['owner_id'], 'owner-id');
        expect(json['is_shared'], true);
        expect(json['created_at'], isA<String>());
        expect(json['updated_at'], isA<String>());
      });

      test('날짜가 ISO 8601 형식으로 직렬화된다', () {
        final json = ledgerModel.toJson();

        expect(json['created_at'], testCreatedAt.toIso8601String());
        expect(json['updated_at'], testUpdatedAt.toIso8601String());
      });

      test('모든 필드가 JSON에 포함된다', () {
        final json = ledgerModel.toJson();

        expect(json.containsKey('id'), true);
        expect(json.containsKey('name'), true);
        expect(json.containsKey('description'), true);
        expect(json.containsKey('currency'), true);
        expect(json.containsKey('owner_id'), true);
        expect(json.containsKey('is_shared'), true);
        expect(json.containsKey('created_at'), true);
        expect(json.containsKey('updated_at'), true);
      });

      test('null description을 올바르게 직렬화한다', () {
        final model = LedgerModel(
          id: 'test-id',
          name: '가계부',
          currency: 'KRW',
          ownerId: 'owner-id',
          isShared: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final json = model.toJson();

        expect(json['description'], null);
      });
    });

    group('toCreateJson', () {
      test('생성용 JSON을 올바르게 만든다', () {
        final json = LedgerModel.toCreateJson(
          name: '새 가계부',
          description: '가계부 설명',
          currency: 'KRW',
          ownerId: 'owner-id',
        );

        expect(json['name'], '새 가계부');
        expect(json['description'], '가계부 설명');
        expect(json['currency'], 'KRW');
        expect(json['owner_id'], 'owner-id');
        expect(json['is_shared'], false);
      });

      test('기본값이 올바르게 설정된다', () {
        final json = LedgerModel.toCreateJson(
          name: '가계부',
          currency: 'KRW',
          ownerId: 'owner-id',
        );

        expect(json['is_shared'], false);
      });

      test('isShared를 true로 설정할 수 있다', () {
        final json = LedgerModel.toCreateJson(
          name: '공유 가계부',
          currency: 'KRW',
          ownerId: 'owner-id',
          isShared: true,
        );

        expect(json['is_shared'], true);
      });

      test('id와 타임스탬프는 포함되지 않는다', () {
        final json = LedgerModel.toCreateJson(
          name: '가계부',
          currency: 'KRW',
          ownerId: 'owner-id',
        );

        expect(json.containsKey('id'), false);
        expect(json.containsKey('created_at'), false);
        expect(json.containsKey('updated_at'), false);
      });

      test('null description을 올바르게 처리한다', () {
        final json = LedgerModel.toCreateJson(
          name: '가계부',
          description: null,
          currency: 'KRW',
          ownerId: 'owner-id',
        );

        expect(json['description'], null);
      });
    });

    group('fromJson -> toJson 왕복 변환', () {
      test('데이터가 손실 없이 변환된다', () {
        final originalJson = {
          'id': 'test-id',
          'name': '우리 가계부',
          'description': '테스트 설명',
          'currency': 'KRW',
          'owner_id': 'owner-id',
          'is_shared': true,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final model = LedgerModel.fromJson(originalJson);
        final convertedJson = model.toJson();

        expect(convertedJson['id'], originalJson['id']);
        expect(convertedJson['name'], originalJson['name']);
        expect(convertedJson['description'], originalJson['description']);
        expect(convertedJson['currency'], originalJson['currency']);
        expect(convertedJson['owner_id'], originalJson['owner_id']);
        expect(convertedJson['is_shared'], originalJson['is_shared']);
      });
    });

    group('엣지 케이스', () {
      test('빈 문자열을 이름으로 사용할 수 있다', () {
        final json = {
          'id': 'test-id',
          'name': '',
          'currency': 'KRW',
          'owner_id': 'owner-id',
          'is_shared': false,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = LedgerModel.fromJson(json);

        expect(result.name, '');
      });

      test('빈 문자열을 설명으로 사용할 수 있다', () {
        final json = {
          'id': 'test-id',
          'name': '가계부',
          'description': '',
          'currency': 'KRW',
          'owner_id': 'owner-id',
          'is_shared': false,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = LedgerModel.fromJson(json);

        expect(result.description, '');
      });

      test('다양한 화폐 단위를 처리할 수 있다', () {
        final currencies = ['KRW', 'USD', 'JPY', 'EUR', 'CNY'];

        for (final currency in currencies) {
          final json = LedgerModel.toCreateJson(
            name: '가계부',
            currency: currency,
            ownerId: 'owner-id',
          );

          expect(json['currency'], currency);
        }
      });

      test('매우 긴 이름을 처리할 수 있다', () {
        final longName = '아주 긴 가계부 이름 ' * 20;
        final json = {
          'id': 'test-id',
          'name': longName,
          'currency': 'KRW',
          'owner_id': 'owner-id',
          'is_shared': false,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = LedgerModel.fromJson(json);

        expect(result.name, longName);
      });

      test('매우 긴 설명을 처리할 수 있다', () {
        final longDesc = '아주 긴 설명 ' * 50;
        final json = {
          'id': 'test-id',
          'name': '가계부',
          'description': longDesc,
          'currency': 'KRW',
          'owner_id': 'owner-id',
          'is_shared': false,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = LedgerModel.fromJson(json);

        expect(result.description, longDesc);
      });
    });
  });

  group('LedgerMemberModel', () {
    final testJoinedAt = DateTime(2026, 2, 12, 10, 0, 0);

    final memberModel = LedgerMemberModel(
      id: 'member-id',
      ledgerId: 'ledger-id',
      userId: 'user-id',
      role: 'owner',
      joinedAt: testJoinedAt,
      displayName: '홍길동',
      email: 'hong@example.com',
      avatarUrl: 'https://example.com/avatar.jpg',
      color: '#FF5733',
    );

    test('LedgerMember 엔티티를 확장한다', () {
      expect(memberModel, isA<LedgerMember>());
    });

    group('fromJson', () {
      test('JSON에서 올바르게 역직렬화된다', () {
        final json = {
          'id': 'member-id',
          'ledger_id': 'ledger-id',
          'user_id': 'user-id',
          'role': 'editor',
          'created_at': '2026-02-12T10:00:00.000',
          'profiles': {
            'display_name': '김철수',
            'email': 'kim@example.com',
            'avatar_url': 'https://example.com/kim.jpg',
            'color': '#00FF00',
          },
        };

        final result = LedgerMemberModel.fromJson(json);

        expect(result.id, 'member-id');
        expect(result.ledgerId, 'ledger-id');
        expect(result.userId, 'user-id');
        expect(result.role, 'editor');
        expect(result.displayName, '김철수');
        expect(result.email, 'kim@example.com');
        expect(result.avatarUrl, 'https://example.com/kim.jpg');
        expect(result.color, '#00FF00');
      });

      test('프로필이 null일 때 올바르게 처리한다', () {
        final json = {
          'id': 'member-id',
          'ledger_id': 'ledger-id',
          'user_id': 'user-id',
          'role': 'viewer',
          'created_at': '2026-02-12T10:00:00.000',
          'profiles': null,
        };

        final result = LedgerMemberModel.fromJson(json);

        expect(result.displayName, null);
        expect(result.email, null);
        expect(result.avatarUrl, null);
        expect(result.color, null);
      });

      test('프로필 필드가 부분적으로 null일 때 처리한다', () {
        final json = {
          'id': 'member-id',
          'ledger_id': 'ledger-id',
          'user_id': 'user-id',
          'role': 'editor',
          'created_at': '2026-02-12T10:00:00.000',
          'profiles': {
            'email': 'test@example.com',
            'color': '#FF0000',
          },
        };

        final result = LedgerMemberModel.fromJson(json);

        expect(result.displayName, null);
        expect(result.email, 'test@example.com');
        expect(result.avatarUrl, null);
        expect(result.color, '#FF0000');
      });

      test('다양한 role 값을 파싱한다', () {
        final roles = ['owner', 'editor', 'viewer'];

        for (final role in roles) {
          final json = {
            'id': 'member-id',
            'ledger_id': 'ledger-id',
            'user_id': 'user-id',
            'role': role,
            'created_at': '2026-02-12T10:00:00.000',
          };

          final result = LedgerMemberModel.fromJson(json);

          expect(result.role, role);
        }
      });
    });

    group('엣지 케이스', () {
      test('빈 문자열을 displayName으로 사용할 수 있다', () {
        final json = {
          'id': 'member-id',
          'ledger_id': 'ledger-id',
          'user_id': 'user-id',
          'role': 'viewer',
          'created_at': '2026-02-12T10:00:00.000',
          'profiles': {
            'display_name': '',
            'email': 'test@example.com',
          },
        };

        final result = LedgerMemberModel.fromJson(json);

        expect(result.displayName, '');
      });

      test('빈 문자열을 email로 사용할 수 있다', () {
        final json = {
          'id': 'member-id',
          'ledger_id': 'ledger-id',
          'user_id': 'user-id',
          'role': 'viewer',
          'created_at': '2026-02-12T10:00:00.000',
          'profiles': {
            'email': '',
          },
        };

        final result = LedgerMemberModel.fromJson(json);

        expect(result.email, '');
      });

      test('알 수 없는 role 값을 처리할 수 있다', () {
        final json = {
          'id': 'member-id',
          'ledger_id': 'ledger-id',
          'user_id': 'user-id',
          'role': 'unknown_role',
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = LedgerMemberModel.fromJson(json);

        expect(result.role, 'unknown_role');
        expect(result.isOwner, false);
        expect(result.isEditor, false);
        expect(result.isViewer, false);
        expect(result.canEdit, false);
      });

      test('매우 긴 displayName을 처리할 수 있다', () {
        final longName = '아주 긴 사용자 이름 ' * 10;
        final json = {
          'id': 'member-id',
          'ledger_id': 'ledger-id',
          'user_id': 'user-id',
          'role': 'viewer',
          'created_at': '2026-02-12T10:00:00.000',
          'profiles': {
            'display_name': longName,
          },
        };

        final result = LedgerMemberModel.fromJson(json);

        expect(result.displayName, longName);
      });
    });
  });
}
