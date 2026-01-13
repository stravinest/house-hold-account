import 'package:flutter/material.dart';

class AssetConstants {
  AssetConstants._();

  static const Map<String, IconData> categoryIcons = {
    '정기예금': Icons.savings,
    '적금': Icons.account_balance,
    '주식': Icons.trending_up,
    '펀드': Icons.pie_chart,
    '부동산': Icons.home,
    '암호화폐': Icons.currency_bitcoin,
    '기타 자산': Icons.wallet,
  };

  static const Map<String, Color> categoryColors = {
    '정기예금': Color(0xFF4CAF50),
    '적금': Color(0xFF66BB6A),
    '주식': Color(0xFF2196F3),
    '펀드': Color(0xFF1976D2),
    '부동산': Color(0xFFFF9800),
    '암호화폐': Color(0xFFFFC107),
    '기타 자산': Color(0xFF9E9E9E),
  };

  static const List<String> savingCategories = ['정기예금', '적금'];
  static const List<String> investmentCategories = ['주식', '펀드', '암호화폐'];
  static const List<String> realEstateCategories = ['부동산'];

  static IconData getCategoryIcon(String categoryName) {
    return categoryIcons[categoryName] ?? Icons.wallet;
  }

  static Color getCategoryColor(String categoryName) {
    return categoryColors[categoryName] ?? const Color(0xFF9E9E9E);
  }

  static String getCategoryGroup(String categoryName) {
    if (savingCategories.contains(categoryName)) return '저축';
    if (investmentCategories.contains(categoryName)) return '투자';
    if (realEstateCategories.contains(categoryName)) return '부동산';
    return '기타';
  }
}
