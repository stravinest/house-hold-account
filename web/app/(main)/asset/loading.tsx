export default function AssetLoading() {
  return (
    <div className='flex flex-col gap-6 animate-pulse'>
      <div className='h-7 w-20 rounded bg-surface-container' />
      <div className='grid grid-cols-1 gap-4 md:grid-cols-3'>
        {[...Array(3)].map((_, i) => (
          <div key={i} className='h-24 rounded-[16px] border border-card-border bg-white' />
        ))}
      </div>
      <div className='h-64 rounded-[16px] border border-card-border bg-white' />
    </div>
  );
}
