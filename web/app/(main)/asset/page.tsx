import { redirect } from 'next/navigation';
import { Landmark, Building2, Banknote, Plus } from 'lucide-react';
import { formatAmount, formatDate } from '@/lib/utils';
import { getCurrentUserLedger } from '@/lib/queries/ledger';
import { getAssetSummary } from '@/lib/queries/asset';
import { SummaryCard } from '@/components/shared/SummaryCard';

export default async function AssetPage() {
  const ledgerInfo = await getCurrentUserLedger();

  if (!ledgerInfo?.ledger) {
    redirect('/login');
  }

  const ledgerId = ledgerInfo.ledger.id;
  const { totalAsset, categories, assets } = await getAssetSummary(ledgerId);

  // 부동산, 예적금 카테고리 금액 추출
  const realEstate = categories.find((c) => c.name.includes('부동산'))?.total || 0;
  const savings = categories.find(
    (c) => c.name.includes('예금') || c.name.includes('적금')
  )?.total || 0;

  return (
    <div className='flex flex-col gap-6'>
      {/* Header */}
      <h1 className='text-[22px] font-semibold text-on-surface'>자산 관리</h1>

      {/* Summary Cards */}
      <div className='grid grid-cols-1 gap-4 md:grid-cols-3'>
        <SummaryCard
          icon={Landmark}
          iconColor='#2E7D32'
          label='총 자산'
          value={formatAmount(totalAsset)}
          valueColor='text-primary'
        />
        <SummaryCard
          icon={Building2}
          iconColor='#42A5F5'
          label='부동산'
          value={formatAmount(realEstate)}
          valueColor='text-on-surface'
        />
        <SummaryCard
          icon={Banknote}
          iconColor='#66BB6A'
          label='예적금'
          value={formatAmount(savings)}
          valueColor='text-on-surface'
        />
      </div>

      {/* Asset List */}
      <div className='rounded-[16px] border border-card-border bg-white p-6'>
        <div className='mb-4 flex items-center justify-between'>
          <h2 className='text-[15px] font-semibold text-on-surface'>자산 목록</h2>
          <button className='flex items-center gap-2 rounded-[10px] bg-primary px-3 py-1.5 text-sm font-semibold text-white transition-colors hover:bg-primary/90'>
            <Plus size={14} />
            자산 추가
          </button>
        </div>
        {assets.length > 0 ? (
          <div className='flex flex-col'>
            {assets.map((asset: any) => (
              <div
                key={asset.id}
                className='flex cursor-pointer items-center justify-between border-b border-separator py-3 transition-colors last:border-b-0 hover:bg-surface'
              >
                <div>
                  <p className='text-sm font-medium text-on-surface'>
                    {asset.title}
                  </p>
                  <p className='text-xs text-on-surface-variant'>
                    {asset.categories?.name || '기타'}
                    {asset.maturity_date
                      ? ` / 만기 ${formatDate(asset.maturity_date)}`
                      : ''}
                  </p>
                </div>
                <p className='text-sm font-semibold text-asset'>
                  {formatAmount(asset.amount)}
                </p>
              </div>
            ))}
          </div>
        ) : (
          <div className='flex flex-col items-center gap-3 py-12'>
            <Landmark size={32} className='text-on-surface-variant' />
            <p className='text-sm text-on-surface-variant'>등록된 자산이 없습니다</p>
          </div>
        )}
      </div>
    </div>
  );
}
