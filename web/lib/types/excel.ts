// 내보내기 옵션
export interface ExportOptions {
  startDate: string;
  endDate: string;
  transactionType: 'all' | 'income' | 'expense' | 'asset';
  includeCategory: boolean;
  includePaymentMethod: boolean;
  includeMemo: boolean;
  includeAuthor: boolean;
  includeFixedExpense: boolean;
  fileFormat: 'xlsx' | 'csv';
}

// 가져오기 컬럼 매핑
export interface ColumnMapping {
  date: number | null;
  type: number | null;
  amount: number | null;
  description: number | null;
  category: number | null;
  paymentMethod: number | null;
  memo: number | null;
}

// 가져오기 미리보기 행
export interface ImportPreviewRow {
  rowIndex: number;
  date: string;
  type: 'income' | 'expense' | 'asset';
  amount: number;
  description: string;
  category?: string;
  paymentMethod?: string;
  memo?: string;
  isDuplicate: boolean;
  error?: string;
}

// 가져오기 옵션
export interface ImportOptions {
  createMissingCategories: boolean;
  matchPaymentMethods: boolean;
  previewBeforeImport: boolean;
}

// 가져오기 결과
export interface ImportResult {
  total: number;
  success: number;
  skipped: number;
  failed: number;
  errors: { row: number; message: string }[];
}

// 거래 추가 폼 데이터
export interface AddTransactionFormData {
  type: 'income' | 'expense' | 'asset';
  amount: number;
  description: string;
  date: string;
  categoryId: string | null;
  paymentMethodId: string | null;
  isRecurring: boolean;
  isFixedExpense: boolean;
  memo: string;
}
