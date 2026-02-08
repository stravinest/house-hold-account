import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';
import { NavigationProvider } from '@/components/ui/NavigationProgress';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: '우생가계부 - 우리집 생활 공유가계부',
  description: '가족, 커플, 룸메이트를 위한 우생가계부. 실시간 동기화, 자동 수집, 강력한 통계까지.',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang='ko'>
      <body className={`${inter.className} antialiased`}>
        <NavigationProvider>{children}</NavigationProvider>
      </body>
    </html>
  );
}
