import { describe, it, expect } from 'vitest';
import {
  parseDateString,
  parseAmountString,
  parseTransactionType,
  autoMapColumns,
  mapRowsToPreview,
  findHeaderRowIndex,
} from '@/lib/utils/excel';
import type { ColumnMapping } from '@/lib/types/excel';

describe('parseDateString - 다양한 날짜 형식 파싱 테스트', () => {
  it('YYYY-MM-DD 형식을 정상적으로 파싱해야 한다', () => {
    expect(parseDateString('2024-01-15')).toBe('2024-01-15');
  });

  it('YYYY/MM/DD 형식을 하이픈 형식으로 변환해야 한다', () => {
    expect(parseDateString('2024/01/15')).toBe('2024-01-15');
  });

  it('YYYYMMDD 형식을 정상적으로 파싱해야 한다', () => {
    expect(parseDateString('20240115')).toBe('2024-01-15');
  });

  it('MM/DD/YYYY 형식을 정상적으로 파싱해야 한다', () => {
    expect(parseDateString('01/15/2024')).toBe('2024-01-15');
  });

  it('빈 문자열은 null을 반환해야 한다', () => {
    expect(parseDateString('')).toBeNull();
  });

  it('인식할 수 없는 형식은 null을 반환해야 한다', () => {
    expect(parseDateString('abc')).toBeNull();
    expect(parseDateString('2024년1월15일')).toBeNull();
  });

  it('앞뒤 공백이 있어도 정상적으로 파싱해야 한다', () => {
    expect(parseDateString('  2024-01-15  ')).toBe('2024-01-15');
  });

  it('Excel 시리얼 날짜 숫자를 파싱해야 한다', () => {
    // 45306 = 2024-01-15 in Excel serial date
    const result = parseDateString('45306');
    expect(result).toBe('2024-01-15');
  });
});

describe('parseAmountString - 금액 문자열 파싱 테스트', () => {
  it('정수 문자열을 정상적으로 파싱해야 한다', () => {
    expect(parseAmountString('10000')).toBe(10000);
  });

  it('콤마가 포함된 금액을 파싱해야 한다', () => {
    expect(parseAmountString('10,000')).toBe(10000);
  });

  it('"원" 단위가 포함된 금액을 파싱해야 한다', () => {
    expect(parseAmountString('10,000원')).toBe(10000);
  });

  it('음수 금액은 절대값으로 변환해야 한다', () => {
    expect(parseAmountString('-5000')).toBe(5000);
  });

  it('0은 null을 반환해야 한다 (유효하지 않은 금액)', () => {
    expect(parseAmountString('0')).toBeNull();
  });

  it('빈 문자열은 null을 반환해야 한다', () => {
    expect(parseAmountString('')).toBeNull();
  });

  it('숫자가 아닌 문자열은 null을 반환해야 한다', () => {
    expect(parseAmountString('abc')).toBeNull();
  });

  it('통화 기호(₩)가 포함되어도 파싱해야 한다', () => {
    expect(parseAmountString('₩50,000')).toBe(50000);
  });
});

describe('parseTransactionType - 거래 유형 파싱 테스트', () => {
  it('"지출"을 expense로 파싱해야 한다', () => {
    expect(parseTransactionType('지출')).toBe('expense');
  });

  it('"expense"를 expense로 파싱해야 한다', () => {
    expect(parseTransactionType('expense')).toBe('expense');
  });

  it('"수입"을 income으로 파싱해야 한다', () => {
    expect(parseTransactionType('수입')).toBe('income');
  });

  it('"income"을 income으로 파싱해야 한다', () => {
    expect(parseTransactionType('income')).toBe('income');
  });

  it('"자산"을 asset으로 파싱해야 한다', () => {
    expect(parseTransactionType('자산')).toBe('asset');
  });

  it('대소문자를 구분하지 않아야 한다', () => {
    expect(parseTransactionType('EXPENSE')).toBe('expense');
    expect(parseTransactionType('Income')).toBe('income');
  });

  it('앞뒤 공백이 있어도 정상 파싱해야 한다', () => {
    expect(parseTransactionType('  지출  ')).toBe('expense');
  });

  it('알 수 없는 값은 null을 반환해야 한다', () => {
    expect(parseTransactionType('unknown')).toBeNull();
    expect(parseTransactionType('')).toBeNull();
  });

  it('"입금", "출금", "결제" 등 동의어도 파싱해야 한다', () => {
    expect(parseTransactionType('입금')).toBe('income');
    expect(parseTransactionType('출금')).toBe('expense');
    expect(parseTransactionType('결제')).toBe('expense');
  });
});

describe('autoMapColumns - 자동 컬럼 매핑 테스트', () => {
  it('한글 헤더를 정상적으로 매핑해야 한다', () => {
    const headers = ['날짜', '유형', '금액', '제목', '카테고리', '결제수단', '메모'];
    const mapping = autoMapColumns(headers);
    expect(mapping.date).toBe(0);
    expect(mapping.type).toBe(1);
    expect(mapping.amount).toBe(2);
    expect(mapping.description).toBe(3);
    expect(mapping.category).toBe(4);
    expect(mapping.paymentMethod).toBe(5);
    expect(mapping.memo).toBe(6);
  });

  it('영문 헤더를 정상적으로 매핑해야 한다', () => {
    const headers = ['date', 'type', 'amount', 'description', 'category', 'payment', 'memo'];
    const mapping = autoMapColumns(headers);
    expect(mapping.date).toBe(0);
    expect(mapping.type).toBe(1);
    expect(mapping.amount).toBe(2);
    expect(mapping.description).toBe(3);
    expect(mapping.category).toBe(4);
    expect(mapping.paymentMethod).toBe(5);
    expect(mapping.memo).toBe(6);
  });

  it('동의어 헤더도 매핑해야 한다 (거래일, 적요, 비고 등)', () => {
    const headers = ['거래일', '구분', '거래금액', '적요', '분류', '카드', '비고'];
    const mapping = autoMapColumns(headers);
    expect(mapping.date).toBe(0);
    expect(mapping.type).toBe(1);
    expect(mapping.amount).toBe(2);
    expect(mapping.description).toBe(3);
    expect(mapping.category).toBe(4);
    expect(mapping.paymentMethod).toBe(5);
    expect(mapping.memo).toBe(6);
  });

  it('매핑할 수 없는 헤더는 null로 유지해야 한다', () => {
    const headers = ['날짜', '금액', '제목'];
    const mapping = autoMapColumns(headers);
    expect(mapping.date).toBe(0);
    expect(mapping.amount).toBe(1);
    expect(mapping.description).toBe(2);
    expect(mapping.type).toBeNull();
    expect(mapping.category).toBeNull();
    expect(mapping.paymentMethod).toBeNull();
    expect(mapping.memo).toBeNull();
  });

  it('빈 헤더 배열에 대해 모두 null을 반환해야 한다', () => {
    const mapping = autoMapColumns([]);
    expect(mapping.date).toBeNull();
    expect(mapping.type).toBeNull();
    expect(mapping.amount).toBeNull();
    expect(mapping.description).toBeNull();
  });
});

describe('mapRowsToPreview - 미리보기 행 변환 테스트', () => {
  const fullMapping: ColumnMapping = {
    date: 0,
    type: 1,
    amount: 2,
    description: 3,
    category: 4,
    paymentMethod: 5,
    memo: 6,
  };

  it('정상 데이터를 미리보기 행으로 변환해야 한다', () => {
    const rows = [['2024-01-15', '지출', '15000', '점심 식사', '식비', '신한카드', '회사 근처']];
    const result = mapRowsToPreview(rows, fullMapping);
    expect(result).toHaveLength(1);
    expect(result[0].date).toBe('2024-01-15');
    expect(result[0].type).toBe('expense');
    expect(result[0].amount).toBe(15000);
    expect(result[0].description).toBe('점심 식사');
    expect(result[0].category).toBe('식비');
    expect(result[0].paymentMethod).toBe('신한카드');
    expect(result[0].memo).toBe('회사 근처');
    expect(result[0].error).toBeUndefined();
  });

  it('날짜 형식이 잘못된 행은 에러를 포함해야 한다', () => {
    const rows = [['잘못된날짜', '지출', '15000', '점심']];
    const result = mapRowsToPreview(rows, fullMapping);
    expect(result[0].error).toContain('날짜 형식 오류');
  });

  it('금액이 없는 행은 에러를 포함해야 한다', () => {
    const rows = [['2024-01-15', '지출', '', '점심']];
    const result = mapRowsToPreview(rows, fullMapping);
    expect(result[0].error).toContain('금액 형식 오류');
  });

  it('제목이 없는 행은 에러를 포함해야 한다', () => {
    const rows = [['2024-01-15', '지출', '15000', '']];
    const result = mapRowsToPreview(rows, fullMapping);
    expect(result[0].error).toContain('제목 없음');
  });

  it('유형이 잘못된 행은 에러를 포함하지만 기본값 expense로 설정해야 한다', () => {
    const rows = [['2024-01-15', 'unknown', '15000', '점심']];
    const result = mapRowsToPreview(rows, fullMapping);
    expect(result[0].error).toContain('유형 형식 오류');
    expect(result[0].type).toBe('expense');
  });

  it('여러 에러가 있으면 콤마로 구분하여 표시해야 한다', () => {
    const rows = [['잘못된날짜', '', '', '']];
    const result = mapRowsToPreview(rows, fullMapping);
    expect(result[0].error).toContain('날짜 형식 오류');
    expect(result[0].error).toContain('금액 형식 오류');
    expect(result[0].error).toContain('제목 없음');
  });

  it('rowIndex는 Excel 행 번호(2부터 시작)에 맞아야 한다', () => {
    const rows = [
      ['2024-01-15', '지출', '15000', '점심'],
      ['2024-01-16', '수입', '3000000', '급여'],
    ];
    const result = mapRowsToPreview(rows, fullMapping);
    expect(result[0].rowIndex).toBe(2);
    expect(result[1].rowIndex).toBe(3);
  });

  it('선택 필드(카테고리, 결제수단, 메모)가 매핑되지 않은 경우 undefined여야 한다', () => {
    const minMapping: ColumnMapping = {
      date: 0, type: 1, amount: 2, description: 3,
      category: null, paymentMethod: null, memo: null,
    };
    const rows = [['2024-01-15', '지출', '15000', '점심']];
    const result = mapRowsToPreview(rows, minMapping);
    expect(result[0].category).toBeUndefined();
    expect(result[0].paymentMethod).toBeUndefined();
    expect(result[0].memo).toBeUndefined();
  });
});

describe('findHeaderRowIndex - 안내 문구가 포함된 파일에서 헤더 행 자동 감지 테스트', () => {
  it('안내 문구 없이 첫 번째 행이 헤더인 경우 0을 반환해야 한다', () => {
    const rows = [
      ['날짜', '유형', '금액', '제목'],
      ['2024-01-15', '지출', '15000', '점심'],
    ];
    expect(findHeaderRowIndex(rows)).toBe(0);
  });

  it('샘플 파일처럼 상단에 안내 문구가 있으면 실제 헤더 행 인덱스를 반환해야 한다', () => {
    const rows = [
      ['[ 가져오기 입력 안내 ]', '', '', ''],
      [],
      ['* 필수 컬럼', '', '', ''],
      ['  날짜 (필수)', '지원 형식: 2024-01-15', '', ''],
      ['  유형 (필수)', '지출, 수입, 자산', '', ''],
      ['  금액 (필수)', '숫자만 입력', '', ''],
      ['  제목 (필수)', '거래 내용', '', ''],
      [],
      ['날짜', '유형', '금액', '제목', '카테고리', '결제수단', '메모'],
      ['2024-01-15', '지출', '15000', '점심', '식비', '신한카드', ''],
    ];
    expect(findHeaderRowIndex(rows)).toBe(8);
  });

  it('영문 헤더도 감지할 수 있어야 한다', () => {
    const rows = [
      ['some guide text', '', '', ''],
      ['date', 'type', 'amount', 'description'],
      ['2024-01-15', 'expense', '15000', 'lunch'],
    ];
    expect(findHeaderRowIndex(rows)).toBe(1);
  });

  it('헤더 키워드가 포함되어도 긴 설명 문구는 헤더로 인식하지 않아야 한다', () => {
    const rows = [
      ['날짜 형식을 확인하세요', '금액은 숫자만 입력', '제목을 입력해주세요'],
      ['날짜', '금액', '제목', '유형'],
    ];
    // 첫 번째 행은 셀 길이가 10자 초과이므로 건너뜀
    expect(findHeaderRowIndex(rows)).toBe(1);
  });

  it('빈 행만 있으면 0을 반환해야 한다', () => {
    const rows = [[''], ['']];
    expect(findHeaderRowIndex(rows)).toBe(0);
  });
});
