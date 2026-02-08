'use client';

import { useState } from 'react';
import { Tag } from 'lucide-react';

type CategoryType = 'expense' | 'income' | 'asset';

type CategoryItem = {
  id: string;
  name: string;
  icon: string | null;
  type: 'income' | 'expense' | 'asset';
  sort_order: number;
};

const tabs: { key: CategoryType; label: string }[] = [
  { key: 'expense', label: '지출' },
  { key: 'income', label: '수입' },
  { key: 'asset', label: '자산' },
];

export function CategoryList({
  expenseCategories,
  incomeCategories,
  assetCategories,
}: {
  expenseCategories: CategoryItem[];
  incomeCategories: CategoryItem[];
  assetCategories: CategoryItem[];
}) {
  const [activeTab, setActiveTab] = useState<CategoryType>('expense');

  const categoryMap: Record<CategoryType, CategoryItem[]> = {
    expense: expenseCategories,
    income: incomeCategories,
    asset: assetCategories,
  };

  const currentCategories = categoryMap[activeTab];

  return (
    <>
      {/* Underline Tabs */}
      <div className='flex border-b border-separator'>
        {tabs.map((tab) => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key)}
            className={`px-5 pb-3 text-sm font-medium transition-colors ${
              activeTab === tab.key
                ? 'border-b-2 border-primary text-primary'
                : 'text-on-surface-variant hover:text-on-surface'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Category Grid */}
      {currentCategories.length > 0 ? (
        <div className='grid grid-cols-2 gap-3 md:grid-cols-4'>
          {currentCategories.map((cat) => (
            <div
              key={cat.id}
              className='flex cursor-pointer flex-col items-center gap-2 rounded-[16px] border border-card-border bg-white p-5 transition-colors hover:bg-surface'
            >
              <span className='text-3xl'>{cat.icon || ''}</span>
              <span className='text-sm font-medium text-on-surface'>{cat.name}</span>
            </div>
          ))}
        </div>
      ) : (
        <div className='flex flex-col items-center gap-3 rounded-[16px] border border-card-border bg-white py-12'>
          <Tag size={32} className='text-on-surface-variant' />
          <p className='text-sm text-on-surface-variant'>등록된 카테고리가 없습니다</p>
        </div>
      )}
    </>
  );
}
