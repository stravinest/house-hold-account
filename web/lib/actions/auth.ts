'use server';

import { createClient } from '@/lib/supabase/server';
import { redirect } from 'next/navigation';

export async function signIn(formData: FormData) {
  const email = formData.get('email') as string;
  const password = formData.get('password') as string;

  if (!email || !password) {
    return { error: '이메일과 비밀번호를 입력하세요.' };
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });

  if (error) {
    if (error.message.includes('Invalid login credentials')) {
      return { error: '이메일 또는 비밀번호가 올바르지 않습니다.' };
    }
    if (error.message.includes('Email not confirmed')) {
      return { error: '이메일 인증을 완료해주세요.' };
    }
    return { error: error.message };
  }

  redirect('/dashboard');
}

export async function signUp(formData: FormData) {
  const email = formData.get('email') as string;
  const password = formData.get('password') as string;
  const confirmPassword = formData.get('confirm') as string;

  if (!email || !password) {
    return { error: '이메일과 비밀번호를 입력하세요.' };
  }

  if (password !== confirmPassword) {
    return { error: '비밀번호가 일치하지 않습니다.' };
  }

  if (password.length < 6) {
    return { error: '비밀번호는 6자 이상이어야 합니다.' };
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      emailRedirectTo: `${process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000'}/auth/callback`,
    },
  });

  if (error) {
    if (error.message.includes('already registered')) {
      return { error: '이미 가입된 이메일입니다.' };
    }
    return { error: error.message };
  }

  return { success: '인증 이메일을 발송했습니다. 이메일을 확인해주세요.' };
}

export async function signOut() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect('/login');
}

export async function signInWithGoogle() {
  const supabase = await createClient();
  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: `${process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000'}/auth/callback`,
    },
  });

  if (error) {
    return { error: error.message };
  }

  if (data.url) {
    redirect(data.url);
  }
}

export async function updatePassword(formData: FormData) {
  const password = formData.get('password') as string;
  const confirm = formData.get('confirm') as string;

  if (!password) {
    return { error: '새 비밀번호를 입력하세요.' };
  }

  if (password.length < 6) {
    return { error: '비밀번호는 6자 이상이어야 합니다.' };
  }

  if (password !== confirm) {
    return { error: '비밀번호가 일치하지 않습니다.' };
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.updateUser({ password });

  if (error) {
    if (error.message.includes('same_password')) {
      return { error: '기존 비밀번호와 동일합니다. 다른 비밀번호를 입력하세요.' };
    }
    return { error: error.message };
  }

  redirect('/dashboard');
}

export async function resetPassword(formData: FormData) {
  const email = formData.get('email') as string;

  if (!email) {
    return { error: '이메일을 입력하세요.' };
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.resetPasswordForEmail(email);

  if (error) {
    return { error: error.message };
  }

  return { success: '인증 코드를 발송했습니다.', email };
}

export async function verifyPasswordResetOtp(email: string, token: string) {
  if (!email || !token) {
    return { error: '이메일과 인증 코드를 입력하세요.' };
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.verifyOtp({
    type: 'recovery',
    email,
    token,
  });

  if (error) {
    if (error.message.includes('expired') || error.message.includes('Token')) {
      return { error: '코드가 만료되었습니다. 재전송해주세요.' };
    }
    return { error: '잘못된 코드입니다. 다시 확인해주세요.' };
  }

  return { success: true };
}
