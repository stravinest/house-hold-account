class FinancialConstants {
  FinancialConstants._();

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

  static const List<String> incomeKeywords = [
    '입금',
    '받으셨습니다',
    '지급되었습니다',
    '충전',
    '환급',
    '환불',
  ];

  static const List<String> cancelKeywords = ['취소', '승인취소', '결제취소'];

  static const Map<String, List<String>> defaultTypeKeywords = {
    'expense': ['출금', '결제', '승인', '이체', '사용', '지급', '체크', '일시불', '할부'],
    'income': ['입금', '충전', '환불', '환급'],
  };
}
