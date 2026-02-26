import 'package:flutter/foundation.dart';

import '../../../../config/supabase_config.dart';
import '../repositories/category_keyword_mapping_repository.dart';

/// 상호명-카테고리 매핑 규칙
class MerchantCategoryRule {
  final String id;
  final String ledgerId;
  final String merchantPattern;
  final String categoryId;
  final bool isRegex;
  final int priority;
  final DateTime createdAt;

  const MerchantCategoryRule({
    required this.id,
    required this.ledgerId,
    required this.merchantPattern,
    required this.categoryId,
    this.isRegex = false,
    this.priority = 0,
    required this.createdAt,
  });

  factory MerchantCategoryRule.fromJson(Map<String, dynamic> json) {
    return MerchantCategoryRule(
      id: json['id'] as String,
      ledgerId: json['ledger_id'] as String,
      merchantPattern: json['merchant_pattern'] as String,
      categoryId: json['category_id'] as String,
      isRegex: json['is_regex'] as bool? ?? false,
      priority: json['priority'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// 상호명이 이 규칙과 매칭되는지 확인
  bool matches(String merchant) {
    if (isRegex) {
      return RegExp(merchantPattern, caseSensitive: false).hasMatch(merchant);
    }
    return merchant.toLowerCase().contains(merchantPattern.toLowerCase());
  }
}

/// 기본 시스템 카테고리 매핑 규칙
class SystemCategoryRules {
  SystemCategoryRules._();

  /// 음식점/카페 패턴
  static const List<String> foodPatterns = [
    '스타벅스',
    '이디야',
    '투썸',
    '빽다방',
    '메가커피',
    '컴포즈',
    '할리스',
    '카페',
    '커피',
    'coffee',
    '맥도날드',
    'mcdonald',
    'kfc',
    '버거킹',
    '롯데리아',
    '피자헛',
    '도미노',
    '파파존스',
    'bbq',
    'bhc',
    '교촌',
    '굽네',
    '치킨',
    '족발',
    '보쌈',
    '삼겹',
    '갈비',
    '고기',
    '분식',
    '김밥',
    '떡볶이',
    '라면',
    '국수',
    '우동',
    '초밥',
    '회',
    '일식',
    '중식',
    '양식',
    '한식',
    '음식',
    '식당',
    '레스토랑',
    'restaurant',
  ];

  /// 마트/편의점 패턴
  static const List<String> martPatterns = [
    'cu',
    'gs25',
    'gs편의점',
    '세븐일레븐',
    '7eleven',
    '이마트',
    '롯데마트',
    '홈플러스',
    '코스트코',
    '트레이더스',
    '하나로마트',
    '농협마트',
    '노브랜드',
    '마트',
    '슈퍼',
    '편의점',
    '미니스톱',
    '스토어',
    '다이소',
    '올리브영',
    '랄라블라',
    '롭스',
    '왓슨스',
  ];

  /// 교통 패턴
  static const List<String> transportPatterns = [
    '택시',
    '카카오택시',
    '타다',
    '버스',
    '지하철',
    '전철',
    '철도',
    'ktx',
    'srt',
    'korail',
    '기차',
    '고속버스',
    '시외버스',
    '주유소',
    'sk에너지',
    'gs칼텍스',
    's-oil',
    '현대오일뱅크',
    '주유',
    '충전소',
    '파킹',
    '주차',
    '톨게이트',
    '하이패스',
    '공항',
    '터미널',
  ];

  /// 쇼핑 패턴
  static const List<String> shoppingPatterns = [
    '쿠팡',
    '네이버쇼핑',
    '지마켓',
    '옥션',
    '11번가',
    '위메프',
    '티몬',
    '무신사',
    '지그재그',
    '에이블리',
    '브랜디',
    '아이디어스',
    '오늘의집',
    '백화점',
    '현대백화점',
    '롯데백화점',
    '신세계',
    '갤러리아',
    'ak플라자',
    '아울렛',
    '애플스토어',
    '삼성스토어',
    'apple',
    'samsung',
    '유니클로',
    '자라',
    'zara',
    'h&m',
    '나이키',
    '아디다스',
    'nike',
    'adidas',
  ];

  /// 의료/건강 패턴
  static const List<String> healthPatterns = [
    '병원',
    '의원',
    '클리닉',
    '치과',
    '한의원',
    '약국',
    '건강검진',
    '내과',
    '외과',
    '피부과',
    '안과',
    '이비인후과',
    '정형외과',
    '산부인과',
    '소아과',
    '정신과',
    '심리상담',
    '헬스',
    '피트니스',
    '짐',
    'gym',
    '필라테스',
    '요가',
    'yoga',
  ];

  /// 문화/여가 패턴
  static const List<String> culturePatterns = [
    'cgv',
    '메가박스',
    '롯데시네마',
    '영화관',
    '극장',
    '공연',
    '콘서트',
    '뮤지컬',
    '전시',
    '미술관',
    '박물관',
    '도서관',
    '서점',
    '교보문고',
    '영풍문고',
    '예스24',
    '알라딘',
    '넷플릭스',
    'netflix',
    '왓챠',
    '디즈니플러스',
    '웨이브',
    '티빙',
    '쿠팡플레이',
    '유튜브',
    '스포티파이',
    '멜론',
    '지니',
    '플로',
    '노래방',
    '볼링',
    '당구',
    'pc방',
    '게임',
  ];

  /// 교육 패턴
  static const List<String> educationPatterns = [
    '학원',
    '과외',
    '어학원',
    '영어학원',
    '수학학원',
    '입시',
    '대학',
    '학교',
    '유치원',
    '어린이집',
    '학습지',
    '교재',
    '인강',
    '강의',
    '클래스',
    '메가스터디',
    '에듀윌',
    '해커스',
    '야나두',
  ];

  /// 통신/유틸리티 패턴
  static const List<String> utilityPatterns = [
    'skt',
    'kt',
    'lgu+',
    'lg유플러스',
    '알뜰폰',
    '통신요금',
    '인터넷',
    '전기요금',
    '한전',
    '가스요금',
    '도시가스',
    '수도요금',
    '관리비',
    '월세',
    '전세',
  ];

  /// 모든 시스템 규칙 (카테고리명 기반)
  static const Map<String, List<String>> allRules = {
    '식비': foodPatterns,
    '음식': foodPatterns,
    '카페': foodPatterns,
    '마트': martPatterns,
    '생필품': martPatterns,
    '편의점': martPatterns,
    '교통': transportPatterns,
    '차량': transportPatterns,
    '주유': transportPatterns,
    '쇼핑': shoppingPatterns,
    '의류': shoppingPatterns,
    '패션': shoppingPatterns,
    '의료': healthPatterns,
    '건강': healthPatterns,
    '병원': healthPatterns,
    '문화': culturePatterns,
    '여가': culturePatterns,
    '취미': culturePatterns,
    '교육': educationPatterns,
    '학원': educationPatterns,
    '통신': utilityPatterns,
    '공과금': utilityPatterns,
    '관리비': utilityPatterns,
  };
}

/// 카테고리 매핑 서비스
///
/// 상호명을 기반으로 적절한 카테고리를 추천합니다.
class CategoryMappingService {
  final dynamic _client;
  final CategoryKeywordMappingRepository _keywordMappingRepository;

  // 캐시: ledgerId -> rules
  final Map<String, List<MerchantCategoryRule>> _ruleCache = {};

  /// 기본 생성자 - Supabase 클라이언트 주입
  CategoryMappingService({dynamic client})
    : _client = client ?? SupabaseConfig.client,
      _keywordMappingRepository = CategoryKeywordMappingRepository();

  /// LIKE 패턴에서 특수문자 이스케이프 (SQL Injection 방지)
  String _escapeLikePattern(String input) {
    return input
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
  }

  /// 키워드 매핑으로 카테고리 찾기
  ///
  /// sourceContent(원본 메시지)에서 등록된 keyword 포함 여부 확인
  /// 여러 개 매칭 시 가장 긴 키워드 우선 (구체적 매칭)
  Future<String?> findCategoryByKeywordMapping(
    String sourceContent,
    String paymentMethodId,
    String sourceType,
    String ledgerId,
  ) async {
    if (sourceContent.isEmpty || paymentMethodId.isEmpty) return null;

    try {
      final mappings = await _keywordMappingRepository.getByPaymentMethod(
        paymentMethodId,
        sourceType: sourceType,
      );

      if (mappings.isEmpty) return null;

      final lowerContent = sourceContent.toLowerCase();

      // 매칭되는 키워드 필터링
      final matched = mappings.where((m) {
        return lowerContent.contains(m.keyword.toLowerCase());
      }).toList();

      if (matched.isEmpty) return null;

      // 가장 긴 키워드 우선 (구체적 매칭)
      matched.sort((a, b) => b.keyword.length.compareTo(a.keyword.length));

      return matched.first.categoryId;
    } catch (e) {
      debugPrint('CategoryMappingService.findCategoryByKeywordMapping error: $e');
      return null;
    }
  }

  /// 상호명으로 카테고리 찾기
  ///
  /// 1. 키워드 매핑 우선 (sourceContent/paymentMethodId/sourceType 제공 시)
  /// 2. 사용자 정의 규칙
  /// 3. 시스템 기본 규칙 적용
  /// 4. 매칭 안되면 null
  Future<String?> findCategoryId(
    String merchant,
    String ledgerId, {
    bool useCache = true,
    String? sourceContent,
    String? paymentMethodId,
    String? sourceType,
  }) async {
    if (merchant.isEmpty) return null;

    try {
      // 1. 키워드 매핑 확인 (sourceContent와 paymentMethodId가 있을 때)
      if (sourceContent != null &&
          paymentMethodId != null &&
          sourceType != null) {
        final keywordCategoryId = await findCategoryByKeywordMapping(
          sourceContent,
          paymentMethodId,
          sourceType,
          ledgerId,
        );
        if (keywordCategoryId != null) return keywordCategoryId;
      }

      // 2. 사용자 정의 규칙 확인
      final userCategoryId = await _findByUserRules(
        merchant,
        ledgerId,
        useCache: useCache,
      );
      if (userCategoryId != null) return userCategoryId;

      // 3. 시스템 규칙으로 카테고리명 찾기
      final systemCategoryName = _findBySystemRules(merchant);
      if (systemCategoryName == null) return null;

      // 4. 카테고리명으로 실제 ID 조회
      return _getCategoryIdByName(systemCategoryName, ledgerId);
    } catch (e, st) {
      // 카테고리 매핑 실패는 치명적이지 않음 - null 반환
      debugPrint('CategoryMappingService.findCategoryId error: $e\n$st');
      return null;
    }
  }

  /// 사용자 정의 규칙으로 카테고리 찾기
  Future<String?> _findByUserRules(
    String merchant,
    String ledgerId, {
    bool useCache = true,
  }) async {
    List<MerchantCategoryRule> rules;

    if (useCache && _ruleCache.containsKey(ledgerId)) {
      rules = _ruleCache[ledgerId]!;
    } else {
      rules = await _loadUserRules(ledgerId);
      _ruleCache[ledgerId] = rules;
    }

    // 우선순위 높은 것부터 매칭
    rules.sort((a, b) => b.priority.compareTo(a.priority));

    for (final rule in rules) {
      if (rule.matches(merchant)) {
        return rule.categoryId;
      }
    }
    return null;
  }

  /// 사용자 정의 규칙 로드
  Future<List<MerchantCategoryRule>> _loadUserRules(String ledgerId) async {
    final response = await _client
        .from('merchant_category_rules')
        .select()
        .eq('ledger_id', ledgerId)
        .order('priority', ascending: false);

    return (response as List)
        .map((json) => MerchantCategoryRule.fromJson(json))
        .toList();
  }

  /// 시스템 규칙으로 카테고리명 찾기
  String? _findBySystemRules(String merchant) {
    final lowerMerchant = merchant.toLowerCase();

    for (final entry in SystemCategoryRules.allRules.entries) {
      for (final pattern in entry.value) {
        if (lowerMerchant.contains(pattern.toLowerCase())) {
          return entry.key;
        }
      }
    }
    return null;
  }

  /// 카테고리명으로 ID 조회
  Future<String?> _getCategoryIdByName(
    String categoryName,
    String ledgerId,
  ) async {
    try {
      final escapedName = _escapeLikePattern(categoryName);
      final response = await _client
          .from('categories')
          .select('id')
          .eq('ledger_id', ledgerId)
          .ilike('name', '%$escapedName%')
          .limit(1)
          .maybeSingle();

      return response?['id'] as String?;
    } catch (e) {
      // 에러 발생 시 null 반환 (카테고리 매핑 실패는 치명적이지 않음)
      // 로깅은 상위 레이어에서 처리
      rethrow;
    }
  }

  /// 사용자 정의 규칙 추가
  Future<MerchantCategoryRule> addRule({
    required String ledgerId,
    required String merchantPattern,
    required String categoryId,
    bool isRegex = false,
    int priority = 0,
  }) async {
    final response = await _client
        .from('merchant_category_rules')
        .insert({
          'ledger_id': ledgerId,
          'merchant_pattern': merchantPattern,
          'category_id': categoryId,
          'is_regex': isRegex,
          'priority': priority,
        })
        .select()
        .single();

    // 캐시 무효화
    _ruleCache.remove(ledgerId);

    return MerchantCategoryRule.fromJson(response);
  }

  /// 사용자 정의 규칙 삭제
  Future<void> deleteRule(String ruleId, String ledgerId) async {
    await _client.from('merchant_category_rules').delete().eq('id', ruleId);

    // 캐시 무효화
    _ruleCache.remove(ledgerId);
  }

  /// 사용자 정의 규칙 목록 조회
  Future<List<MerchantCategoryRule>> getRules(String ledgerId) async {
    return _loadUserRules(ledgerId);
  }

  /// 캐시 초기화
  void clearCache([String? ledgerId]) {
    if (ledgerId != null) {
      _ruleCache.remove(ledgerId);
    } else {
      _ruleCache.clear();
    }
  }

  /// 상호명으로 카테고리 학습 (이전 거래 기반)
  Future<String?> learnCategoryFromHistory(
    String merchant,
    String ledgerId,
  ) async {
    if (merchant.isEmpty) return null;

    // 비슷한 상호명의 이전 거래에서 가장 많이 사용된 카테고리 찾기
    final escapedMerchant = _escapeLikePattern(merchant);
    final response = await _client
        .from('transactions')
        .select('category_id')
        .eq('ledger_id', ledgerId)
        .ilike('description', '%$escapedMerchant%')
        .not('category_id', 'is', null)
        .limit(10);

    if ((response as List).isEmpty) return null;

    // 카테고리 빈도 계산
    final categoryCount = <String, int>{};
    for (final row in response) {
      final categoryId = row['category_id'] as String?;
      if (categoryId != null) {
        categoryCount[categoryId] = (categoryCount[categoryId] ?? 0) + 1;
      }
    }

    if (categoryCount.isEmpty) return null;

    // 가장 빈번한 카테고리 반환
    final sorted = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }
}
