export default function StatisticsLoading() {
  return (
    <div className='flex flex-col gap-6 animate-pulse'>
      {/* Header */}
      <div className='flex items-center justify-between'>
        <div className='h-7 w-20 rounded bg-surface-container' />
        <div className='h-8 w-48 rounded-[8px] bg-surface-container' />
      </div>
      {/* Summary Cards */}
      <div className='grid grid-cols-1 gap-4 md:grid-cols-3'>
        {[...Array(3)].map((_, i) => (
          <div key={i} className='h-24 rounded-[16px] border border-card-border bg-white' />
        ))}
      </div>
      {/* Chart */}
      <div className='h-72 rounded-[16px] border border-card-border bg-white' />
      {/* Category List */}
      <div className='rounded-[16px] border border-card-border bg-white p-6'>
        <div className='flex flex-col gap-3'>
          {[...Array(5)].map((_, i) => (
            <div key={i} className='flex items-center gap-3'>
              <div className='h-8 w-8 rounded bg-surface-container' />
              <div className='h-4 flex-1 rounded bg-surface-container' />
              <div className='h-4 w-20 rounded bg-surface-container' />
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
