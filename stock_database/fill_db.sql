-- Přidání uživatelů (simulujeme registraci přes Supabase Auth)
INSERT INTO users (id, email) VALUES
('11111111-1111-1111-1111-111111111111', 'alice@example.com'),
('22222222-2222-2222-2222-222222222222', 'bob@example.com');

-- Přidání skladů (každý uživatel si může vytvořit vlastní sklady)
INSERT INTO storages (id, user_id, name) VALUES
('aaaaaaa1-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'Lednička'),
('aaaaaaa2-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'Mrazák'),
('bbbbbbb1-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', 'Spíž');

-- Přidání čárových kódů a produktů
INSERT INTO barcodes (id, barcode, name, brand, category) VALUES
('ccccccc1-cccc-cccc-cccc-cccccccccccc', '8594003620010', 'Mléko 1,5%', 'Madeta', 'Mléčné výrobky'),
('ccccccc2-cccc-cccc-cccc-cccccccccccc', '8594003620027', 'Máslo 250g', 'Madeta', 'Mléčné výrobky'),
('ccccccc3-cccc-cccc-cccc-cccccccccccc', '8000500310427', 'Špagety 500g', 'Barilla', 'Těstoviny'),
('ccccccc4-cccc-cccc-cccc-cccccccccccc', '8594003620034', 'Rohlík', 'Pekařství U Krále', 'Pečivo');

-- Přidání položek do skladů uživatelů
INSERT INTO items (id, user_id, storage_id, barcode_id, quantity, expiration_date) VALUES
('ddddddd1-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111', 'aaaaaaa1-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'ccccccc1-cccc-cccc-cccc-cccccccccccc', 2, '2025-03-15'),
('ddddddd2-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111', 'aaaaaaa2-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'ccccccc2-cccc-cccc-cccc-cccccccccccc', 1, '2025-05-10'),
('ddddddd3-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111', 'aaaaaaa1-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'ccccccc3-cccc-cccc-cccc-cccccccccccc', 3, NULL),
('ddddddd4-dddd-dddd-dddd-dddddddddddd', '22222222-2222-2222-2222-222222222222', 'bbbbbbb1-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'ccccccc4-cccc-cccc-cccc-cccccccccccc', 10, '2025-02-20');
