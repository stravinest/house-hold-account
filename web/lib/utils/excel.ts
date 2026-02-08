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

// 가져오기: 파일 파싱 -> 헤더 + 데이터 반환
export function parseImportFile(file: File): Promise<{ headers: string[]; rows: string[][] }> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const data = new Uint8Array(e.target?.result as ArrayBuffer);
        const wb = XLSX.read(data, { type: 'array' });
        const ws = wb.Sheets[wb.SheetNames[0]];
        const jsonData = XLSX.utils.sheet_to_json<string[]>(ws, { header: 1 });

        if (jsonData.length < 2) {
          reject(new Error('파일에 데이터가 없습니다.'));
          return;
        }

        const headers = jsonData[0].map((h) => String(h || '').trim());
        const rows = jsonData.slice(1).filter((row) =>
          row.some((cell) => cell !== null && cell !== undefined && String(cell).trim() !== ''),
        );

        resolve({ headers, rows: rows.map((r) => r.map((c) => String(c ?? ''))) });
      } catch {
        reject(new Error('파일을 읽을 수 없습니다.'));
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
