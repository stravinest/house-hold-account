'use client';

type Member = {
  id: string;
  name: string;
  color: string;
};

type UserFilterChipsProps = {
  members: Member[];
  activeFilter: string; // 'all' | 'me' | member id
  onChange: (filter: string) => void;
};

export function UserFilterChips({ members, activeFilter, onChange }: UserFilterChipsProps) {
  return (
    <div className='flex items-center gap-3'>
      <span className='text-[13px] font-medium text-on-surface-variant'>통계 범위</span>
      <div className='flex items-center gap-2'>
        <button
          onClick={() => onChange('all')}
          className={`rounded-full px-[14px] py-[6px] text-xs font-semibold transition-colors ${
            activeFilter === 'all'
              ? 'bg-primary text-white'
              : 'border border-[#E0E0E0] text-on-surface-variant hover:bg-surface-container'
          }`}
        >
          합산
        </button>
        {members.map((member) => (
          <button
            key={member.id}
            onClick={() => onChange(member.id)}
            className={`flex items-center gap-1.5 rounded-full px-[14px] py-[6px] text-xs font-medium transition-colors ${
              activeFilter === member.id
                ? 'bg-primary text-white'
                : 'border border-[#E0E0E0] text-on-surface-variant hover:bg-surface-container'
            }`}
          >
            <div
              className='h-[18px] w-[18px] rounded-full'
              style={{ backgroundColor: member.color || '#A8DAB5' }}
            />
            {member.name}
          </button>
        ))}
      </div>
    </div>
  );
}
