// DEPRECATED: 이 파일은 더 이상 사용되지 않습니다.
// 자산 유형별 분류(저축/투자/부동산)가 제거되었습니다.
// 사용자가 categories 테이블을 통해 자산 카테고리를 직접 생성합니다.
// 이 파일은 삭제해도 됩니다.

import 'package:flutter/material.dart';

@Deprecated('사용자 정의 카테고리를 사용하세요')
class AssetTypeChart extends StatelessWidget {
  final dynamic breakdown;

  const AssetTypeChart({super.key, required this.breakdown});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('DEPRECATED: 자산 유형별 차트가 제거되었습니다'));
  }
}

@Deprecated('사용자 정의 카테고리를 사용하세요')
class AssetTypeBreakdownCard extends StatelessWidget {
  final dynamic breakdown;

  const AssetTypeBreakdownCard({super.key, required this.breakdown});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('DEPRECATED: 자산 유형별 분류가 제거되었습니다')),
      ),
    );
  }
}
