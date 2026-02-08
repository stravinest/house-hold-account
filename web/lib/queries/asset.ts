import { createClient } from '@/lib/supabase/server';

export async function getAssets(ledgerId: string) {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from('transactions')
    .select('*, categories(name, icon, color)')
    .eq('ledger_id', ledgerId)
    .eq('is_asset', true)
    .order('date', { ascending: false });

  if (error) throw error;
  return data || [];
}

export async function getAssetSummary(ledgerId: string) {
  const assets = await getAssets(ledgerId);

  const totalAsset = assets.reduce((sum, a) => sum + a.amount, 0);

  // 카테고리별 그룹화
  const byCategory: Record<string, { name: string; total: number; count: number }> = {};
  for (const asset of assets) {
    const catName = (asset as any).categories?.name || '기타';
    if (!byCategory[catName]) {
      byCategory[catName] = { name: catName, total: 0, count: 0 };
    }
    byCategory[catName].total += asset.amount;
    byCategory[catName].count += 1;
  }

  return {
    totalAsset,
    categories: Object.values(byCategory),
    assets,
  };
}
