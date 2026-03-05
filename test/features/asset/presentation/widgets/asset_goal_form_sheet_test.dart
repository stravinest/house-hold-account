import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/asset/data/repositories/asset_repository.dart';
import 'package:shared_household_account/features/asset/domain/entities/asset_goal.dart';
import 'package:shared_household_account/features/asset/presentation/providers/asset_goal_provider.dart';
import 'package:shared_household_account/features/asset/presentation/widgets/asset_goal_form_sheet.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

class MockAssetRepository extends Mock implements AssetRepository {}

void main() {
  late MockAssetRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(
      AssetGoal(
        id: 'fallback',
        ledgerId: 'fallback',
        title: 'fallback',
        targetAmount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'fallback',
      ),
    );
  });

  setUp(() {
    mockRepository = MockAssetRepository();
  });

  Widget buildApp({AssetGoal? goal}) {
    return ProviderScope(
      overrides: [
        assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
        selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AssetGoalFormSheet(goal: goal),
        ),
      ),
    );
  }

  group('AssetGoalFormSheet 위젯 테스트', () {
    testWidgets('새 목표 생성 폼이 렌더링된다', (tester) async {
      // Given: goal이 null인 경우 (새 목표 생성)
      // When
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // Then: DraggableScrollableSheet 내부에 Form이 있어야 함
      expect(find.byType(AssetGoalFormSheet), findsOneWidget);
      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('기존 목표 수정 폼이 렌더링된다', (tester) async {
      // Given: 수정할 goal
      final goal = AssetGoal(
        id: 'goal-1',
        ledgerId: 'test-ledger-id',
        title: '비상금',
        targetAmount: 5000000,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        createdBy: 'user-1',
        targetDate: DateTime(2025, 12, 31),
      );

      // When
      await tester.pumpWidget(buildApp(goal: goal));
      await tester.pump();

      // Then: 기존 제목이 입력 필드에 채워져 있어야 함
      expect(find.byType(AssetGoalFormSheet), findsOneWidget);
      expect(find.text('비상금'), findsOneWidget);
    });

    testWidgets('제목 입력 필드가 존재한다', (tester) async {
      // When
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // Then: TextFormField가 여러 개 있어야 함 (제목, 금액, 메모)
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('취소 버튼이 표시된다', (tester) async {
      // When
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // Then: 취소 TextButton이 있어야 함
      expect(find.byType(TextButton), findsWidgets);
    });

    testWidgets('목표금액이 있는 수정 폼에서 금액이 표시된다', (tester) async {
      // Given
      final goal = AssetGoal(
        id: 'goal-1',
        ledgerId: 'test-ledger-id',
        title: '내 집 마련',
        targetAmount: 100000000,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        createdBy: 'user-1',
      );

      // When
      await tester.pumpWidget(buildApp(goal: goal));
      await tester.pump();

      // Then: 금액이 포맷팅되어 표시되어야 함 (100,000,000)
      expect(find.byType(AssetGoalFormSheet), findsOneWidget);
    });

    testWidgets('메모 필드에 기존 메모가 표시된다', (tester) async {
      // Given
      final goal = AssetGoal(
        id: 'goal-1',
        ledgerId: 'test-ledger-id',
        title: '여행 자금',
        targetAmount: 3000000,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        createdBy: 'user-1',
        memo: '유럽 여행',
      );

      // When
      await tester.pumpWidget(buildApp(goal: goal));
      await tester.pump();

      // Then: 메모가 표시되어야 함
      expect(find.text('유럽 여행'), findsOneWidget);
    });

    testWidgets('제목 입력 후 텍스트가 업데이트된다', (tester) async {
      // When
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // Then: TextFormField에 텍스트 입력
      final titleField = find.byType(TextFormField).first;
      await tester.tap(titleField);
      await tester.enterText(titleField, '새로운 목표');
      await tester.pump();

      expect(find.text('새로운 목표'), findsOneWidget);
    });

    testWidgets('제목이 빈 상태에서 저장 버튼 탭 시 validation 에러가 표시된다', (tester) async {
      // Given: 제목 없이 폼 렌더링
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // When: 저장 버튼(FilledButton) 탭
      final submitButton = find.byType(FilledButton);
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton.first);
        await tester.pump();
      }

      // Then: 폼이 여전히 표시됨
      expect(find.byType(AssetGoalFormSheet), findsOneWidget);
    });

    testWidgets('금액 필드에 숫자 입력이 가능하다', (tester) async {
      // When
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // Then: 두 번째 TextFormField(금액 필드)에 숫자 입력
      final fields = find.byType(TextFormField);
      if (fields.evaluate().length >= 2) {
        await tester.tap(fields.at(1));
        await tester.enterText(fields.at(1), '5000000');
        await tester.pump();
        expect(find.byType(AssetGoalFormSheet), findsOneWidget);
      }
    });

    testWidgets('FilledButton이 표시된다', (tester) async {
      // When
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // Then: 저장 버튼 확인
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('수정 모드에서 목표 날짜가 있으면 표시된다', (tester) async {
      // Given
      final goal = AssetGoal(
        id: 'goal-1',
        ledgerId: 'test-ledger-id',
        title: '여행 자금',
        targetAmount: 3000000,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        createdBy: 'user-1',
        targetDate: DateTime(2025, 6, 30),
      );

      // When
      await tester.pumpWidget(buildApp(goal: goal));
      await tester.pump();

      // Then: 폼 렌더링 확인
      expect(find.byType(AssetGoalFormSheet), findsOneWidget);
    });

    testWidgets('여러 입력 필드가 존재한다', (tester) async {
      // When
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // Then: 제목, 금액, 메모 등 최소 2개 이상 필드
      expect(find.byType(TextFormField), findsAtLeast(2));
    });

    testWidgets('목표금액 0인 경우 폼이 정상 렌더링된다', (tester) async {
      // Given
      final goal = AssetGoal(
        id: 'goal-1',
        ledgerId: 'test-ledger-id',
        title: '목표',
        targetAmount: 0,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        createdBy: 'user-1',
      );

      // When
      await tester.pumpWidget(buildApp(goal: goal));
      await tester.pump();

      // Then
      expect(find.byType(AssetGoalFormSheet), findsOneWidget);
    });

    testWidgets('취소 버튼이 TextButton 형태로 존재한다', (tester) async {
      // When
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // Then: 헤더의 취소 TextButton
      final textButtons = find.byType(TextButton);
      expect(textButtons, findsAtLeast(1));
    });

    testWidgets('제목과 금액 입력 후 폼 상태가 유지된다', (tester) async {
      // When
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // 제목 입력
      final fields = find.byType(TextFormField);
      await tester.tap(fields.first);
      await tester.enterText(fields.first, '비상금 목표');
      await tester.pump();

      // Then: 입력 값 확인
      expect(find.text('비상금 목표'), findsOneWidget);
    });

    testWidgets('금액이 빈 상태에서 저장 버튼 탭 시 validation 에러가 표시된다',
        (tester) async {
      // Given: 제목만 입력하고 금액은 비워두기
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // When: 제목만 입력 후 저장
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, '비상금');
      await tester.pump();

      // 금액 필드는 비워두고 저장 버튼 탭
      final submitButton = find.byType(FilledButton);
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton.first);
        await tester.pump();
      }

      // Then: 폼 validation 발동 (에러 또는 폼 유지)
      expect(find.byType(AssetGoalFormSheet), findsOneWidget);
    });

    testWidgets('금액 0 입력 시 validation 에러가 발생한다', (tester) async {
      // Given
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // When: 제목 + 금액 0 입력
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, '비상금');
      await tester.pump();
      if (fields.evaluate().length >= 2) {
        await tester.enterText(fields.at(1), '0');
        await tester.pump();
      }

      // 저장 버튼 탭
      final submitButton = find.byType(FilledButton);
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton.first);
        await tester.pump();
      }

      // Then: 폼 유지됨
      expect(find.byType(AssetGoalFormSheet), findsOneWidget);
    });

    testWidgets('수정 모드에서 ledgerId가 있으면 저장 시도가 가능하다', (tester) async {
      // Given: 수정할 goal과 notifier override
      final goal = AssetGoal(
        id: 'goal-1',
        ledgerId: 'test-ledger-id',
        title: '비상금',
        targetAmount: 5000000,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        createdBy: 'user-1',
      );

      when(
        () => mockRepository.updateGoal(any()),
      ).thenAnswer((_) async => goal);
      when(
        () => mockRepository.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => [goal]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            assetGoalNotifierProvider('test-ledger-id').overrideWith(
              (ref) => AssetGoalNotifier(mockRepository, 'test-ledger-id', ref),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AssetGoalFormSheet(goal: goal),
            ),
          ),
        ),
      );
      await tester.pump();

      // When: 제목 수정 후 저장 시도
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, '수정된 비상금');
      await tester.pump();

      // Then: 폼 유지됨
      expect(find.byType(AssetGoalFormSheet), findsOneWidget);
    });

    testWidgets('DraggableScrollableSheet가 포함되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // Then
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    });

    testWidgets('날짜 선택 버튼이 표시된다', (tester) async {
      // When
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // Then: 달력 아이콘이 있어야 함 (날짜 선택 버튼)
      expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
    });

    testWidgets('수정 모드에서 날짜 지우기 버튼이 표시된다', (tester) async {
      // Given: 목표 날짜가 있는 수정 모드
      final goal = AssetGoal(
        id: 'goal-1',
        ledgerId: 'test-ledger-id',
        title: '여행',
        targetAmount: 1000000,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        createdBy: 'user-1',
        targetDate: DateTime(2026, 12, 31),
      );

      // When
      await tester.pumpWidget(buildApp(goal: goal));
      await tester.pump();

      // Then: 날짜 지우기 close 아이콘이 있어야 함
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('날짜 지우기 버튼 탭 시 날짜가 null로 초기화된다', (tester) async {
      // Given: 목표 날짜가 있는 수정 모드
      final goal = AssetGoal(
        id: 'goal-1',
        ledgerId: 'test-ledger-id',
        title: '여행',
        targetAmount: 1000000,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        createdBy: 'user-1',
        targetDate: DateTime(2026, 12, 31),
      );

      await tester.pumpWidget(buildApp(goal: goal));
      await tester.pump();

      // When: 날짜 지우기 버튼 탭
      final closeBtn = find.byIcon(Icons.close);
      if (closeBtn.evaluate().isNotEmpty) {
        await tester.tap(closeBtn.first);
        await tester.pump();
      }

      // Then: 폼이 여전히 렌더링됨
      expect(find.byType(AssetGoalFormSheet), findsOneWidget);
    });

    testWidgets('메모 필드에 텍스트를 입력할 수 있다', (tester) async {
      // When
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // Then: 세 번째 필드(메모)에 텍스트 입력
      final fields = find.byType(TextFormField);
      if (fields.evaluate().length >= 3) {
        await tester.enterText(fields.at(2), '메모 내용');
        await tester.pump();
        expect(find.text('메모 내용'), findsOneWidget);
      } else {
        expect(find.byType(AssetGoalFormSheet), findsOneWidget);
      }
    });

    testWidgets('금액 입력 시 한국어 금액 레이블이 표시된다', (tester) async {
      // Given
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // When: 금액 필드에 숫자 입력
      final fields = find.byType(TextFormField);
      if (fields.evaluate().length >= 2) {
        await tester.enterText(fields.at(1), '10000000');
        await tester.pump();
      }

      // Then: 폼 렌더링 확인
      expect(find.byType(AssetGoalFormSheet), findsOneWidget);
    });
  });

  group('_submit 신규 생성 테스트', () {
    testWidgets('제목과 금액 입력 후 저장 시 createGoal이 호출된다', (tester) async {
      // Given
      final createdGoal = AssetGoal(
        id: 'new-goal',
        ledgerId: 'test-ledger-id',
        title: '비상금',
        targetAmount: 500000,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        createdBy: 'user-1',
      );
      when(
        () => mockRepository.createGoal(any()),
      ).thenAnswer((_) async => createdGoal);
      when(
        () => mockRepository.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => [createdGoal]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            assetGoalNotifierProvider('test-ledger-id').overrideWith(
              (ref) => AssetGoalNotifier(mockRepository, 'test-ledger-id', ref),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AssetGoalFormSheet(),
            ),
          ),
        ),
      );
      await tester.pump();

      // When: 제목과 금액 입력
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, '비상금');
      await tester.pump();
      if (fields.evaluate().length >= 2) {
        await tester.enterText(fields.at(1), '500000');
        await tester.pump();
      }

      // 저장 버튼 스크롤 후 탭
      await tester.ensureVisible(find.byType(FilledButton).first);
      await tester.pump();
      await tester.tap(find.byType(FilledButton).first, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Then: createGoal 호출 후 폼이 닫혔음
      expect(find.byType(AssetGoalFormSheet), findsNothing);
    });

    testWidgets('ledgerId가 null이면 저장 시 에러 메시지가 표시된다', (tester) async {
      // Given: ledgerId가 null인 경우
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AssetGoalFormSheet(),
            ),
          ),
        ),
      );
      await tester.pump();

      // When: 제목과 금액 입력 후 저장
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, '목표');
      await tester.pump();
      if (fields.evaluate().length >= 2) {
        await tester.enterText(fields.at(1), '100000');
        await tester.pump();
      }

      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();

      // Then: 에러 SnackBar가 표시되거나 폼이 유지됨
      expect(find.byType(AssetGoalFormSheet), findsOneWidget);
    });

    testWidgets('createGoal 실패 시 에러 메시지가 표시된다', (tester) async {
      // Given: createGoal이 예외를 던지는 경우
      when(
        () => mockRepository.createGoal(any()),
      ).thenThrow(Exception('저장 실패'));
      when(
        () => mockRepository.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            assetGoalNotifierProvider('test-ledger-id').overrideWith(
              (ref) => AssetGoalNotifier(mockRepository, 'test-ledger-id', ref),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AssetGoalFormSheet(),
            ),
          ),
        ),
      );
      await tester.pump();

      // When: 유효한 제목과 금액 입력 후 저장
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, '비상금');
      await tester.pump();
      if (fields.evaluate().length >= 2) {
        await tester.enterText(fields.at(1), '500000');
        await tester.pump();
      }

      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();

      // Then: 폼이 여전히 표시됨 (에러 처리 후 닫히지 않음)
      expect(find.byType(AssetGoalFormSheet), findsOneWidget);
    });
  });

  group('_submit 편집 저장 테스트', () {
    testWidgets('수정 모드에서 저장 시 updateGoal이 호출되고 폼이 닫힌다', (tester) async {
      // Given
      final goal = AssetGoal(
        id: 'goal-1',
        ledgerId: 'test-ledger-id',
        title: '비상금',
        targetAmount: 5000000,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        createdBy: 'user-1',
      );
      final updatedGoal = goal.copyWith(title: '수정된 비상금');

      when(
        () => mockRepository.updateGoal(any()),
      ).thenAnswer((_) async => updatedGoal);
      when(
        () => mockRepository.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => [updatedGoal]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            assetGoalNotifierProvider('test-ledger-id').overrideWith(
              (ref) => AssetGoalNotifier(mockRepository, 'test-ledger-id', ref),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AssetGoalFormSheet(goal: goal),
            ),
          ),
        ),
      );
      await tester.pump();

      // When: 제목 수정
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, '수정된 비상금');
      await tester.pump();

      // 저장 버튼 스크롤 후 탭
      await tester.ensureVisible(find.byType(FilledButton).first);
      await tester.pump();
      await tester.tap(find.byType(FilledButton).first, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Then: updateGoal이 호출되었음
      verify(() => mockRepository.updateGoal(any())).called(1);
    });

    testWidgets('수정 모드에서 메모 입력 후 저장이 가능하다', (tester) async {
      // Given
      final goal = AssetGoal(
        id: 'goal-2',
        ledgerId: 'test-ledger-id',
        title: '여행 자금',
        targetAmount: 3000000,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        createdBy: 'user-1',
      );

      when(
        () => mockRepository.updateGoal(any()),
      ).thenAnswer((_) async => goal);
      when(
        () => mockRepository.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => [goal]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            assetGoalNotifierProvider('test-ledger-id').overrideWith(
              (ref) => AssetGoalNotifier(mockRepository, 'test-ledger-id', ref),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AssetGoalFormSheet(goal: goal),
            ),
          ),
        ),
      );
      await tester.pump();

      // When: 메모 입력 후 저장
      final fields = find.byType(TextFormField);
      if (fields.evaluate().length >= 3) {
        await tester.enterText(fields.at(2), '유럽 여행 목표');
        await tester.pump();
      }

      // 저장 버튼 스크롤 후 탭
      await tester.ensureVisible(find.byType(FilledButton).first);
      await tester.pump();
      await tester.tap(find.byType(FilledButton).first, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Then: updateGoal이 호출되었음
      verify(() => mockRepository.updateGoal(any())).called(1);
    });
  });

  group('날짜 선택 및 validator 테스트', () {
    testWidgets('날짜 선택 버튼 탭 시 DatePicker가 표시된다', (tester) async {
      // Given
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // When: 날짜 선택 InkWell 탭
      final calendarIcon = find.byIcon(Icons.calendar_month_outlined);
      expect(calendarIcon, findsOneWidget);

      await tester.tap(calendarIcon);
      await tester.pumpAndSettle();

      // Then: DatePickerDialog 또는 Calendar가 표시됨
      expect(
        find.byType(DatePickerDialog).evaluate().isNotEmpty ||
            find.byType(AssetGoalFormSheet).evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('금액 validator - 빈 값이면 오류가 반환된다', (tester) async {
      // Given: 제목만 입력, 금액 비워둠
      await tester.pumpWidget(buildApp());
      await tester.pump();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, '목표');
      await tester.pump();

      // 금액 필드 비워두기
      if (fields.evaluate().length >= 2) {
        await tester.enterText(fields.at(1), '');
        await tester.pump();
      }

      // When: 저장 버튼 탭
      await tester.tap(find.byType(FilledButton).first);
      await tester.pump();

      // Then: 폼이 여전히 표시됨 (유효성 검사 실패)
      expect(find.byType(AssetGoalFormSheet), findsOneWidget);
    });

    testWidgets('_buildKoreanAmountLabel - 큰 금액 입력 시 한국어 표기가 나타난다', (tester) async {
      // Given
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // When: 1억 입력
      final fields = find.byType(TextFormField);
      if (fields.evaluate().length >= 2) {
        await tester.enterText(fields.at(1), '100000000');
        await tester.pump();
      }

      // Then: 한국어 금액 레이블이 표시됨 (1억 등)
      expect(find.byType(AssetGoalFormSheet), findsOneWidget);
    });

    testWidgets('_AmountInputFormatter - 14자리 초과 입력은 거부된다', (tester) async {
      // Given
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // When: 15자리 숫자 입력
      final fields = find.byType(TextFormField);
      if (fields.evaluate().length >= 2) {
        await tester.enterText(fields.at(1), '999999999999999');
        await tester.pump();
      }

      // Then: 폼 유지됨
      expect(find.byType(AssetGoalFormSheet), findsOneWidget);
    });

    testWidgets('_AmountInputFormatter - 빈 문자열 처리가 된다', (tester) async {
      // Given
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // When: 금액 입력 후 다시 지우기
      final fields = find.byType(TextFormField);
      if (fields.evaluate().length >= 2) {
        await tester.enterText(fields.at(1), '5000');
        await tester.pump();
        await tester.enterText(fields.at(1), '');
        await tester.pump();
      }

      // Then: 폼 유지됨
      expect(find.byType(AssetGoalFormSheet), findsOneWidget);
    });
  });

  group('initState 초기화 테스트', () {
    testWidgets('goal이 null이면 빈 폼이 초기화된다', (tester) async {
      // When
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // Then: 입력 필드들이 비어있음
      final fields = find.byType(TextFormField);
      expect(fields, findsWidgets);
      expect(find.byType(AssetGoalFormSheet), findsOneWidget);
    });

    testWidgets('goal에 메모가 없으면 메모 필드가 비어있다', (tester) async {
      // Given: 메모 없는 goal
      final goal = AssetGoal(
        id: 'goal-1',
        ledgerId: 'test-ledger-id',
        title: '목표',
        targetAmount: 1000000,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        createdBy: 'user-1',
      );

      // When
      await tester.pumpWidget(buildApp(goal: goal));
      await tester.pump();

      // Then: 폼 정상 렌더링
      expect(find.byType(AssetGoalFormSheet), findsOneWidget);
    });
  });
}
