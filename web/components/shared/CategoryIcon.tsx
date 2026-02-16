'use client';

export function CategoryIcon({ icon, name, size = 16 }: { icon: string | null; name: string; size?: number }) {
  if (icon && icon.trim()) {
    return (
      <span className='material-icons-outlined leading-none' style={{ fontSize: `${size}px` }}>
        {icon}
      </span>
    );
  }
  return <span className='text-xs font-medium'>{name.charAt(0)}</span>;
}
