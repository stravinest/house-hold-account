import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/data/models/payment_method_model.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/payment_method.dart';

void main() {
  group('PaymentMethodModel', () {
    final testCreatedAt = DateTime(2026, 2, 12, 10, 0, 0);

    final model = PaymentMethodModel(
      id: 'payment-id',
      ledgerId: 'ledger-id',
      ownerUserId: 'owner-id',
      name: '신한카드',
      icon: '💳',
      color: '#4A90E2',
      isDefault: false,
      sortOrder: 0,
      createdAt: testCreatedAt,
      autoSaveMode: AutoSaveMode.suggest,
      defaultCategoryId: 'category-id',
      canAutoSave: true,
      autoCollectSource: AutoCollectSource.sms,
    );

    test('PaymentMethod 엔티티를 확장한다', () {
      expect(model, isA<PaymentMethod>());
    });

    group('fromJson', () {
      test('JSON에서 올바르게 역직렬화된다', () {
        final json = {
          'id': 'json-id',
          'ledger_id': 'ledger-id',
          'owner_user_id': 'owner-id',
          'name': 'KB카드',
          'icon': '🏦',
          'color': '#FF0000',
          'is_default': true,
          'sort_order': 5,
          'created_at': '2026-02-12T10:00:00.000',
          'auto_save_mode': 'auto',
          'default_category_id': 'category-id',
          'can_auto_save': true,
          'auto_collect_source': 'push',
        };

        final result = PaymentMethodModel.fromJson(json);

        expect(result.id, 'json-id');
        expect(result.ledgerId, 'ledger-id');
        expect(result.ownerUserId, 'owner-id');
        expect(result.name, 'KB카드');
        expect(result.icon, '🏦');
        expect(result.color, '#FF0000');
        expect(result.isDefault, true);
        expect(result.sortOrder, 5);
        expect(result.autoSaveMode, AutoSaveMode.auto);
        expect(result.defaultCategoryId, 'category-id');
        expect(result.canAutoSave, true);
        expect(result.autoCollectSource, AutoCollectSource.push);
      });

      test('기본값이 올바르게 설정된다', () {
        final json = {
          'id': 'json-id',
          'ledger_id': 'ledger-id',
          'owner_user_id': 'owner-id',
          'name': '현금',
          'is_default': false,
          'sort_order': 0,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = PaymentMethodModel.fromJson(json);

        expect(result.icon, '');
        expect(result.color, '#6750A4');
        expect(result.autoSaveMode, AutoSaveMode.manual);
        expect(result.defaultCategoryId, null);
        expect(result.canAutoSave, true);
        expect(result.autoCollectSource, AutoCollectSource.sms);
      });

      test('null 값들을 올바르게 처리한다', () {
        final json = {
          'id': 'json-id',
          'ledger_id': 'ledger-id',
          'owner_user_id': 'owner-id',
          'name': '테스트',
          'icon': null,
          'color': null,
          'is_default': false,
          'sort_order': 0,
          'created_at': '2026-02-12T10:00:00.000',
          'auto_save_mode': null,
          'default_category_id': null,
          'can_auto_save': null,
          'auto_collect_source': null,
        };

        final result = PaymentMethodModel.fromJson(json);

        expect(result.icon, '');
        expect(result.color, '#6750A4');
        expect(result.autoSaveMode, AutoSaveMode.manual);
        expect(result.defaultCategoryId, null);
        expect(result.canAutoSave, true);
        expect(result.autoCollectSource, AutoCollectSource.sms);
      });

      test('다양한 autoSaveMode 값을 파싱한다', () {
        final modes = {
          'manual': AutoSaveMode.manual,
          'suggest': AutoSaveMode.suggest,
          'auto': AutoSaveMode.auto,
        };

        modes.forEach((key, value) {
          final json = {
            'id': 'json-id',
            'ledger_id': 'ledger-id',
            'owner_user_id': 'owner-id',
            'name': '테스트',
            'is_default': false,
            'sort_order': 0,
            'created_at': '2026-02-12T10:00:00.000',
            'auto_save_mode': key,
          };

          final result = PaymentMethodModel.fromJson(json);

          expect(result.autoSaveMode, value);
        });
      });

      test('다양한 autoCollectSource 값을 파싱한다', () {
        final sources = {
          'sms': AutoCollectSource.sms,
          'push': AutoCollectSource.push,
        };

        sources.forEach((key, value) {
          final json = {
            'id': 'json-id',
            'ledger_id': 'ledger-id',
            'owner_user_id': 'owner-id',
            'name': '테스트',
            'is_default': false,
            'sort_order': 0,
            'created_at': '2026-02-12T10:00:00.000',
            'auto_collect_source': key,
          };

          final result = PaymentMethodModel.fromJson(json);

          expect(result.autoCollectSource, value);
        });
      });
    });

    group('toJson', () {
      test('JSON으로 올바르게 직렬화된다', () {
        final json = model.toJson();

        expect(json['id'], 'payment-id');
        expect(json['ledger_id'], 'ledger-id');
        expect(json['owner_user_id'], 'owner-id');
        expect(json['name'], '신한카드');
        expect(json['icon'], '💳');
        expect(json['color'], '#4A90E2');
        expect(json['is_default'], false);
        expect(json['sort_order'], 0);
        expect(json['created_at'], isA<String>());
        expect(json['auto_save_mode'], 'suggest');
        expect(json['default_category_id'], 'category-id');
        expect(json['can_auto_save'], true);
        expect(json['auto_collect_source'], 'sms');
      });

      test('모든 필드가 JSON에 포함된다', () {
        final json = model.toJson();

        expect(json.containsKey('id'), true);
        expect(json.containsKey('ledger_id'), true);
        expect(json.containsKey('owner_user_id'), true);
        expect(json.containsKey('name'), true);
        expect(json.containsKey('icon'), true);
        expect(json.containsKey('color'), true);
        expect(json.containsKey('is_default'), true);
        expect(json.containsKey('sort_order'), true);
        expect(json.containsKey('created_at'), true);
        expect(json.containsKey('auto_save_mode'), true);
        expect(json.containsKey('default_category_id'), true);
        expect(json.containsKey('can_auto_save'), true);
        expect(json.containsKey('auto_collect_source'), true);
      });

      test('null defaultCategoryId를 올바르게 직렬화한다', () {
        final modelWithoutCategory = PaymentMethodModel(
          id: 'payment-id',
          ledgerId: 'ledger-id',
          ownerUserId: 'owner-id',
          name: '현금',
          icon: '💵',
          color: '#00FF00',
          isDefault: false,
          sortOrder: 0,
          createdAt: testCreatedAt,
        );

        final json = modelWithoutCategory.toJson();

        expect(json['default_category_id'], null);
      });
    });

    group('toCreateJson', () {
      test('생성용 JSON을 올바르게 만든다', () {
        final json = PaymentMethodModel.toCreateJson(
          ledgerId: 'ledger-id',
          ownerUserId: 'owner-id',
          name: '새 카드',
        );

        expect(json['ledger_id'], 'ledger-id');
        expect(json['owner_user_id'], 'owner-id');
        expect(json['name'], '새 카드');
        expect(json['is_default'], false);
        expect(json['sort_order'], 0);
        expect(json['can_auto_save'], true);
      });

      test('기본값이 올바르게 설정된다', () {
        final json = PaymentMethodModel.toCreateJson(
          ledgerId: 'ledger-id',
          ownerUserId: 'owner-id',
          name: '테스트',
        );

        expect(json['icon'], '');
        expect(json['color'], '#6750A4');
        expect(json['is_default'], false);
        expect(json['sort_order'], 0);
        expect(json['can_auto_save'], true);
      });

      test('선택적 파라미터를 커스텀할 수 있다', () {
        final json = PaymentMethodModel.toCreateJson(
          ledgerId: 'ledger-id',
          ownerUserId: 'owner-id',
          name: '커스텀 카드',
          icon: '🎴',
          color: '#123456',
          sortOrder: 10,
          canAutoSave: false,
        );

        expect(json['icon'], '🎴');
        expect(json['color'], '#123456');
        expect(json['sort_order'], 10);
        expect(json['can_auto_save'], false);
      });

      test('id와 타임스탬프는 포함되지 않는다', () {
        final json = PaymentMethodModel.toCreateJson(
          ledgerId: 'ledger-id',
          ownerUserId: 'owner-id',
          name: '테스트',
        );

        expect(json.containsKey('id'), false);
        expect(json.containsKey('created_at'), false);
      });
    });

    group('toAutoSaveUpdateJson', () {
      test('자동 저장 업데이트 JSON을 올바르게 만든다', () {
        final json = PaymentMethodModel.toAutoSaveUpdateJson(
          autoSaveMode: AutoSaveMode.auto,
        );

        expect(json['auto_save_mode'], 'auto');
        expect(json.containsKey('default_category_id'), false);
        expect(json.containsKey('auto_collect_source'), false);
      });

      test('defaultCategoryId를 포함할 수 있다', () {
        final json = PaymentMethodModel.toAutoSaveUpdateJson(
          autoSaveMode: AutoSaveMode.suggest,
          defaultCategoryId: 'category-id',
        );

        expect(json['auto_save_mode'], 'suggest');
        expect(json['default_category_id'], 'category-id');
      });

      test('autoCollectSource를 포함할 수 있다', () {
        final json = PaymentMethodModel.toAutoSaveUpdateJson(
          autoSaveMode: AutoSaveMode.auto,
          autoCollectSource: AutoCollectSource.push,
        );

        expect(json['auto_save_mode'], 'auto');
        expect(json['auto_collect_source'], 'push');
      });

      test('모든 필드를 포함할 수 있다', () {
        final json = PaymentMethodModel.toAutoSaveUpdateJson(
          autoSaveMode: AutoSaveMode.suggest,
          defaultCategoryId: 'category-id',
          autoCollectSource: AutoCollectSource.sms,
        );

        expect(json['auto_save_mode'], 'suggest');
        expect(json['default_category_id'], 'category-id');
        expect(json['auto_collect_source'], 'sms');
      });
    });

    group('fromJson -> toJson 왕복 변환', () {
      test('데이터가 손실 없이 변환된다', () {
        final originalJson = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'owner_user_id': 'owner-id',
          'name': '신한카드',
          'icon': '💳',
          'color': '#4A90E2',
          'is_default': false,
          'sort_order': 5,
          'created_at': '2026-02-12T10:00:00.000',
          'auto_save_mode': 'suggest',
          'default_category_id': 'category-id',
          'can_auto_save': true,
          'auto_collect_source': 'sms',
        };

        final model = PaymentMethodModel.fromJson(originalJson);
        final convertedJson = model.toJson();

        expect(convertedJson['id'], originalJson['id']);
        expect(convertedJson['name'], originalJson['name']);
        expect(convertedJson['auto_save_mode'], originalJson['auto_save_mode']);
        expect(convertedJson['auto_collect_source'], originalJson['auto_collect_source']);
      });
    });

    group('엣지 케이스', () {
      test('빈 문자열을 이름으로 사용할 수 있다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'owner_user_id': 'owner-id',
          'name': '',
          'is_default': false,
          'sort_order': 0,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = PaymentMethodModel.fromJson(json);

        expect(result.name, '');
      });

      test('매우 긴 이름을 처리할 수 있다', () {
        final longName = '아주 긴 결제수단 이름 ' * 20;
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'owner_user_id': 'owner-id',
          'name': longName,
          'is_default': false,
          'sort_order': 0,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = PaymentMethodModel.fromJson(json);

        expect(result.name, longName);
      });

      test('알 수 없는 autoSaveMode 값은 manual로 처리된다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'owner_user_id': 'owner-id',
          'name': '테스트',
          'is_default': false,
          'sort_order': 0,
          'created_at': '2026-02-12T10:00:00.000',
          'auto_save_mode': 'unknown_mode',
        };

        final result = PaymentMethodModel.fromJson(json);

        expect(result.autoSaveMode, AutoSaveMode.manual);
      });

      test('알 수 없는 autoCollectSource 값은 sms로 처리된다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'owner_user_id': 'owner-id',
          'name': '테스트',
          'is_default': false,
          'sort_order': 0,
          'created_at': '2026-02-12T10:00:00.000',
          'auto_collect_source': 'unknown_source',
        };

        final result = PaymentMethodModel.fromJson(json);

        expect(result.autoCollectSource, AutoCollectSource.sms);
      });
    });
  });
}
