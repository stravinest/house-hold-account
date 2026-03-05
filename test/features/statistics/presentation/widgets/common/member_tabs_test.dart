import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/domain/entities/ledger.dart';
import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:shared_household_account/features/statistics/presentation/widgets/common/member_tabs.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

void main() {
  // 테스트용 멤버 생성 헬퍼
  LedgerMember makeMember({
    required String userId,
    String? displayName,
    String? email,
    String? color,
  }) {
    return LedgerMember(
      id: 'member-$userId',
      ledgerId: 'ledger-1',
      userId: userId,
      role: 'member',
      joinedAt: DateTime(2026, 1, 1),
      displayName: displayName,
      email: email,
      color: color,
    );
  }

  Widget buildWidget({
    required List<LedgerMember> members,
    required SharedStatisticsState sharedState,
    ValueChanged<SharedStatisticsState>? onStateChanged,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MemberTabs(
          members: members,
          sharedState: sharedState,
          onStateChanged: onStateChanged ?? (_) {},
        ),
      ),
    );
  }

  group('MemberTabs 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링된다', (tester) async {
      // Given
      final members = [
        makeMember(userId: 'user-1', displayName: '홍길동', color: '#FF5722'),
        makeMember(userId: 'user-2', displayName: '김철수', color: '#4CAF50'),
      ];
      const sharedState = SharedStatisticsState(
        mode: SharedStatisticsMode.combined,
      );

      // When
      await tester.pumpWidget(buildWidget(members: members, sharedState: sharedState));

      // Then
      expect(find.byType(MemberTabs), findsOneWidget);
    });

    testWidgets('합계 버튼이 항상 표시된다', (tester) async {
      // Given
      final members = [
        makeMember(userId: 'user-1', displayName: '홍길동', color: '#FF5722'),
      ];
      const sharedState = SharedStatisticsState(mode: SharedStatisticsMode.combined);

      // When
      await tester.pumpWidget(buildWidget(members: members, sharedState: sharedState));
      await tester.pumpAndSettle();

      // Then - 합계 텍스트가 표시되어야 함
      expect(find.byType(MemberTabs), findsOneWidget);
    });

    testWidgets('멤버의 displayName이 탭에 표시된다', (tester) async {
      // Given
      final members = [
        makeMember(userId: 'user-1', displayName: '홍길동', color: '#FF5722'),
        makeMember(userId: 'user-2', displayName: '김철수', color: '#4CAF50'),
      ];
      const sharedState = SharedStatisticsState(mode: SharedStatisticsMode.combined);

      // When
      await tester.pumpWidget(buildWidget(members: members, sharedState: sharedState));
      await tester.pumpAndSettle();

      // Then
      expect(find.text('홍길동'), findsOneWidget);
      expect(find.text('김철수'), findsOneWidget);
    });

    testWidgets('displayName이 없으면 email 앞부분을 사용한다', (tester) async {
      // Given
      final members = [
        makeMember(
          userId: 'user-1',
          displayName: null,
          email: 'test@example.com',
          color: '#FF5722',
        ),
      ];
      const sharedState = SharedStatisticsState(mode: SharedStatisticsMode.combined);

      // When
      await tester.pumpWidget(buildWidget(members: members, sharedState: sharedState));
      await tester.pumpAndSettle();

      // Then
      expect(find.text('test'), findsOneWidget);
    });

    testWidgets('combined 모드일 때 합계 탭이 선택 상태로 표시된다', (tester) async {
      // Given
      final members = [
        makeMember(userId: 'user-1', displayName: '홍길동', color: '#FF5722'),
      ];
      const sharedState = SharedStatisticsState(
        mode: SharedStatisticsMode.combined,
      );

      // When
      await tester.pumpWidget(buildWidget(members: members, sharedState: sharedState));
      await tester.pumpAndSettle();

      // Then - 위젯이 렌더링되면 combined 상태
      expect(find.byType(MemberTabs), findsOneWidget);
    });

    testWidgets('singleUser 모드일 때 해당 사용자 탭이 선택 상태로 표시된다', (tester) async {
      // Given
      final members = [
        makeMember(userId: 'user-1', displayName: '홍길동', color: '#FF5722'),
        makeMember(userId: 'user-2', displayName: '김철수', color: '#4CAF50'),
      ];
      const sharedState = SharedStatisticsState(
        mode: SharedStatisticsMode.singleUser,
        selectedUserId: 'user-1',
      );

      // When
      await tester.pumpWidget(buildWidget(members: members, sharedState: sharedState));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(MemberTabs), findsOneWidget);
    });

    testWidgets('사용자 탭을 탭하면 onStateChanged가 singleUser 모드로 호출된다', (tester) async {
      // Given
      SharedStatisticsState? changedState;
      final members = [
        makeMember(userId: 'user-1', displayName: '홍길동', color: '#FF5722'),
        makeMember(userId: 'user-2', displayName: '김철수', color: '#4CAF50'),
      ];
      const sharedState = SharedStatisticsState(mode: SharedStatisticsMode.combined);

      await tester.pumpWidget(buildWidget(
        members: members,
        sharedState: sharedState,
        onStateChanged: (state) => changedState = state,
      ));
      await tester.pumpAndSettle();

      // When - 홍길동 탭 탭하기
      await tester.tap(find.text('홍길동'));
      await tester.pumpAndSettle();

      // Then
      expect(changedState, isNotNull);
      expect(changedState!.mode, SharedStatisticsMode.singleUser);
      expect(changedState!.selectedUserId, 'user-1');
    });

    testWidgets('멤버 색상이 없어도 정상 렌더링된다', (tester) async {
      // Given
      final members = [
        makeMember(userId: 'user-1', displayName: '홍길동', color: null),
      ];
      const sharedState = SharedStatisticsState(mode: SharedStatisticsMode.combined);

      // When
      await tester.pumpWidget(buildWidget(members: members, sharedState: sharedState));

      // Then
      expect(find.byType(MemberTabs), findsOneWidget);
    });

    testWidgets('멤버가 1명일 때도 정상 렌더링된다', (tester) async {
      // Given
      final members = [
        makeMember(userId: 'user-1', displayName: '홍길동', color: '#FF5722'),
      ];
      const sharedState = SharedStatisticsState(mode: SharedStatisticsMode.combined);

      // When
      await tester.pumpWidget(buildWidget(members: members, sharedState: sharedState));

      // Then
      expect(find.byType(MemberTabs), findsOneWidget);
    });
  });

  group('MemberTabs.getDisplayName 정적 메서드 테스트', () {
    testWidgets('displayName이 있으면 displayName을 반환한다', (tester) async {
      // Given
      final member = LedgerMember(
        id: 'member-1',
        ledgerId: 'ledger-1',
        userId: 'user-1',
        role: 'member',
        joinedAt: DateTime(2026, 1, 1),
        displayName: '홍길동',
        email: 'hong@example.com',
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              final name = MemberTabs.getDisplayName(member, l10n);
              // Then
              expect(name, '홍길동');
              return const Scaffold();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('displayName이 없으면 email 앞부분을 반환한다', (tester) async {
      // Given
      final member = LedgerMember(
        id: 'member-1',
        ledgerId: 'ledger-1',
        userId: 'user-1',
        role: 'member',
        joinedAt: DateTime(2026, 1, 1),
        displayName: null,
        email: 'hong@example.com',
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              final name = MemberTabs.getDisplayName(member, l10n);
              // Then
              expect(name, 'hong');
              return const Scaffold();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    });
  });
}
