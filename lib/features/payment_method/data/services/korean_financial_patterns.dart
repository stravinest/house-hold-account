/// 한국 금융사별 상세 SMS 패턴 정의
///
/// 각 금융사의 SMS 포맷을 정의하며, SMS 스캔 시 패턴 학습의 기본 템플릿으로 사용됩니다.
library;

/// 금융사 SMS 포맷 정의
class FinancialSmsFormat {
  final String institutionName;
  final String institutionType; // 'card' | 'bank' | 'local_currency'
  final List<String> senderPatterns;
  final String amountRegex;
  final Map<String, List<String>> typeKeywords;
  final String? merchantRegex;
  final String? dateRegex;
  final String? sampleSms;

  const FinancialSmsFormat({
    required this.institutionName,
    required this.institutionType,
    required this.senderPatterns,
    required this.amountRegex,
    required this.typeKeywords,
    this.merchantRegex,
    this.dateRegex,
    this.sampleSms,
  });
}

/// 한국 금융사 SMS 패턴 모음
class KoreanFinancialPatterns {
  KoreanFinancialPatterns._();

  /// 모든 금융사 패턴
  static const List<FinancialSmsFormat> allPatterns = [
    // === 카드사 ===
    kbCard,
    shinhanCard,
    samsungCard,
    hyundaiCard,
    lotteCard,
    wooriCard,
    hanaCard,
    bcCard,
    nhCard,

    // === 은행 ===
    kbBank,
    shinhanBank,
    wooriBank,
    hanaBank,
    nhBank,
    ibkBank,
    kakaoBank,
    tossBank,
    kBank,

    // === 지역화폐 ===
    suwonPay,
    yonginPay,
    hwaseongPay,
    goyangPay,
    bucheonPay,
    seoulPay,
    incheonPay,
  ];

  // ============ 카드사 ============

  /// KB국민카드
  static const kbCard = FinancialSmsFormat(
    institutionName: 'KB국민카드',
    institutionType: 'card',
    senderPatterns: ['KB국민', 'KB카드', '국민카드', '15881688', '15449999'],
    amountRegex: r'([0-9,]+)\s*원',
    typeKeywords: {
      'expense': ['승인', '결제', '사용', '일시불', '할부'],
      'income': ['취소', '환불'],
    },
    merchantRegex: r'원\s+(?:일시불|할부)?\s*(.+?)(?:\s*\(|$)',
    dateRegex: r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})',
    sampleSms: '[Web발신] KB국민카드 1*2*승인 홍*동 50,000원 일시불 스타벅스코리아 01/15 14:30',
  );

  /// 신한카드
  static const shinhanCard = FinancialSmsFormat(
    institutionName: '신한카드',
    institutionType: 'card',
    senderPatterns: ['신한카드', '신한', '15447000', '15447200', '15444000'],
    amountRegex: r'([0-9,]+)\s*원',
    typeKeywords: {
      'expense': ['승인', '결제', '사용'],
      'income': ['취소', '환불'],
    },
    merchantRegex: r'승인\s+(.+?)(?:\s*\d|$)',
    dateRegex: r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})',
    sampleSms: '신한카드 1234 홍길동님 50,000원 승인 스타벅스 01/15 14:30',
  );

  /// 삼성카드
  static const samsungCard = FinancialSmsFormat(
    institutionName: '삼성카드',
    institutionType: 'card',
    senderPatterns: ['삼성카드', '15888700'],
    amountRegex: r'([0-9,]+)\s*원',
    typeKeywords: {
      'expense': ['승인', '결제', '사용', '일시불'],
      'income': ['취소', '환불'],
    },
    merchantRegex: r'승인\s+(.+?)(?:\s*누적|$)',
    dateRegex: r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})',
    sampleSms: '삼성카드 승인 50,000원 일시불 스타벅스 01/15 14:30 누적:100,000원',
  );

  /// 현대카드
  static const hyundaiCard = FinancialSmsFormat(
    institutionName: '현대카드',
    institutionType: 'card',
    senderPatterns: ['현대카드', '15886474'],
    amountRegex: r'([0-9,]+)\s*원',
    typeKeywords: {
      'expense': ['승인', '결제', '사용'],
      'income': ['취소', '환불'],
    },
    merchantRegex: r'승인\s+(.+?)(?:\s*\d|$)',
    dateRegex: r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})',
    sampleSms: '현대카드 승인 50,000원 스타벅스 01/15 14:30',
  );

  /// 롯데카드
  static const lotteCard = FinancialSmsFormat(
    institutionName: '롯데카드',
    institutionType: 'card',
    senderPatterns: ['롯데카드', '15882100'],
    amountRegex: r'([0-9,]+)\s*원',
    typeKeywords: {
      'expense': ['승인', '결제', '사용'],
      'income': ['취소', '환불'],
    },
    merchantRegex: r'승인\s+(.+?)(?:\s*\d|$)',
    dateRegex: r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})',
    sampleSms: '롯데카드 승인 50,000원 스타벅스 01/15 14:30',
  );

  /// 우리카드
  static const wooriCard = FinancialSmsFormat(
    institutionName: '우리카드',
    institutionType: 'card',
    senderPatterns: ['우리카드', '15889955'],
    amountRegex: r'([0-9,]+)\s*원',
    typeKeywords: {
      'expense': ['승인', '결제', '사용'],
      'income': ['취소', '환불'],
    },
    merchantRegex: r'승인\s+(.+?)(?:\s*\d|$)',
    dateRegex: r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})',
    sampleSms: '우리카드 승인 50,000원 스타벅스 01/15 14:30',
  );

  /// 하나카드
  static const hanaCard = FinancialSmsFormat(
    institutionName: '하나카드',
    institutionType: 'card',
    senderPatterns: ['하나카드', '18001111'],
    amountRegex: r'([0-9,]+)\s*원',
    typeKeywords: {
      'expense': ['승인', '결제', '사용'],
      'income': ['취소', '환불'],
    },
    merchantRegex: r'승인\s+(.+?)(?:\s*\d|$)',
    dateRegex: r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})',
    sampleSms: '하나카드 승인 50,000원 스타벅스 01/15 14:30',
  );

  /// BC카드
  static const bcCard = FinancialSmsFormat(
    institutionName: 'BC카드',
    institutionType: 'card',
    senderPatterns: ['BC카드', 'BC', '15884000'],
    amountRegex: r'([0-9,]+)\s*원',
    typeKeywords: {
      'expense': ['승인', '결제', '사용'],
      'income': ['취소', '환불'],
    },
    merchantRegex: r'승인\s+(.+?)(?:\s*\d|$)',
    dateRegex: r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})',
    sampleSms: 'BC카드 승인 50,000원 스타벅스 01/15 14:30',
  );

  /// NH농협카드
  static const nhCard = FinancialSmsFormat(
    institutionName: 'NH농협카드',
    institutionType: 'card',
    senderPatterns: ['NH', '농협카드', 'NH카드', '15442100'],
    amountRegex: r'([0-9,]+)\s*원',
    typeKeywords: {
      'expense': ['승인', '결제', '사용'],
      'income': ['취소', '환불'],
    },
    merchantRegex: r'승인\s+(.+?)(?:\s*\d|$)',
    dateRegex: r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})',
    sampleSms: 'NH농협카드 승인 50,000원 스타벅스 01/15 14:30',
  );

  // ============ 은행 ============

  /// KB국민은행
  static const kbBank = FinancialSmsFormat(
    institutionName: 'KB국민은행',
    institutionType: 'bank',
    senderPatterns: ['KB국민', '국민은행', '15889999'],
    amountRegex: r'([0-9,]+)\s*원',
    typeKeywords: {
      'expense': ['출금', '이체', '자동이체', '송금'],
      'income': ['입금', '급여', '이자'],
    },
    merchantRegex: r'(?:입금|출금)\s+(.+?)(?:\s*잔액|$)',
    dateRegex: r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})',
    sampleSms: 'KB국민은행 출금 50,000원 홍길동 잔액 1,000,000원 01/15 14:30',
  );

  /// 신한은행
  static const shinhanBank = FinancialSmsFormat(
    institutionName: '신한은행',
    institutionType: 'bank',
    senderPatterns: ['신한은행', '신한', '15778000'],
    amountRegex: r'([0-9,]+)\s*원',
    typeKeywords: {
      'expense': ['출금', '이체', '자동이체', '송금'],
      'income': ['입금', '급여', '이자'],
    },
    merchantRegex: r'(?:입금|출금)\s+(.+?)(?:\s*잔액|$)',
    dateRegex: r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})',
    sampleSms: '신한은행 입금 500,000원 급여 잔액 2,000,000원',
  );

  /// 우리은행
  static const wooriBank = FinancialSmsFormat(
    institutionName: '우리은행',
    institutionType: 'bank',
    senderPatterns: ['우리은행', '15889955'],
    amountRegex: r'([0-9,]+)\s*원',
    typeKeywords: {
      'expense': ['출금', '이체', '자동이체', '송금'],
      'income': ['입금', '급여', '이자'],
    },
    merchantRegex: r'(?:입금|출금)\s+(.+?)(?:\s*잔액|$)',
    dateRegex: r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})',
    sampleSms: '우리은행 출금 100,000원 관리비 잔액 500,000원',
  );

  /// 하나은행
  static const hanaBank = FinancialSmsFormat(
    institutionName: '하나은행',
    institutionType: 'bank',
    senderPatterns: ['하나은행', '15991111'],
    amountRegex: r'([0-9,]+)\s*원',
    typeKeywords: {
      'expense': ['출금', '이체', '자동이체', '송금'],
      'income': ['입금', '급여', '이자'],
    },
    merchantRegex: r'(?:입금|출금)\s+(.+?)(?:\s*잔액|$)',
    dateRegex: r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})',
    sampleSms: '하나은행 입금 1,000,000원 급여 잔액 3,000,000원',
  );

  /// NH농협은행
  static const nhBank = FinancialSmsFormat(
    institutionName: 'NH농협은행',
    institutionType: 'bank',
    senderPatterns: ['NH농협', '농협은행', '15881111'],
    amountRegex: r'([0-9,]+)\s*원',
    typeKeywords: {
      'expense': ['출금', '이체', '자동이체', '송금'],
      'income': ['입금', '급여', '이자'],
    },
    merchantRegex: r'(?:입금|출금)\s+(.+?)(?:\s*잔액|$)',
    dateRegex: r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})',
    sampleSms: 'NH농협은행 출금 200,000원 이체 잔액 800,000원',
  );

  /// IBK기업은행
  static const ibkBank = FinancialSmsFormat(
    institutionName: 'IBK기업은행',
    institutionType: 'bank',
    senderPatterns: ['IBK', '기업은행', '15882588'],
    amountRegex: r'([0-9,]+)\s*원',
    typeKeywords: {
      'expense': ['출금', '이체', '자동이체', '송금'],
      'income': ['입금', '급여', '이자'],
    },
    merchantRegex: r'(?:입금|출금)\s+(.+?)(?:\s*잔액|$)',
    dateRegex: r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})',
    sampleSms: 'IBK기업은행 입금 2,000,000원 사업소득 잔액 5,000,000원',
  );

  /// 카카오뱅크
  static const kakaoBank = FinancialSmsFormat(
    institutionName: '카카오뱅크',
    institutionType: 'bank',
    senderPatterns: ['카카오뱅크', '카뱅', '16618100'],
    amountRegex: r'([0-9,]+)\s*원',
    typeKeywords: {
      'expense': ['출금', '이체', '송금', '결제'],
      'income': ['입금', '받았어요', '충전'],
    },
    merchantRegex: r'(?:입금|출금|이체)\s+(.+?)(?:\s*잔액|$)',
    dateRegex: r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})',
    sampleSms: '카카오뱅크 입금 100,000원 홍길동님으로부터',
  );

  /// 토스뱅크
  static const tossBank = FinancialSmsFormat(
    institutionName: '토스뱅크',
    institutionType: 'bank',
    senderPatterns: ['토스', '토스뱅크', 'toss'],
    amountRegex: r'([0-9,]+)\s*원',
    typeKeywords: {
      'expense': ['출금', '이체', '송금', '결제'],
      'income': ['입금', '받았어요', '충전'],
    },
    merchantRegex: r'(?:입금|출금|이체)\s+(.+?)(?:\s*잔액|$)',
    dateRegex: r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})',
    sampleSms: '토스뱅크 50,000원 입금 홍길동',
  );

  /// 케이뱅크
  static const kBank = FinancialSmsFormat(
    institutionName: '케이뱅크',
    institutionType: 'bank',
    senderPatterns: ['케이뱅크', 'K뱅크', '15221700'],
    amountRegex: r'([0-9,]+)\s*원',
    typeKeywords: {
      'expense': ['출금', '이체', '송금', '결제'],
      'income': ['입금', '받았습니다', '충전'],
    },
    merchantRegex: r'(?:입금|출금|이체)\s+(.+?)(?:\s*잔액|$)',
    dateRegex: r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})',
    sampleSms: '케이뱅크 입금 300,000원 급여',
  );

  // ============ 지역화폐 ============

  /// 수원페이 (수원시)
  static const suwonPay = FinancialSmsFormat(
    institutionName: '수원페이',
    institutionType: 'local_currency',
    senderPatterns: ['수원페이', '경기지역화폐', '수원시'],
    amountRegex: r'([0-9,]+)\s*원',
    typeKeywords: {
      'expense': ['결제', '사용', '출금'],
      'income': ['충전', '지급', '환급', '캐시백'],
    },
    merchantRegex: r'결제\s+(.+?)(?:\s*\d|$)',
    dateRegex: r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})',
    sampleSms: '[경기지역화폐] 15,000원 결제 (스타벅스 수원점) 잔액: 35,000원',
  );

  /// 용인와이페이 (용인시)
  static const yonginPay = FinancialSmsFormat(
    institutionName: '용인와이페이',
    institutionType: 'local_currency',
    senderPatterns: ['용인와이페이', '용인페이', '경기지역화폐', '용인시'],
    amountRegex: r'([0-9,]+)\s*원',
    typeKeywords: {
      'expense': ['결제', '사용', '출금'],
      'income': ['충전', '지급', '환급', '캐시백'],
    },
    merchantRegex: r'결제\s+(.+?)(?:\s*\d|$)',
    dateRegex: r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})',
    sampleSms: '[용인와이페이] 15,000원 결제 (스타벅스 용인점) 잔액: 35,000원',
  );

  /// 행복화성지역화폐 (화성시)
  static const hwaseongPay = FinancialSmsFormat(
    institutionName: '행복화성지역화폐',
    institutionType: 'local_currency',
    senderPatterns: ['행복화성', '화성페이', '경기지역화폐', '화성시'],
    amountRegex: r'([0-9,]+)\s*원',
    typeKeywords: {
      'expense': ['결제', '사용', '출금'],
      'income': ['충전', '지급', '환급', '캐시백'],
    },
    merchantRegex: r'결제\s+(.+?)(?:\s*\d|$)',
    dateRegex: r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})',
    sampleSms: '[행복화성지역화폐] 15,000원 결제 (스타벅스 화성점) 잔액: 35,000원',
  );

  /// 고양페이 (고양시)
  static const goyangPay = FinancialSmsFormat(
    institutionName: '고양페이',
    institutionType: 'local_currency',
    senderPatterns: ['고양페이', '경기지역화폐', '고양시'],
    amountRegex: r'([0-9,]+)\s*원',
    typeKeywords: {
      'expense': ['결제', '사용', '출금'],
      'income': ['충전', '지급', '환급', '캐시백'],
    },
    merchantRegex: r'결제\s+(.+?)(?:\s*\d|$)',
    dateRegex: r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})',
    sampleSms: '[고양페이] 15,000원 결제 (스타벅스 고양점) 잔액: 35,000원',
  );

  /// 부천페이 (부천시)
  static const bucheonPay = FinancialSmsFormat(
    institutionName: '부천페이',
    institutionType: 'local_currency',
    senderPatterns: ['부천페이', '경기지역화폐', '부천시'],
    amountRegex: r'([0-9,]+)\s*원',
    typeKeywords: {
      'expense': ['결제', '사용', '출금'],
      'income': ['충전', '지급', '환급', '캐시백'],
    },
    merchantRegex: r'결제\s+(.+?)(?:\s*\d|$)',
    dateRegex: r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})',
    sampleSms: '[부천페이] 15,000원 결제 (스타벅스 부천점) 잔액: 35,000원',
  );

  /// 서울사랑상품권
  static const seoulPay = FinancialSmsFormat(
    institutionName: '서울사랑상품권',
    institutionType: 'local_currency',
    senderPatterns: ['서울사랑', '서울상품권', '서울페이', '제로페이'],
    amountRegex: r'([0-9,]+)\s*원',
    typeKeywords: {
      'expense': ['결제', '사용', '출금'],
      'income': ['충전', '지급', '환급', '캐시백'],
    },
    merchantRegex: r'결제\s+(.+?)(?:\s*\d|$)',
    dateRegex: r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})',
    sampleSms: '서울사랑상품권 결제 20,000원 편의점 잔액 80,000원',
  );

  /// 인천이음페이
  static const incheonPay = FinancialSmsFormat(
    institutionName: '인천이음페이',
    institutionType: 'local_currency',
    senderPatterns: ['인천이음', '이음페이', '인천페이'],
    amountRegex: r'([0-9,]+)\s*원',
    typeKeywords: {
      'expense': ['결제', '사용', '출금'],
      'income': ['충전', '지급', '환급', '캐시백'],
    },
    merchantRegex: r'결제\s+(.+?)(?:\s*\d|$)',
    dateRegex: r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})',
    sampleSms: '인천이음페이 결제 15,000원 음식점 잔액 35,000원',
  );

  /// 금융사 이름으로 패턴 찾기
  static FinancialSmsFormat? findByName(String name) {
    return allPatterns.cast<FinancialSmsFormat?>().firstWhere(
      (p) => p?.institutionName == name,
      orElse: () => null,
    );
  }

  /// 발신자 패턴으로 금융사 찾기
  static FinancialSmsFormat? findBySender(String sender) {
    final lowerSender = sender.toLowerCase();
    for (final pattern in allPatterns) {
      for (final senderPattern in pattern.senderPatterns) {
        if (lowerSender.contains(senderPattern.toLowerCase())) {
          return pattern;
        }
      }
    }
    return null;
  }

  /// 금융사 타입별 필터링
  static List<FinancialSmsFormat> getByType(String type) {
    return allPatterns.where((p) => p.institutionType == type).toList();
  }

  /// 카드사 목록
  static List<FinancialSmsFormat> get cardPatterns => getByType('card');

  /// 은행 목록
  static List<FinancialSmsFormat> get bankPatterns => getByType('bank');

  /// 지역화폐 목록
  static List<FinancialSmsFormat> get localCurrencyPatterns =>
      getByType('local_currency');
}
