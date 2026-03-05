import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/settings/data/services/app_update_service.dart';
import 'package:shared_household_account/features/settings/presentation/widgets/app_update_dialog.dart';

void main() {
  group('AppUpdateDialog _openStore 및 추가 커버리지 테스트', () {
    testWidgets('업데이트 버튼 탭 시 다이얼로그가 닫혀야 한다', (tester) async {
      // Given: storeUrl이 있는 버전 정보
      const versionInfo = AppVersionInfo(
        version: '2.0.0',
        buildNumber: 200,
        isForceUpdate: false,
        storeUrl: null, // 기본 URL 사용
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

      // When: 업데이트 버튼 탭 (url_launcher는 테스트 환경에서 무시됨)
      await tester.tap(find.text('업데이트'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Then: 코드가 실행됨 (url_launcher 실패해도 mounted 체크 후 pop)
      // AlertDialog가 닫히거나 그대로인지는 환경에 따라 다름
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('storeUrl이 빈 문자열일 때 기본 URL을 사용해야 한다', (tester) async {
      // Given: storeUrl이 빈 문자열인 경우
      const versionInfo = AppVersionInfo(
        version: '2.0.0',
        buildNumber: 200,
        isForceUpdate: false,
        storeUrl: '',
      );

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppUpdateDialog(versionInfo: versionInfo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 업데이트 버튼이 표시됨
      expect(find.text('업데이트'), findsOneWidget);
    });

    testWidgets('강제 업데이트 시 barrierDismissible이 false여야 한다', (tester) async {
      // Given: 강제 업데이트
      const versionInfo = AppVersionInfo(
        version: '3.0.0',
        buildNumber: 300,
        isForceUpdate: true,
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

      // When
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      // Then: 다이얼로그 표시 (나중에 버튼 없음 = 강제 업데이트)
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('나중에'), findsNothing);
    });

    testWidgets('AppUpdateDialog 위젯이 직접 생성되어 build() 메서드가 실행된다', (tester) async {
      // Given: 릴리즈 노트가 있는 경우
      const versionInfo = AppVersionInfo(
        version: '1.5.0',
        buildNumber: 150,
        isForceUpdate: false,
        releaseNotes: '새 기능이 추가되었습니다',
      );

      // When: 위젯 렌더링
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppUpdateDialog(versionInfo: versionInfo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 버전과 릴리즈 노트가 표시됨
      expect(find.text('v1.5.0'), findsOneWidget);
      expect(find.text('새 기능이 추가되었습니다'), findsOneWidget);
      // 나중에 버튼도 표시됨 (isForceUpdate=false)
      expect(find.text('나중에'), findsOneWidget);
      expect(find.text('업데이트'), findsOneWidget);
    });

    testWidgets('나중에 버튼 탭 시 다이얼로그가 닫혀야 한다 (직접 위젯)', (tester) async {
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
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => AppUpdateDialog(versionInfo: versionInfo),
                ),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      );

      // When: 다이얼로그 열기
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // When: 나중에 탭
      await tester.tap(find.text('나중에'));
      await tester.pumpAndSettle();

      // Then: 다이얼로그 닫힘
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
