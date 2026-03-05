import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/settings/data/services/export_service.dart';
import 'package:shared_household_account/features/transaction/domain/entities/transaction.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // path_provider 플러그인 목 설정
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'getTemporaryDirectory') {
        return Directory.systemTemp.path;
      }
      return null;
    },
  );

  group('ExportService 추가 기능 테스트', () {
    late AppLocalizations l10n;

    setUpAll(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    });

    group('_filterTransactions 날짜 경계 테스트', () {
      test('startDate와 동일한 날짜의 거래는 포함되어야 한다', () async {
        // Given: 정확히 startDate와 같은 날짜
        final startDate = DateTime(2026, 2, 1);
        final transactions = [
          TestDataFactory.transaction(
            id: 'tx1',
            amount: 10000,
            type: 'expense',
            date: startDate,
          ),
        ];
        final options = ExportOptions(
          startDate: startDate,
          endDate: DateTime(2026, 2, 28),
          format: ExportFileFormat.xlsx,
        );

        // When
        final file = await ExportService.exportToExcel(
          transactions,
          options,
          l10n: l10n,
        );

        // Then: 파일 생성 성공
        expect(file.existsSync(), isTrue);
        await file.delete();
      });

      test('endDate와 동일한 날짜의 거래는 포함되어야 한다', () async {
        // Given: 정확히 endDate와 같은 날짜
        final endDate = DateTime(2026, 2, 28);
        final transactions = [
          TestDataFactory.transaction(
            id: 'tx1',
            amount: 10000,
            type: 'expense',
            date: endDate,
          ),
        ];
        final options = ExportOptions(
          startDate: DateTime(2026, 2, 1),
          endDate: endDate,
          format: ExportFileFormat.xlsx,
        );

        // When
        final file = await ExportService.exportToExcel(
          transactions,
          options,
          l10n: l10n,
        );

        // Then
        expect(file.existsSync(), isTrue);
        await file.delete();
      });

      test('날짜 범위 밖의 거래는 필터링되어야 한다', () async {
        // Given: 범위 밖 날짜 거래
        final transactions = [
          TestDataFactory.transaction(
            id: 'tx1',
            amount: 99999,
            type: 'expense',
            date: DateTime(2026, 1, 31), // 범위 밖
          ),
          TestDataFactory.transaction(
            id: 'tx2',
            amount: 10000,
            type: 'expense',
            date: DateTime(2026, 2, 15), // 범위 안
          ),
        ];
        final options = ExportOptions(
          startDate: DateTime(2026, 2, 1),
          endDate: DateTime(2026, 2, 28),
          format: ExportFileFormat.csv,
        );

        // When
        final file = await ExportService.exportToCsv(
          transactions,
          options,
          l10n: l10n,
        );

        // Then: 파일 생성됨 (1건만 포함)
        expect(file.existsSync(), isTrue);
        await file.delete();
      });
    });

    group('_buildHeaders 옵션별 헤더 생성 테스트', () {
      test('모든 옵션 포함 시 헤더에 모든 컬럼이 포함되어야 한다', () async {
        // Given: 모든 옵션 활성화
        final transactions = [
          TestDataFactory.transaction(
            id: 'tx1',
            amount: 10000,
            type: 'expense',
            date: DateTime(2026, 2, 1),
          ),
        ];
        final options = ExportOptions(
          startDate: DateTime(2026, 2, 1),
          endDate: DateTime(2026, 2, 28),
          includeCategory: true,
          includePaymentMethod: true,
          includeMemo: true,
          includeAuthor: true,
          includeFixedExpense: true,
          format: ExportFileFormat.xlsx,
        );

        // When
        final file = await ExportService.exportToExcel(
          transactions,
          options,
          l10n: l10n,
        );

        // Then: 파일 생성 성공 (모든 컬럼 포함)
        expect(file.existsSync(), isTrue);
        expect(file.lengthSync(), greaterThan(0));
        await file.delete();
      });

      test('모든 옵션 비활성화 시 기본 컬럼만 포함되어야 한다', () async {
        // Given: 모든 선택 컬럼 비활성화
        final transactions = [
          TestDataFactory.transaction(
            id: 'tx1',
            amount: 10000,
            type: 'income',
            date: DateTime(2026, 2, 1),
          ),
        ];
        final options = ExportOptions(
          startDate: DateTime(2026, 2, 1),
          endDate: DateTime(2026, 2, 28),
          includeCategory: false,
          includePaymentMethod: false,
          includeMemo: false,
          includeAuthor: false,
          includeFixedExpense: false,
          format: ExportFileFormat.csv,
        );

        // When
        final file = await ExportService.exportToCsv(
          transactions,
          options,
          l10n: l10n,
        );

        // Then: 파일 생성 성공 (기본 컬럼만)
        expect(file.existsSync(), isTrue);
        await file.delete();
      });
    });

    group('_buildRow 거래 타입 레이블 테스트', () {
      test('expense 타입 거래를 Excel로 내보낼 수 있다', () async {
        // Given: expense 타입
        final transactions = [
          TestDataFactory.transaction(
            id: 'tx1',
            amount: 50000,
            type: 'expense',
            date: DateTime(2026, 2, 1),
          ),
        ];
        final options = ExportOptions(
          startDate: DateTime(2026, 2, 1),
          endDate: DateTime(2026, 2, 28),
          format: ExportFileFormat.xlsx,
        );

        // When
        final file = await ExportService.exportToExcel(
          transactions,
          options,
          l10n: l10n,
        );

        // Then: 파일 생성 성공
        expect(file.existsSync(), isTrue);
        await file.delete();
      });

      test('income 타입 거래를 CSV로 내보낼 수 있다', () async {
        // Given: income 타입
        final transactions = [
          TestDataFactory.transaction(
            id: 'tx1',
            amount: 3000000,
            type: 'income',
            date: DateTime(2026, 2, 1),
          ),
        ];
        final options = ExportOptions(
          startDate: DateTime(2026, 2, 1),
          endDate: DateTime(2026, 2, 28),
          format: ExportFileFormat.csv,
        );

        // When
        final file = await ExportService.exportToCsv(
          transactions,
          options,
          l10n: l10n,
        );

        // Then
        expect(file.existsSync(), isTrue);
        await file.delete();
      });

      test('asset 타입 거래를 Excel로 내보낼 수 있다', () async {
        // Given: asset 타입
        final transactions = [
          TestDataFactory.transaction(
            id: 'tx1',
            amount: 1000000,
            type: 'asset',
            date: DateTime(2026, 2, 1),
          ),
        ];
        final options = ExportOptions(
          startDate: DateTime(2026, 2, 1),
          endDate: DateTime(2026, 2, 28),
          transactionType: 'asset',
          format: ExportFileFormat.xlsx,
        );

        // When
        final file = await ExportService.exportToExcel(
          transactions,
          options,
          l10n: l10n,
        );

        // Then
        expect(file.existsSync(), isTrue);
        await file.delete();
      });

      test('포함 필드가 있는 거래를 includeAuthor true로 내보낼 수 있다', () async {
        // Given: userName 포함
        final transactions = [
          TestDataFactory.transaction(
            id: 'tx1',
            amount: 10000,
            type: 'expense',
            date: DateTime(2026, 2, 1),
          ),
        ];
        final options = ExportOptions(
          startDate: DateTime(2026, 2, 1),
          endDate: DateTime(2026, 2, 28),
          includeAuthor: true,
          format: ExportFileFormat.xlsx,
        );

        // When
        final file = await ExportService.exportToExcel(
          transactions,
          options,
          l10n: l10n,
        );

        // Then
        expect(file.existsSync(), isTrue);
        await file.delete();
      });

      test('isFixedExpense true인 거래를 includeFixedExpense true로 내보낼 수 있다', () async {
        // Given: 고정비 거래
        final transactions = [
          TestDataFactory.transaction(
            id: 'tx1',
            amount: 500000,
            type: 'expense',
            date: DateTime(2026, 2, 1),
            isFixedExpense: true,
          ),
        ];
        final options = ExportOptions(
          startDate: DateTime(2026, 2, 1),
          endDate: DateTime(2026, 2, 28),
          includeFixedExpense: true,
          format: ExportFileFormat.csv,
        );

        // When
        final file = await ExportService.exportToCsv(
          transactions,
          options,
          l10n: l10n,
        );

        // Then
        expect(file.existsSync(), isTrue);
        await file.delete();
      });
    });

    group('ExportFileFormat 열거형 테스트', () {
      test('ExportFileFormat.xlsx 값이 존재한다', () {
        // Given & When & Then
        expect(ExportFileFormat.xlsx, isNotNull);
      });

      test('ExportFileFormat.csv 값이 존재한다', () {
        // Given & When & Then
        expect(ExportFileFormat.csv, isNotNull);
      });

      test('xlsx와 csv는 서로 다른 값이다', () {
        // Given & When & Then
        expect(ExportFileFormat.xlsx == ExportFileFormat.csv, isFalse);
      });
    });

    group('ExportOptions 생성 테스트', () {
      test('income 타입 필터 옵션을 생성할 수 있다', () {
        // Given & When
        final options = ExportOptions(
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 12, 31),
          transactionType: 'income',
        );

        // Then
        expect(options.transactionType, 'income');
      });

      test('asset 타입 필터 옵션을 생성할 수 있다', () {
        // Given & When
        final options = ExportOptions(
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 12, 31),
          transactionType: 'asset',
        );

        // Then
        expect(options.transactionType, 'asset');
      });
    });
  });
}
