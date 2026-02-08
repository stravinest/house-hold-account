'use client';

import Link from 'next/link';
import { useActionState } from 'react';
import { updatePassword } from '@/lib/actions/auth';
import { Button, Input } from '@/components/ui';

export default function ResetPasswordPage() {
  const [state, formAction, pending] = useActionState(
    async (_prevState: { error?: string; success?: string } | null, formData: FormData) => {
      return await updatePassword(formData);
    },
    null,
  );

  return (
    <div className='w-full max-w-md rounded-2xl bg-white p-12 shadow-sm'>
      {/* Header */}
      <div className='mb-8 flex flex-col items-center gap-3'>
        <div className='flex h-20 w-20 items-center justify-center rounded-full bg-green-50'>
          <svg
            xmlns='http://www.w3.org/2000/svg'
            fill='none'
            viewBox='0 0 24 24'
            strokeWidth={1.5}
            stroke='currentColor'
            className='h-10 w-10 text-primary'
          >
            <path
              strokeLinecap='round'
              strokeLinejoin='round'
              d='M16.5 10.5V6.75a4.5 4.5 0 1 0-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 0 0 2.25-2.25v-6.75a2.25 2.25 0 0 0-2.25-2.25H6.75a2.25 2.25 0 0 0-2.25 2.25v6.75a2.25 2.25 0 0 0 2.25 2.25Z'
            />
          </svg>
        </div>
        <h1 className='text-3xl font-bold text-primary'>새 비밀번호 설정</h1>
        <p className='text-center text-sm text-gray-600'>
          새로운 비밀번호를 입력해주세요
        </p>
      </div>

      {/* Messages */}
      {state?.error ? (
        <div className='mb-4 rounded-lg bg-red-50 p-3 text-sm text-expense'>
          {state.error}
        </div>
      ) : null}

      {/* Form */}
      <form action={formAction} className='flex flex-col gap-4'>
        <Input
          id='password'
          name='password'
          type='password'
          label='새 비밀번호'
          placeholder='6자 이상 입력하세요'
          required
          minLength={6}
        />

        <Input
          id='confirm'
          name='confirm'
          type='password'
          label='비밀번호 확인'
          placeholder='비밀번호를 다시 입력하세요'
          required
          minLength={6}
        />

        <Button type='submit' size='lg' loading={pending}>
          비밀번호 변경
        </Button>
      </form>

      {/* Back to login */}
      <div className='mt-6 flex justify-center'>
        <Link href='/login' className='text-sm font-semibold text-primary hover:underline'>
          로그인으로 돌아가기
        </Link>
      </div>
    </div>
  );
}
