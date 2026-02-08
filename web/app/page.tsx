import Image from 'next/image';
import { Wallet, Users, BarChart3 } from 'lucide-react';
import { LinkWithProgress } from '@/components/ui/LinkWithProgress';

export default function Home() {
  return (
    <main className='min-h-screen bg-white'>
      {/* NavBar */}
      <nav className='flex items-center justify-between px-[120px] py-4'>
        <div className='flex items-center gap-2.5'>
          <Image
            src='/app_icon.png'
            alt='우생가계부'
            width={36}
            height={36}
            className='object-contain'
          />
        </div>
        <div className='flex items-center gap-6'>
          <a href='#features' className='text-[15px] font-medium text-on-surface-variant'>
            주요 기능
          </a>
          <LinkWithProgress
            href='/login'
            className='text-[15px] font-medium text-on-surface-variant'
          >
            로그인
          </LinkWithProgress>
        </div>
      </nav>

      {/* Hero Section */}
      <section
        className='flex flex-col items-center gap-10 px-[120px] py-20'
        style={{
          background: 'linear-gradient(180deg, #F0F7F1 0%, #FFFFFF 100%)',
        }}
      >
        <h1 className='text-center text-[56px] font-bold leading-[1.15] text-on-surface'>
          우리집 생활
          <br />
          공유가계부
        </h1>

        <p className='max-w-[550px] text-center text-lg leading-[1.6] text-on-surface-variant'>
          가족, 커플, 룸메이트를 위한 우생가계부.
          <br />
          실시간 동기화, 자동 수집, 강력한 통계까지.
        </p>

        {/* CTA Buttons */}
        <div className='flex items-center gap-4'>
          <LinkWithProgress
            href='/signup'
            loadingText='이동 중...'
            className='flex h-[52px] w-[180px] items-center justify-center rounded-md bg-primary text-base font-medium text-white transition-colors hover:bg-primary/90'
          >
            시작하기
          </LinkWithProgress>
          <LinkWithProgress
            href='/login'
            loadingText='이동 중...'
            className='flex h-[52px] w-[180px] items-center justify-center rounded-md border border-outline bg-transparent text-base font-medium text-primary transition-colors hover:bg-gray-50'
          >
            로그인
          </LinkWithProgress>
        </div>

        {/* Highlight Cards */}
        <div className='flex w-full justify-center gap-6'>
          <div className='flex w-[280px] flex-col items-center gap-3 rounded-lg bg-white p-6 shadow-[0_4px_20px_rgba(0,0,0,0.05)]'>
            <Wallet className='h-8 w-8 text-primary' />
            <h3 className='text-center text-base font-semibold text-on-surface'>
              스마트 수집
            </h3>
            <p className='text-center text-[13px] leading-[1.5] text-on-surface-variant'>
              SMS와 알림에서
              <br />
              거래 내역을 자동 수집
            </p>
          </div>

          <div className='flex w-[280px] flex-col items-center gap-3 rounded-lg bg-white p-6 shadow-[0_4px_20px_rgba(0,0,0,0.05)]'>
            <Users className='h-8 w-8 text-primary' />
            <h3 className='text-center text-base font-semibold text-on-surface'>
              실시간 공유
            </h3>
            <p className='text-center text-[13px] leading-[1.5] text-on-surface-variant'>
              가족, 룸메이트와
              <br />
              실시간으로 동기화
            </p>
          </div>

          <div className='flex w-[280px] flex-col items-center gap-3 rounded-lg bg-white p-6 shadow-[0_4px_20px_rgba(0,0,0,0.05)]'>
            <BarChart3 className='h-8 w-8 text-primary' />
            <h3 className='text-center text-base font-semibold text-on-surface'>
              강력한 통계
            </h3>
            <p className='text-center text-[13px] leading-[1.5] text-on-surface-variant'>
              카테고리별, 결제수단별
              <br />
              상세한 분석 제공
            </p>
          </div>
        </div>
      </section>

      {/* How It Works */}
      <section id='features' className='flex flex-col items-center gap-12 bg-white px-[120px] py-20'>
        <h2 className='text-center text-4xl font-bold text-on-surface'>
          이용 방법
        </h2>
        <p className='text-center text-lg text-on-surface-variant'>
          간단한 3단계로 시작하세요
        </p>

        <div className='flex w-full justify-center gap-8'>
          {/* Step 1 */}
          <div className='flex flex-1 flex-col items-center gap-4 p-8'>
            <div className='flex h-12 w-12 items-center justify-center rounded-full bg-primary text-lg font-bold text-white'>
              1
            </div>
            <h3 className='text-center text-lg font-semibold text-on-surface'>
              계정 만들기
            </h3>
            <p className='text-center text-sm leading-[1.6] text-on-surface-variant'>
              이메일 또는 Google로
              <br />
              간편하게 가입하세요.
            </p>
          </div>

          {/* Step 2 */}
          <div className='flex flex-1 flex-col items-center gap-4 p-8'>
            <div className='flex h-12 w-12 items-center justify-center rounded-full bg-primary text-lg font-bold text-white'>
              2
            </div>
            <h3 className='text-center text-lg font-semibold text-on-surface'>
              멤버 초대하기
            </h3>
            <p className='text-center text-sm leading-[1.6] text-on-surface-variant'>
              가족이나 룸메이트에게
              <br />
              가계부를 공유하세요.
            </p>
          </div>

          {/* Step 3 */}
          <div className='flex flex-1 flex-col items-center gap-4 p-8'>
            <div className='flex h-12 w-12 items-center justify-center rounded-full bg-primary text-lg font-bold text-white'>
              3
            </div>
            <h3 className='text-center text-lg font-semibold text-on-surface'>
              함께 기록하기
            </h3>
            <p className='text-center text-sm leading-[1.6] text-on-surface-variant'>
              거래를 기록하고 통계를
              <br />
              실시간으로 함께 확인하세요.
            </p>
          </div>
        </div>
      </section>

      {/* Final CTA */}
      <section className='flex flex-col items-center justify-center gap-8 bg-primary px-[120px] py-20'>
        <h2 className='text-center text-[40px] font-bold leading-[1.2] text-white'>
          지금 바로
          <br />
          우생가계부를 시작하세요
        </h2>
        <p className='text-center text-lg text-white/80'>
          수천 가구가 우생가계부와 함께 더 똑똑하게 돈을 관리하고 있습니다.
        </p>
        <div className='flex items-center gap-4'>
          <LinkWithProgress
            href='/signup'
            loadingText='이동 중...'
            className='flex h-[52px] items-center justify-center rounded-md bg-white px-8 py-4 text-base font-semibold text-primary transition-colors hover:bg-gray-100'
          >
            무료로 시작하기
          </LinkWithProgress>
          <a
            href='#features'
            className='flex h-[52px] items-center justify-center rounded-md border border-white/50 bg-transparent px-8 py-4 text-base font-medium text-white/[0.87] transition-colors hover:bg-white/10'
          >
            더 알아보기
          </a>
        </div>
      </section>

      {/* Footer */}
      <footer className='flex flex-col gap-8 bg-on-surface px-[120px] py-12'>
        <div className='flex w-full items-start justify-between'>
          <div className='flex flex-col gap-3'>
            <div className='flex items-center gap-2.5'>
              <Image
                src='/app_icon.png'
                alt='우생가계부'
                width={28}
                height={28}
                className='object-contain'
              />
              <span className='text-base font-bold text-white'>우생가계부</span>
            </div>
            <p className='text-[13px] text-white/50'>우리집 생활 공유가계부</p>
          </div>
          <div className='flex items-center gap-6'>
            <LinkWithProgress href='/terms' className='text-sm text-white/60 transition-colors hover:text-white'>
              이용약관
            </LinkWithProgress>
            <LinkWithProgress href='/privacy' className='text-sm text-white/60 transition-colors hover:text-white'>
              개인정보처리방침
            </LinkWithProgress>
            <a href='mailto:support@example.com' className='text-sm text-white/60 transition-colors hover:text-white'>
              고객지원
            </a>
          </div>
        </div>
        <div className='h-px w-full bg-white/[0.08]' />
        <p className='text-center text-xs text-white/[0.38]'>
          &copy; 2026 우생가계부. All rights reserved.
        </p>
      </footer>
    </main>
  );
}
