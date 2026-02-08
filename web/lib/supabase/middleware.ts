import { createServerClient } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';

export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({
    request,
  });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet: { name: string; value: string; options?: Record<string, unknown> }[]) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          );
          supabaseResponse = NextResponse.next({
            request,
          });
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          );
        },
      },
    }
  );

  // 세션 갱신
  const {
    data: { user },
  } = await supabase.auth.getUser();

  // 루트 경로에 code 파라미터가 있으면 /auth/callback으로 포워딩
  // (모바일 앱에서 보낸 비밀번호 재설정 이메일을 웹에서 열었을 때 발생)
  if (request.nextUrl.pathname === '/' && request.nextUrl.searchParams.has('code')) {
    const url = request.nextUrl.clone();
    const code = url.searchParams.get('code');
    url.pathname = '/auth/callback';
    url.searchParams.set('code', code!);
    // 모바일에서 보낸 링크는 type 정보가 없으므로 recovery로 간주
    if (!url.searchParams.has('type')) {
      url.searchParams.set('type', 'recovery');
    }
    return NextResponse.redirect(url);
  }

  // 공개 경로 목록 (인증 불필요)
  const publicPaths = [
    '/',
    '/login',
    '/signup',
    '/forgot-password',
    '/reset-password',
    '/terms',
    '/privacy',
    '/auth/callback',
  ];

  const isPublicPath = publicPaths.some(
    (path) => request.nextUrl.pathname === path
  );

  // 인증되지 않은 사용자가 보호된 경로 접근 시 로그인으로 리다이렉트
  if (!user && !isPublicPath) {
    const url = request.nextUrl.clone();
    url.pathname = '/login';
    return NextResponse.redirect(url);
  }

  // 인증된 사용자가 인증 페이지 접근 시 대시보드로 리다이렉트
  if (user && (request.nextUrl.pathname === '/login' || request.nextUrl.pathname === '/signup')) {
    const url = request.nextUrl.clone();
    url.pathname = '/dashboard';
    return NextResponse.redirect(url);
  }

  return supabaseResponse;
}
