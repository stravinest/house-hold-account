export default function LedgerLoading() {
  return (
    <div className='flex flex-col gap-6 animate-pulse'>
      {/* Header */}
      <div className='flex items-center justify-between'>
        <div className='h-7 w-28 rounded bg-surface-container' />
        <div className='flex gap-2'>
          <div className='h-9 w-24 rounded-[8px] bg-surface-container' />
          <div className='h-9 w-24 rounded-[8px] bg-surface-container' />
        </div>
      </div>
      {/* Month Nav + Filter */}
      <div className='flex items-center justify-between'>
        <div className='h-7 w-36 rounded bg-surface-container' />
        <div className='h-8 w-48 rounded-[8px] bg-surface-container' />
      </div>
      {/* Summary Cards */}
      <div className='grid grid-cols-1 gap-4 md:grid-cols-3'>
        {[...Array(3)].map((_, i) => (
          <div key={i} className='h-24 rounded-[16px] border border-card-border bg-white' />
        ))}
      </div>
      {/* Transaction List */}
      <div className='rounded-[16px] border border-card-border bg-white'>
        {[...Array(8)].map((_, i) => (
          <div key={i} className='flex items-center gap-3 border-b border-separator px-6 py-4 last:border-b-0'>
            <div className='h-9 w-9 shrink-0 rounded-full bg-surface-container' />
            <div className='flex-1'>
              <div className='mb-1.5 h-4 w-48 rounded bg-surface-container' />
              <div className='h-3 w-32 rounded bg-surface-container' />
            </div>
            <div className='h-4 w-20 rounded bg-surface-container' />
          </div>
        ))}
      </div>
    </div>
  );
}
