import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

/**
 * Tailwind CSS 클래스 병합 유틸리티
 * clsx + tailwind-merge 조합으로 조건부 클래스 적용 및 충돌 해결
 */
export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}
