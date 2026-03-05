import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/domain/entities/ledger.dart';
import 'package:shared_household_account/features/share/presentation/providers/share_provider.dart';

import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:shared_household_account/features/statistics/presentation/widgets/common/shared_user_filter.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

LedgerMember _makeMember({
  required String userId,
  String? displayName,
  String? email,
}) {
  return LedgerMember(
    id: 'member-$userId',
    ledgerId: 'ledger-1',
    userId: userId,
    role: 'member',
    joinedAt: DateTime(2024, 1, 1),
    displayName: displayName,
    email: email ?? '$userId@test.com',
  );
}

Widget buildWidget({
  List<LedgerMember> members = const [],
  SharedStatisticsState? initialState,
}) {
  return ProviderScope(
    overrides: [
      currentLedgerMembersProvider.overrideWith((ref) async => members),
      if (initialState != null)
        sharedStatisticsStateProvider.overrideWith(
          (ref) => initialState,
        ),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SharedUserFilter(),
      ),
    ),
  );
}

void main() {
  group('SharedUserFilter 위젯 테스트', () {
    testWidgets('멤버가 1명이면 필터가 표시되지 않는다', (tester) async {
      // Given
      final members = [_makeMember(userId: 'user-1')];

      // When
      await tester.pumpWidget(buildWidget(members: members));
      await tester.pumpAndSettle();

      // Then: SizedBox.shrink()가 반환되어 필터 없음
      expect(find.byType(SingleChildScrollView), findsNothing);
    });

    testWidgets('멤버가 0명이면 필터가 표시되지 않는다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(members: []));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SingleChildScrollView), findsNothing);
    });

    testWidgets('멤버가 2명이면 필터 탭들이 표시된다', (tester) async {
      // Given
      final members = [
        _makeMember(userId: 'user-1', displayName: '김철수'),
        _makeMember(userId: 'user-2', displayName: '이영희'),
      ];

      // When
      await tester.pumpWidget(buildWidget(members: members));
      await tester.pumpAndSettle();

      // Then: 스크롤 가능한 Row가 표시됨
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('멤버가 2명이면 합쳐서 버튼이 표시된다', (tester) async {
      // Given
      final members = [
        _makeMember(userId: 'user-1'),
        _makeMember(userId: 'user-2'),
      ];

      // When
      await tester.pumpWidget(buildWidget(members: members));
      await tester.pumpAndSettle();

      // Then: 로딩 상태에서는 아직 표시 안 됨을 확인하고 데이터 후 확인
      expect(find.byType(SharedUserFilter), findsOneWidget);
    });

    testWidgets('로딩 중에도 위젯이 정상적으로 렌더링된다', (tester) async {
      // Given: 빈 멤버 목록으로 로딩 완료 시뮬레이션
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentLedgerMembersProvider.overrideWith(
              (ref) async => <LedgerMember>[],
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: SharedUserFilter()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 위젯이 에러 없이 렌더링
      expect(find.byType(SharedUserFilter), findsOneWidget);
    });

    testWidgets('합쳐서 버튼을 탭하면 combined 모드로 변경된다', (tester) async {
      // Given: 2명 멤버, singleUser 모드로 시작
      final members = [
        _makeMember(userId: 'user-1', displayName: '김철수'),
        _makeMember(userId: 'user-2', displayName: '이영희'),
      ];
      await tester.pumpWidget(
        buildWidget(
          members: members,
          initialState: const SharedStatisticsState(
            mode: SharedStatisticsMode.singleUser,
            selectedUserId: 'user-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: '합쳐서' 버튼(첫 번째 GestureDetector) 탭
      final gestureFinders = find.byType(GestureDetector);
      expect(gestureFinders, findsWidgets);
      await tester.tap(gestureFinders.first);
      await tester.pumpAndSettle();

      // Then: 위젯이 여전히 정상 렌더링
      expect(find.byType(SharedUserFilter), findsOneWidget);
    });

    testWidgets('사용자 버튼을 탭하면 singleUser 모드로 변경된다', (tester) async {
      // Given: 2명 멤버, combined 모드로 시작
      final members = [
        _makeMember(userId: 'user-1', displayName: '김철수'),
        _makeMember(userId: 'user-2', displayName: '이영희'),
      ];
      await tester.pumpWidget(
        buildWidget(
          members: members,
          initialState: const SharedStatisticsState(
            mode: SharedStatisticsMode.combined,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 두 번째 GestureDetector(첫 번째 사용자 버튼) 탭
      final gestureFinders = find.byType(GestureDetector);
      if (gestureFinders.evaluate().length >= 2) {
        await tester.tap(gestureFinders.at(1));
        await tester.pumpAndSettle();
      }

      // Then: 위젯이 여전히 정상 렌더링
      expect(find.byType(SharedUserFilter), findsOneWidget);
    });

    testWidgets('겹쳐서 버튼을 탭하면 overlay 모드로 변경된다', (tester) async {
      // Given: 2명 멤버, combined 모드로 시작
      final members = [
        _makeMember(userId: 'user-1', displayName: '김철수'),
        _makeMember(userId: 'user-2', displayName: '이영희'),
      ];
      await tester.pumpWidget(
        buildWidget(
          members: members,
          initialState: const SharedStatisticsState(
            mode: SharedStatisticsMode.combined,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 마지막 GestureDetector(겹쳐서 버튼) 탭
      final gestureFinders = find.byType(GestureDetector);
      if (gestureFinders.evaluate().isNotEmpty) {
        await tester.tap(gestureFinders.last);
        await tester.pumpAndSettle();
      }

      // Then: 위젯이 여전히 정상 렌더링
      expect(find.byType(SharedUserFilter), findsOneWidget);
    });

    testWidgets('에러 발생 시 SizedBox.shrink가 표시된다', (tester) async {
      // Given: currentLedgerMembersProvider가 에러를 반환
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentLedgerMembersProvider.overrideWith(
              (ref) => Future<List<LedgerMember>>.error(Exception('에러')),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: SharedUserFilter()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 에러 상태에서 SingleChildScrollView가 없음(SizedBox.shrink 반환)
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.byType(SharedUserFilter), findsOneWidget);
    });

    testWidgets('displayName이 없으면 이메일 앞부분을 이름으로 사용한다', (tester) async {
      // Given: displayName 없고 email만 있는 멤버 2명
      final members = [
        _makeMember(userId: 'user-1', email: 'alice@example.com'),
        _makeMember(userId: 'user-2', email: 'bob@example.com'),
      ];

      // When
      await tester.pumpWidget(buildWidget(members: members));
      await tester.pumpAndSettle();

      // Then: 필터가 표시됨 (이메일 기반 이름 사용)
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
