'use server';

import { revalidatePath } from 'next/cache';
import { createClient } from '@/lib/supabase/server';
import type { ImportResult } from '@/lib/types/excel';

interface ImportTransaction {
  ledger_id: string;
  user_id: string;
  type: 'income' | 'expense' | 'asset';
  amount: number;
  title: string;
  date: string;
  category_id?: string | null;
  payment_method_id?: string | null;
  memo?: string | null;
}

const DATE_REGEX = /^\d{4}-\d{2}-\d{2}$/;
const MAX_AMOUNT = 999_999_999;
const MAX_DESCRIPTION_LENGTH = 500;
const MAX_IMPORT_ROWS = 5000;

// HTML/스크립트 태그 제거
function sanitizeString(str: string): string {
  return str.replace(/<[^>]*>/g, '').replace(/[<>]/g, '').trim();
}

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function earlyError(message: string): ImportResult {
  return { total: 0, success: 0, skipped: 0, failed: 0, errors: [{ row: 0, message }] };
}

export async function importTransactions(
  ledgerId: string,
  transactions: {
    type: 'income' | 'expense' | 'asset';
    amount: number;
    description: string;
    date: string;
    categoryName?: string;
    paymentMethodName?: string;
    memo?: string;
  }[],
  options: {
    createMissingCategories: boolean;
    matchPaymentMethods: boolean;
  },
): Promise<ImportResult> {
  if (!UUID_REGEX.test(ledgerId)) {
    return earlyError('유효하지 않은 가계부입니다.');
  }

  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return earlyError('로그인이 필요합니다.');
  }

  // [S-00] 행 수 제한
  if (transactions.length > MAX_IMPORT_ROWS) {
    return earlyError(`최대 ${MAX_IMPORT_ROWS}건까지 가져올 수 있습니다.`);
  }
  if (transactions.length === 0) {
    return earlyError('가져올 데이터가 없습니다.');
  }

  // [S-01] 가계부 멤버십 검증
  const { data: membership } = await supabase
    .from('ledger_members')
    .select('id')
    .eq('ledger_id', ledgerId)
    .eq('user_id', user.id)
    .single();
  if (!membership) {
    return earlyError('해당 가계부에 대한 권한이 없습니다.');
  }

  // [P-01] import 데이터의 날짜 범위로 중복 체크 쿼리 최적화
  const validDates = transactions
    .map(t => t.date)
    .filter(d => DATE_REGEX.test(d))
    .sort();
  const minDate = validDates[0] || '1900-01-01';
  const maxDate = validDates[validDates.length - 1] || '2099-12-31';

  const [categoriesRes, paymentMethodsRes, existingTxRes] = await Promise.all([
    supabase.from('categories').select('id, name, type').eq('ledger_id', ledgerId),
    supabase.from('payment_methods').select('id, name, owner_user_id').eq('ledger_id', ledgerId),
    supabase
      .from('transactions')
      .select('date, amount, title')
      .eq('ledger_id', ledgerId)
      .gte('date', minDate)
      .lte('date', maxDate),
  ]);

  const categories = categoriesRes.data || [];
  const paymentMethods = paymentMethodsRes.data || [];
  const existingTx = existingTxRes.data || [];

  const existingKeys = new Set(
    existingTx.map((t) => `${t.date}_${t.amount}_${sanitizeString(t.title)}`),
  );

  // [P-02] 누락 카테고리 일괄 생성
  if (options.createMissingCategories) {
    const missingCats: { name: string; type: string }[] = [];
    const seen = new Set<string>();
    for (const tx of transactions) {
      if (tx.categoryName) {
        const key = `${tx.categoryName.toLowerCase()}|${tx.type}`;
        const exists = categories.find(
          c => c.name.toLowerCase() === tx.categoryName!.toLowerCase() && c.type === tx.type,
        );
        if (!exists && !seen.has(key)) {
          seen.add(key);
          missingCats.push({ name: tx.categoryName, type: tx.type });
        }
      }
    }
    if (missingCats.length > 0) {
      const { data: newCats } = await supabase
        .from('categories')
        .insert(missingCats.map(c => ({ ledger_id: ledgerId, name: c.name, type: c.type })))
        .select('id, name, type');
      if (newCats) {
        categories.push(...newCats);
      }
    }
  }

  const result: ImportResult = {
    total: transactions.length,
    success: 0,
    skipped: 0,
    failed: 0,
    errors: [],
  };

  const toInsert: ImportTransaction[] = [];

  for (let i = 0; i < transactions.length; i++) {
    const tx = transactions[i];
    const rowNum = i + 2;

    // [S-02] 서버 사이드 검증
    if (tx.type !== 'income' && tx.type !== 'expense' && tx.type !== 'asset') {
      result.failed++;
      result.errors.push({ row: rowNum, message: '유효하지 않은 거래 유형' });
      continue;
    }
    if (!tx.amount || tx.amount <= 0 || tx.amount > MAX_AMOUNT) {
      result.failed++;
      result.errors.push({ row: rowNum, message: '유효하지 않은 금액' });
      continue;
    }
    if (!tx.description || tx.description.trim().length === 0 || tx.description.length > MAX_DESCRIPTION_LENGTH) {
      result.failed++;
      result.errors.push({ row: rowNum, message: '제목이 비어있거나 너무 깁니다' });
      continue;
    }
    if (!DATE_REGEX.test(tx.date)) {
      result.failed++;
      result.errors.push({ row: rowNum, message: '유효하지 않은 날짜 형식' });
      continue;
    }

    const key = `${tx.date}_${tx.amount}_${sanitizeString(tx.description)}`;

    // 중복 체크
    if (existingKeys.has(key)) {
      result.skipped++;
      continue;
    }

    // 카테고리 매칭
    let categoryId: string | null = null;
    if (tx.categoryName) {
      const matched = categories.find(
        (c) => c.name.toLowerCase() === tx.categoryName!.toLowerCase() && c.type === tx.type,
      );
      if (matched) {
        categoryId = matched.id;
      }
    }

    // 결제수단 매칭 (본인 소유 자동수집 결제수단 우선, 그다음 공유 결제수단)
    let paymentMethodId: string | null = null;
    if (tx.paymentMethodName && options.matchPaymentMethods) {
      const lowerName = tx.paymentMethodName.toLowerCase();
      const ownMatch = paymentMethods.find(
        (p) => p.name.toLowerCase() === lowerName && p.owner_user_id === user.id,
      );
      const sharedMatch = paymentMethods.find(
        (p) => p.name.toLowerCase() === lowerName && p.owner_user_id === null,
      );
      const matched = ownMatch || sharedMatch;
      if (matched) {
        paymentMethodId = matched.id;
      }
    }

    toInsert.push({
      ledger_id: ledgerId,
      user_id: user.id,
      type: tx.type,
      amount: tx.amount,
      title: sanitizeString(tx.description),
      date: tx.date,
      category_id: categoryId,
      payment_method_id: paymentMethodId,
      memo: tx.memo ? sanitizeString(tx.memo) || null : null,
    });

    existingKeys.add(key);
  }

  // 배치 insert (50건씩)
  const batchSize = 50;
  for (let i = 0; i < toInsert.length; i += batchSize) {
    const batch = toInsert.slice(i, i + batchSize);
    const { error } = await supabase.from('transactions').insert(batch);
    if (error) {
      result.failed += batch.length;
      result.errors.push({ row: i + 1, message: error.message });
    } else {
      result.success += batch.length;
    }
  }

  revalidatePath('/ledger');
  revalidatePath('/dashboard');
  revalidatePath('/statistics');

  return result;
}
