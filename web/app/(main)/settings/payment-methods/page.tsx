import { redirect } from 'next/navigation';
import { Plus, CreditCard } from 'lucide-react';
import { getCurrentUserLedger } from '@/lib/queries/ledger';
import { getPaymentMethods } from '@/lib/queries/payment-method';
import { BackLink } from '@/components/shared/BackLink';

export default async function PaymentMethodsPage() {
  const ledgerInfo = await getCurrentUserLedger();

  if (!ledgerInfo?.ledger) {
    redirect('/login');
  }

  const paymentMethods = await getPaymentMethods(ledgerInfo.ledger.id);

  // 타입별 그룹화
  const grouped: Record<string, any[]> = {};
  for (const method of paymentMethods as any[]) {
    const group = method.can_auto_save ? '자동수집' : '수동 입력';
    if (!grouped[group]) grouped[group] = [];
    grouped[group].push(method);
  }

  return (
    <div className='flex flex-col gap-6'>
      <BackLink href='/settings' label='설정' />
      <div className='flex items-center justify-between'>
        <h1 className='text-[22px] font-semibold text-on-surface'>결제수단 관리</h1>
        <button className='flex items-center gap-2 rounded-[10px] bg-primary px-4 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-primary/90'>
          <Plus size={16} />
          결제수단 추가
        </button>
      </div>

      {/* Payment Method List */}
      {paymentMethods.length > 0 ? (
        <div className='flex flex-col gap-4'>
          {Object.entries(grouped).map(([groupName, methods]) => (
            <div
              key={groupName}
              className='rounded-[16px] border border-card-border bg-white'
            >
              <div className='border-b border-separator px-5 py-3'>
                <h2 className='text-sm font-semibold text-on-surface'>{groupName}</h2>
              </div>
              {methods.map((method: any, index: number) => (
                <div
                  key={method.id}
                  className={`flex cursor-pointer items-center justify-between px-5 py-4 transition-colors hover:bg-surface ${
                    index < methods.length - 1 ? 'border-b border-separator' : ''
                  }`}
                >
                  <div className='flex items-center gap-3'>
                    <CreditCard size={18} className='text-on-surface-variant' />
                    <div>
                      <p className='text-sm font-medium text-on-surface'>
                        {method.name}
                      </p>
                      <p className='text-xs text-on-surface-variant'>
                        {method.can_auto_save
                          ? method.auto_save_mode === 'auto'
                            ? '자동 모드'
                            : method.auto_save_mode === 'suggest'
                              ? '제안 모드'
                              : '수동 모드'
                          : '수동 입력'}
                      </p>
                    </div>
                  </div>
                  {method.can_auto_save ? (
                    <span className='rounded-[8px] bg-green-50 px-3 py-1.5 text-xs font-semibold text-primary'>
                      자동수집
                    </span>
                  ) : null}
                </div>
              ))}
            </div>
          ))}
        </div>
      ) : (
        <div className='flex flex-col items-center gap-3 rounded-[16px] border border-card-border bg-white py-12'>
          <CreditCard size={32} className='text-on-surface-variant' />
          <p className='text-sm text-on-surface-variant'>등록된 결제수단이 없습니다</p>
        </div>
      )}
    </div>
  );
}
