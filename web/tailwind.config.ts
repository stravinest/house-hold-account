import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './features/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // Primary (동일한 녹색 - Flutter와 일치)
        primary: {
          DEFAULT: '#2E7D32',
          container: '#A8DAB5',
          on: '#FFFFFF',
          'on-container': '#00210B',
        },
        // 시맨틱 색상
        expense: '#BA1A1A',
        income: '#2E7D32',
        asset: '#006A6A',
        // Surface
        surface: {
          DEFAULT: '#FDFDF5',
          container: '#EFEEE6',
          'container-high': '#E9E8E0',
          'container-highest': '#E3E3DB',
        },
        // Text
        'on-surface': {
          DEFAULT: '#1A1C19',
          variant: '#44483E',
        },
        // Outline
        outline: {
          DEFAULT: '#74796D',
          variant: '#C4C8BB',
        },
        // Error
        error: {
          DEFAULT: '#BA1A1A',
        },
        // 디자인 토큰 (Pencil 디자인 기반)
        sidebar: '#FAFBFA',
        separator: '#F5F5F3',
        'tab-bg': '#F5F6F5',
        'card-border': '#F0F0EC',
      },
      spacing: {
        xs: '4px',
        sm: '8px',
        md: '16px',
        lg: '24px',
        xl: '32px',
        xxl: '48px',
      },
      borderRadius: {
        xs: '4px',
        sm: '8px',
        md: '12px',
        lg: '16px',
        xl: '20px',
        pill: '9999px',
      },
      fontSize: {
        xs: ['12px', { lineHeight: '16px' }],
        sm: ['14px', { lineHeight: '20px' }],
        base: ['16px', { lineHeight: '24px' }],
        lg: ['18px', { lineHeight: '28px' }],
        xl: ['20px', { lineHeight: '28px' }],
        '2xl': ['24px', { lineHeight: '32px' }],
        '3xl': ['30px', { lineHeight: '36px' }],
      },
      keyframes: {
        progress: {
          '0%': { width: '0%', marginLeft: '0%' },
          '50%': { width: '70%', marginLeft: '0%' },
          '80%': { width: '90%', marginLeft: '0%' },
          '100%': { width: '90%', marginLeft: '0%' },
        },
      },
      animation: {
        progress: 'progress 2s ease-out forwards',
      },
    },
  },
  plugins: [],
};

export default config;
