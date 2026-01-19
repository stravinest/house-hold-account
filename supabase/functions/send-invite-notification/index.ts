// Supabase Edge Function: send-invite-notification
// 가계부 초대 관련 푸시 알림 발송 (초대 받음, 수락됨, 거부됨)
import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'jsr:@supabase/supabase-js@2';

// FCM HTTP v1 API endpoint
const FCM_URL = 'https://fcm.googleapis.com/v1/projects';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// 알림 타입: invite_received (초대 받음), invite_accepted (수락됨), invite_rejected (거부됨)
type NotificationType = 'invite_received' | 'invite_accepted' | 'invite_rejected';

interface InviteNotificationRequest {
  type?: NotificationType; // 기본값: invite_received
  target_user_id: string; // 알림 받을 사용자 ID
  actor_name: string; // 행동한 사용자 이름 (초대자 또는 초대받은 사람)
  ledger_name: string;
  // 하위 호환성을 위한 기존 필드
  invitee_user_id?: string;
  inviter_name?: string;
}

interface FcmSendResult {
  success: boolean;
  errorCode?: string;
  errorMessage?: string;
  shouldDeleteToken: boolean;
}

// Google OAuth2 access token 생성
async function getAccessToken(serviceAccount: {
  client_email: string;
  private_key: string;
  project_id: string;
}): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const exp = now + 3600;

  // JWT Header
  const header = {
    alg: 'RS256',
    typ: 'JWT',
  };

  // JWT Payload
  const payload = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: exp,
  };

  // Base64URL encode
  const encoder = new TextEncoder();
  const headerB64 = btoa(JSON.stringify(header))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');
  const payloadB64 = btoa(JSON.stringify(payload))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');

  const signInput = `${headerB64}.${payloadB64}`;

  // Import private key and sign
  const pemContents = serviceAccount.private_key
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\n/g, '');

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
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');

  const jwt = `${signInput}.${signatureB64}`;

  // Exchange JWT for access token
  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const tokenData = await tokenResponse.json();
  return tokenData.access_token;
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
          const invalidTokenCodes = ['UNREGISTERED', 'INVALID_ARGUMENT', 'NOT_FOUND'];
          const errorDetails = errorJson.error.details || [];

          for (const detail of errorDetails) {
            if (detail['@type']?.includes('ErrorInfo') && invalidTokenCodes.includes(detail.reason)) {
              shouldDeleteToken = true;
              errorCode = detail.reason;
              break;
            }
          }

          if (errorJson.error.status === 'NOT_FOUND' || errorJson.error.status === 'INVALID_ARGUMENT') {
            shouldDeleteToken = true;
          }
        }
      } catch {
        // JSON 파싱 실패 시 무시
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

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const firebaseServiceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');

    if (!firebaseServiceAccountJson) {
      console.error('FIREBASE_SERVICE_ACCOUNT not configured');
      return new Response(
        JSON.stringify({ error: 'Firebase not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);
    const firebaseServiceAccount = JSON.parse(firebaseServiceAccountJson);

    const requestBody: InviteNotificationRequest = await req.json();

    const notificationType: NotificationType = requestBody.type || 'invite_received';
    const targetUserId = requestBody.target_user_id || requestBody.invitee_user_id;
    const actorName = requestBody.actor_name || requestBody.inviter_name;
    const ledgerName = requestBody.ledger_name;

    console.log(`Processing ${notificationType} notification for user: ${targetUserId}`);
    console.log(`Actor: ${actorName}, Ledger: ${ledgerName}`);

    if (!targetUserId || !actorName || !ledgerName) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const settingsColumn = notificationType === 'invite_received'
      ? 'invite_received_enabled'
      : 'invite_accepted_enabled';

    const { data: settings, error: settingsError } = await supabase
      .schema('house')
      .from('notification_settings')
      .select(settingsColumn)
      .eq('user_id', targetUserId)
      .single();

    if (settingsError) {
      console.error('Settings query error:', settingsError);
    }

    const isEnabled = settings?.[settingsColumn] ?? true;
    if (!isEnabled) {
      console.log(`User has disabled ${notificationType} notifications`);
      return new Response(
        JSON.stringify({ message: `User has disabled ${notificationType} notifications` }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const { data: tokens, error: tokensError } = await supabase
      .schema('house')
      .from('fcm_tokens')
      .select('token')
      .eq('user_id', targetUserId);

    if (tokensError) {
      console.error('Tokens query error:', tokensError);
      return new Response(
        JSON.stringify({ error: 'Failed to query tokens' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (!tokens || tokens.length === 0) {
      console.log('No FCM tokens found for user');
      return new Response(
        JSON.stringify({ message: 'No FCM tokens found for user' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const accessToken = await getAccessToken(firebaseServiceAccount);

    let notificationTitle: string;
    let notificationBody: string;

    switch (notificationType) {
      case 'invite_accepted':
        notificationTitle = '초대 수락됨';
        notificationBody = `${actorName}님이 '${ledgerName}' 가계부 초대를 수락했습니다.`;
        break;
      case 'invite_rejected':
        notificationTitle = '초대 거절됨';
        notificationBody = `${actorName}님이 '${ledgerName}' 가계부 초대를 거절했습니다.`;
        break;
      case 'invite_received':
      default:
        notificationTitle = '가계부 초대';
        notificationBody = `${actorName}님이 '${ledgerName}' 가계부로 초대했습니다.`;
        break;
    }

    const results: { token: string; success: boolean; errorCode?: string }[] = [];
    const tokensToDelete: string[] = [];

    console.log(`Sending notifications to ${tokens.length} token(s)`);

    for (const tokenData of tokens) {
      const result = await sendFcmMessage(
        accessToken,
        firebaseServiceAccount.project_id,
        tokenData.token,
        notificationTitle,
        notificationBody,
        {
          type: notificationType,
          actor_name: actorName,
          ledger_name: ledgerName,
        }
      );

      results.push({
        token: tokenData.token.substring(0, 30) + '...',
        success: result.success,
        errorCode: result.errorCode,
      });

      if (result.shouldDeleteToken) {
        tokensToDelete.push(tokenData.token);
        console.log(`Token marked for deletion: ${tokenData.token.substring(0, 30)}... (reason: ${result.errorCode})`);
      }
    }

    // 6. 유효하지 않은 토큰 삭제
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

    const successCount = results.filter((r) => r.success).length;
    if (successCount > 0) {
      const { error: insertError } = await supabase
        .schema('house')
        .from('push_notifications')
        .insert({
          user_id: targetUserId,
          type: notificationType,
          title: notificationTitle,
          body: notificationBody,
          data: { actor_name: actorName, ledger_name: ledgerName },
        });

      if (insertError) {
        console.error('Failed to save notification record:', insertError);
      }
    }

    const failCount = results.filter((r) => !r.success).length;
    console.log(`Push notification results: ${successCount} success, ${failCount} failed`, JSON.stringify(results));

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Notification sent',
        tokens_count: tokens.length,
        results: results,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error:', error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : 'Unknown error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
