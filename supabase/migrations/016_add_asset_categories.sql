INSERT INTO categories (ledger_id, name, type, icon, color, is_default, sort_order, created_at)
SELECT 
  l.id,
  c.name,
  'asset',
  c.icon,
  c.color,
  true,
  c.sort_order,
  NOW()
FROM ledgers l
CROSS JOIN (
  VALUES 
    ('정기예금', 'savings', '#4CAF50', 1),
    ('적금', 'account_balance', '#66BB6A', 2),
    ('주식', 'trending_up', '#2196F3', 3),
    ('펀드', 'pie_chart', '#1976D2', 4),
    ('부동산', 'home', '#FF9800', 5),
    ('암호화폐', 'currency_bitcoin', '#FFC107', 6),
    ('기타 자산', 'wallet', '#9E9E9E', 7)
) AS c(name, icon, color, sort_order)
WHERE NOT EXISTS (
  SELECT 1 FROM categories 
  WHERE categories.ledger_id = l.id 
  AND categories.name = c.name 
  AND categories.type = 'asset'
);
