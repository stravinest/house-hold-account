import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/data/models/learned_push_format_model.dart';
import 'package:shared_household_account/features/payment_method/data/services/financial_constants.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/learned_push_format.dart';

void main() {
  group('LearnedPushFormatModel', () {
    final testCreatedAt = DateTime(2026, 2, 12, 10, 0, 0);
    final testUpdatedAt = DateTime(2026, 2, 12, 11, 0, 0);

    final learnedFormatModel = LearnedPushFormatModel(
      id: 'test-id',
      paymentMethodId: 'payment-method-id',
      packageName: 'com.kbcard.cxh.appcard',
      appKeywords: ['KB Pay', 'KB카드'],
      amountRegex: r'(\d{1,3}(,\d{3})*|\d+)원',
      typeKeywords: {
        'expense': ['승인', '결제'],
        'income': ['입금', '수령'],
      },
      merchantRegex: r'가맹점\s*[:：]\s*(.+)',
      dateRegex: r'(\d{2})/(\d{2})\s+(\d{2}):(\d{2})',
      sampleNotification: '승인 10,000원\nKB Pay\n스타벅스',
      confidence: 0.9,
      matchCount: 10,
      createdAt: testCreatedAt,
      updatedAt: testUpdatedAt,
    );

    test('LearnedPushFormat 엔티티를 확장한다', () {
      expect(learnedFormatModel, isA<LearnedPushFormat>());
    });

    group('fromJson', () {
      test('JSON에서 올바르게 역직렬화된다', () {
        final json = {
          'id': 'json-id',
          'payment_method_id': 'payment-method-id',
          'package_name': 'com.kbcard.cxh.appcard',
          'app_keywords': ['KB Pay', 'KB카드'],
          'amount_regex': r'\d+원',
          'type_keywords': {
            'expense': ['승인', '결제'],
            'income': ['입금'],
          },
          'merchant_regex': r'가맹점\s*[:：]\s*(.+)',
          'date_regex': r'(\d{2})/(\d{2})',
          'sample_notification': '승인 10,000원',
          'confidence': 0.95,
          'match_count': 20,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = LearnedPushFormatModel.fromJson(json);

        expect(result.id, 'json-id');
        expect(result.paymentMethodId, 'payment-method-id');
        expect(result.packageName, 'com.kbcard.cxh.appcard');
        expect(result.appKeywords, ['KB Pay', 'KB카드']);
        expect(result.amountRegex, r'\d+원');
        expect(result.typeKeywords['expense'], ['승인', '결제']);
        expect(result.typeKeywords['income'], ['입금']);
        expect(result.merchantRegex, r'가맹점\s*[:：]\s*(.+)');
        expect(result.dateRegex, r'(\d{2})/(\d{2})');
        expect(result.sampleNotification, '승인 10,000원');
        expect(result.confidence, 0.95);
        expect(result.matchCount, 20);
      });

      test('typeKeywords가 String(JSON encoded)일 때 파싱한다', () {
        final typeKeywordsMap = {
          'expense': ['승인', '결제'],
          'income': ['입금'],
        };
        final json = {
          'id': 'json-id',
          'payment_method_id': 'payment-method-id',
          'package_name': 'com.test.app',
          'app_keywords': ['테스트'],
          'amount_regex': r'\d+원',
          'type_keywords': jsonEncode(typeKeywordsMap),
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = LearnedPushFormatModel.fromJson(json);

        expect(result.typeKeywords['expense'], ['승인', '결제']);
        expect(result.typeKeywords['income'], ['입금']);
      });

      test('typeKeywords가 null일 때 기본값을 사용한다', () {
        final json = {
          'id': 'json-id',
          'payment_method_id': 'payment-method-id',
          'package_name': 'com.test.app',
          'app_keywords': ['테스트'],
          'amount_regex': r'\d+원',
          'type_keywords': null,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = LearnedPushFormatModel.fromJson(json);

        expect(result.typeKeywords, FinancialConstants.defaultTypeKeywords);
      });

      test('appKeywords가 null일 때 빈 리스트를 사용한다', () {
        final json = {
          'id': 'json-id',
          'payment_method_id': 'payment-method-id',
          'package_name': 'com.test.app',
          'app_keywords': null,
          'amount_regex': r'\d+원',
          'type_keywords': {
            'expense': ['승인'],
          },
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = LearnedPushFormatModel.fromJson(json);

        expect(result.appKeywords, isEmpty);
      });

      test('null 값들을 올바르게 처리한다', () {
        final json = {
          'id': 'json-id',
          'payment_method_id': 'payment-method-id',
          'package_name': 'com.test.app',
          'app_keywords': [],
          'amount_regex': r'\d+원',
          'type_keywords': {
            'expense': ['승인'],
          },
          'merchant_regex': null,
          'date_regex': null,
          'sample_notification': null,
          'confidence': null,
          'match_count': null,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = LearnedPushFormatModel.fromJson(json);

        expect(result.merchantRegex, null);
        expect(result.dateRegex, null);
        expect(result.sampleNotification, null);
        expect(result.confidence, 0.8);
        expect(result.matchCount, 0);
      });
    });

    group('toJson', () {
      test('JSON으로 올바르게 직렬화된다', () {
        final json = learnedFormatModel.toJson();

        expect(json['id'], 'test-id');
        expect(json['payment_method_id'], 'payment-method-id');
        expect(json['package_name'], 'com.kbcard.cxh.appcard');
        expect(json['app_keywords'], ['KB Pay', 'KB카드']);
        expect(json['amount_regex'], r'(\d{1,3}(,\d{3})*|\d+)원');
        expect(json['type_keywords']['expense'], ['승인', '결제']);
        expect(json['type_keywords']['income'], ['입금', '수령']);
        expect(json['merchant_regex'], r'가맹점\s*[:：]\s*(.+)');
        expect(json['date_regex'], r'(\d{2})/(\d{2})\s+(\d{2}):(\d{2})');
        expect(json['sample_notification'], '승인 10,000원\nKB Pay\n스타벅스');
        expect(json['confidence'], 0.9);
        expect(json['match_count'], 10);
        expect(json['created_at'], isA<String>());
        expect(json['updated_at'], isA<String>());
      });

      test('null 값들을 올바르게 직렬화한다', () {
        final model = LearnedPushFormatModel(
          id: 'test-id',
          paymentMethodId: 'payment-method-id',
          packageName: 'com.test.app',
          appKeywords: [],
          amountRegex: r'\d+원',
          typeKeywords: {},
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final json = model.toJson();

        expect(json['merchant_regex'], null);
        expect(json['date_regex'], null);
        expect(json['sample_notification'], null);
      });
    });

    group('toCreateJson', () {
      test('생성용 JSON을 올바르게 만든다', () {
        final json = LearnedPushFormatModel.toCreateJson(
          paymentMethodId: 'payment-method-id',
          packageName: 'com.kbcard.cxh.appcard',
          appKeywords: ['KB Pay', 'KB카드'],
          amountRegex: r'\d+원',
          typeKeywords: {
            'expense': ['승인', '결제'],
          },
          merchantRegex: r'가맹점\s*[:：]\s*(.+)',
          dateRegex: r'(\d{2})/(\d{2})',
          sampleNotification: '승인 10,000원',
          confidence: 0.95,
        );

        expect(json['payment_method_id'], 'payment-method-id');
        expect(json['package_name'], 'com.kbcard.cxh.appcard');
        expect(json['app_keywords'], ['KB Pay', 'KB카드']);
        expect(json['amount_regex'], r'\d+원');
        expect(json['type_keywords']['expense'], ['승인', '결제']);
        expect(json['merchant_regex'], r'가맹점\s*[:：]\s*(.+)');
        expect(json['date_regex'], r'(\d{2})/(\d{2})');
        expect(json['sample_notification'], '승인 10,000원');
        expect(json['confidence'], 0.95);
      });

      test('기본값이 올바르게 설정된다', () {
        final json = LearnedPushFormatModel.toCreateJson(
          paymentMethodId: 'payment-method-id',
          packageName: 'com.test.app',
          amountRegex: r'\d+원',
        );

        expect(json['app_keywords'], isEmpty);
        expect(json['type_keywords'], FinancialConstants.defaultTypeKeywords);
        expect(json['confidence'], 0.8);
      });

      test('null 필드들은 JSON에 포함되지 않는다', () {
        final json = LearnedPushFormatModel.toCreateJson(
          paymentMethodId: 'payment-method-id',
          packageName: 'com.test.app',
          amountRegex: r'\d+원',
        );

        expect(json.containsKey('merchant_regex'), false);
        expect(json.containsKey('date_regex'), false);
        expect(json.containsKey('sample_notification'), false);
      });
    });

    group('fromEntity / toEntity', () {
      test('Entity를 Model로 변환할 수 있다', () {
        final entity = LearnedPushFormat(
          id: 'entity-id',
          paymentMethodId: 'payment-method-id',
          packageName: 'com.test.app',
          appKeywords: ['테스트'],
          amountRegex: r'\d+원',
          typeKeywords: {'expense': ['승인']},
          confidence: 0.9,
          matchCount: 15,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final model = LearnedPushFormatModel.fromEntity(entity);

        expect(model.id, entity.id);
        expect(model.paymentMethodId, entity.paymentMethodId);
        expect(model.packageName, entity.packageName);
        expect(model.appKeywords, entity.appKeywords);
        expect(model.amountRegex, entity.amountRegex);
        expect(model.typeKeywords, entity.typeKeywords);
        expect(model.confidence, entity.confidence);
        expect(model.matchCount, entity.matchCount);
      });

      test('Model을 Entity로 변환할 수 있다', () {
        final entity = learnedFormatModel.toEntity();

        expect(entity, isA<LearnedPushFormat>());
        expect(entity.id, learnedFormatModel.id);
        expect(entity.paymentMethodId, learnedFormatModel.paymentMethodId);
        expect(entity.packageName, learnedFormatModel.packageName);
        expect(entity.appKeywords, learnedFormatModel.appKeywords);
        expect(entity.amountRegex, learnedFormatModel.amountRegex);
        expect(entity.typeKeywords, learnedFormatModel.typeKeywords);
        expect(entity.confidence, learnedFormatModel.confidence);
        expect(entity.matchCount, learnedFormatModel.matchCount);
      });
    });

    group('fromJson -> toJson 왕복 변환', () {
      test('데이터가 손실 없이 변환된다', () {
        final originalJson = {
          'id': 'test-id',
          'payment_method_id': 'payment-method-id',
          'package_name': 'com.test.app',
          'app_keywords': ['테스트'],
          'amount_regex': r'\d+원',
          'type_keywords': {
            'expense': ['승인', '결제'],
          },
          'merchant_regex': r'가맹점\s*[:：]\s*(.+)',
          'date_regex': r'(\d{2})/(\d{2})',
          'sample_notification': '승인 10,000원',
          'confidence': 0.9,
          'match_count': 10,
          'created_at': '2026-02-12T10:00:00.000Z',
          'updated_at': '2026-02-12T11:00:00.000Z',
        };

        final model = LearnedPushFormatModel.fromJson(originalJson);
        final convertedJson = model.toJson();

        expect(convertedJson['id'], originalJson['id']);
        expect(convertedJson['package_name'], originalJson['package_name']);
        expect(convertedJson['amount_regex'], originalJson['amount_regex']);
        expect(convertedJson['confidence'], originalJson['confidence']);
        expect(convertedJson['match_count'], originalJson['match_count']);
      });
    });

    group('엣지 케이스', () {
      test('빈 appKeywords를 처리할 수 있다', () {
        final json = {
          'id': 'test-id',
          'payment_method_id': 'payment-method-id',
          'package_name': 'com.test.app',
          'app_keywords': [],
          'amount_regex': r'\d+원',
          'type_keywords': {
            'expense': ['승인'],
          },
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = LearnedPushFormatModel.fromJson(json);

        expect(result.appKeywords, isEmpty);
      });

      test('복잡한 typeKeywords를 처리할 수 있다', () {
        final json = {
          'id': 'test-id',
          'payment_method_id': 'payment-method-id',
          'package_name': 'com.test.app',
          'app_keywords': [],
          'amount_regex': r'\d+원',
          'type_keywords': {
            'expense': ['승인', '결제'],
            'income': ['입금'],
          },
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = LearnedPushFormatModel.fromJson(json);

        expect(result.typeKeywords['expense'], ['승인', '결제']);
        expect(result.typeKeywords['income'], ['입금']);
      });

      test('매우 긴 패키지명을 처리할 수 있다', () {
        final longPackage = 'com.${'very' * 20}.long.package.name';
        final json = LearnedPushFormatModel.toCreateJson(
          paymentMethodId: 'payment-method-id',
          packageName: longPackage,
          amountRegex: r'\d+원',
        );

        expect(json['package_name'], longPackage);
      });

      test('confidence 경계값을 처리할 수 있다', () {
        final json1 = LearnedPushFormatModel.toCreateJson(
          paymentMethodId: 'payment-method-id',
          packageName: 'com.test.app',
          amountRegex: r'\d+원',
          confidence: 0.0,
        );
        final json2 = LearnedPushFormatModel.toCreateJson(
          paymentMethodId: 'payment-method-id',
          packageName: 'com.test.app',
          amountRegex: r'\d+원',
          confidence: 1.0,
        );

        expect(json1['confidence'], 0.0);
        expect(json2['confidence'], 1.0);
      });

      test('매우 긴 sampleNotification을 처리할 수 있다', () {
        final longNotification = '승인 10,000원\n' * 100;
        final model = LearnedPushFormatModel(
          id: learnedFormatModel.id,
          paymentMethodId: learnedFormatModel.paymentMethodId,
          packageName: learnedFormatModel.packageName,
          appKeywords: learnedFormatModel.appKeywords,
          amountRegex: learnedFormatModel.amountRegex,
          typeKeywords: learnedFormatModel.typeKeywords,
          merchantRegex: learnedFormatModel.merchantRegex,
          dateRegex: learnedFormatModel.dateRegex,
          sampleNotification: longNotification,
          confidence: learnedFormatModel.confidence,
          matchCount: learnedFormatModel.matchCount,
          createdAt: learnedFormatModel.createdAt,
          updatedAt: learnedFormatModel.updatedAt,
        );
        final json = model.toJson();

        expect(json['sample_notification'], longNotification);
      });
    });
  });
}
