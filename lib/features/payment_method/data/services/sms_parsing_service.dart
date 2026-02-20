import '../../../payment_method/domain/entities/learned_format.dart';
import '../../../payment_method/domain/entities/learned_push_format.dart';
import '../../../payment_method/domain/entities/learned_sms_format.dart';
import 'financial_constants.dart';

/// SMS 파싱 결과를 담는 클래스
class ParsedSmsResult {
  final int? amount;
  final String? transactionType; // 'expense'(지출) | 'income'(수입)
  final String? merchant;
  final DateTime? date;
  final String? cardLastDigits;
  final double confidence;
  final String? matchedPattern;

  const ParsedSmsResult({
    this.amount,
    this.transactionType,
    this.merchant,
    this.date,
    this.cardLastDigits,
    this.confidence = 0.0,
    this.matchedPattern,
  });

  bool get isParsed => amount != null && transactionType != null;

  @override
  String toString() {
    return 'ParsedSmsResult(amount: $amount, type: $transactionType, '
        'merchant: $merchant, date: $date, confidence: $confidence)';
  }
}

/// 한국 금융사 SMS 패턴 정의
class KoreanFinancialSmsPatterns {
  KoreanFinancialSmsPatterns._();

  // 금액 패턴 (콤마 포함/미포함, 원 단위)
  static final RegExp amountPattern = RegExp(
    r'([0-9,]+)\s*원',
    caseSensitive: false,
  );

  // 카드 끝자리 패턴
  static final RegExp cardDigitsPattern = RegExp(
    r'(\d{4})\s*[카승]',
    caseSensitive: false,
  );

  // 날짜/시간 패턴들
  static final List<RegExp> datePatterns = [
    // MM/DD HH:MM or MM/DD HH:mm
    RegExp(r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})'),
    // MM-DD HH:MM
    RegExp(r'(\d{1,2})-(\d{1,2})\s+(\d{1,2}):(\d{2})'),
    // YYYY.MM.DD HH:MM
    RegExp(r'(\d{4})\.(\d{1,2})\.(\d{1,2})\s+(\d{1,2}):(\d{2})'),
    // MM월DD일 HH시MM분
    RegExp(r'(\d{1,2})월\s*(\d{1,2})일\s*(\d{1,2})시\s*(\d{2})분'),
  ];

  static List<String> get expenseKeywords => FinancialConstants.expenseKeywords;
  static List<String> get incomeKeywords => FinancialConstants.incomeKeywords;
  static List<String> get cancelKeywords => FinancialConstants.cancelKeywords;
}

/// 금융사별 SMS 발신자 패턴
class FinancialSmsSenders {
  FinancialSmsSenders._();

  static const Map<String, List<String>> senderPatterns = {
    // 카드사 (2026-01-25 웹 서치로 전화번호 검증됨)
    'KB국민카드': ['KB국민', 'KB카드', '국민카드', '15881688', '15449999'],
    'KB Pay': ['KB Pay', 'KBPay', 'KB페이'], // KB Pay 앱 추가
    '신한카드': ['신한카드', '신한', '15447000', '15447200', '15444000'],
    '삼성카드': ['삼성카드', '15888700'],
    '현대카드': ['현대카드', '15886474'],
    '롯데카드': ['롯데카드', '15882100'],
    '우리카드': ['우리카드', '15889955'],
    '하나카드': ['하나카드', '18001111'],
    'BC카드': ['BC카드', '15884000'],
    'NH농협카드': ['NH', '농협카드', '15442100'],

    // 은행
    'KB국민은행': ['KB국민', '국민은행', '15889999'],
    '신한은행': ['신한은행', '신한', '15778000'],
    '우리은행': ['우리은행', '15889955'],
    '하나은행': ['하나은행', '15991111'],
    'NH농협은행': ['NH농협', '농협은행', '15881111'],
    '기업은행': ['IBK', '기업은행', '15882588'],
    '카카오뱅크': ['카카오뱅크', '카뱅', '16618100'],
    '토스뱅크': ['토스', '토스뱅크', 'toss'],
    '케이뱅크': ['케이뱅크', 'K뱅크', '15221700'],

    // 지역화폐 (경기도 개별 시/군) - 고유 키워드를 앞에 배치
    '수원페이': ['수원페이', '수원시', '경기지역화폐'],
    '용인와이페이': ['용인와이페이', '용인페이', '용인시', '경기지역화폐'],
    '행복화성지역화폐': ['행복화성', '화성페이', '화성시', '경기지역화폐'],
    '고양페이': ['고양페이', '고양시', '경기지역화폐'],
    '부천페이': ['부천페이', '부천시', '경기지역화폐'],
    '서울사랑상품권': ['서울사랑', '서울상품권', '서울페이'],
    '인천이음페이': ['인천이음', '이음페이'],
  };

  /// 여러 금융사에 공통으로 사용되는 패턴 (경기지역화폐 등)
  /// 이 패턴으로만 매칭되면 후순위로 처리하고, 고유 패턴을 우선 매칭한다.
  static const Set<String> _sharedPatterns = {
    '경기지역화폐',
  };

  /// 발신자 또는 본문에서 금융사 식별
  /// [sender]: 발신자 (번호 또는 이름)
  /// [content]: 문자 본문 (선택, 제공 시 본문에서도 금융사 패턴 검색)
  ///
  /// 고유 패턴(각 금융사 전용)을 우선 매칭하고,
  /// 공통 패턴(경기지역화폐 등)으로만 매칭되는 경우는 후순위로 처리한다.
  static String? identifyFinancialInstitution(
    String sender, [
    String? content,
  ]) {
    final lowerSender = sender.toLowerCase();
    final lowerContent = content?.toLowerCase();

    String? fallbackMatch;

    for (final entry in senderPatterns.entries) {
      for (final pattern in entry.value) {
        final lowerPattern = pattern.toLowerCase();
        final isShared = _sharedPatterns.contains(pattern);

        bool matched = false;
        if (lowerSender.contains(lowerPattern)) {
          matched = true;
        } else if (lowerContent != null &&
            lowerContent.contains(lowerPattern)) {
          matched = true;
        }

        if (matched) {
          if (!isShared) {
            // 고유 패턴 매칭 시 즉시 반환
            return entry.key;
          } else if (fallbackMatch == null) {
            // 공통 패턴으로만 매칭된 첫 번째 결과를 fallback으로 저장
            fallbackMatch = entry.key;
          }
        }
      }
    }
    return fallbackMatch;
  }

  /// 발신자 또는 본문이 금융 관련인지 확인
  /// [sender]: 발신자 (번호 또는 이름)
  /// [content]: 문자 본문 (선택, 제공 시 본문에서도 금융사 패턴 검색)
  static bool isFinancialSender(String sender, [String? content]) {
    return identifyFinancialInstitution(sender, content) != null;
  }
}

/// SMS 파싱 서비스
class SmsParsingService {
  SmsParsingService._();

  /// 샘플 텍스트로부터 학습된 포맷 생성
  static LearnedSmsFormat generateFormatFromSample({
    required String sample,
    required String paymentMethodId,
    String? knownMerchant,
  }) {
    // 1. 발신자/금융사 식별 및 키워드 추출
    // 순서 보장을 위해 List 사용 (중복 제거는 수동으로 처리)
    final potentialKeywords = <String>[];

    // 대괄호 안의 내용 우선 추출 (사용자가 직접 수정한 경우 강력한 힌트)
    final bracketPattern = RegExp(r'\[([^\]]+)\]');
    final bracketMatch = bracketPattern.firstMatch(sample);
    if (bracketMatch != null && bracketMatch.group(1) != null) {
      final keyword = bracketMatch.group(1)!;
      if (!potentialKeywords.contains(keyword)) {
        potentialKeywords.add(keyword);
      }
    }

    // 기존에 정의된 금융사 패턴 매칭
    final knownSender = FinancialSmsSenders.identifyFinancialInstitution(
      sample,
    );
    if (knownSender != null) {
      if (!potentialKeywords.contains(knownSender)) {
        potentialKeywords.add(knownSender);
      }
      final keywords = FinancialSmsSenders.senderPatterns[knownSender];
      if (keywords != null) {
        for (final k in keywords.where((k) => sample.contains(k))) {
          if (!potentialKeywords.contains(k)) {
            potentialKeywords.add(k);
          }
        }
      }
    }

    // 일반적인 패턴 (예: "XX카드", "XX은행", "XX페이", "XX뱅크")
    final generalPattern = RegExp(r'([가-힣\w]+(?:카드|은행|페이|화폐|뱅크))');
    final matches = generalPattern.allMatches(sample);
    for (final match in matches) {
      final keyword = match.group(1);
      if (keyword != null && !potentialKeywords.contains(keyword)) {
        potentialKeywords.add(keyword);
      }
    }

    // 첫 단어 추출 (여전히 비어있는 경우)
    if (potentialKeywords.isEmpty && sample.trim().isNotEmpty) {
      final firstWord = sample.trim().split(RegExp(r'\s+')).first;
      if (firstWord.length > 1) {
        potentialKeywords.add(firstWord);
      }
    }

    // 2. 금액 패턴 추출
    // 단순히 숫자를 찾는 것이 아니라, 샘플 내의 금액 위치를 특정하여 정규식 생성
    String amountRegex = KoreanFinancialSmsPatterns.amountPattern.pattern;
    final amountMatch = KoreanFinancialSmsPatterns.amountPattern.firstMatch(
      sample,
    );
    if (amountMatch != null) {
      // 샘플에서 찾은 금액 주변의 맥락을 포함한 정규식을 만들 수도 있으나,
      // 현재는 기본 패턴을 사용하는 것이 안전함.
      // 필요하다면 추후 "15,000원" 자리에 (\d+(?:,\d+)*)원 패턴을 삽입하는 방식 고려.
    }

    // 3. 거래 유형 (지출/수입)
    final typeKeywords = <String, List<String>>{'expense': [], 'income': []};

    for (final keyword in KoreanFinancialSmsPatterns.expenseKeywords) {
      if (sample.contains(keyword)) {
        typeKeywords['expense']!.add(keyword);
      }
    }
    for (final keyword in KoreanFinancialSmsPatterns.incomeKeywords) {
      if (sample.contains(keyword)) {
        typeKeywords['income']!.add(keyword);
      }
    }

    return LearnedSmsFormat(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // 임시 ID
      paymentMethodId: paymentMethodId,
      senderPattern: knownSender ?? potentialKeywords.firstOrNull ?? '',
      senderKeywords: potentialKeywords.toList(),
      amountRegex: amountRegex,
      typeKeywords: typeKeywords,
      sampleSms: sample,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      // merchantRegex, dateRegex는 복잡하므로 일단 기본 파싱 로직에 맡김 (null)
    );
  }

  /// SMS 내용을 파싱하여 거래 정보 추출
  static ParsedSmsResult parseSms(String sender, String content) {
    // 취소 메시지인 경우 무시
    if (_isCancelMessage(content)) {
      return const ParsedSmsResult(confidence: 0.0, matchedPattern: 'cancel');
    }

    // 금액 추출
    final amount = _parseAmount(content);
    if (amount == null) {
      return const ParsedSmsResult(confidence: 0.0);
    }

    // 거래 타입 추출
    final transactionType = _parseTransactionType(content);

    // 상호명 추출
    final merchant = _parseMerchant(content);

    // 날짜 추출
    final date = _parseDate(content);

    // 카드 끝자리 추출
    final cardDigits = _parseCardDigits(content);

    // 신뢰도 계산
    final confidence = _calculateConfidence(
      amount: amount,
      transactionType: transactionType,
      merchant: merchant,
      date: date,
    );

    return ParsedSmsResult(
      amount: amount,
      transactionType: transactionType,
      merchant: merchant,
      date: date,
      cardLastDigits: cardDigits,
      confidence: confidence,
      matchedPattern: FinancialSmsSenders.identifyFinancialInstitution(sender),
    );
  }

  static ParsedSmsResult parseSmsWithFormat(
    String content,
    LearnedFormat format,
  ) {
    int? amount;
    String? transactionType;
    String? merchant;
    DateTime? date;

    // 금액 추출 (잘못된 정규식 방어)
    try {
      final amountMatch = RegExp(format.amountRegex).firstMatch(content);
      if (amountMatch != null) {
        final amountStr = amountMatch.group(1)?.replaceAll(',', '') ?? '';
        amount = int.tryParse(amountStr);
      }
    } catch (_) {
      // 잘못된 정규식 - 기본 패턴으로 폴백
      amount = _parseAmount(content);
    }

    // 거래 타입 결정
    final typeKeywords = format.typeKeywords;
    for (final keyword in typeKeywords['expense'] ?? []) {
      if (content.contains(keyword)) {
        transactionType = 'expense';
        break;
      }
    }
    if (transactionType == null) {
      for (final keyword in typeKeywords['income'] ?? []) {
        if (content.contains(keyword)) {
          transactionType = 'income';
          break;
        }
      }
    }

    // 상호명 추출 (잘못된 정규식 방어)
    if (format.merchantRegex != null) {
      try {
        final merchantMatch = RegExp(format.merchantRegex!).firstMatch(content);
        if (merchantMatch != null) {
          merchant = merchantMatch.group(1)?.trim();
        }
      } catch (_) {
        // 잘못된 정규식 - 기본 파싱으로 폴백
        merchant = _parseMerchant(content);
      }
    } else {
      merchant = _parseMerchant(content);
    }

    // 날짜 추출 (잘못된 정규식 방어)
    if (format.dateRegex != null) {
      try {
        final dateMatch = RegExp(format.dateRegex!).firstMatch(content);
        if (dateMatch != null) {
          date = _parseDateFromMatch(dateMatch);
        }
      } catch (_) {
        // 잘못된 정규식 - 기본 파싱으로 폴백
        date = _parseDate(content);
      }
    } else {
      date = _parseDate(content);
    }

    final confidence =
        _calculateConfidence(
          amount: amount,
          transactionType: transactionType,
          merchant: merchant,
          date: date,
        ) *
        format.confidence;

    // matchedPattern: LearnedSmsFormat은 senderPattern, LearnedPushFormat은 packageName 사용
    final matchedPattern = (format is LearnedSmsFormat)
        ? format.senderPattern
        : (format is LearnedPushFormat)
        ? format.packageName
        : null;

    return ParsedSmsResult(
      amount: amount,
      transactionType: transactionType,
      merchant: merchant,
      date: date,
      confidence: confidence,
      matchedPattern: matchedPattern,
    );
  }

  /// 취소 메시지 여부 확인
  static bool _isCancelMessage(String content) {
    return KoreanFinancialSmsPatterns.cancelKeywords.any(
      (keyword) => content.contains(keyword),
    );
  }

  /// 금액 추출
  static int? _parseAmount(String content) {
    final match = KoreanFinancialSmsPatterns.amountPattern.firstMatch(content);
    if (match == null) return null;

    final amountStr = match.group(1)?.replaceAll(',', '');
    return int.tryParse(amountStr ?? '');
  }

  /// 거래 타입 추출 (지출/수입)
  static String? _parseTransactionType(String content) {
    // 수입 키워드 먼저 체크 (입금 > 출금 우선순위)
    for (final keyword in KoreanFinancialSmsPatterns.incomeKeywords) {
      if (content.contains(keyword)) {
        return 'income';
      }
    }

    // 지출 키워드 체크
    for (final keyword in KoreanFinancialSmsPatterns.expenseKeywords) {
      if (content.contains(keyword)) {
        return 'expense';
      }
    }

    return null;
  }

  /// 상호명 추출
  static String? _parseMerchant(String content) {
    // 일반적인 패턴들: "~에서", "~(으)로", "~결제"
    final patterns = [
      // KB: "[Web발신] KB국민카드 1234 승인 홍길동 50,000원 일시불 스타벅스"
      RegExp(r'원\s+(?:일시불|할부)?\s*(.+)$'),
      // 신한: "신한카드 1234 홍길동님 50,000원 승인 스타벅스"
      RegExp(r'승인\s+(.+)$'),
      // 지역화폐: "경기지역화폐 스타벅스 50,000원 결제"
      RegExp(r'^[\w가-힣]+\s+(.+?)\s+[\d,]+원'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null) {
        var merchant = match.group(1)?.trim();
        // 불필요한 정보 제거
        merchant = _cleanMerchant(merchant);
        if (merchant != null && merchant.isNotEmpty) {
          return merchant;
        }
      }
    }

    return null;
  }

  /// 상호명 정리
  static String? _cleanMerchant(String? merchant) {
    if (merchant == null) return null;

    // 불필요한 접미사 제거
    merchant = merchant
        .replaceAll(RegExp(r'\(누적.*\)'), '')
        .replaceAll(RegExp(r'잔액.*$'), '')
        .replaceAll(RegExp(r'누적.*$'), '')
        .trim();

    // 너무 짧거나 숫자만 있으면 무시
    if (merchant.length < 2 || RegExp(r'^[\d\s]+$').hasMatch(merchant)) {
      return null;
    }

    return merchant;
  }

  /// 카드 끝자리 추출
  static String? _parseCardDigits(String content) {
    final match = KoreanFinancialSmsPatterns.cardDigitsPattern.firstMatch(
      content,
    );
    return match?.group(1);
  }

  /// 날짜 추출
  static DateTime? _parseDate(String content) {
    for (final pattern in KoreanFinancialSmsPatterns.datePatterns) {
      final match = pattern.firstMatch(content);
      if (match != null) {
        return _parseDateFromMatch(match);
      }
    }
    return null;
  }

  /// RegExpMatch에서 DateTime 파싱
  static DateTime? _parseDateFromMatch(RegExpMatch match) {
    try {
      final now = DateTime.now();
      final groups = match.groups([1, 2, 3, 4, 5]);

      int year = now.year;
      int month, day, hour, minute;

      if (groups.length >= 5 && groups[4] != null) {
        // YYYY.MM.DD HH:MM 형식
        year = int.parse(groups[0] ?? now.year.toString());
        month = int.parse(groups[1] ?? '1');
        day = int.parse(groups[2] ?? '1');
        hour = int.parse(groups[3] ?? '0');
        minute = int.parse(groups[4] ?? '0');
      } else {
        // MM/DD HH:MM 형식
        month = int.parse(groups[0] ?? '1');
        day = int.parse(groups[1] ?? '1');
        hour = int.parse(groups[2] ?? '0');
        minute = int.parse(groups[3] ?? '0');
      }

      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      return null;
    }
  }

  /// 파싱 신뢰도 계산 (0.0 ~ 1.0)
  static double _calculateConfidence({
    int? amount,
    String? transactionType,
    String? merchant,
    DateTime? date,
  }) {
    double score = 0.0;

    if (amount != null && amount > 0) score += 0.4;
    if (transactionType != null) score += 0.3;
    if (merchant != null && merchant.isNotEmpty) score += 0.2;
    if (date != null) score += 0.1;

    return score;
  }

  /// 중복 해시 생성 (3분 이내 동일 거래 판별용)
  static String generateDuplicateHash(
    int amount,
    String? paymentMethodId,
    DateTime timestamp,
  ) {
    // 3분 단위로 버킷팅
    final bucket = timestamp.millisecondsSinceEpoch ~/ (3 * 60 * 1000);
    return '$amount-${paymentMethodId ?? 'unknown'}-$bucket';
  }
}
