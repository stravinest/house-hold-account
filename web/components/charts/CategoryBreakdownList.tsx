'use client';

const COLORS = [
  '#2E7D32',
  '#42A5F5',
  '#FF7043',
  '#AB47BC',
  '#FFA726',
  '#26A69A',
  '#EC407A',
  '#78909C',
];

type CategoryItem = {
  name: string;
  value: number;
};

type CategoryBreakdownListProps = {
  title: string;
  data: CategoryItem[];
};

export function CategoryBreakdownList({ title, data }: CategoryBreakdownListProps) {
  const total = data.reduce((sum, item) => sum + item.value, 0);

  return (
    <div className='flex w-full flex-col rounded-[16px] border border-card-border bg-white p-6 md:w-[320px]'>
      <h3 className='mb-4 text-[15px] font-semibold text-on-surface'>{title}</h3>
      <div className='flex flex-1 flex-col gap-3 overflow-y-auto'>
        {data.length > 0 ? (
          data.map((item, index) => {
            const percent = total > 0 ? Math.round((item.value / total) * 100) : 0;
            return (
              <div key={item.name} className='flex items-center justify-between'>
                <div className='flex items-center gap-2'>
                  <div
                    className='h-2 w-2 rounded-[4px]'
                    style={{ backgroundColor: COLORS[index % COLORS.length] }}
                  />
                  <span className='text-sm text-on-surface'>{item.name}</span>
                </div>
                <span className='text-xs text-on-surface-variant'>{percent}%</span>
              </div>
            );
          })
        ) : (
          <p className='py-4 text-center text-sm text-on-surface-variant'>
            데이터가 없습니다
          </p>
        )}
      </div>
    </div>
  );
}
