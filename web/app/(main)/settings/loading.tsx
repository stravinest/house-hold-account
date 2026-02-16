export default function SettingsLoading() {
  return (
    <div className='flex flex-col gap-6 animate-pulse'>
      <div className='h-7 w-20 rounded bg-surface-container' />
      <div className='rounded-[16px] border border-card-border bg-white p-6'>
        <div className='flex flex-col gap-4'>
          {[...Array(6)].map((_, i) => (
            <div key={i} className='flex items-center justify-between'>
              <div className='h-4 w-32 rounded bg-surface-container' />
              <div className='h-4 w-20 rounded bg-surface-container' />
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
