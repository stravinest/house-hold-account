import { redirect } from 'next/navigation';
import { Plus } from 'lucide-react';
import { getCurrentUserLedger } from '@/lib/queries/ledger';
import { getCategories } from '@/lib/queries/category';
import { BackLink } from '@/components/shared/BackLink';
import { CategoryList } from './category-list';

export default async function CategoriesPage() {
  const ledgerInfo = await getCurrentUserLedger();

  if (!ledgerInfo?.ledger) {
    redirect('/login');
  }

  const ledgerId = ledgerInfo.ledger.id;
  const [expenseCategories, incomeCategories, assetCategories] = await Promise.all([
    getCategories(ledgerId, 'expense'),
    getCategories(ledgerId, 'income'),
    getCategories(ledgerId, 'asset'),
  ]);

  return (
    <div className='flex flex-col gap-6'>
      <BackLink href='/settings' label='설정' />
      <div className='flex items-center justify-between'>
        <h1 className='text-[22px] font-semibold text-on-surface'>카테고리 관리</h1>
        <button className='flex items-center gap-2 rounded-[10px] bg-primary px-4 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-primary/90'>
          <Plus size={16} />
          카테고리 추가
        </button>
      </div>

      <CategoryList
        expenseCategories={expenseCategories}
        incomeCategories={incomeCategories}
        assetCategories={assetCategories}
      />
    </div>
  );
}
