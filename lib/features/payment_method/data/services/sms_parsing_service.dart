import '../../../payment_method/domain/entities/learned_sms_format.dart';

/// SMS 파싱 결과를 담는 클래스
class ParsedSmsResult {
  final int? amount;
  final String? transactionType; // 'expense' | 'income'
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

  // 지출 키워드
  static const List<String> expenseKeywords = [
    '승인',
    '결제',
    '사용',
    '출금',
    '이체',
    '지급',
    '체크',
    '일시불',
    '할부',
  ];

  // 수입 키워드
  static const List<String> incomeKeywords = [
    '입금',
    '받으셨습니다',
    '지급되었습니다',
    '충전',
    '환급',
    '환불',
  ];

  // 취소 키워드 (무시해야 함)
  static const List<String> cancelKeywords = ['취소', '승인취소', '결제취소'];
}

/// 금융사별 SMS 발신자 패턴
class FinancialSmsSenders {
  FinancialSmsSenders._();

  static const Map<String, List<String>> senderPatterns = {
    // 카드사
    'KB국민카드': ['KB국민', 'KB카드', '국민카드', '15881688', '15449999'],
    '신한카드': ['신한카드', '신한', '15447200', '15444000'],
    '삼성카드': ['삼성카드', '15881000'],
    '현대카드': ['현대카드', '15776200'],
    '롯데카드': ['롯데카드', '15882100'],
    '우리카드': ['우리카드', '15889955'],
    '하나카드': ['하나카드', '18001111'],
    'BC카드': ['BC카드', '15880300'],
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

    // 지역화폐
    '경기지역화폐': ['경기', '지역화폐', '경기지역', '경기화폐'],
    '서울사랑상품권': ['서울사랑', '서울상품권', '서울페이'],
    '인천이음페이': ['인천이음', '이음페이'],
  };

  /// 발신자 문자열에서 금융사 식별
  static String? identifyFinancialInstitution(String sender) {
    final lowerSender = sender.toLowerCase();
    for (final entry in senderPatterns.entries) {
      for (final pattern in entry.value) {
        if (lowerSender.contains(pattern.toLowerCase())) {
          return entry.key;
        }
      }
    }
    return null;
  }

  /// 발신자가 금융 관련인지 확인
  static bool isFinancialSender(String sender) {
    return identifyFinancialInstitution(sender) != null;
  }
}

/// SMS 파싱 서비스
class SmsParsingService {
  SmsParsingService._();

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

  /// 학습된 포맷을 사용하여 SMS 파싱
  static ParsedSmsResult parseSmsWithFormat(
    String content,
    LearnedSmsFormat format,
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

    return ParsedSmsResult(
      amount: amount,
      transactionType: transactionType,
      merchant: merchant,
      date: date,
      confidence: confidence,
      matchedPattern: format.senderPattern,
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
