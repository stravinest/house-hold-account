'use client';

import Link from 'next/link';
import { useActionState, useRef, useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { LockKeyhole, MailCheck } from 'lucide-react';
import { resetPassword, verifyPasswordResetOtp } from '@/lib/actions/auth';
import { Button, Input } from '@/components/ui';

const OTP_LENGTH = 8;

export default function ForgotPasswordPage() {
  const router = useRouter();
  const [step, setStep] = useState<'email' | 'otp'>('email');
  const [email, setEmail] = useState('');
  const [otp, setOtp] = useState<string[]>(Array(OTP_LENGTH).fill(''));
  const [otpError, setOtpError] = useState('');
  const [otpLoading, setOtpLoading] = useState(false);
  const [resendCooldown, setResendCooldown] = useState(0);
  const inputRefs = useRef<(HTMLInputElement | null)[]>([]);

  const [state, formAction, pending] = useActionState(
    async (_prevState: { error?: string; success?: string; email?: string } | null, formData: FormData) => {
      const result = await resetPassword(formData);
      if (result.success && result.email) {
        setEmail(result.email);
        setStep('otp');
        setResendCooldown(60);
      }
      return result;
    },
    null,
  );

  // 재전송 쿨다운 타이머
  useEffect(() => {
    if (resendCooldown <= 0) return;
    const timer = setInterval(() => {
      setResendCooldown((prev) => prev - 1);
    }, 1000);
    return () => clearInterval(timer);
  }, [resendCooldown]);

  // OTP 검증
  const handleVerifyOtp = useCallback(async (code: string) => {
    setOtpLoading(true);
    const result = await verifyPasswordResetOtp(email, code);
    if (result.error) {
      setOtpError(result.error);
      setOtp(Array(OTP_LENGTH).fill(''));
      inputRefs.current[0]?.focus();
      setOtpLoading(false);
    } else {
      router.push('/reset-password');
    }
  }, [email, router]);

  // OTP 입력 핸들러
  const handleOtpChange = useCallback((index: number, value: string) => {
    if (!/^\d*$/.test(value)) return;

    const newOtp = [...otp];
    newOtp[index] = value.slice(-1);
    setOtp(newOtp);
    setOtpError('');

    // 다음 칸으로 자동 포커스
    if (value && index < OTP_LENGTH - 1) {
      inputRefs.current[index + 1]?.focus();
    }

    // 모든 칸이 채워지면 자동 검증
    const code = newOtp.join('');
    if (code.length === OTP_LENGTH) {
      handleVerifyOtp(code);
    }
  }, [otp, handleVerifyOtp]);

  const handleOtpKeyDown = useCallback((index: number, e: React.KeyboardEvent) => {
    if (e.key === 'Backspace' && !otp[index] && index > 0) {
      inputRefs.current[index - 1]?.focus();
    }
  }, [otp]);

  const handleOtpPaste = useCallback((e: React.ClipboardEvent) => {
    e.preventDefault();
    const pasted = e.clipboardData.getData('text').replace(/\D/g, '').slice(0, OTP_LENGTH);
    if (!pasted) return;

    const newOtp = Array(OTP_LENGTH).fill('');
    for (let i = 0; i < pasted.length; i++) {
      newOtp[i] = pasted[i];
    }
    setOtp(newOtp);
    setOtpError('');

    if (pasted.length === OTP_LENGTH) {
      handleVerifyOtp(pasted);
    } else {
      inputRefs.current[pasted.length]?.focus();
    }
  }, [handleVerifyOtp]);

  const handleResend = async () => {
    if (resendCooldown > 0) return;
    const formData = new FormData();
    formData.set('email', email);
    const result = await resetPassword(formData);
    if (result.success) {
      setOtp(Array(OTP_LENGTH).fill(''));
      setOtpError('');
      setResendCooldown(60);
      inputRefs.current[0]?.focus();
    }
  };

  if (step === 'otp') {
    return (
      <div className='w-[480px] rounded-[20px] border border-black/[0.03] bg-white px-11 py-12 shadow-[0_8px_32px_rgba(0,0,0,0.03)]'>
        {/* Header */}
        <div className='mb-8 flex flex-col items-center gap-3'>
          <div className='flex h-12 w-12 items-center justify-center rounded-full bg-primary-container'>
            <MailCheck className='h-6 w-6 text-primary' />
          </div>
          <h1 className='text-2xl font-semibold text-on-surface'>인증 코드 입력</h1>
          <p className='text-center text-sm leading-[1.5] text-on-surface-variant'>
            아래 이메일로 전송된 코드를 입력하세요
          </p>
          <div className='rounded-lg bg-surface-container-highest px-4 py-2'>
            <span className='text-sm font-medium text-on-surface'>{email}</span>
          </div>
        </div>

        {/* OTP Error */}
        {otpError ? (
          <div className='mb-4 rounded-[10px] bg-red-50 p-3 text-sm text-expense'>
            {otpError}
          </div>
        ) : null}

        {/* OTP Input */}
        <div className='mb-2 flex justify-center gap-2' onPaste={handleOtpPaste}>
          {otp.map((digit, i) => (
            <input
              key={i}
              ref={(el) => { inputRefs.current[i] = el; }}
              type='text'
              inputMode='numeric'
              maxLength={1}
              value={digit}
              onChange={(e) => handleOtpChange(i, e.target.value)}
              onKeyDown={(e) => handleOtpKeyDown(i, e)}
              disabled={otpLoading}
              autoFocus={i === 0}
              className='h-12 w-10 rounded-lg border border-outline bg-surface-container-highest text-center text-lg font-semibold text-on-surface outline-none transition-colors focus:border-primary focus:ring-1 focus:ring-primary disabled:opacity-50'
            />
          ))}
        </div>

        {/* Verifying indicator */}
        {otpLoading ? (
          <p className='mb-4 text-center text-sm text-primary'>확인 중...</p>
        ) : null}

        {/* Expiry notice */}
        <p className='mb-6 text-center text-xs text-on-surface-variant'>
          코드는 1시간 동안 유효합니다
        </p>

        {/* Resend */}
        <div className='flex justify-center'>
          <button
            type='button'
            onClick={handleResend}
            disabled={resendCooldown > 0 || otpLoading}
            className='text-sm font-medium text-primary hover:underline disabled:cursor-not-allowed disabled:text-on-surface-variant disabled:no-underline'
          >
            {resendCooldown > 0 ? `재전송 (${resendCooldown}초 후 가능)` : '코드 재전송'}
          </button>
        </div>

        {/* Back */}
        <div className='mt-6 flex justify-center gap-4'>
          <button
            type='button'
            onClick={() => {
              setStep('email');
              setOtp(Array(OTP_LENGTH).fill(''));
              setOtpError('');
            }}
            className='text-[13px] text-on-surface-variant hover:underline'
          >
            이전 단계로
          </button>
          <Link href='/login' className='text-[13px] font-medium text-primary hover:underline'>
            로그인으로 돌아가기
          </Link>
        </div>
      </div>
    );
  }

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
          인증 코드를 보내드립니다
        </p>
      </div>

      {/* Messages */}
      {state?.error ? (
        <div className='mb-4 rounded-[10px] bg-red-50 p-3 text-sm text-expense'>
          {state.error}
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
          인증 코드 보내기
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
