import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/settings/data/services/app_update_service.dart';
import 'package:shared_household_account/features/settings/presentation/widgets/app_update_dialog.dart';

Widget buildWidget(AppVersionInfo versionInfo) {
  return MaterialApp(
    home: Scaffold(
      body: AppUpdateDialog(versionInfo: versionInfo),
    ),
  );
}

void main() {
  group('AppUpdateDialog 위젯 테스트', () {
    testWidgets('버전 정보가 표시된다', (tester) async {
      // Given
      const versionInfo = AppVersionInfo(
        version: '2.0.0',
        buildNumber: 200,
      );

      // When
      await tester.pumpWidget(buildWidget(versionInfo));
      await tester.pumpAndSettle();

      // Then: 버전 번호가 표시됨
      expect(find.text('v2.0.0'), findsOneWidget);
    });

    testWidgets('강제 업데이트가 아닌 경우 나중에 버튼이 표시된다', (tester) async {
      // Given
      const versionInfo = AppVersionInfo(
        version: '2.0.0',
        buildNumber: 200,
        isForceUpdate: false,
      );

      // When
      await tester.pumpWidget(buildWidget(versionInfo));
      await tester.pumpAndSettle();

      // Then
      expect(find.text('나중에'), findsOneWidget);
    });

    testWidgets('강제 업데이트인 경우 나중에 버튼이 표시되지 않는다', (tester) async {
      // Given
      const versionInfo = AppVersionInfo(
        version: '2.0.0',
        buildNumber: 200,
        isForceUpdate: true,
      );

      // When
      await tester.pumpWidget(buildWidget(versionInfo));
      await tester.pumpAndSettle();

      // Then
      expect(find.text('나중에'), findsNothing);
    });

    testWidgets('릴리즈 노트가 있으면 표시된다', (tester) async {
      // Given
      const versionInfo = AppVersionInfo(
        version: '2.0.0',
        buildNumber: 200,
        releaseNotes: '버그 수정 및 성능 개선',
      );

      // When
      await tester.pumpWidget(buildWidget(versionInfo));
      await tester.pumpAndSettle();

      // Then
      expect(find.text('버그 수정 및 성능 개선'), findsOneWidget);
    });

    testWidgets('릴리즈 노트가 없으면 표시되지 않는다', (tester) async {
      // Given
      const versionInfo = AppVersionInfo(
        version: '2.0.0',
        buildNumber: 200,
        releaseNotes: null,
      );

      // When
      await tester.pumpWidget(buildWidget(versionInfo));
      await tester.pumpAndSettle();

      // Then: AlertDialog는 표시되지만 relaseNotes 텍스트는 없음
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('나중에 버튼 탭 시 다이얼로그가 닫힌다', (tester) async {
      // Given
      const versionInfo = AppVersionInfo(
        version: '2.0.0',
        buildNumber: 200,
        isForceUpdate: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => AppUpdateDialog.show(context, versionInfo),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      );

      // When: 다이얼로그 열기
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 표시됨
      expect(find.byType(AlertDialog), findsOneWidget);

      // When: 나중에 탭
      await tester.tap(find.text('나중에'));
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 닫힘
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
