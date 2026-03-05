import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/features/notification/domain/entities/notification_type.dart';
import 'package:shared_household_account/features/notification/presentation/pages/notification_settings_page.dart';
import 'package:shared_household_account/features/notification/presentation/providers/notification_settings_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

import '../../../../helpers/mock_repositories.dart';

class MockUser extends Mock implements User {}

Widget buildTestWidget({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: child,
    ),
  );
}

void main() {
  late MockNotificationSettingsRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(NotificationType.transactionAdded);
  });

  setUp(() {
    mockRepository = MockNotificationSettingsRepository();
  });

  Map<NotificationType, bool> buildDefaultSettings({bool value = true}) {
    return {for (final type in NotificationType.values) type: value};
  }

  group('NotificationSettingsPage 위젯 테스트', () {
    group('로딩 상태', () {
      testWidgets('로딩 중일 때 CircularProgressIndicator를 표시한다',
          (WidgetTester tester) async {
        // Given: 완료되지 않는 Completer를 사용하여 로딩 상태 유지
        // Future.delayed는 pending timer 경고를 유발하므로 Completer 사용
        final completer = Completer<Map<NotificationType, bool>>();
        when(() => mockRepository.getNotificationSettings(any()))
            .thenAnswer((_) => completer.future);

        final testUser = MockUser();
        when(() => testUser.id).thenReturn('test-user-id');

        // When
        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              currentUserProvider.overrideWith((ref) => testUser),
              notificationSettingsRepositoryProvider
                  .overrideWith((ref) => mockRepository),
            ],
            child: const NotificationSettingsPage(),
          ),
        );

        // pumpWidget 직후(Future 완료 전)에는 로딩 상태
        await tester.pump();

        // Then
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // 테스트 종료 전 completer를 완료시켜 pending timer 제거
        completer.complete(buildDefaultSettings());
        await tester.pumpAndSettle();
      });
    });

    group('데이터 표시', () {
      testWidgets('알림 설정이 로드되면 SwitchListTile들을 표시한다',
          (WidgetTester tester) async {
        // Given: 모든 알림이 활성화된 설정
        when(() => mockRepository.getNotificationSettings(any()))
            .thenAnswer((_) async => buildDefaultSettings(value: true));

        final testUser = MockUser();
        when(() => testUser.id).thenReturn('test-user-id');

        // When
        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              currentUserProvider.overrideWith((ref) => testUser),
              notificationSettingsRepositoryProvider
                  .overrideWith((ref) => mockRepository),
            ],
            child: const NotificationSettingsPage(),
          ),
        );
        await tester.pumpAndSettle();

        // Then: SwitchListTile이 렌더링되어야 한다 (6개 - UI에 노출된 타입)
        expect(find.byType(SwitchListTile), findsWidgets);
      });

      testWidgets('AppBar 제목이 표시된다', (WidgetTester tester) async {
        // Given
        when(() => mockRepository.getNotificationSettings(any()))
            .thenAnswer((_) async => buildDefaultSettings());
        final testUser = MockUser();
        when(() => testUser.id).thenReturn('test-user-id');

        // When
        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              currentUserProvider.overrideWith((ref) => testUser),
              notificationSettingsRepositoryProvider
                  .overrideWith((ref) => mockRepository),
            ],
            child: const NotificationSettingsPage(),
          ),
        );
        await tester.pumpAndSettle();

        // Then: AppBar가 있어야 한다
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('로그인하지 않은 경우에도 기본 설정으로 UI를 표시한다',
          (WidgetTester tester) async {
        // Given: 로그인하지 않은 상태 (provider가 기본값 반환)
        // When
        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              currentUserProvider.overrideWith((ref) => null),
              notificationSettingsRepositoryProvider
                  .overrideWith((ref) => mockRepository),
            ],
            child: const NotificationSettingsPage(),
          ),
        );
        await tester.pumpAndSettle();

        // Then: SwitchListTile들이 기본값(true)으로 표시되어야 한다
        expect(find.byType(SwitchListTile), findsWidgets);
      });

      testWidgets('Divider가 섹션 구분선으로 표시된다', (WidgetTester tester) async {
        // Given
        when(() => mockRepository.getNotificationSettings(any()))
            .thenAnswer((_) async => buildDefaultSettings());
        final testUser = MockUser();
        when(() => testUser.id).thenReturn('test-user-id');

        // When
        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              currentUserProvider.overrideWith((ref) => testUser),
              notificationSettingsRepositoryProvider
                  .overrideWith((ref) => mockRepository),
            ],
            child: const NotificationSettingsPage(),
          ),
        );
        await tester.pumpAndSettle();

        // Then: Divider가 있어야 한다
        expect(find.byType(Divider), findsWidgets);
      });
    });

    group('에러 상태', () {
      testWidgets('알림 설정 로드 실패 시 에러 뷰를 표시한다', (WidgetTester tester) async {
        // Given: 에러를 반환하는 repository
        when(() => mockRepository.getNotificationSettings(any()))
            .thenThrow(Exception('네트워크 오류'));

        final testUser = MockUser();
        when(() => testUser.id).thenReturn('test-user-id');

        // When
        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              currentUserProvider.overrideWith((ref) => testUser),
              notificationSettingsRepositoryProvider
                  .overrideWith((ref) => mockRepository),
            ],
            child: const NotificationSettingsPage(),
          ),
        );
        await tester.pumpAndSettle();

        // Then: 에러 아이콘이 표시되어야 한다 (EmptyState 내부)
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });
    });

    group('토글 인터랙션', () {
      testWidgets('SwitchListTile를 탭하면 updateNotificationSetting이 호출된다',
          (WidgetTester tester) async {
        // Given: 활성화된 설정
        final initialSettings = buildDefaultSettings(value: true);
        final updatedSettings = {
          ...initialSettings,
          NotificationType.transactionAdded: false,
        };

        var callCount = 0;
        when(() => mockRepository.getNotificationSettings(any())).thenAnswer(
          (_) async {
            if (callCount == 0) {
              callCount++;
              return initialSettings;
            }
            return updatedSettings;
          },
        );
        when(
          () => mockRepository.updateNotificationSetting(
            userId: any(named: 'userId'),
            type: any(named: 'type'),
            enabled: any(named: 'enabled'),
          ),
        ).thenAnswer((_) async {});

        final testUser = MockUser();
        when(() => testUser.id).thenReturn('test-user-id');

        // When
        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              currentUserProvider.overrideWith((ref) => testUser),
              notificationSettingsRepositoryProvider
                  .overrideWith((ref) => mockRepository),
            ],
            child: const NotificationSettingsPage(),
          ),
        );
        await tester.pumpAndSettle();

        // SwitchListTile 첫 번째 항목을 탭
        final switches = find.byType(SwitchListTile);
        expect(switches, findsWidgets);
        await tester.tap(switches.first);
        await tester.pumpAndSettle();

        // Then: updateNotificationSetting이 호출되어야 한다
        verify(
          () => mockRepository.updateNotificationSetting(
            userId: 'test-user-id',
            type: any(named: 'type'),
            enabled: any(named: 'enabled'),
          ),
        ).called(1);
      });

      testWidgets('업데이트 실패 시 에러 스낵바가 표시된다', (WidgetTester tester) async {
        // Given: 설정 로드는 성공, 업데이트는 실패
        when(() => mockRepository.getNotificationSettings(any()))
            .thenAnswer((_) async => buildDefaultSettings(value: true));
        when(
          () => mockRepository.updateNotificationSetting(
            userId: any(named: 'userId'),
            type: any(named: 'type'),
            enabled: any(named: 'enabled'),
          ),
        ).thenThrow(Exception('업데이트 실패'));

        final testUser = MockUser();
        when(() => testUser.id).thenReturn('test-user-id');

        // When
        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              currentUserProvider.overrideWith((ref) => testUser),
              notificationSettingsRepositoryProvider
                  .overrideWith((ref) => mockRepository),
            ],
            child: const NotificationSettingsPage(),
          ),
        );
        await tester.pumpAndSettle();

        // 스위치 탭
        final switches = find.byType(SwitchListTile);
        expect(switches, findsWidgets);
        await tester.tap(switches.first);
        await tester.pumpAndSettle();

        // Then: SnackBar가 표시되어야 한다
        expect(find.byType(SnackBar), findsOneWidget);
      });
    });

    group('페이지 구조 검증', () {
      testWidgets('NotificationSettingsPage는 ConsumerWidget이다',
          (WidgetTester tester) async {
        expect(const NotificationSettingsPage(), isA<ConsumerWidget>());
      });

      testWidgets('Scaffold가 렌더링된다', (WidgetTester tester) async {
        // Given
        when(() => mockRepository.getNotificationSettings(any()))
            .thenAnswer((_) async => buildDefaultSettings());
        final testUser = MockUser();
        when(() => testUser.id).thenReturn('test-user-id');

        // When
        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              currentUserProvider.overrideWith((ref) => testUser),
              notificationSettingsRepositoryProvider
                  .overrideWith((ref) => mockRepository),
            ],
            child: const NotificationSettingsPage(),
          ),
        );
        await tester.pump();

        // Then
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });
  });
}
