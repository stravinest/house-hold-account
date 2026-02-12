import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/payment_method.dart';
import 'package:shared_household_account/features/payment_method/presentation/providers/payment_method_provider.dart';
import 'package:shared_household_account/features/payment_method/presentation/widgets/auto_save_mode_dialog.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('AutoSaveModeDialog 위젯 테스트', () {
    late PaymentMethod testPaymentMethod;

    setUp(() {
      testPaymentMethod = TestDataFactory.paymentMethod(
        name: 'Test Card',
        icon: '💳',
        color: '#FF0000',
        canAutoSave: true,
        autoSaveMode: AutoSaveMode.manual,
      );
    });

    testWidgets('다이얼로그가 정상적으로 렌더링된다', (tester) async {
      // Given
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: Scaffold(
              body: AutoSaveModeDialog(paymentMethod: testPaymentMethod),
            ),
          ),
        ),
      );
      await tester.pump();

      // Then: 기본 UI 요소 확인
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('결제수단 정보가 표시된다', (tester) async {
      // Given
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: Scaffold(
              body: AutoSaveModeDialog(paymentMethod: testPaymentMethod),
            ),
          ),
        ),
      );
      await tester.pump();

      // Then: 결제수단 이름 확인
      expect(find.text('Test Card'), findsOneWidget);
    });

    testWidgets('저장 및 취소 버튼이 표시된다', (tester) async {
      // Given
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: Scaffold(
              body: AutoSaveModeDialog(paymentMethod: testPaymentMethod),
            ),
          ),
        ),
      );
      await tester.pump();

      // Then: 버튼 확인
      expect(find.text('취소'), findsOneWidget);
      expect(find.text('저장'), findsOneWidget);
    });

    testWidgets('자동 수집 모드 옵션이 표시된다', (tester) async {
      // Given
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: Scaffold(
              body: AutoSaveModeDialog(paymentMethod: testPaymentMethod),
            ),
          ),
        ),
      );
      await tester.pump();

      // Then: 모드 옵션 확인
      expect(find.byIcon(Icons.notifications_active_outlined), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_outlined), findsOneWidget);
    });
  });
}
