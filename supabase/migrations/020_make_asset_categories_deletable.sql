-- Make asset categories deletable by users

UPDATE categories 
SET is_default = false 
WHERE type = 'asset' 
AND is_default = true;
