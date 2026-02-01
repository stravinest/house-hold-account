// 거래 타입
export type TransactionType = 'income' | 'expense' | 'asset';

// 거래 인터페이스
export interface Transaction {
  id: string;
  ledger_id: string;
  user_id: string;
  type: TransactionType;
  amount: number;
  category_id?: string;
  payment_method_id?: string;
  date: string;
  memo?: string;
  created_at: string;
  updated_at: string;
}

// 카테고리 인터페이스
export interface Category {
  id: string;
  ledger_id: string;
  name: string;
  icon: string;
  color: string;
  type: TransactionType;
  created_at: string;
}

// 결제수단 인터페이스
export interface PaymentMethod {
  id: string;
  ledger_id: string;
  name: string;
  icon: string;
  color: string;
  can_auto_save: boolean;
  created_at: string;
}

// 사용자 인터페이스
export interface User {
  id: string;
  email: string;
  display_name?: string;
  color?: string;
  created_at: string;
}

// 가계부 인터페이스
export interface Ledger {
  id: string;
  name: string;
  created_at: string;
}

// 통계 - 카테고리별
export interface CategoryStatistics {
  categoryId: string;
  categoryName: string;
  categoryIcon: string;
  categoryColor: string;
  amount: number;
  percentage?: number;
}

// 통계 - 월별
export interface MonthlyStatistics {
  year: number;
  month: number;
  income: number;
  expense: number;
  saving: number;
  balance?: number;
}

// 통계 - 연도별
export interface YearlyStatistics {
  year: number;
  income: number;
  expense: number;
  saving: number;
  balance?: number;
}

// 필터 상태
export interface FilterState {
  dateRange: {
    start: Date;
    end: Date;
  };
  type: 'all' | TransactionType;
  categoryIds: string[];
  userIds: string[];
  paymentMethodIds: string[];
}
