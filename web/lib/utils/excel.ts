import * as XLSX from 'xlsx';
import type { ExportOptions, ColumnMapping, ImportPreviewRow } from '@/lib/types/excel';

type TransactionRow = {
  date: string;
  type: string;
  amount: number;
  description: string;
  categoryName?: string;
  paymentMethodName?: string;
  memo?: string;
  userName?: string;
  isFixedExpense?: boolean;
};

// 내보내기: 거래 데이터 -> xlsx/csv 파일 다운로드
export function exportTransactions(
  transactions: TransactionRow[],
  options: ExportOptions,
) {
  const headers: string[] = ['날짜', '유형', '금액', '제목'];
  if (options.includeCategory) headers.push('카테고리');
  if (options.includePaymentMethod) headers.push('결제수단');
  if (options.includeMemo) headers.push('메모');
  if (options.includeAuthor) headers.push('작성자');
  if (options.includeFixedExpense) headers.push('고정비');

  const rows = transactions.map((tx) => {
    const typeLabel = tx.type === 'income' ? '수입' : tx.type === 'expense' ? '지출' : '자산';
    const row: (string | number)[] = [tx.date, typeLabel, tx.amount, tx.description];
    if (options.includeCategory) row.push(tx.categoryName || '');
    if (options.includePaymentMethod) row.push(tx.paymentMethodName || '');
    if (options.includeMemo) row.push(tx.memo || '');
    if (options.includeAuthor) row.push(tx.userName || '');
    if (options.includeFixedExpense) row.push(tx.isFixedExpense ? 'Y' : 'N');
    return row;
  });

  const wsData = [headers, ...rows];
  const ws = XLSX.utils.aoa_to_sheet(wsData);

  // 열 너비 자동 조정
  ws['!cols'] = headers.map((h) => ({ wch: Math.max(h.length * 2, 12) }));

  if (options.fileFormat === 'xlsx') {
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, '거래내역');
    XLSX.writeFile(wb, `거래내역_${options.startDate}_${options.endDate}.xlsx`);
  } else {
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, '거래내역');
    XLSX.writeFile(wb, `거래내역_${options.startDate}_${options.endDate}.csv`, {
      bookType: 'csv',
    });
  }
}

// 파일 업로드 제한
const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB
const MAX_ROW_COUNT = 5000;
const ALLOWED_EXTENSIONS = ['.xlsx', '.xls', '.csv'];
const ALLOWED_MIME_TYPES = [
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'application/vnd.ms-excel',
  'text/csv',
  'application/csv',
];

// 파일 유효성 검증
function validateFile(file: File): string | null {
  if (file.size > MAX_FILE_SIZE) {
    return `파일 크기가 너무 큽니다. (최대 ${MAX_FILE_SIZE / 1024 / 1024}MB, 현재 ${(file.size / 1024 / 1024).toFixed(1)}MB)`;
  }
  const parts = file.name.split('.');
  const ext = parts.length > 1 ? '.' + parts.pop()!.toLowerCase() : '';
  if (!ext || !ALLOWED_EXTENSIONS.includes(ext)) {
    return `지원하지 않는 파일 형식입니다. (${ALLOWED_EXTENSIONS.join(', ')})`;
  }
  if (file.type && !ALLOWED_MIME_TYPES.includes(file.type) && file.type !== '') {
    return '지원하지 않는 파일 형식입니다.';
  }
  return null;
}

// 헤더 행으로 인식할 키워드 목록
const HEADER_KEYWORDS = ['날짜', 'date', '금액', 'amount', '제목', 'description', '유형', 'type', '내용', '적요', '거래일', '구분'];

// 헤더 행 자동 감지: 짧은 셀(헤더처럼 보이는 셀)에서 키워드가 3개 이상 매칭되는 행을 찾음
export function findHeaderRowIndex(rows: string[][]): number {
  for (let i = 0; i < Math.min(rows.length, 30); i++) {
    const row = rows[i];
    if (!row || row.length < 3) continue;
    // 각 셀이 짧고(10자 이하) 키워드와 일치하는지 확인 (안내 문구의 긴 셀은 제외)
    const lowerCells = row.map((c) => String(c || '').toLowerCase().trim());
    const matchCount = lowerCells.filter((cell) =>
      cell.length > 0 && cell.length <= 10 && HEADER_KEYWORDS.some((kw) => cell.includes(kw)),
    ).length;
    if (matchCount >= 3) return i;
  }
  return 0;
}

// 가져오기: 파일 파싱 -> 헤더 + 데이터 반환
export function parseImportFile(file: File): Promise<{ headers: string[]; rows: string[][]; truncated: boolean }> {
  const fileError = validateFile(file);
  if (fileError) return Promise.reject(new Error(fileError));

  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const data = new Uint8Array(e.target?.result as ArrayBuffer);
        const wb = XLSX.read(data, { type: 'array' });
        const ws = wb.Sheets[wb.SheetNames[0]];
        const jsonData = XLSX.utils.sheet_to_json<string[]>(ws, { header: 1 });

        if (jsonData.length < 2) {
          reject(new Error('파일에 데이터가 없습니다. 헤더 행과 데이터 행이 필요합니다.'));
          return;
        }

        // 안내 문구가 포함된 샘플 파일도 자동으로 헤더 행을 찾아냄
        const headerIdx = findHeaderRowIndex(
          jsonData.map((r) => r.map((c) => String(c ?? ''))),
        );

        const headers = jsonData[headerIdx].map((h) => String(h || '').trim());
        const allRows = jsonData.slice(headerIdx + 1).filter((row) =>
          row.some((cell) => cell !== null && cell !== undefined && String(cell).trim() !== ''),
        );

        const truncated = allRows.length > MAX_ROW_COUNT;
        const rows = allRows.slice(0, MAX_ROW_COUNT);

        resolve({
          headers,
          rows: rows.map((r) => r.map((c) => String(c ?? ''))),
          truncated,
        });
      } catch {
        reject(new Error('파일을 읽을 수 없습니다. 올바른 Excel 또는 CSV 파일인지 확인하세요.'));
      }
    };
    reader.onerror = () => reject(new Error('파일 읽기에 실패했습니다.'));
    reader.readAsArrayBuffer(file);
  });
}

// 자동 컬럼 매핑
export function autoMapColumns(headers: string[]): ColumnMapping {
  const mapping: ColumnMapping = {
    date: null,
    type: null,
    amount: null,
    description: null,
    category: null,
    paymentMethod: null,
    memo: null,
  };

  const patterns: Record<keyof ColumnMapping, string[]> = {
    date: ['날짜', 'date', '일자', '거래일', '일시'],
    type: ['유형', 'type', '종류', '구분', '거래유형'],
    amount: ['금액', 'amount', '가격', '거래금액', '결제금액'],
    description: ['제목', 'description', '내용', '적요', '거래내용', '상호명', '가맹점'],
    category: ['카테고리', 'category', '분류'],
    paymentMethod: ['결제수단', 'payment', '지불수단', '카드'],
    memo: ['메모', 'memo', '비고', 'note'],
  };

  const lowerHeaders = headers.map((h) => h.toLowerCase().trim());

  for (const [field, keywords] of Object.entries(patterns)) {
    const idx = lowerHeaders.findIndex((h) =>
      keywords.some((kw) => h.includes(kw.toLowerCase())),
    );
    if (idx !== -1) {
      mapping[field as keyof ColumnMapping] = idx;
    }
  }

  return mapping;
}

// 날짜 문자열 파싱 (다양한 형식 지원)
export function parseDateString(value: string): string | null {
  const trimmed = String(value).trim();

  // YYYY-MM-DD
  if (/^\d{4}-\d{2}-\d{2}$/.test(trimmed)) return trimmed;

  // YYYY/MM/DD
  if (/^\d{4}\/\d{2}\/\d{2}$/.test(trimmed)) return trimmed.replace(/\//g, '-');

  // MM/DD/YYYY
  const mdyMatch = trimmed.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
  if (mdyMatch) {
    return `${mdyMatch[3]}-${mdyMatch[1].padStart(2, '0')}-${mdyMatch[2].padStart(2, '0')}`;
  }

  // YYYYMMDD
  if (/^\d{8}$/.test(trimmed)) {
    return `${trimmed.slice(0, 4)}-${trimmed.slice(4, 6)}-${trimmed.slice(6, 8)}`;
  }

  // Excel serial date number
  const num = Number(trimmed);
  if (!isNaN(num) && num > 30000 && num < 60000) {
    const date = new Date((num - 25569) * 86400 * 1000);
    const y = date.getUTCFullYear();
    const m = String(date.getUTCMonth() + 1).padStart(2, '0');
    const d = String(date.getUTCDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
  }

  return null;
}

// 금액 문자열 파싱
export function parseAmountString(value: string): number | null {
  const cleaned = String(value).replace(/[,원\sWKRW₩\-+]/g, '').trim();
  const num = Number(cleaned);
  return isNaN(num) || num === 0 ? null : Math.abs(num);
}

// 거래 유형 파싱
export function parseTransactionType(value: string): 'income' | 'expense' | 'asset' | null {
  const lower = String(value).toLowerCase().trim();
  if (['수입', 'income', '입금'].includes(lower)) return 'income';
  if (['지출', 'expense', '출금', '결제'].includes(lower)) return 'expense';
  if (['자산', 'asset'].includes(lower)) return 'asset';
  return null;
}

// 샘플 Excel 템플릿 생성 및 다운로드
export function generateSampleExcel() {
  const wb = XLSX.utils.book_new();

  // 단일 시트: 입력 안내 + 예시 데이터를 함께 표시
  const data = [
    // --- 입력 안내 ---
    ['[ 가져오기 입력 안내 ]', '', '', '', '', '', ''],
    [],
    ['* 필수 컬럼', '', '', '', '', '', ''],
    ['  날짜 (필수)', '지원 형식: 2024-01-15 / 2024/01/15 / 20240115 / 01/15/2024 / Excel 날짜 셀', '', '', '', '', ''],
    ['  유형 (필수)', '지출(expense/출금/결제), 수입(income/입금), 자산(asset) - 대소문자 무관', '', '', '', '', ''],
    ['  금액 (필수)', '숫자만 입력. 콤마/원/W 자동 제거. 최대 999,999,999. 예: 15000, 15,000원', '', '', '', '', ''],
    ['  제목 (필수)', '거래 내용 (최대 500자). 비어있으면 오류', '', '', '', '', ''],
    [],
    ['* 선택 컬럼', '', '', '', '', '', ''],
    ['  카테고리', '등록된 카테고리명 입력. 미등록 시 자동 생성 가능 (옵션)', '', '', '', '', ''],
    ['  결제수단', '등록된 결제수단명과 동일하게 입력 (예: 신한카드, 현금)', '', '', '', '', ''],
    ['  메모', '자유 입력 (선택)', '', '', '', '', ''],
    [],
    ['* 참고사항', '', '', '', '', '', ''],
    ['  - 첫 번째 행이 헤더(컬럼명)입니다. 헤더명이 다르면 매핑 단계에서 수동 지정 가능', '', '', '', '', '', ''],
    ['  - 같은 날짜+금액+제목 조합은 중복으로 감지되어 자동 건너뜁니다', '', '', '', '', '', ''],
    ['  - 파일 제한: 최대 5MB, 5,000건, .xlsx/.xls/.csv 지원', '', '', '', '', '', ''],
    ['  - 오류 행(날짜/금액/제목 누락)은 미리보기에서 빨간색으로 표시되며 가져오기에서 제외됩니다', '', '', '', '', '', ''],
    [],
    ['아래 예시 데이터를 지우고 본인의 거래 내역을 입력하세요.', '', '', '', '', '', ''],
    [],
    // --- 헤더 ---
    ['날짜', '유형', '금액', '제목', '카테고리', '결제수단', '메모'],
    // --- 예시 데이터 ---
    ['2024-01-15', '지출', 15000, '점심 식사', '식비', '신한카드', '회사 근처 식당'],
    ['2024-01-15', '수입', 3000000, '1월 급여', '급여', '', ''],
    ['2024-01-16', '지출', 1400, '버스 출퇴근', '교통', '교통카드', ''],
    ['2024/01/17', '지출', 45000, '마트 장보기', '식비', '현금', '주간 식재료'],
    ['2024-01-18', 'expense', 50000, '통신비', '고정비', '자동이체', '휴대폰 요금'],
    ['20240120', '수입', 500000, '부수입', '기타수입', '', '프리랜서 작업비'],
    ['2024-01-22', '자산', 1000000, '정기예금', '예금', '', '3개월 만기'],
  ];

  const ws = XLSX.utils.aoa_to_sheet(data);
  ws['!cols'] = [
    { wch: 16 }, { wch: 12 }, { wch: 14 }, { wch: 20 },
    { wch: 12 }, { wch: 12 }, { wch: 24 },
  ];

  // B열 병합 (안내 텍스트가 길어서 여러 컬럼에 걸쳐 보이도록)
  ws['!merges'] = [
    { s: { r: 0, c: 0 }, e: { r: 0, c: 6 } },  // 제목
    { s: { r: 3, c: 1 }, e: { r: 3, c: 6 } },   // 날짜 설명
    { s: { r: 4, c: 1 }, e: { r: 4, c: 6 } },   // 유형 설명
    { s: { r: 5, c: 1 }, e: { r: 5, c: 6 } },   // 금액 설명
    { s: { r: 6, c: 1 }, e: { r: 6, c: 6 } },   // 제목 설명
    { s: { r: 9, c: 1 }, e: { r: 9, c: 6 } },   // 카테고리 설명
    { s: { r: 10, c: 1 }, e: { r: 10, c: 6 } },  // 결제수단 설명
    { s: { r: 11, c: 1 }, e: { r: 11, c: 6 } },  // 메모 설명
    { s: { r: 14, c: 0 }, e: { r: 14, c: 6 } },  // 참고1
    { s: { r: 15, c: 0 }, e: { r: 15, c: 6 } },  // 참고2
    { s: { r: 16, c: 0 }, e: { r: 16, c: 6 } },  // 참고3
    { s: { r: 17, c: 0 }, e: { r: 17, c: 6 } },  // 참고4
    { s: { r: 19, c: 0 }, e: { r: 19, c: 6 } },  // 안내 문구
  ];

  XLSX.utils.book_append_sheet(wb, ws, '가져오기 샘플');

  XLSX.writeFile(wb, '가계부_가져오기_샘플.xlsx');
}

// 매핑된 데이터를 미리보기 행으로 변환
export function mapRowsToPreview(
  rows: string[][],
  mapping: ColumnMapping,
): ImportPreviewRow[] {
  return rows.map((row, idx) => {
    const dateVal = mapping.date !== null ? (row[mapping.date] ?? '') : '';
    const typeVal = mapping.type !== null ? (row[mapping.type] ?? '') : '';
    const amountVal = mapping.amount !== null ? (row[mapping.amount] ?? '') : '';
    const descVal = mapping.description !== null ? (row[mapping.description] ?? '') : '';

    const parsedDate = parseDateString(dateVal);
    const parsedAmount = parseAmountString(amountVal);
    const parsedType = parseTransactionType(typeVal);

    const errors: string[] = [];
    if (!parsedDate) errors.push('날짜 형식 오류');
    if (!parsedAmount) errors.push('금액 형식 오류');
    if (!parsedType) errors.push('유형 형식 오류');
    if (!descVal.trim()) errors.push('제목 없음');

    return {
      rowIndex: idx + 2,
      date: parsedDate || dateVal,
      type: parsedType || 'expense',
      amount: parsedAmount || 0,
      description: descVal.trim() || '',
      category: mapping.category !== null ? String(row[mapping.category] ?? '').trim() : undefined,
      paymentMethod: mapping.paymentMethod !== null ? String(row[mapping.paymentMethod] ?? '').trim() : undefined,
      memo: mapping.memo !== null ? String(row[mapping.memo] ?? '').trim() : undefined,
      isDuplicate: false,
      error: errors.length > 0 ? errors.join(', ') : undefined,
    };
  });
}
