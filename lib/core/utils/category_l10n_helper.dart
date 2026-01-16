import '../../l10n/generated/app_localizations.dart';

/// 카테고리 이름을 l10n 문자열로 변환하는 헬퍼
///
/// DB에서 가져온 카테고리 이름이 기본 카테고리인 경우 현재 로케일에 맞게 번역합니다.
/// 커스텀 카테고리인 경우 원래 이름을 그대로 반환합니다.
class CategoryL10nHelper {
  /// 기본 카테고리 이름 매핑 (한글 -> l10n 키)
  static const _defaultCategoryMap = {
    // 지출
    '식비': 'defaultCategoryFood',
    '교통': 'defaultCategoryTransport',
    '쇼핑': 'defaultCategoryShopping',
    '생활': 'defaultCategoryLiving',
    '통신': 'defaultCategoryTelecom',
    '의료': 'defaultCategoryMedical',
    '문화': 'defaultCategoryCulture',
    '교육': 'defaultCategoryEducation',
    '기타 지출': 'defaultCategoryOtherExpense',
    // 수입
    '급여': 'defaultCategorySalary',
    '부업': 'defaultCategorySideJob',
    '용돈': 'defaultCategoryAllowance',
    '이자': 'defaultCategoryInterest',
    '기타 수입': 'defaultCategoryOtherIncome',
    // 자산
    '정기예금': 'defaultCategoryFixedDeposit',
    '적금': 'defaultCategorySavings',
    '주식': 'defaultCategoryStock',
    '펀드': 'defaultCategoryFund',
    '부동산': 'defaultCategoryRealEstate',
    '암호화폐': 'defaultCategoryCrypto',
    '기타 자산': 'defaultCategoryOtherAsset',
    // 특수 카테고리
    '미지정': 'categoryUncategorized',
    '고정비': 'categoryFixedExpense',
    '미분류': 'categoryUnknown',
  };

  /// 카테고리 이름을 현재 로케일에 맞게 번역
  ///
  /// [categoryName] - DB에서 가져온 카테고리 이름
  /// [l10n] - AppLocalizations 인스턴스
  ///
  /// 기본 카테고리면 번역된 이름을, 커스텀 카테고리면 원래 이름을 반환
  static String translate(String categoryName, AppLocalizations l10n) {
    final key = _defaultCategoryMap[categoryName];
    if (key == null) {
      return categoryName; // 커스텀 카테고리는 그대로 반환
    }

    // l10n 키에 해당하는 문자열 반환
    switch (key) {
      // 지출
      case 'defaultCategoryFood':
        return l10n.defaultCategoryFood;
      case 'defaultCategoryTransport':
        return l10n.defaultCategoryTransport;
      case 'defaultCategoryShopping':
        return l10n.defaultCategoryShopping;
      case 'defaultCategoryLiving':
        return l10n.defaultCategoryLiving;
      case 'defaultCategoryTelecom':
        return l10n.defaultCategoryTelecom;
      case 'defaultCategoryMedical':
        return l10n.defaultCategoryMedical;
      case 'defaultCategoryCulture':
        return l10n.defaultCategoryCulture;
      case 'defaultCategoryEducation':
        return l10n.defaultCategoryEducation;
      case 'defaultCategoryOtherExpense':
        return l10n.defaultCategoryOtherExpense;
      // 수입
      case 'defaultCategorySalary':
        return l10n.defaultCategorySalary;
      case 'defaultCategorySideJob':
        return l10n.defaultCategorySideJob;
      case 'defaultCategoryAllowance':
        return l10n.defaultCategoryAllowance;
      case 'defaultCategoryInterest':
        return l10n.defaultCategoryInterest;
      case 'defaultCategoryOtherIncome':
        return l10n.defaultCategoryOtherIncome;
      // 자산
      case 'defaultCategoryFixedDeposit':
        return l10n.defaultCategoryFixedDeposit;
      case 'defaultCategorySavings':
        return l10n.defaultCategorySavings;
      case 'defaultCategoryStock':
        return l10n.defaultCategoryStock;
      case 'defaultCategoryFund':
        return l10n.defaultCategoryFund;
      case 'defaultCategoryRealEstate':
        return l10n.defaultCategoryRealEstate;
      case 'defaultCategoryCrypto':
        return l10n.defaultCategoryCrypto;
      case 'defaultCategoryOtherAsset':
        return l10n.defaultCategoryOtherAsset;
      // 특수 카테고리
      case 'categoryUncategorized':
        return l10n.categoryUncategorized;
      case 'categoryFixedExpense':
        return l10n.categoryFixedExpense;
      case 'categoryUnknown':
        return l10n.categoryUnknown;
      default:
        return categoryName;
    }
  }
}
