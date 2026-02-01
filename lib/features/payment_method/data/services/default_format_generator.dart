/// 결제수단 이름을 기반으로 기본 SMS/Push 감지 포맷을 생성하는 서비스
///
/// 자동수집 결제수단 생성 시 템플릿이 없어도 결제수단 이름 기반으로
/// 기본 감지 키워드를 자동 생성합니다.
class DefaultFormatGenerator {
  DefaultFormatGenerator._();

  /// 금융사별 확장 키워드 매핑
  /// 결제수단 이름에 해당 키가 포함되면 확장 키워드를 추가
  static const Map<String, _FinancialServiceInfo> _financialServices = {
    // 카드사
    'KB국민': _FinancialServiceInfo(
      smsKeywords: ['KB국민', 'KB Pay', '국민카드', 'KB카드'],
      pushKeywords: ['KB국민', 'KB Pay', '국민카드', 'KB카드'],
      pushPackage: 'com.kbcard.cxh.appcard',
      smsSenderPattern: 'KB국민',
    ),
    '신한': _FinancialServiceInfo(
      smsKeywords: ['신한카드', '신한', 'SOL페이'],
      pushKeywords: ['신한카드', '신한', 'SOL페이'],
      pushPackage: 'com.shcard.smartpay',
      smsSenderPattern: '신한',
    ),
    '삼성': _FinancialServiceInfo(
      smsKeywords: ['삼성카드', '삼성'],
      pushKeywords: ['삼성카드', '삼성'],
      pushPackage: 'kr.co.samsungcard.mpocket',
      smsSenderPattern: '삼성카드',
    ),
    '현대': _FinancialServiceInfo(
      smsKeywords: ['현대카드', '현대'],
      pushKeywords: ['현대카드', '현대'],
      pushPackage: 'com.hyundaicard.appcard',
      smsSenderPattern: '현대카드',
    ),
    '롯데': _FinancialServiceInfo(
      smsKeywords: ['롯데카드', '롯데', '디지로카'],
      pushKeywords: ['롯데카드', '롯데', '디지로카'],
      pushPackage: 'com.lcacApp',
      smsSenderPattern: '롯데카드',
    ),
    '하나': _FinancialServiceInfo(
      smsKeywords: ['하나카드', '하나'],
      pushKeywords: ['하나카드', '하나'],
      pushPackage: 'com.hanaskcard.paycla',
      smsSenderPattern: '하나카드',
    ),
    '우리': _FinancialServiceInfo(
      smsKeywords: ['우리카드', '우리'],
      pushKeywords: ['우리카드', '우리'],
      pushPackage: 'com.wooricard.smartapp',
      smsSenderPattern: '우리카드',
    ),
    'NH': _FinancialServiceInfo(
      smsKeywords: ['NH카드', 'NH', '농협카드', 'NH농협카드', 'NH올원페이'],
      pushKeywords: ['NH카드', 'NH', '농협카드', 'NH농협카드', 'NH올원페이'],
      pushPackage: 'nh.smart.nhallonepay',
      smsSenderPattern: 'NH',
    ),
    'BC': _FinancialServiceInfo(
      smsKeywords: ['BC카드', 'BC', '페이북', 'ISP'],
      pushKeywords: ['BC카드', 'BC', '페이북', 'ISP'],
      pushPackage: 'kvp.jjy.MispAndroid320',
      smsSenderPattern: 'BC카드',
    ),

    // 지역화폐 - 경기도 (경기지역화폐 앱으로 통합)
    '수원페이': _FinancialServiceInfo(
      smsKeywords: ['수원페이', '경기지역화폐', '수원시', '수원이'],
      pushKeywords: ['수원페이', '경기지역화폐', '수원시', '수원이'],
      pushPackage: 'gov.gyeonggi.ggcard',
      smsSenderPattern: '경기지역화폐',
    ),
    '용인와이페이': _FinancialServiceInfo(
      smsKeywords: ['용인와이페이', '용인페이', '경기지역화폐', '용인시'],
      pushKeywords: ['용인와이페이', '용인페이', '경기지역화폐', '용인시'],
      pushPackage: 'gov.gyeonggi.ggcard',
      smsSenderPattern: '경기지역화폐',
    ),
    '행복화성': _FinancialServiceInfo(
      smsKeywords: ['행복화성', '화성페이', '경기지역화폐', '화성시'],
      pushKeywords: ['행복화성', '화성페이', '경기지역화폐', '화성시'],
      pushPackage: 'gov.gyeonggi.ggcard',
      smsSenderPattern: '경기지역화폐',
    ),
    '고양페이': _FinancialServiceInfo(
      smsKeywords: ['고양페이', '경기지역화폐', '고양시'],
      pushKeywords: ['고양페이', '경기지역화폐', '고양시'],
      pushPackage: 'gov.gyeonggi.ggcard',
      smsSenderPattern: '경기지역화폐',
    ),
    '부천페이': _FinancialServiceInfo(
      smsKeywords: ['부천페이', '경기지역화폐', '부천시'],
      pushKeywords: ['부천페이', '경기지역화폐', '부천시'],
      pushPackage: 'gov.gyeonggi.ggcard',
      smsSenderPattern: '경기지역화폐',
    ),
    '경기지역화폐': _FinancialServiceInfo(
      smsKeywords: ['경기지역화폐'],
      pushKeywords: ['경기지역화폐'],
      pushPackage: 'gov.gyeonggi.ggcard',
      smsSenderPattern: '경기지역화폐',
    ),

    // 지역화폐 - 서울
    '서울사랑': _FinancialServiceInfo(
      smsKeywords: ['서울사랑', '서울페이', '서울상품권', '서울페이+'],
      pushKeywords: ['서울사랑', '서울페이', '서울상품권', '서울페이+', 'Seoul Pay'],
      pushPackage: 'com.bizplay.seoul.pay',
      smsSenderPattern: '서울페이',
    ),
    '서울페이': _FinancialServiceInfo(
      smsKeywords: ['서울페이', '서울사랑', '서울상품권', '서울페이+'],
      pushKeywords: ['서울페이', '서울사랑', '서울상품권', '서울페이+', 'Seoul Pay'],
      pushPackage: 'com.bizplay.seoul.pay',
      smsSenderPattern: '서울페이',
    ),

    // 지역화폐 - 인천
    '인천이음': _FinancialServiceInfo(
      smsKeywords: ['인천이음', '이음페이', '인천e음'],
      pushKeywords: ['인천이음', '이음페이', '인천e음'],
      pushPackage: 'gov.incheon.incheonercard',
      smsSenderPattern: '인천이음',
    ),

    // 간편결제
    '카카오페이': _FinancialServiceInfo(
      smsKeywords: ['카카오페이', '카카오'],
      pushKeywords: ['카카오페이', '카카오'],
      pushPackage: 'com.kakaopay.app',
      smsSenderPattern: '카카오페이',
    ),
    '네이버페이': _FinancialServiceInfo(
      smsKeywords: ['네이버페이', '네이버'],
      pushKeywords: ['네이버페이', '네이버'],
      pushPackage: 'com.navercorp.android.npay',
      smsSenderPattern: '네이버페이',
    ),
    '토스': _FinancialServiceInfo(
      smsKeywords: ['토스', 'toss'],
      pushKeywords: ['토스', 'toss'],
      pushPackage: 'viva.republica.toss',
      smsSenderPattern: '토스',
    ),
    '페이코': _FinancialServiceInfo(
      smsKeywords: ['페이코', 'PAYCO'],
      pushKeywords: ['페이코', 'PAYCO'],
      pushPackage: 'com.nhnent.payapp',
      smsSenderPattern: '페이코',
    ),
  };

  /// 결제수단 이름을 기반으로 SMS 포맷 정보 생성
  static SmsFormatInfo generateSmsFormat(String paymentMethodName) {
    final info = _findMatchingService(paymentMethodName);

    if (info != null) {
      return SmsFormatInfo(
        senderPattern: info.smsSenderPattern,
        senderKeywords: info.smsKeywords,
      );
    }

    // 매칭되는 금융사가 없으면 결제수단 이름을 기본 키워드로 사용
    return SmsFormatInfo(
      senderPattern: paymentMethodName,
      senderKeywords: [paymentMethodName],
    );
  }

  /// 결제수단 이름을 기반으로 Push 포맷 정보 생성
  static PushFormatInfo generatePushFormat(String paymentMethodName) {
    final info = _findMatchingService(paymentMethodName);

    if (info != null) {
      return PushFormatInfo(
        packageName: info.pushPackage,
        appKeywords: info.pushKeywords,
      );
    }

    // 매칭되는 금융사가 없으면 결제수단 이름을 기본 키워드로 사용
    return PushFormatInfo(
      packageName: paymentMethodName,
      appKeywords: [paymentMethodName],
    );
  }

  /// 결제수단 이름과 매칭되는 금융사 정보 찾기
  static _FinancialServiceInfo? _findMatchingService(String paymentMethodName) {
    for (final entry in _financialServices.entries) {
      if (paymentMethodName.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }
}

/// 금융사 정보 내부 클래스
class _FinancialServiceInfo {
  final List<String> smsKeywords;
  final List<String> pushKeywords;
  final String pushPackage;
  final String smsSenderPattern;

  const _FinancialServiceInfo({
    required this.smsKeywords,
    required this.pushKeywords,
    required this.pushPackage,
    required this.smsSenderPattern,
  });
}

/// SMS 포맷 생성 결과
class SmsFormatInfo {
  final String senderPattern;
  final List<String> senderKeywords;

  const SmsFormatInfo({
    required this.senderPattern,
    required this.senderKeywords,
  });
}

/// Push 포맷 생성 결과
class PushFormatInfo {
  final String packageName;
  final List<String> appKeywords;

  const PushFormatInfo({required this.packageName, required this.appKeywords});
}
