class AppConstants {
  AppConstants._();

  // 앱 정보
  static const String appName = '공유 가계부';
  static const String appVersion = '1.0.0';

  // 통화
  static const String defaultCurrency = 'KRW';
  static const List<String> supportedCurrencies = ['KRW', 'USD', 'JPY', 'EUR'];

  // 거래 타입
  static const String transactionTypeIncome = 'income';
  static const String transactionTypeExpense = 'expense';

  // 멤버 권한
  static const String roleOwner = 'owner';
  static const String roleEditor = 'editor';
  static const String roleViewer = 'viewer';

  // 공유 가계부
  static const int maxMembersPerLedger = 2;

  // 반복 타입
  static const String recurringDaily = 'daily';
  static const String recurringWeekly = 'weekly';
  static const String recurringMonthly = 'monthly';

  // 이미지 관련
  static const int maxImageSizeKB = 500;
  static const double imageQuality = 0.7;

  // 페이지네이션
  static const int defaultPageSize = 20;

  // 캐시 관련
  static const Duration cacheDuration = Duration(minutes: 5);
}
