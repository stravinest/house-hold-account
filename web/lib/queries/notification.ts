import { createClient } from '@/lib/supabase/server';

export async function getNotificationSettings() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) return null;

  const { data } = await supabase
    .from('notification_settings')
    .select('*')
    .eq('user_id', user.id)
    .single();

  return data;
}

export async function updateNotificationSettings(settings: {
  transaction_alert?: boolean;
  budget_alert?: boolean;
  share_alert?: boolean;
  daily_summary?: boolean;
}) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) throw new Error('로그인이 필요합니다.');

  const { data, error } = await supabase
    .from('notification_settings')
    .upsert({
      user_id: user.id,
      ...settings,
    }, {
      onConflict: 'user_id',
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}
