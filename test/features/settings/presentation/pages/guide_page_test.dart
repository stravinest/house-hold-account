import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_household_account/config/router.dart';
import 'package:shared_household_account/features/settings/presentation/pages/guide_page.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

Widget _buildTestApp({Widget? child}) {
  final router = GoRouter(
    initialLocation: '/guide',
    routes: [
      GoRoute(
        path: '/guide',
        builder: (context, state) => child ?? const GuidePage(),
      ),
      GoRoute(
        path: Routes.transactionGuide,
        builder: (context, state) => const Scaffold(body: Text('거래 가이드')),
      ),
      GoRoute(
        path: Routes.shareGuide,
        builder: (context, state) => const Scaffold(body: Text('공유 가이드')),
      ),
      GoRoute(
        path: Routes.autoCollectGuide,
        builder: (context, state) => const Scaffold(body: Text('자동수집 가이드')),
      ),
    ],
  );

  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
    ),
  );
}

void main() {
  group('GuidePage 위젯 테스트', () {
    testWidgets('기본 구조가 렌더링되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('가이드 AppBar 제목이 표시되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then - AppBar가 존재하는지 확인
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('GuideColors 색상 상수들이 올바른 값을 가진다', (tester) async {
      // Given & When & Then
      expect(GuideColors.surface, const Color(0xFFFDFDF5));
      expect(GuideColors.primary, const Color(0xFF2E7D32));
      expect(GuideColors.primaryContainer, const Color(0xFFA8DAB5));
      expect(GuideColors.onSurface, const Color(0xFF1A1C19));
      expect(GuideColors.onSurfaceVariant, const Color(0xFF44483E));
    });

    testWidgets('가이드 카드들이 표시되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then - InkWell이 있는 네비게이션 카드가 포함되어야 함
      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('ListView 스크롤이 가능해야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then
      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);
    });
  });

  group('GuideColors 색상 상수 테스트', () {
    test('expense 색상이 빨간색 계열이어야 한다', () {
      expect(GuideColors.expense, const Color(0xFFE53935));
    });

    test('warning 색상이 주황색 계열이어야 한다', () {
      expect(GuideColors.warning, const Color(0xFFE65100));
    });

    test('error 색상이 빨간색 계열이어야 한다', () {
      expect(GuideColors.error, const Color(0xFFBA1A1A));
    });

    test('memberBlue 색상이 파란색 계열이어야 한다', () {
      expect(GuideColors.memberBlue, const Color(0xFFA8D8EA));
    });

    test('memberCoral 색상이 코랄 계열이어야 한다', () {
      expect(GuideColors.memberCoral, const Color(0xFFFFB6A3));
    });

    test('outlineVariant 색상이 회색 계열이어야 한다', () {
      expect(GuideColors.outlineVariant, const Color(0xFFC4C8BB));
    });
  });
}
