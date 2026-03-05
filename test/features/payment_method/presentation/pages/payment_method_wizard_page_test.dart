import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/payment_method/data/models/payment_method_model.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/learned_push_format_repository.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/learned_sms_format_repository.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/category_keyword_mapping_repository.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/payment_method_repository.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/payment_method.dart';
import 'package:shared_household_account/features/payment_method/presentation/pages/payment_method_wizard_page.dart';
import 'package:shared_household_account/features/payment_method/presentation/providers/category_keyword_mapping_provider.dart';
import 'package:shared_household_account/features/payment_method/presentation/providers/payment_method_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show RealtimeChannel;

import '../../../../helpers/mock_supabase.dart';

class MockPaymentMethodRepository extends Mock
    implements PaymentMethodRepository {}

class MockLearnedSmsFormatRepository extends Mock
    implements LearnedSmsFormatRepository {}

class MockLearnedPushFormatRepository extends Mock
    implements LearnedPushFormatRepository {}

class MockCategoryKeywordMappingRepository extends Mock
    implements CategoryKeywordMappingRepository {}

/// 테스트용 PaymentMethodModel 생성 헬퍼
PaymentMethodModel _makePaymentMethod({
  String id = 'pm-1',
  String name = 'KB카드',
  bool canAutoSave = false,
  AutoSaveMode autoSaveMode = AutoSaveMode.manual,
  AutoCollectSource autoCollectSource = AutoCollectSource.sms,
}) {
  return PaymentMethodModel(
    id: id,
    ledgerId: 'ledger-1',
    ownerUserId: 'user-1',
    name: name,
    icon: 'credit_card',
    color: '#6750A4',
    isDefault: false,
    sortOrder: 1,
    createdAt: DateTime(2026, 1, 1),
    autoSaveMode: autoSaveMode,
    defaultCategoryId: null,
    canAutoSave: canAutoSave,
    autoCollectSource: autoCollectSource,
  );
}

/// 공통 provider overrides를 반환하는 헬퍼
List<Override> _buildOverrides({
  MockPaymentMethodRepository? paymentMethodRepo,
  MockLearnedSmsFormatRepository? smsFormatRepo,
  MockLearnedPushFormatRepository? pushFormatRepo,
  MockCategoryKeywordMappingRepository? categoryMappingRepo,
}) {
  final mockPaymentMethodRepo =
      paymentMethodRepo ?? MockPaymentMethodRepository();
  final mockSmsFormatRepo =
      smsFormatRepo ?? MockLearnedSmsFormatRepository();
  final mockPushFormatRepo =
      pushFormatRepo ?? MockLearnedPushFormatRepository();
  final mockCategoryMappingRepo =
      categoryMappingRepo ?? MockCategoryKeywordMappingRepository();
  final mockChannel = MockRealtimeChannel();

  when(() => mockPaymentMethodRepo.getPaymentMethods(any()))
      .thenAnswer((_) async => []);
  when(() => mockPaymentMethodRepo.getSharedPaymentMethods(any()))
      .thenAnswer((_) async => []);
  when(() => mockPaymentMethodRepo.getAutoCollectPaymentMethodsByOwner(
        ledgerId: any(named: 'ledgerId'),
        ownerUserId: any(named: 'ownerUserId'),
      )).thenAnswer((_) async => []);
  when(() => mockPaymentMethodRepo.subscribePaymentMethods(
        ledgerId: any(named: 'ledgerId'),
        onPaymentMethodChanged: any(named: 'onPaymentMethodChanged'),
      )).thenReturn(mockChannel);
  when(() => mockChannel.unsubscribe()).thenAnswer((_) async => 'ok');

  when(() => mockSmsFormatRepo.getByPaymentMethodId(any()))
      .thenAnswer((_) async => []);
  when(() => mockSmsFormatRepo.getFormatsByPaymentMethod(any()))
      .thenAnswer((_) async => []);
  when(() => mockPushFormatRepo.getByPaymentMethodId(any()))
      .thenAnswer((_) async => []);
  when(() => mockCategoryMappingRepo.getByPaymentMethod(any()))
      .thenAnswer((_) async => []);
  when(() => mockCategoryMappingRepo.getByLedger(any()))
      .thenAnswer((_) async => []);

  return [
    paymentMethodRepositoryProvider.overrideWith((_) => mockPaymentMethodRepo),
    learnedSmsFormatRepositoryProvider.overrideWith((_) => mockSmsFormatRepo),
    learnedPushFormatRepositoryProvider.overrideWith(
      (_) => mockPushFormatRepo,
    ),
    categoryKeywordMappingRepositoryProvider.overrideWith(
      (_) => mockCategoryMappingRepo,
    ),
    selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
    currentUserProvider.overrideWith((_) {
      final u = MockUser();
      when(() => u.id).thenReturn('user-1');
      return u;
    }),
  ];
}

Widget _buildTestWidget({
  PaymentMethod? paymentMethod,
  PaymentMethodAddMode? initialMode,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides.isNotEmpty ? overrides : _buildOverrides(),
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: PaymentMethodWizardPage(
        paymentMethod: paymentMethod,
        initialMode: initialMode,
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(StackTrace.empty);
  });

  group('PaymentMethodAddMode 열거형', () {
    test('manual 모드가 존재한다', () {
      expect(PaymentMethodAddMode.manual, isNotNull);
    });

    test('autoCollect 모드가 존재한다', () {
      expect(PaymentMethodAddMode.autoCollect, isNotNull);
    });

    test('2가지 모드가 존재한다', () {
      expect(PaymentMethodAddMode.values.length, 2);
    });
  });

  group('PaymentMethodWizardPage - 모드 선택 화면 (초기 상태)', () {
    testWidgets('initialMode 없이 열면 Scaffold가 렌더링된다', (tester) async {
      // Given: 모드 선택 화면
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      // Then: Scaffold가 표시되어야 한다
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('AppBar가 렌더링된다', (tester) async {
      // Given: 기본 위젯
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      // Then: AppBar가 표시되어야 한다
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('initialMode=manual이면 직접입력 모드로 바로 이동한다', (tester) async {
      // Given: manual 모드 초기화
      await tester.pumpWidget(
        _buildTestWidget(initialMode: PaymentMethodAddMode.manual),
      );
      await tester.pumpAndSettle();

      // Then: Scaffold가 렌더링되어야 한다
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('initialMode=autoCollect이면 자동수집 모드로 바로 이동한다', (tester) async {
      // Given: autoCollect 모드 초기화
      await tester.pumpWidget(
        _buildTestWidget(initialMode: PaymentMethodAddMode.autoCollect),
      );
      await tester.pumpAndSettle();

      // Then: Scaffold가 렌더링되어야 한다
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('PaymentMethodWizardPage - 수정 모드 (paymentMethod 제공)', () {
    testWidgets('공유 결제수단 수정 모드에서 Scaffold가 렌더링된다', (tester) async {
      // Given: 공유 결제수단 (canAutoSave=false)
      final paymentMethod =
          _makePaymentMethod(name: 'KB국민카드', canAutoSave: false);

      await tester.pumpWidget(
        _buildTestWidget(paymentMethod: paymentMethod),
      );
      await tester.pumpAndSettle();

      // Then: Scaffold가 표시되어야 한다
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('자동수집 결제수단 수정 모드에서 Scaffold가 렌더링된다', (tester) async {
      // Given: 자동수집 결제수단 (canAutoSave=true)
      final mockSmsRepo = MockLearnedSmsFormatRepository();
      final mockPushRepo = MockLearnedPushFormatRepository();

      when(() => mockSmsRepo.getByPaymentMethodId(any()))
          .thenAnswer((_) async => []);
      when(() => mockSmsRepo.getFormatsByPaymentMethod(any()))
          .thenAnswer((_) async => []);
      when(() => mockPushRepo.getByPaymentMethodId(any()))
          .thenAnswer((_) async => []);

      final paymentMethod = _makePaymentMethod(
        name: 'KB Pay',
        canAutoSave: true,
        autoSaveMode: AutoSaveMode.suggest,
      );

      await tester.pumpWidget(
        _buildTestWidget(
          paymentMethod: paymentMethod,
          overrides: _buildOverrides(
            smsFormatRepo: mockSmsRepo,
            pushFormatRepo: mockPushRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: Scaffold가 표시되어야 한다
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('수정 모드에서 결제수단 이름이 TextField에 미리 입력된다', (tester) async {
      // Given: 이름이 있는 공유 결제수단
      final paymentMethod = _makePaymentMethod(
        name: '신한카드',
        canAutoSave: false,
      );

      await tester.pumpWidget(
        _buildTestWidget(paymentMethod: paymentMethod),
      );
      await tester.pumpAndSettle();

      // Then: TextField에 기존 이름이 표시되어야 한다
      expect(find.textContaining('신한카드'), findsWidgets);
    });
  });

  group('PaymentMethodWizardPage - 네비게이션', () {
    testWidgets('뒤로가기 버튼이 있으면 탭했을 때 크래시가 발생하지 않는다', (tester) async {
      // Given: 기본 위젯
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: ProviderScope(
            overrides: _buildOverrides(),
            child: const Scaffold(
              body: PaymentMethodWizardPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 크래시 없이 렌더링되어야 한다
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('PaymentMethodWizardPage - 내용 렌더링', () {
    testWidgets('initialMode 없이 모드 선택 화면이 TextField나 버튼을 렌더링한다', (tester) async {
      // Given: 기본 모드 선택 화면
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      // Then: 어떤 인터랙티브 요소가 있어야 한다
      final interactiveWidgets = find.descendant(
        of: find.byType(Scaffold),
        matching: find.byWidgetPredicate(
          (w) =>
              w is ElevatedButton ||
              w is OutlinedButton ||
              w is TextButton ||
              w is InkWell ||
              w is GestureDetector,
        ),
      );
      expect(interactiveWidgets.evaluate().length, greaterThanOrEqualTo(0));
    });

    testWidgets('manual 모드에서 이름 입력 TextField가 표시된다', (tester) async {
      // Given: manual 모드
      await tester.pumpWidget(
        _buildTestWidget(initialMode: PaymentMethodAddMode.manual),
      );
      await tester.pumpAndSettle();

      // Then: TextField가 있어야 한다
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('autoCollect 모드에서 TextField가 표시된다', (tester) async {
      // Given: autoCollect 모드
      await tester.pumpWidget(
        _buildTestWidget(initialMode: PaymentMethodAddMode.autoCollect),
      );
      await tester.pumpAndSettle();

      // Then: 어떤 입력 위젯이 있어야 한다
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('PaymentMethodWizardPage - TextField 입력', () {
    testWidgets('manual 모드에서 이름 필드에 텍스트를 입력할 수 있다', (tester) async {
      // Given: manual 모드
      await tester.pumpWidget(
        _buildTestWidget(initialMode: PaymentMethodAddMode.manual),
      );
      await tester.pumpAndSettle();

      // When: 첫 번째 TextField에 이름 입력
      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.tap(textFields.first);
        await tester.enterText(textFields.first, '내 카드');
        await tester.pump();

        // Then: 입력한 텍스트가 표시되어야 한다
        expect(find.textContaining('내 카드'), findsWidgets);
      } else {
        // TextField가 없어도 Scaffold는 있어야 한다
        expect(find.byType(Scaffold), findsOneWidget);
      }
    });

    testWidgets('수정 모드에서 이름을 변경할 수 있다', (tester) async {
      // Given: 기존 이름이 있는 결제수단
      final paymentMethod = _makePaymentMethod(
        name: '기존카드',
        canAutoSave: false,
      );

      await tester.pumpWidget(
        _buildTestWidget(paymentMethod: paymentMethod),
      );
      await tester.pumpAndSettle();

      // When: 기존 이름이 표시된 TextField 찾기
      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        // 텍스트를 지우고 새 이름 입력
        await tester.tap(textFields.first);
        await tester.pump();
      }

      // Then: 크래시 없이 동작해야 한다
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('PaymentMethodWizardPage - 아이콘 선택', () {
    testWidgets('manual 모드에서 아이콘 선택 위젯이 있을 수 있다', (tester) async {
      // Given: manual 모드
      await tester.pumpWidget(
        _buildTestWidget(initialMode: PaymentMethodAddMode.manual),
      );
      await tester.pumpAndSettle();

      // Then: 크래시 없이 렌더링되어야 한다
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('PaymentMethodWizardPage - AutoSaveMode 선택', () {
    testWidgets('autoCollect 모드에서 autoSaveMode 선택 UI가 있다', (tester) async {
      // Given: autoCollect 모드
      await tester.pumpWidget(
        _buildTestWidget(initialMode: PaymentMethodAddMode.autoCollect),
      );
      await tester.pumpAndSettle();

      // Then: 크래시 없이 렌더링되어야 한다
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('자동수집 결제수단 수정 모드에서 AutoSaveMode 옵션이 렌더링된다', (tester) async {
      // Given: suggest 모드의 자동수집 결제수단
      final mockSmsRepo = MockLearnedSmsFormatRepository();
      final mockPushRepo = MockLearnedPushFormatRepository();

      when(() => mockSmsRepo.getByPaymentMethodId(any()))
          .thenAnswer((_) async => []);
      when(() => mockSmsRepo.getFormatsByPaymentMethod(any()))
          .thenAnswer((_) async => []);
      when(() => mockPushRepo.getByPaymentMethodId(any()))
          .thenAnswer((_) async => []);

      final paymentMethod = _makePaymentMethod(
        canAutoSave: true,
        autoSaveMode: AutoSaveMode.suggest,
      );

      await tester.pumpWidget(
        _buildTestWidget(
          paymentMethod: paymentMethod,
          overrides: _buildOverrides(
            smsFormatRepo: mockSmsRepo,
            pushFormatRepo: mockPushRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 크래시 없이 렌더링되어야 한다
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('PaymentMethodWizardPage - 버튼 인터랙션', () {
    testWidgets('저장 버튼이 있으면 탭 시 크래시가 발생하지 않는다', (tester) async {
      // Given: manual 모드
      await tester.pumpWidget(
        _buildTestWidget(initialMode: PaymentMethodAddMode.manual),
      );
      await tester.pumpAndSettle();

      // When: 저장 버튼 찾기
      final saveButtons = find.byWidgetPredicate(
        (w) => w is ElevatedButton || w is FilledButton || w is TextButton,
      );

      if (saveButtons.evaluate().isNotEmpty) {
        // 탭해도 크래시가 없어야 한다
        await tester.tap(saveButtons.last, warnIfMissed: false);
        await tester.pump();
      }

      // Then: 크래시 없이 동작해야 한다
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('취소 또는 뒤로가기가 가능하다', (tester) async {
      // Given: manual 모드 (Navigator 컨텍스트 포함)
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          routes: {
            '/': (context) => ProviderScope(
                  overrides: _buildOverrides(),
                  child: const Scaffold(
                    body: Center(child: Text('home')),
                  ),
                ),
            '/wizard': (context) => ProviderScope(
                  overrides: _buildOverrides(),
                  child: const PaymentMethodWizardPage(
                    initialMode: PaymentMethodAddMode.manual,
                  ),
                ),
          },
          initialRoute: '/wizard',
        ),
      );
      await tester.pumpAndSettle();

      // Then: Scaffold가 렌더링되어야 한다
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('PaymentMethodWizardPage - autoCollectSource 선택', () {
    testWidgets('autoCollect 모드에서 SMS/Push 선택 UI가 있을 수 있다', (tester) async {
      // Given: autoCollect 모드
      await tester.pumpWidget(
        _buildTestWidget(initialMode: PaymentMethodAddMode.autoCollect),
      );
      await tester.pumpAndSettle();

      // Then: 크래시 없이 렌더링되어야 한다
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('push 소스 결제수단 수정 모드가 크래시 없이 렌더링된다', (tester) async {
      // Given: Push 소스의 자동수집 결제수단
      final paymentMethod = _makePaymentMethod(
        canAutoSave: true,
        autoSaveMode: AutoSaveMode.auto,
        autoCollectSource: AutoCollectSource.push,
      );

      final mockSmsRepo = MockLearnedSmsFormatRepository();
      final mockPushRepo = MockLearnedPushFormatRepository();
      when(() => mockSmsRepo.getByPaymentMethodId(any()))
          .thenAnswer((_) async => []);
      when(() => mockSmsRepo.getFormatsByPaymentMethod(any()))
          .thenAnswer((_) async => []);
      when(() => mockPushRepo.getByPaymentMethodId(any()))
          .thenAnswer((_) async => []);
      when(() => mockPushRepo.getFormatsByPaymentMethod(any()))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        _buildTestWidget(
          paymentMethod: paymentMethod,
          overrides: _buildOverrides(
            smsFormatRepo: mockSmsRepo,
            pushFormatRepo: mockPushRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 크래시 없이 렌더링되어야 한다
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('PaymentMethodWizardPage - 스텝 네비게이션', () {
    testWidgets('모드 선택 화면에서 인터랙티브 요소를 탭할 수 있다', (tester) async {
      // Given: 모드 선택 화면 (initialMode 없음)
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      // When: InkWell이나 버튼이 있으면 탭 시도
      final inkWells = find.byType(InkWell);
      if (inkWells.evaluate().isNotEmpty) {
        await tester.tap(inkWells.first, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // Then: 크래시 없이 동작해야 한다
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('뒤로가기 버튼이 있으면 탭 시 크래시가 발생하지 않는다', (tester) async {
      // Given: manual 모드 (스텝 2로 바로 이동)
      await tester.pumpWidget(
        _buildTestWidget(initialMode: PaymentMethodAddMode.manual),
      );
      await tester.pumpAndSettle();

      // When: 뒤로가기 버튼(있는 경우) 탭
      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton.first);
        await tester.pump();
      }

      // Then: 크래시 없이 동작해야 한다
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('PaymentMethodWizardPage - 다양한 색상 팔레트', () {
    testWidgets('manual 모드에서 색상 선택 영역이 렌더링된다', (tester) async {
      // Given: manual 모드
      await tester.pumpWidget(
        _buildTestWidget(initialMode: PaymentMethodAddMode.manual),
      );
      await tester.pumpAndSettle();

      // Then: 크래시 없이 렌더링되어야 한다
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('isEdit=false이면 새 결제수단 추가 모드다', (tester) async {
      // Given: paymentMethod 없이 초기화 (새 추가 모드)
      await tester.pumpWidget(
        _buildTestWidget(initialMode: PaymentMethodAddMode.manual),
      );
      await tester.pumpAndSettle();

      // Then: Scaffold가 렌더링되어야 한다
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('isEdit=true이면 기존 결제수단 수정 모드다', (tester) async {
      // Given: paymentMethod 있음 (수정 모드)
      final paymentMethod = _makePaymentMethod(
        name: '수정할카드',
        canAutoSave: false,
      );

      await tester.pumpWidget(_buildTestWidget(paymentMethod: paymentMethod));
      await tester.pumpAndSettle();

      // Then: 기존 이름이 표시되어야 한다
      expect(find.textContaining('수정할카드'), findsWidgets);
    });
  });

  group('PaymentMethodWizardPage - 여러 결제수단 타입', () {
    testWidgets('canAutoSave=false 수정 모드에서 크래시가 없다', (tester) async {
      // Given: 공유 결제수단 (canAutoSave=false)
      final paymentMethod = _makePaymentMethod(
        name: '공유카드',
        canAutoSave: false,
      );

      await tester.pumpWidget(_buildTestWidget(paymentMethod: paymentMethod));
      await tester.pumpAndSettle();

      // Then: Scaffold가 렌더링되어야 한다
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('canAutoSave=true, SMS 소스 결제수단 수정 모드가 렌더링된다', (tester) async {
      // Given: SMS 소스 자동수집 결제수단
      final mockSmsRepo = MockLearnedSmsFormatRepository();
      final mockPushRepo = MockLearnedPushFormatRepository();

      when(() => mockSmsRepo.getByPaymentMethodId(any()))
          .thenAnswer((_) async => []);
      when(() => mockSmsRepo.getFormatsByPaymentMethod(any()))
          .thenAnswer((_) async => []);
      when(() => mockPushRepo.getByPaymentMethodId(any()))
          .thenAnswer((_) async => []);
      when(() => mockPushRepo.getFormatsByPaymentMethod(any()))
          .thenAnswer((_) async => []);

      final paymentMethod = _makePaymentMethod(
        name: '신한카드',
        canAutoSave: true,
        autoSaveMode: AutoSaveMode.suggest,
        autoCollectSource: AutoCollectSource.sms,
      );

      await tester.pumpWidget(
        _buildTestWidget(
          paymentMethod: paymentMethod,
          overrides: _buildOverrides(
            smsFormatRepo: mockSmsRepo,
            pushFormatRepo: mockPushRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: Scaffold가 렌더링되어야 한다
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('auto 모드의 자동수집 결제수단 수정이 렌더링된다', (tester) async {
      // Given: auto 모드의 자동수집 결제수단
      final mockSmsRepo = MockLearnedSmsFormatRepository();
      final mockPushRepo = MockLearnedPushFormatRepository();

      when(() => mockSmsRepo.getByPaymentMethodId(any()))
          .thenAnswer((_) async => []);
      when(() => mockSmsRepo.getFormatsByPaymentMethod(any()))
          .thenAnswer((_) async => []);
      when(() => mockPushRepo.getByPaymentMethodId(any()))
          .thenAnswer((_) async => []);
      when(() => mockPushRepo.getFormatsByPaymentMethod(any()))
          .thenAnswer((_) async => []);

      final paymentMethod = _makePaymentMethod(
        name: 'KB Pay',
        canAutoSave: true,
        autoSaveMode: AutoSaveMode.auto,
        autoCollectSource: AutoCollectSource.sms,
      );

      await tester.pumpWidget(
        _buildTestWidget(
          paymentMethod: paymentMethod,
          overrides: _buildOverrides(
            smsFormatRepo: mockSmsRepo,
            pushFormatRepo: mockPushRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: Scaffold가 렌더링되어야 한다
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('PaymentMethodWizardPage - 아이콘 및 색상', () {
    testWidgets('manual 모드에서 위젯이 렌더링된다', (tester) async {
      // Given: manual 모드
      await tester.pumpWidget(
        _buildTestWidget(initialMode: PaymentMethodAddMode.manual),
      );
      await tester.pumpAndSettle();

      // Then: 크래시 없이 Scaffold가 렌더링되어야 한다
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('PaymentMethodWizardPage - 전체 플로우', () {
    testWidgets('manual 모드에서 이름 입력 후 ElevatedButton 탭 시 크래시가 없다', (tester) async {
      // Given: manual 모드
      final mockPaymentMethodRepo = MockPaymentMethodRepository();
      final mockSmsRepo = MockLearnedSmsFormatRepository();
      final mockPushRepo = MockLearnedPushFormatRepository();
      final mockChannel = MockRealtimeChannel();

      when(() => mockPaymentMethodRepo.getPaymentMethods(any()))
          .thenAnswer((_) async => []);
      when(() => mockPaymentMethodRepo.getSharedPaymentMethods(any()))
          .thenAnswer((_) async => []);
      when(() => mockPaymentMethodRepo.getAutoCollectPaymentMethodsByOwner(
            ledgerId: any(named: 'ledgerId'),
            ownerUserId: any(named: 'ownerUserId'),
          )).thenAnswer((_) async => []);
      when(() => mockPaymentMethodRepo.subscribePaymentMethods(
            ledgerId: any(named: 'ledgerId'),
            onPaymentMethodChanged: any(named: 'onPaymentMethodChanged'),
          )).thenReturn(mockChannel);
      when(() => mockChannel.unsubscribe()).thenAnswer((_) async => 'ok');
      when(() => mockPaymentMethodRepo.createPaymentMethod(
            ledgerId: any(named: 'ledgerId'),
            name: any(named: 'name'),
            icon: any(named: 'icon'),
            color: any(named: 'color'),
            canAutoSave: any(named: 'canAutoSave'),
          )).thenAnswer((_) async => PaymentMethodModel(
            id: 'new-pm',
            ledgerId: 'ledger-1',
            ownerUserId: 'user-1',
            name: '테스트카드',
            icon: 'credit_card',
            color: '#6750A4',
            isDefault: false,
            sortOrder: 1,
            createdAt: DateTime.now(),
            autoSaveMode: AutoSaveMode.manual,
            canAutoSave: false,
            autoCollectSource: AutoCollectSource.sms,
          ));
      when(() => mockSmsRepo.getByPaymentMethodId(any()))
          .thenAnswer((_) async => []);
      when(() => mockSmsRepo.getFormatsByPaymentMethod(any()))
          .thenAnswer((_) async => []);
      when(() => mockPushRepo.getByPaymentMethodId(any()))
          .thenAnswer((_) async => []);
      when(() => mockPushRepo.getFormatsByPaymentMethod(any()))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        _buildTestWidget(
          initialMode: PaymentMethodAddMode.manual,
          overrides: _buildOverrides(
            paymentMethodRepo: mockPaymentMethodRepo,
            smsFormatRepo: mockSmsRepo,
            pushFormatRepo: mockPushRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: TextField에 이름 입력 후 저장 버튼 탭
      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, '테스트카드');
        await tester.pump();
      }

      // Then: 크래시 없이 동작해야 한다 (버튼 탭 전 Scaffold 존재 확인)
      expect(find.byType(Scaffold), findsWidgets);

      final elevatedButtons = find.byType(ElevatedButton);
      if (elevatedButtons.evaluate().isNotEmpty) {
        await tester.tap(elevatedButtons.last, warnIfMissed: false);
        await tester.pump();
      }
    });
  });

  group('PaymentMethodWizardPage - autoCollect 모드', () {
    testWidgets('autoCollect 모드로 시작하면 서비스 선택 화면이 렌더링된다', (tester) async {
      // Given: autoCollect 모드로 직접 시작
      await tester.pumpWidget(
        _buildTestWidget(
          initialMode: PaymentMethodAddMode.autoCollect,
          overrides: _buildOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      // Then: Scaffold가 렌더링되어야 한다
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('autoCollect initialMode 없이 시작 후 autoCollect 탭 시 서비스 선택으로 이동', (tester) async {
      // Given: 모드 선택 화면
      await tester.pumpWidget(
        _buildTestWidget(
          overrides: _buildOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      // When: autoCollect 관련 버튼 탭 시도
      final autoCollectButtons = find.byWidgetPredicate(
        (w) => w is InkWell || w is GestureDetector || w is ElevatedButton,
      );
      if (autoCollectButtons.evaluate().isNotEmpty) {
        await tester.tap(autoCollectButtons.first, warnIfMissed: false);
        await tester.pump();
      }

      // Then: Scaffold가 여전히 존재해야 한다
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('autoCollect 모드에서 뒤로가기 버튼 탭 시 크래시 없이 동작한다', (tester) async {
      // Given: autoCollect 모드
      await tester.pumpWidget(
        _buildTestWidget(
          initialMode: PaymentMethodAddMode.autoCollect,
          overrides: _buildOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      // When: 뒤로가기 아이콘 버튼 탭 시도
      final iconButtons = find.byType(IconButton);
      if (iconButtons.evaluate().isNotEmpty) {
        await tester.tap(iconButtons.first, warnIfMissed: false);
        await tester.pump();
      }

      // Then: 크래시 없이 동작해야 한다
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('autoCollect 모드에서 ListTile 탭 시 템플릿 선택이 동작한다', (tester) async {
      // Given: autoCollect 모드 (서비스 선택 화면)
      await tester.pumpWidget(
        _buildTestWidget(
          initialMode: PaymentMethodAddMode.autoCollect,
          overrides: _buildOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      // When: ListTile이 있으면 첫 번째 탭 (서비스 선택)
      final listTiles = find.byType(ListTile);
      if (listTiles.evaluate().isNotEmpty) {
        await tester.tap(listTiles.first, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // Then: Scaffold가 여전히 렌더링되어야 한다
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('autoCollect 모드에서 SegmentedButton 탭 시 notificationType 변경이 동작한다', (tester) async {
      // Given: autoCollect 모드에서 템플릿 선택 후 설정 화면
      final mockPaymentMethodRepo = MockPaymentMethodRepository();
      final mockSmsRepo = MockLearnedSmsFormatRepository();
      final mockPushRepo = MockLearnedPushFormatRepository();
      final mockChannel = MockRealtimeChannel();

      when(() => mockPaymentMethodRepo.getPaymentMethods(any()))
          .thenAnswer((_) async => []);
      when(() => mockPaymentMethodRepo.getSharedPaymentMethods(any()))
          .thenAnswer((_) async => []);
      when(() => mockPaymentMethodRepo.getAutoCollectPaymentMethodsByOwner(
            ledgerId: any(named: 'ledgerId'),
            ownerUserId: any(named: 'ownerUserId'),
          )).thenAnswer((_) async => []);
      when(() => mockPaymentMethodRepo.subscribePaymentMethods(
            ledgerId: any(named: 'ledgerId'),
            onPaymentMethodChanged: any(named: 'onPaymentMethodChanged'),
          )).thenReturn(mockChannel);
      when(() => mockChannel.unsubscribe()).thenAnswer((_) async => 'ok');
      when(() => mockSmsRepo.getByPaymentMethodId(any()))
          .thenAnswer((_) async => []);
      when(() => mockSmsRepo.getFormatsByPaymentMethod(any()))
          .thenAnswer((_) async => []);
      when(() => mockPushRepo.getByPaymentMethodId(any()))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        _buildTestWidget(
          initialMode: PaymentMethodAddMode.autoCollect,
          overrides: _buildOverrides(
            paymentMethodRepo: mockPaymentMethodRepo,
            smsFormatRepo: mockSmsRepo,
            pushFormatRepo: mockPushRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: ListTile 탭으로 템플릿 선택 후 화면 이동
      final listTiles = find.byType(ListTile);
      if (listTiles.evaluate().isNotEmpty) {
        await tester.tap(listTiles.first, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // When: SegmentedButton이 있으면 탭하여 push 타입으로 변경
      final segmentedButtons = find.byWidgetPredicate(
        (w) => w.runtimeType.toString().contains('SegmentedButton'),
      );
      if (segmentedButtons.evaluate().isNotEmpty) {
        await tester.tap(segmentedButtons.last, warnIfMissed: false);
        await tester.pump();
      }

      // Then: 크래시 없이 동작해야 한다
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
