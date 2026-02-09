import 'package:equatable/equatable.dart';

enum FinancialServiceCategory {
  card,
  localCurrency,
  manual, // 직접 입력
}

class FinancialServiceTemplate extends Equatable {
  final String id;
  final String name;
  final String logoIcon;
  final String color;
  final String defaultSampleSms;
  final String? defaultSamplePush; // Push 알림 샘플 (null이면 SMS와 동일하거나 미지원)
  final List<String> defaultKeywords;
  final FinancialServiceCategory category;

  const FinancialServiceTemplate({
    required this.id,
    required this.name,
    required this.logoIcon,
    required this.color,
    required this.defaultSampleSms,
    this.defaultSamplePush,
    required this.defaultKeywords,
    required this.category,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    logoIcon,
    color,
    defaultSampleSms,
    defaultSamplePush,
    defaultKeywords,
    category,
  ];

  // 프리셋 데이터 - 카드사 9개 + 지역화폐 3개
  static const List<FinancialServiceTemplate> templates = [
    // === 카드사 (9개) ===
    FinancialServiceTemplate(
      id: 'kb_card',
      name: 'KB국민카드',
      logoIcon: 'assets/logos/kb_card.png',
      color: '#FFBC00',
      category: FinancialServiceCategory.card,
      defaultSampleSms:
          '[KB국민] 홍길동님(1*2*)\n15,000원 승인 일시불\n01/21 13:30\n(누적 50,000원)\n스타벅스 강남점',
      defaultSamplePush:
          'KB국민카드\n홍길동님(1*2*) 15,000원 승인 일시불 01/21 13:30 (누적 50,000원) 스타벅스 강남점',
      defaultKeywords: ['KB국민', '국민카드', 'KB카드'],
    ),
    FinancialServiceTemplate(
      id: 'shinhan_card',
      name: '신한카드',
      logoIcon: 'assets/logos/shinhan_card.png',
      color: '#0046FF',
      category: FinancialServiceCategory.card,
      defaultSampleSms:
          '[신한카드] 홍길동님\n15,000원 승인\n신한(1*2*) 일시불\n01/21 13:30\n스타벅스',
      defaultSamplePush: '신한카드 승인\n홍길동님 15,000원 일시불\n스타벅스',
      defaultKeywords: ['신한카드', '신한'],
    ),
    FinancialServiceTemplate(
      id: 'samsung_card',
      name: '삼성카드',
      logoIcon: 'assets/logos/samsung_card.png',
      color: '#1428A0',
      category: FinancialServiceCategory.card,
      defaultSampleSms:
          '[삼성카드] 홍길동님\n15,000원 승인\n삼성(1*2*)\n01/21 13:30 일시불\n스타벅스',
      defaultSamplePush: '삼성카드 승인\n15,000원 일시불\n스타벅스',
      defaultKeywords: ['삼성카드'],
    ),
    FinancialServiceTemplate(
      id: 'hyundai_card',
      name: '현대카드',
      logoIcon: 'assets/logos/hyundai_card.png',
      color: '#000000',
      category: FinancialServiceCategory.card,
      defaultSampleSms:
          '[현대카드] 홍길동님\n15,000원 승인\n현대(1*2*)\n01/21 13:30 일시불\n스타벅스',
      defaultSamplePush: '현대카드 승인\n15,000원 일시불\n스타벅스',
      defaultKeywords: ['현대카드'],
    ),
    FinancialServiceTemplate(
      id: 'lotte_card',
      name: '롯데카드',
      logoIcon: 'assets/logos/lotte_card.png',
      color: '#ED1C24',
      category: FinancialServiceCategory.card,
      defaultSampleSms:
          '[롯데카드] 홍길동님\n15,000원 승인\n롯데(1*2*)\n01/21 13:30 일시불\n스타벅스',
      defaultSamplePush: '롯데카드 승인\n15,000원 일시불\n스타벅스',
      defaultKeywords: ['롯데카드'],
    ),
    FinancialServiceTemplate(
      id: 'woori_card',
      name: '우리카드',
      logoIcon: 'assets/logos/woori_card.png',
      color: '#0056A4',
      category: FinancialServiceCategory.card,
      defaultSampleSms:
          '[우리카드] 홍길동님\n15,000원 승인\n우리(1*2*)\n01/21 13:30 일시불\n스타벅스',
      defaultSamplePush: '우리카드 승인\n15,000원 일시불\n스타벅스',
      defaultKeywords: ['우리카드'],
    ),
    FinancialServiceTemplate(
      id: 'hana_card',
      name: '하나카드',
      logoIcon: 'assets/logos/hana_card.png',
      color: '#009775',
      category: FinancialServiceCategory.card,
      defaultSampleSms:
          '[하나카드] 홍길동님\n15,000원 승인\n하나(1*2*)\n01/21 13:30 일시불\n스타벅스',
      defaultSamplePush: '하나카드 승인\n15,000원 일시불\n스타벅스',
      defaultKeywords: ['하나카드'],
    ),
    FinancialServiceTemplate(
      id: 'bc_card',
      name: 'BC카드',
      logoIcon: 'assets/logos/bc_card.png',
      color: '#F37321',
      category: FinancialServiceCategory.card,
      defaultSampleSms:
          '[BC카드] 홍길동님\n15,000원 승인\nBC(1*2*)\n01/21 13:30 일시불\n스타벅스',
      defaultSamplePush: 'BC카드 승인\n15,000원 일시불\n스타벅스',
      defaultKeywords: ['BC카드', 'BC'],
    ),
    FinancialServiceTemplate(
      id: 'nh_card',
      name: 'NH농협카드',
      logoIcon: 'assets/logos/nh_card.png',
      color: '#009A3E',
      category: FinancialServiceCategory.card,
      defaultSampleSms:
          '[NH농협카드] 홍길동님 15,000원 승인\n농협BC(1*2*)\n01/21 13:30 일시불\n스타벅스',
      defaultSamplePush: 'NH농협카드 승인\n홍길동님 15,000원 정상처리 완료\n스타벅스',
      defaultKeywords: ['NH농협카드', '농협카드', 'NH농협'],
    ),

    // === 지역화폐 (7개) ===
    // 경기도 지역화폐 (개별 시/군)
    FinancialServiceTemplate(
      id: 'suwon_pay',
      name: '수원페이',
      logoIcon: 'assets/logos/suwon_pay.png',
      color: '#1B5E20',
      category: FinancialServiceCategory.localCurrency,
      defaultSampleSms: '[경기지역화폐] 15,000원 결제\n(스타벅스 수원점)\n잔액: 35,000원',
      defaultSamplePush:
          '경기지역화폐 결제알림\n15,000원 결제 완료\n가맹점: 스타벅스 수원점\n잔액: 35,000원',
      defaultKeywords: ['수원페이', '경기지역화폐', '수원시'],
    ),
    FinancialServiceTemplate(
      id: 'yongin_pay',
      name: '용인와이페이',
      logoIcon: 'assets/logos/yongin_pay.png',
      color: '#4CAF50',
      category: FinancialServiceCategory.localCurrency,
      defaultSampleSms: '[경기지역화폐] 15,000원 결제\n(스타벅스 용인점)\n잔액: 35,000원',
      defaultSamplePush:
          '경기지역화폐 결제알림\n15,000원 결제 완료\n가맹점: 스타벅스 용인점\n잔액: 35,000원',
      defaultKeywords: ['용인와이페이', '용인페이', '경기지역화폐', '용인시'],
    ),
    FinancialServiceTemplate(
      id: 'hwaseong_pay',
      name: '행복화성지역화폐',
      logoIcon: 'assets/logos/hwaseong_pay.png',
      color: '#388E3C',
      category: FinancialServiceCategory.localCurrency,
      defaultSampleSms: '[경기지역화폐] 15,000원 결제\n(스타벅스 화성점)\n잔액: 35,000원',
      defaultSamplePush:
          '경기지역화폐 결제알림\n15,000원 결제 완료\n가맹점: 스타벅스 화성점\n잔액: 35,000원',
      defaultKeywords: ['행복화성', '화성페이', '경기지역화폐', '화성시'],
    ),
    FinancialServiceTemplate(
      id: 'goyang_pay',
      name: '고양페이',
      logoIcon: 'assets/logos/goyang_pay.png',
      color: '#2E7D32',
      category: FinancialServiceCategory.localCurrency,
      defaultSampleSms: '[경기지역화폐] 15,000원 결제\n(스타벅스 고양점)\n잔액: 35,000원',
      defaultSamplePush:
          '경기지역화폐 결제알림\n15,000원 결제 완료\n가맹점: 스타벅스 고양점\n잔액: 35,000원',
      defaultKeywords: ['고양페이', '경기지역화폐', '고양시'],
    ),
    FinancialServiceTemplate(
      id: 'bucheon_pay',
      name: '부천페이',
      logoIcon: 'assets/logos/bucheon_pay.png',
      color: '#43A047',
      category: FinancialServiceCategory.localCurrency,
      defaultSampleSms: '[경기지역화폐] 15,000원 결제\n(스타벅스 부천점)\n잔액: 35,000원',
      defaultSamplePush:
          '경기지역화폐 결제알림\n15,000원 결제 완료\n가맹점: 스타벅스 부천점\n잔액: 35,000원',
      defaultKeywords: ['부천페이', '경기지역화폐', '부천시'],
    ),
    FinancialServiceTemplate(
      id: 'seoul_love',
      name: '서울사랑상품권',
      logoIcon: 'assets/logos/seoul_love.png',
      color: '#7B1FA2',
      category: FinancialServiceCategory.localCurrency,
      defaultSampleSms: '[서울사랑상품권] 15,000원 결제\n스타벅스 서울점\n잔액: 35,000원',
      defaultSamplePush: '서울사랑상품권 결제\n15,000원 결제 완료\n가맹점: 스타벅스\n잔액: 35,000원',
      defaultKeywords: ['서울사랑', '서울상품권', '서울페이'],
    ),
    FinancialServiceTemplate(
      id: 'incheon_eum',
      name: '인천이음페이',
      logoIcon: 'assets/logos/incheon_eum.png',
      color: '#00838F',
      category: FinancialServiceCategory.localCurrency,
      defaultSampleSms: '[인천이음] 15,000원 결제\n스타벅스 인천점\n잔액: 35,000원',
      defaultSamplePush: '인천이음페이 결제\n15,000원 결제 완료\n가맹점: 스타벅스\n잔액: 35,000원',
      defaultKeywords: ['인천이음', '이음페이'],
    ),
  ];
}
