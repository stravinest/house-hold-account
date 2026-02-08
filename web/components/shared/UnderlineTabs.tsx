'use client';

type Tab = {
  key: string;
  label: string;
};

type UnderlineTabsProps = {
  tabs: Tab[];
  activeKey: string;
  onChange: (key: string) => void;
};

export function UnderlineTabs({ tabs, activeKey, onChange }: UnderlineTabsProps) {
  return (
    <div className='flex w-full border-b border-[#F0F0EC]'>
      {tabs.map((tab) => {
        const isActive = tab.key === activeKey;
        return (
          <button
            key={tab.key}
            onClick={() => onChange(tab.key)}
            className={`px-5 py-3 text-sm font-medium transition-colors ${
              isActive
                ? 'border-b-2 border-primary font-semibold text-primary'
                : 'text-on-surface-variant hover:text-on-surface'
            }`}
          >
            {tab.label}
          </button>
        );
      })}
    </div>
  );
}
