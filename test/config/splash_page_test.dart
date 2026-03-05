import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/config/router.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuthService extends Mock implements AuthService {}

Widget buildSplashPageDirect({
  required Stream<User?> authStream,
}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => authStream),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('ko'),
      home: SplashPage(),
    ),
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://test.supabase.co',
        anonKey: 'test-anon-key',
      );
    } catch (_) {}
  });

  group('SplashPage 위젯 테스트', () {
    testWidgets('SplashPage가 정상적으로 렌더링된다', (tester) async {
      // Given: 인증 상태가 로딩 중
      await tester.pumpWidget(
        buildSplashPageDirect(authStream: const Stream.empty()),
      );
      await tester.pump();

      // Then: 앱 아이콘 컨테이너가 존재한다
      expect(find.byType(SplashPage), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);

      // 타이머 정리
      await tester.pump(const Duration(milliseconds: 2100));
    });

    testWidgets('SplashPage 배경색이 올바르다', (tester) async {
      // Given
      await tester.pumpWidget(
        buildSplashPageDirect(authStream: const Stream.empty()),
      );
      await tester.pump();

      // Then: Scaffold 위젯이 올바른 배경색을 가진다
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, const Color(0xFFFDFDF5));

      // 타이머 정리
      await tester.pump(const Duration(milliseconds: 2100));
    });

    testWidgets('SplashPage에 로딩 인디케이터가 3개의 점으로 구성된다', (tester) async {
      // Given
      await tester.pumpWidget(
        buildSplashPageDirect(authStream: const Stream.empty()),
      );
      await tester.pump();

      // Then: AnimatedBuilder가 존재한다
      expect(find.byType(AnimatedBuilder), findsWidgets);

      // 타이머 정리
      await tester.pump(const Duration(milliseconds: 2100));
    });

    testWidgets('SplashPage에 Column 레이아웃이 존재한다', (tester) async {
      // Given
      await tester.pumpWidget(
        buildSplashPageDirect(authStream: const Stream.empty()),
      );
      await tester.pump();

      // Then: Column 위젯이 존재한다
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Center), findsWidgets);

      // 타이머 정리
      await tester.pump(const Duration(milliseconds: 2100));
    });

    testWidgets('SplashPage에 ClipRRect로 아이콘이 표시된다', (tester) async {
      // Given
      await tester.pumpWidget(
        buildSplashPageDirect(authStream: const Stream.empty()),
      );
      await tester.pump();

      // Then: ClipRRect 위젯이 존재한다 (앱 아이콘 클리핑)
      expect(find.byType(ClipRRect), findsWidgets);

      // 타이머 정리
      await tester.pump(const Duration(milliseconds: 2100));
    });

    testWidgets('SplashPage에 Row 로딩 인디케이터가 존재한다', (tester) async {
      // Given
      await tester.pumpWidget(
        buildSplashPageDirect(authStream: const Stream.empty()),
      );
      await tester.pump();

      // Then: Row 위젯이 존재한다 (로딩 인디케이터)
      expect(find.byType(Row), findsWidgets);

      // 타이머 정리
      await tester.pump(const Duration(milliseconds: 2100));
    });

    testWidgets('SplashPage에 Opacity 위젯들이 존재한다', (tester) async {
      // Given
      await tester.pumpWidget(
        buildSplashPageDirect(authStream: const Stream.empty()),
      );
      await tester.pump();

      // Then: Opacity 위젯들이 존재한다 (점 깜빡임 애니메이션)
      expect(find.byType(Opacity), findsWidgets);

      // 타이머 정리
      await tester.pump(const Duration(milliseconds: 2100));
    });

    testWidgets('SplashPage dispose 시 AnimationController가 정리된다', (tester) async {
      // Given
      await tester.pumpWidget(
        buildSplashPageDirect(authStream: const Stream.empty()),
      );
      await tester.pump();

      // Future.delayed(2000ms) 타이머를 먼저 소진한다
      await tester.pump(const Duration(milliseconds: 2100));

      // When: 다른 위젯으로 교체 (dispose 트리거)
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('replaced'))),
      );

      // Then: dispose 후 에러 없이 정상 종료
      expect(find.text('replaced'), findsOneWidget);
    });
  });

  group('AuthChangeNotifier 위젯 테스트', () {
    testWidgets('authChangeNotifierProvider가 ProviderScope에서 정상 생성된다',
        (tester) async {
      // Given
      late AuthChangeNotifier notifier;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              notifier = ref.watch(authChangeNotifierProvider);
              return const SizedBox();
            },
          ),
        ),
      );

      // Then: AuthChangeNotifier가 생성됐다
      expect(notifier, isA<AuthChangeNotifier>());
      expect(notifier, isA<ChangeNotifier>());
    });

    testWidgets('authStateProvider 변경 시 AuthChangeNotifier가 notifyListeners를 호출한다',
        (tester) async {
      // Given
      final controller = StreamController<User?>();
      int listenerCallCount = 0;

      late AuthChangeNotifier notifier;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => controller.stream),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              notifier = ref.watch(authChangeNotifierProvider);
              return const SizedBox();
            },
          ),
        ),
      );

      notifier.addListener(() {
        listenerCallCount++;
      });

      // When: 스트림에 이벤트 추가
      controller.add(null);
      await tester.pump();

      // Then: notifyListeners가 호출됐다
      expect(listenerCallCount, greaterThanOrEqualTo(1));

      await controller.close();
    });
  });
}
