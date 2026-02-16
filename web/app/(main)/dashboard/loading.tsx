export default function DashboardLoading() {
  return (
    <div className='flex flex-col gap-6 animate-pulse'>
      {/* Header */}
      <div className='flex items-center justify-between'>
        <div className='h-7 w-32 rounded bg-surface-container' />
        <div className='flex gap-2'>
          <div className='h-9 w-24 rounded-[8px] bg-surface-container' />
          <div className='h-9 w-24 rounded-[8px] bg-surface-container' />
        </div>
      </div>
      {/* Summary Cards */}
      <div className='grid grid-cols-1 gap-4 md:grid-cols-3'>
        {[...Array(3)].map((_, i) => (
          <div key={i} className='h-24 rounded-[16px] border border-card-border bg-white' />
        ))}
      </div>
      {/* Chart */}
      <div className='h-64 rounded-[16px] border border-card-border bg-white' />
      {/* Transactions */}
      <div className='rounded-[16px] border border-card-border bg-white p-6'>
        <div className='mb-4 h-5 w-20 rounded bg-surface-container' />
        <div className='flex flex-col gap-1'>
          {[...Array(5)].map((_, i) => (
            <div key={i} className='flex items-center gap-3 py-3'>
              <div className='h-9 w-9 rounded-full bg-surface-container' />
              <div className='flex-1'>
                <div className='mb-1.5 h-4 w-40 rounded bg-surface-container' />
                <div className='h-3 w-28 rounded bg-surface-container' />
              </div>
              <div className='h-4 w-20 rounded bg-surface-container' />
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
