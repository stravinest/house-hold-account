'use client';

import Link from 'next/link';
import { useActionState } from 'react';
import { LockKeyhole } from 'lucide-react';
import { resetPassword } from '@/lib/actions/auth';
import { Button, Input } from '@/components/ui';

export default function ForgotPasswordPage() {
  const [state, formAction, pending] = useActionState(
    async (_prevState: { error?: string; success?: string } | null, formData: FormData) => {
      return await resetPassword(formData);
    },
    null,
  );

  return (
    <div className='w-[480px] rounded-[20px] border border-black/[0.03] bg-white px-11 py-12 shadow-[0_8px_32px_rgba(0,0,0,0.03)]'>
      {/* Header */}
      <div className='mb-8 flex flex-col items-center gap-3'>
        <div className='flex h-12 w-12 items-center justify-center rounded-full bg-primary-container'>
          <LockKeyhole className='h-6 w-6 text-primary' />
        </div>
        <h1 className='text-2xl font-semibold text-on-surface'>비밀번호 찾기</h1>
        <p className='text-center text-sm leading-[1.5] text-on-surface-variant'>
          가입한 이메일을 입력하면
          <br />
          비밀번호 재설정 링크를 보내드립니다
        </p>
      </div>

      {/* Messages */}
      {state?.error ? (
        <div className='mb-4 rounded-[10px] bg-red-50 p-3 text-sm text-expense'>
          {state.error}
        </div>
      ) : null}
      {state?.success ? (
        <div className='mb-4 rounded-[10px] bg-green-50 p-3 text-sm text-primary'>
          {state.success}
        </div>
      ) : null}

      {/* Form */}
      <form action={formAction} className='flex flex-col gap-5'>
        <Input
          id='email'
          name='email'
          type='email'
          label='이메일'
          placeholder='example@email.com'
          required
        />

        <Button type='submit' size='lg' loading={pending} className='w-full'>
          재설정 링크 보내기
        </Button>
      </form>

      {/* Back to login */}
      <div className='mt-8 flex justify-center'>
        <Link href='/login' className='text-[13px] font-medium text-primary hover:underline'>
          로그인으로 돌아가기
        </Link>
      </div>
    </div>
  );
}
