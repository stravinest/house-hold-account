// Supabase Edge Function: send-push-notification
// 트랜잭션 생성/수정/삭제 시 공유 가계부 멤버에게 푸시 알림 발송
import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// FCM HTTP v1 API endpoint
const FCM_URL = 'https://fcm.googleapis.com/v1/projects';

interface WebhookPayload {
  type: 'INSERT' | 'UPDATE' | 'DELETE';
  table: string;
  schema: string;
  record: TransactionRecord | null;
  old_record: TransactionRecord | null;
}

interface TransactionRecord {
  id: string;
  ledger_id: string;
  user_id: string;
  amount: number;
  type: string;
  title: string | null;
  date: string;
}

interface FcmToken {
  token: string;
  user_id: string;
}

interface NotificationSettings {
  user_id: string;
  shared_ledger_change_enabled: boolean;
}

// Google OAuth2 access token 생성
async function getAccessToken(serviceAccount: {
  client_email: string;
  private_key: string;
  project_id: string;
}): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const exp = now + 3600;

  const header = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: exp,
  };

  const encoder = new TextEncoder();

  const toBase64Url = (obj: any) => {
    const json = JSON.stringify(obj);
    const latin1 = encodeURIComponent(json).replace(/%([0-9A-F]{2})/g, (_, p1) =>
      String.fromCharCode(parseInt(p1, 16))
    );
    return btoa(latin1).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
  };

  const headerB64 = toBase64Url(header);
  const payloadB64 = toBase64Url(payload);
  const signInput = `${headerB64}.${payloadB64}`;

  const pemContents = serviceAccount.private_key
    .replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\n/g, '');
  const binaryKey = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryKey,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    encoder.encode(signInput)
  );

  const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');

  const jwt = `${signInput}.${signatureB64}`;

  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const tokenData = await tokenResponse.json();
  if (!tokenData.access_token) {
    throw new Error(`Failed to get access token: ${JSON.stringify(tokenData)}`);
  }
  return tokenData.access_token;
}

interface FcmSendResult {
  success: boolean;
  errorCode?: string;
  errorMessage?: string;
  shouldDeleteToken: boolean;
}

// FCM 메시지 발송
async function sendFcmMessage(
  accessToken: string,
  projectId: string,
  token: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<FcmSendResult> {
  try {
    console.log(`Sending FCM to token: ${token.substring(0, 30)}...`);

    const response = await fetch(`${FCM_URL}/${projectId}/messages:send`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token: token,
          notification: {
            title: title,
            body: body,
          },
          data: data || {},
          android: {
            priority: 'high',
            notification: {
              channel_id: 'household_account_channel',
              sound: 'default',
            },
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
                badge: 1,
              },
            },
          },
        },
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`FCM send error (${response.status}):`, errorText);

      let errorCode = 'UNKNOWN';
      let errorMessage = errorText;
      let shouldDeleteToken = false;

      try {
        const errorJson = JSON.parse(errorText);
        if (errorJson.error) {
          errorCode = errorJson.error.code || errorJson.error.status || 'UNKNOWN';
          errorMessage = errorJson.error.message || errorText;

          // FCM 에러 코드에 따라 토큰 삭제 여부 결정
          // UNREGISTERED: 앱이 제거되거나 재설치됨
          // INVALID_ARGUMENT: 토큰 형식이 잘못됨
          // NOT_FOUND: 토큰이 존재하지 않음
          const invalidTokenCodes = ['UNREGISTERED', 'INVALID_ARGUMENT', 'NOT_FOUND'];
          const errorDetails = errorJson.error.details || [];

          for (const detail of errorDetails) {
            if (detail['@type']?.includes('ErrorInfo') && invalidTokenCodes.includes(detail.reason)) {
              shouldDeleteToken = true;
              errorCode = detail.reason;
              break;
            }
          }

          // status 코드로도 체크
          if (errorJson.error.status === 'NOT_FOUND' || errorJson.error.status === 'INVALID_ARGUMENT') {
            shouldDeleteToken = true;
          }
        }
      } catch {

      }

      console.error(`FCM error details - code: ${errorCode}, shouldDelete: ${shouldDeleteToken}, message: ${errorMessage}`);

      return {
        success: false,
        errorCode,
        errorMessage,
        shouldDeleteToken,
      };
    }

    console.log(`FCM send success for token: ${token.substring(0, 30)}...`);
    return {
      success: true,
      shouldDeleteToken: false,
    };
  } catch (error) {
    console.error('FCM send exception:', error);
    return {
      success: false,
      errorCode: 'EXCEPTION',
      errorMessage: error instanceof Error ? error.message : 'Unknown exception',
      shouldDeleteToken: false,
    };
  }
}

// 알림 메시지 생성
function createNotificationMessage(
  payload: WebhookPayload,
  userName: string
): { title: string; body: string } {
  const record = payload.record || payload.old_record;
  const amount = record?.amount || 0;
  const formattedAmount = new Intl.NumberFormat('ko-KR').format(amount);
  const transactionType = record?.type === 'expense' ? '지출' : record?.type === 'income' ? '수입' : '거래';
  const transactionTitle = record?.title || transactionType;

  switch (payload.type) {
    case 'INSERT':
      return {
        title: '공유 가계부 변경',
        body: `${userName}님이 ${transactionTitle} ${formattedAmount}원을 추가했습니다.`,
      };
    case 'UPDATE':
      return {
        title: '공유 가계부 변경',
        body: `${userName}님이 ${transactionTitle}을 수정했습니다.`,
      };
    case 'DELETE':
      return {
        title: '공유 가계부 변경',
        body: `${userName}님이 ${transactionTitle}을 삭제했습니다.`,
      };
    default:
      return {
        title: '공유 가계부 변경',
        body: '가계부가 변경되었습니다.',
      };
  }
}

Deno.serve(async (req: Request) => {
  try {
    // CORS preflight
    if (req.method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
      });
    }

    // Parse webhook payload
    const payload: WebhookPayload = await req.json();
    console.log('Received webhook:', JSON.stringify(payload));

    // 유효성 검증
    const record = payload.record || payload.old_record;
    if (!record) {
      return new Response(JSON.stringify({ error: 'No record found' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // 환경 변수
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const firebaseServiceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');

    if (!firebaseServiceAccountJson) {
      console.error('FIREBASE_SERVICE_ACCOUNT not configured');
      return new Response(JSON.stringify({ error: 'Firebase not configured' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const firebaseServiceAccount = JSON.parse(firebaseServiceAccountJson);
    const supabase = createClient(supabaseUrl, supabaseKey);

    // 1. 가계부가 공유 가계부인지 확인 (멤버가 2명 이상)
    const { data: members, error: membersError } = await supabase
      .schema('house')
      .from('ledger_members')
      .select('user_id')
      .eq('ledger_id', record.ledger_id);

    if (membersError) {
      console.error('Members query error:', membersError);
      return new Response(JSON.stringify({ error: 'Failed to query members' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // 공유 가계부가 아니면 종료 (멤버가 1명 이하)
    if (!members || members.length <= 1) {
      console.log('Not a shared ledger, skipping notification');
      return new Response(JSON.stringify({ message: 'Not a shared ledger' }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // 2. 트랜잭션 생성자 정보 가져오기
    const { data: creator, error: creatorError } = await supabase
      .schema('house')
      .from('profiles')
      .select('display_name')
      .eq('id', record.user_id)
      .single();

    if (creatorError) {
      console.error('Creator query error:', creatorError);
    }

    const creatorName = creator?.display_name || '멤버';

    // 3. 알림 대상 (생성자 제외한 다른 멤버들)
    const targetUserIds = (members as any[])
      .map((m: any) => m.user_id)
      .filter((id: string) => id !== record.user_id);

    if (targetUserIds.length === 0) {
      console.log('No other members to notify');
      return new Response(JSON.stringify({ message: 'No targets' }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // 4. 알림 설정 확인 (shared_ledger_change_enabled = true인 사용자만)
    const { data: settings, error: settingsError } = await supabase
      .schema('house')
      .from('notification_settings')
      .select('user_id, shared_ledger_change_enabled')
      .in('user_id', targetUserIds)
      .eq('shared_ledger_change_enabled', true);

    if (settingsError) {
      console.error('Settings query error:', settingsError);
      return new Response(JSON.stringify({ error: 'Failed to query settings' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    if (!settings || settings.length === 0) {
      console.log('No users with notifications enabled');
      return new Response(JSON.stringify({ message: 'No enabled users' }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const enabledUserIds = (settings as any[]).map((s: any) => s.user_id);

    // 5. FCM 토큰 조회
    const { data: tokens, error: tokensError } = await supabase
      .schema('house')
      .from('fcm_tokens')
      .select('token, user_id')
      .in('user_id', enabledUserIds);

    if (tokensError) {
      console.error('Tokens query error:', tokensError);
      return new Response(JSON.stringify({ error: 'Failed to query tokens' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    if (!tokens || tokens.length === 0) {
      console.log('No FCM tokens found');
      return new Response(JSON.stringify({ message: 'No tokens' }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // 6. FCM access token 발급
    const accessToken = await getAccessToken(firebaseServiceAccount);

    const { title, body } = createNotificationMessage(payload, creatorName);
    const results: { token: string; userId: string; success: boolean; errorCode?: string }[] = [];
    const tokensToDelete: string[] = [];

    console.log(`Sending notifications to ${tokens.length} token(s)`);

    for (const tokenData of tokens) {
      const result = await sendFcmMessage(
        accessToken,
        firebaseServiceAccount.project_id,
        tokenData.token,
        title,
        body,
        {
          type: 'shared_ledger_change',
          ledger_id: record.ledger_id,
          transaction_id: record.id,
          creator_user_id: record.user_id,
        }
      );

      results.push({
        token: tokenData.token.substring(0, 30) + '...',
        userId: tokenData.user_id,
        success: result.success,
        errorCode: result.errorCode,
      });

      if (result.shouldDeleteToken) {
        tokensToDelete.push(tokenData.token);
        console.log(`Token marked for deletion: ${tokenData.token.substring(0, 30)}... (reason: ${result.errorCode})`);
      }
    }

    if (tokensToDelete.length > 0) {
      console.log(`Deleting ${tokensToDelete.length} invalid token(s)`);
      for (const token of tokensToDelete) {
        const { error: deleteError } = await supabase
          .schema('house')
          .from('fcm_tokens')
          .delete()
          .eq('token', token);

        if (deleteError) {
          console.error(`Failed to delete token: ${deleteError.message}`);
        } else {
          console.log(`Deleted invalid token: ${token.substring(0, 30)}...`);
        }
      }
    }

    // 7. 알림 기록 저장 (성공적으로 전송된 사용자별로 한 번씩만)
    const successfulUserIds = new Set<string>();
    for (const result of results) {
      if (result.success) {
        successfulUserIds.add(result.userId);
      }
    }

    console.log(`Saving notification records for ${successfulUserIds.size} unique user(s)`);

    for (const userId of successfulUserIds) {
      const { error: insertError } = await supabase.schema('house').from('push_notifications').insert({
        user_id: userId,
        type: 'shared_ledger_change',
        title: title,
        body: body,
        data: {
          ledger_id: record.ledger_id,
          transaction_id: record.id,
          action: payload.type,
        },
      });

      if (insertError) {
        console.error(`Failed to save notification record for user ${userId}:`, insertError);
      }
    }

    const successCount = results.filter(r => r.success).length;
    const failCount = results.filter(r => !r.success).length;
    console.log(`Push notification results: ${successCount} success, ${failCount} failed`, JSON.stringify(results));

    return new Response(
      JSON.stringify({
        message: 'Notifications sent',
        results: results,
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    console.error('Edge function error:', error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : 'Unknown error' }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }
});
