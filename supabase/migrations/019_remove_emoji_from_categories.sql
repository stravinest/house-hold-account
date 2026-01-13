UPDATE categories
SET name = regexp_replace(name, '^[^\w\s가-힣]+\s*', '', 'g')
WHERE name ~ '^[^\w가-힣]';
