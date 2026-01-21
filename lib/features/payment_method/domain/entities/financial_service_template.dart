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

  // 프리셋 데이터
  static const List<FinancialServiceTemplate> templates = [
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
      id: 'nh_card',
      name: 'NH농협카드',
      logoIcon: 'assets/logos/nh_card.png',
      color: '#00A852',
      category: FinancialServiceCategory.card,
      defaultSampleSms:
          '[NH농협카드] 홍길동님 15,000원 승인\n농협BC(1*2*)\n01/21 13:30 일시불\n스타벅스',
      defaultSamplePush: 'NH농협카드 승인\n홍길동님 15,000원 정상처리 완료\n스타벅스',
      defaultKeywords: ['NH농협카드', '농협카드', 'NH농협'],
    ),
    FinancialServiceTemplate(
      id: 'gyeonggi_local',
      name: '경기지역화폐',
      logoIcon: 'assets/logos/gyeonggi.png',
      color: '#003764',
      category: FinancialServiceCategory.localCurrency,
      defaultSampleSms: '[경기지역화폐] 15,000원 결제\n(스타벅스 경기점)\n잔액: 35,000원',
      defaultSamplePush:
          '경기지역화폐 결제알림\n15,000원 결제 완료\n가맹점: 스타벅스 경기점\n잔액: 35,000원',
      defaultKeywords: ['경기지역화폐', '경기지역', '지역화폐'],
    ),
  ];
}
