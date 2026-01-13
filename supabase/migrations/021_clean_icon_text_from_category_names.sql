UPDATE categories
SET 
  name = TRIM(
    regexp_replace(
      name, 
      '^(pie_chart|currency_bitcoin|home|wallet|trending_up|savings|account_balance|save)\s+', 
      '', 
      'gi'
    )
  ),
  icon = ''
WHERE type = 'asset'
AND (
  name ~ '^(pie_chart|currency_bitcoin|home|wallet|trending_up|savings|account_balance|save)\s+'
  OR icon IS NOT NULL
);
