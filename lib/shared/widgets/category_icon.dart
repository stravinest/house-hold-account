import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/utils/color_utils.dart';
import '../themes/design_tokens.dart';

/// 카테고리 아이콘 크기
enum CategoryIconSize {
  /// 28x28 - 카테고리 선택 칩, 리스트 아이템
  small(28, 14, BorderRadiusToken.sm),

  /// 36x36 - 카테고리 관리 페이지
  medium(36, 18, BorderRadiusToken.sm),

  /// 48x48 - 상세 화면
  large(48, 22, BorderRadiusToken.md);

  final double dimension;
  final double fontSize;
  final double borderRadius;

  const CategoryIconSize(this.dimension, this.fontSize, this.borderRadius);
}

/// 카테고리 아이콘 위젯
///
/// 카테고리의 아이콘을 일관된 스타일로 표시합니다.
/// - icon이 Material icon 이름이면: 둥근사각형 배경 + Material Icon
/// - icon이 비어있으면: 둥근사각형 배경 + 카테고리명 첫 글자
class CategoryIcon extends StatelessWidget {
  /// Material icon 이름 (예: 'restaurant', 'directions_bus')
  /// 비어있으면 첫 글자 사용
  final String icon;

  /// 카테고리명 (첫 글자 폴백용)
  final String name;

  /// 카테고리 색상 (#RRGGBB)
  final String color;

  /// 아이콘 크기
  final CategoryIconSize size;

  const CategoryIcon({
    super.key,
    required this.icon,
    required this.name,
    required this.color,
    this.size = CategoryIconSize.small,
  });

  /// Material icon 이름 -> IconData 매핑
  static const Map<String, IconData> _iconMap = {
    // 지출 카테고리
    'restaurant': Icons.restaurant,
    'directions_bus': Icons.directions_bus,
    'shopping_cart': Icons.shopping_cart,
    'home': Icons.home,
    'call': Icons.call,
    'local_hospital': Icons.local_hospital,
    'movie': Icons.movie,
    'menu_book': Icons.menu_book,
    'receipt_long': Icons.receipt_long,
    // 수입 카테고리
    'account_balance_wallet': Icons.account_balance_wallet,
    'work': Icons.work,
    'redeem': Icons.redeem,
    'account_balance': Icons.account_balance,
    'attach_money': Icons.attach_money,
    // 자산 카테고리
    'lock': Icons.lock,
    'savings': Icons.savings,
    'trending_up': Icons.trending_up,
    'pie_chart': Icons.pie_chart,
    'apartment': Icons.apartment,
    'currency_bitcoin': Icons.currency_bitcoin,
    'diamond': Icons.diamond,
    // 고정비 카테고리
    'house': Icons.house,
    'domain': Icons.domain,
    'shield': Icons.shield,
    'request_quote': Icons.request_quote,
    'cell_tower': Icons.cell_tower,
    'subscriptions': Icons.subscriptions,
    // 결제수단
    'payments': Icons.payments,
    'credit_card': Icons.credit_card,
    // 특수 카테고리
    'push_pin': Icons.push_pin,
    // 하위 호환 (이전 icon name)
    'smartphone': Icons.smartphone,
  };

  @override
  Widget build(BuildContext context) {
    final bgColor = ColorUtils.parseHexColor(color, fallback: const Color(0xFF6750A4));
    final trimmedIcon = icon.trim();
    final iconData = _iconMap[trimmedIcon];

    if (kDebugMode && trimmedIcon.isNotEmpty && iconData == null) {
      debugPrint('CategoryIcon: _iconMap에 없는 아이콘 "$trimmedIcon" (name: $name)');
    }

    return Container(
      width: size.dimension,
      height: size.dimension,
      decoration: BoxDecoration(
        color: bgColor.withAlpha(51),
        borderRadius: BorderRadius.circular(size.borderRadius),
      ),
      alignment: Alignment.center,
      child: iconData != null
          ? Icon(
              iconData,
              size: size.fontSize,
              color: bgColor,
            )
          : trimmedIcon.isEmpty
              ? Text(
                  name.isNotEmpty ? name.characters.first : '?',
                  style: TextStyle(
                    fontSize: size.fontSize,
                    fontWeight: FontWeight.bold,
                    color: bgColor,
                  ),
                )
              : Icon(
                  Icons.category,
                  size: size.fontSize,
                  color: bgColor,
                ),
    );
  }

}
