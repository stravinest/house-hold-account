'use client';

import Link from 'next/link';
import Image from 'next/image';
import { useActionState } from 'react';
import { signIn, signInWithGoogle } from '@/lib/actions/auth';
import { Button, Input } from '@/components/ui';

export default function LoginPage() {
  const [state, formAction, pending] = useActionState(
    async (_prevState: { error?: string } | null, formData: FormData) => {
      return await signIn(formData);
    },
    null,
  );

  return (
    <div className='w-[480px] rounded-[20px] border border-black/[0.03] bg-white px-11 py-12 shadow-[0_8px_32px_rgba(0,0,0,0.03)]'>
      {/* Logo Section */}
      <div className='mb-8 flex flex-col items-center gap-3'>
        <Image
          src='/app_icon.png'
          alt='우생가계부'
          width={48}
          height={48}
          className='object-contain'
        />
        <h1 className='text-2xl font-semibold text-on-surface'>우생가계부</h1>
        <p className='text-center text-sm text-on-surface-variant'>우리집 생활 공유가계부</p>
      </div>

      {/* Error */}
      {state?.error ? (
        <div className='mb-4 rounded-[10px] bg-red-50 p-3 text-sm text-expense'>
          {state.error}
        </div>
      ) : null}

      {/* Form Section */}
      <form action={formAction} className='flex flex-col gap-5'>
        <Input
          id='email'
          name='email'
          type='email'
          label='이메일'
          placeholder='email@example.com'
          required
        />

        <Input
          id='password'
          name='password'
          type='password'
          label='비밀번호'
          placeholder='비밀번호를 입력하세요'
          required
        />

        <div className='flex justify-end'>
          <Link href='/forgot-password' className='text-[13px] font-medium text-primary hover:underline'>
            비밀번호 찾기
          </Link>
        </div>

        <Button type='submit' size='lg' loading={pending} className='w-full'>
          로그인
        </Button>
      </form>

      {/* Divider */}
      <div className='my-8 flex items-center gap-4'>
        <div className='h-px flex-1 bg-[#EEEEEE]' />
        <span className='text-xs text-[#B0B0B0]'>또는</span>
        <div className='h-px flex-1 bg-[#EEEEEE]' />
      </div>

      {/* Google Login */}
      <form action={async () => { void signInWithGoogle(); }}>
        <Button type='submit' variant='secondary' size='lg' className='w-full'>
          Google로 계속하기
        </Button>
      </form>

      {/* Signup Link */}
      <div className='mt-8 flex justify-center gap-1 text-[13px]'>
        <span className='text-[#AAAAAA]'>계정이 없으신가요?</span>
        <Link href='/signup' className='font-semibold text-primary hover:underline'>
          회원가입
        </Link>
      </div>
    </div>
  );
}
