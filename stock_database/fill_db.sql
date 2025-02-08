-- Vložení uživatelů
INSERT INTO users (email, password_hash) VALUES
('user1@example.com', 'hashedpassword1'),
('user2@example.com', 'hashedpassword2');

-- Vložení skladů (stocks)
INSERT INTO stocks (name) VALUES
('Lednička'),
('Mrazák'),
('Spíž');

-- Vložení čárových kódů (barcodes)
INSERT INTO barcodes (barcode, product_name, category) VALUES
('1234567890123', 'Mouka polohrubá', 'Mouka'),
('2345678901234', 'Mouka hladká', 'Mouka'),
('3456789012345', 'Mléko 1L', 'Mléčné výrobky'),
('4567890123456', 'Margarín', 'Margaríny'),
('5678901234567', 'Káva zrnková', 'Káva'),
('6789012345678', 'Rajčata konzervovaná', 'Zelenina'),
('7890123456789', 'Těstoviny', 'Pasta');

-- Vložení položek do skladů (items)
INSERT INTO items (stock_id, barcode, quantity, expiration_date) VALUES
(1, '1234567890123', 5, '2025-06-30'),
(1, '2345678901234', 3, '2025-06-30'),
(2, '3456789012345', 10, '2025-02-28'),
(1, '4567890123456', 2, '2025-04-15'),
(3, '5678901234567', 1, '2025-08-01'),
(3, '6789012345678', 8, '2026-01-01'),
(2, '7890123456789', 6, '2025-12-15');

-- Další vzorová data pro testování
INSERT INTO items (stock_id, barcode, quantity, expiration_date) VALUES
(2, '2345678901234', 4, '2025-06-30'),
(1, '3456789012345', 6, '2025-02-28'),
(3, '4567890123456', 1, '2025-04-15'),
(2, '5678901234567', 3, '2025-08-01'),
(3, '6789012345678', 12, '2026-01-01'),
(1, '7890123456789', 15, '2025-12-15');
