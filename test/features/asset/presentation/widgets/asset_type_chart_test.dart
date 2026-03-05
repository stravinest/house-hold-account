import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: deprecated_member_use_from_same_package
import 'package:shared_household_account/features/asset/presentation/widgets/asset_type_chart.dart';

void main() {
  group('AssetTypeChart 위젯 테스트 (Deprecated)', () {
    testWidgets('AssetTypeChart가 deprecated 메시지와 함께 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(
        MaterialApp(
          // ignore: deprecated_member_use
          home: Scaffold(
            body: AssetTypeChart(breakdown: null),
          ),
        ),
      );

      // Then: deprecated 위젯이 렌더링됨
      // ignore: deprecated_member_use
      expect(find.byType(AssetTypeChart), findsOneWidget);
    });

    testWidgets('AssetTypeBreakdownCard가 deprecated 메시지와 함께 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssetTypeBreakdownCard(breakdown: null),
          ),
        ),
      );

      // Then: deprecated 카드가 렌더링됨
      expect(find.byType(AssetTypeBreakdownCard), findsOneWidget);
    });
  });
}
