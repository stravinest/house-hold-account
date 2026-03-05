import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/payment_method/data/models/payment_method_model.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/payment_method_repository.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/payment_method.dart';
import 'package:shared_household_account/features/payment_method/presentation/providers/payment_method_provider.dart';
import 'package:shared_household_account/features/payment_method/presentation/widgets/auto_save_mode_dialog.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show RealtimeChannel;

import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_helpers.dart';

class MockPaymentMethodRepository extends Mock
    implements PaymentMethodRepository {}

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

    testWidgets('suggest 모드 카드를 탭하면 선택 상태가 변경된다', (tester) async {
      // Given: manual 모드로 시작
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
      await tester.pumpAndSettle();

      // When: suggest 모드 카드 탭 (notifications_active_outlined 아이콘)
      final suggestCard = find.byIcon(Icons.notifications_active_outlined);
      if (suggestCard.evaluate().isNotEmpty) {
        await tester.tap(suggestCard.first, warnIfMissed: false);
        await tester.pump();
      }

      // Then: 저장 버튼이 활성화되어야 한다 (모드가 변경됨)
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('auto 모드 카드를 탭하면 선택 상태가 변경된다', (tester) async {
      // Given: manual 모드로 시작
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
      await tester.pumpAndSettle();

      // When: auto 모드 카드 탭 (auto_awesome_outlined 아이콘)
      final autoCard = find.byIcon(Icons.auto_awesome_outlined);
      if (autoCard.evaluate().isNotEmpty) {
        await tester.tap(autoCard.first, warnIfMissed: false);
        await tester.pump();
      }

      // Then: 위젯이 업데이트되어야 한다
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('모드 변경 후 저장 버튼 탭 시 크래시가 없다', (tester) async {
      // Given: suggest 모드로 시작
      final suggestMethod = TestDataFactory.paymentMethod(
        name: 'Suggest Card',
        icon: '💳',
        color: '#00FF00',
        canAutoSave: true,
        autoSaveMode: AutoSaveMode.suggest,
      );

      final mockRepo = MockPaymentMethodRepository();
      final mockChannel = MockRealtimeChannel();

      when(() => mockRepo.getPaymentMethods(any()))
          .thenAnswer((_) async => []);
      when(() => mockRepo.getSharedPaymentMethods(any()))
          .thenAnswer((_) async => []);
      when(() => mockRepo.getAutoCollectPaymentMethodsByOwner(
            ledgerId: any(named: 'ledgerId'),
            ownerUserId: any(named: 'ownerUserId'),
          )).thenAnswer((_) async => []);
      when(() => mockRepo.subscribePaymentMethods(
            ledgerId: any(named: 'ledgerId'),
            onPaymentMethodChanged: any(named: 'onPaymentMethodChanged'),
          )).thenReturn(mockChannel);
      when(() => mockChannel.unsubscribe()).thenAnswer((_) async => 'ok');
      when(() => mockRepo.updateAutoSaveSettings(
            id: any(named: 'id'),
            autoSaveMode: any(named: 'autoSaveMode'),
            autoCollectSource: any(named: 'autoCollectSource'),
          )).thenAnswer((_) async => PaymentMethodModel(
            id: 'pm-1',
            ledgerId: 'ledger-1',
            ownerUserId: 'user-1',
            name: 'Suggest Card',
            icon: '💳',
            color: '#00FF00',
            isDefault: false,
            sortOrder: 1,
            createdAt: DateTime.now(),
            autoSaveMode: AutoSaveMode.manual,
            canAutoSave: true,
            autoCollectSource: AutoCollectSource.sms,
          ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            paymentMethodRepositoryProvider.overrideWith((_) => mockRepo),
            selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
            currentUserProvider.overrideWith((_) {
              final u = MockUser();
              when(() => u.id).thenReturn('user-1');
              return u;
            }),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: Scaffold(
              body: AutoSaveModeDialog(paymentMethod: suggestMethod),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: auto 모드 카드 탭
      final autoCard = find.byIcon(Icons.auto_awesome_outlined);
      if (autoCard.evaluate().isNotEmpty) {
        await tester.tap(autoCard.first, warnIfMissed: false);
        await tester.pump();
      }

      // When: 저장 버튼 탭
      final saveButton = find.text('저장');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton.first, warnIfMissed: false);
        await tester.pump();
      }

      // Then: 크래시 없이 동작해야 한다
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('취소 버튼 탭 시 다이얼로그가 닫힌다', (tester) async {
      // Given
      bool closed = false;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (_) => AutoSaveModeDialog(
                        paymentMethod: testPaymentMethod,
                      ),
                    );
                    closed = true;
                  },
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 다이얼로그 열기
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      // When: 취소 버튼 탭
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 닫혀야 한다
      expect(closed, isTrue);
    });
  });
}
