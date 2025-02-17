drop table if exists public.profiles cascade;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;


drop table if exists public.storages cascade;
drop table if exists public.barcodes cascade;
drop table if exists public.items cascade;
drop table if exists public.categories cascade;
drop table if exists public.user_categories cascade;
drop table if exists public.user_barcodes cascade;


drop view public.user_storage_summary;



create table public.profiles (
  id uuid not null references auth.users on delete cascade,
  email TEXT,

  primary key (id)
);
alter table public.profiles enable row level security;




CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name text not null,
    UNIQUE(name) ,
    created_at TIMESTAMP DEFAULT now()
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,

) ;


CREATE TABLE storages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT now(),
    icon_id integer default 1,
    UNIQUE(user_id, name) -- Uživatel nemůže mít 2 sklady se stejným jménem
);

CREATE TABLE barcodes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    barcode TEXT UNIQUE NOT NULL,
    name TEXT default '', -- Např. "Polohrubá mouka"
    brand TEXT default '', -- Např. "Penny", "Albert"
    category_id UUID REFERENCES categories(id),
    package_size TEXT default '',
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE user_barcodes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    barcode TEXT UNIQUE NOT NULL,
    name TEXT default '', -- Např. "Polohrubá mouka"
    brand TEXT default '', -- Např. "Penny", "Albert"
    category_id UUID REFERENCES categories(id),
    package_size TEXT default '',
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    storage_id UUID REFERENCES storages(id) ON DELETE CASCADE,
    barcode_id UUID REFERENCES barcodes(id),
    quantity INT NOT NULL CHECK (quantity >= 0),
    expiration_date DATE, -- Volitelné
    created_at TIMESTAMP DEFAULT now()
);

ALTER TABLE storages ENABLE ROW LEVEL SECURITY;
CREATE POLICY user_can_access_own_storages
ON storages FOR ALL
USING (user_id = auth.uid());


ALTER TABLE items ENABLE ROW LEVEL SECURITY;
CREATE POLICY user_can_access_own_items
ON items FOR ALL
USING (user_id = auth.uid());

ALTER TABLE user_categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY user_can_access_own_items
ON user_categories FOR ALL
USING (user_id = auth.uid());

ALTER TABLE user_barcodes ENABLE ROW LEVEL SECURITY;
CREATE POLICY user_can_access_own_items
ON user_barcodes FOR ALL
USING (user_id = auth.uid());

ALTER TABLE barcodes disaBLE ROW LEVEL SECURITY;
CREATE POLICY user_can_access_all_items
ON public.barcodes FOR ALL;
USING (user_id = auth.uid());





CREATE OR REPLACE VIEW public.storage_summary with
(security_invoker = on) as
SELECT
    s.id AS storage_id,
    s.user_id,  -- Adding user_id to the SELECT statement
    SUM(i.quantity) AS total_quantity,
    c.id AS item_category,  -- Assuming category is now from categories table
    LOWER(TRIM(b.name)) AS normalized_item_name
FROM
    storages s
JOIN
    items i ON s.id = i.storage_id
JOIN
    barcodes b ON i.barcode_id = b.id
JOIN
    categories c ON b.category_id = c.id  -- Joining with categories table
GROUP BY
    s.id, s.user_id, c.id, LOWER(TRIM(b.name));

CREATE OR REPLACE VIEW public.storage_summary WITH
(security_invoker = on) AS
SELECT
    s.id AS storage_id,
    s.user_id,  -- Adding user_id to the SELECT statement
    SUM(i.quantity) AS total_quantity,
    c.id AS item_category,  -- Assuming category is now from categories table
    LOWER(TRIM(COALESCE(NULLIF(ub.name, ''), b.name))) AS normalized_item_name  -- Merged barcode name logic
FROM
    storages s
JOIN
    items i ON s.id = i.storage_id
JOIN
    barcodes b ON i.barcode_id = b.id
LEFT JOIN
    user_barcodes ub ON b.barcode = ub.barcode AND (ub.user_id = s.user_id OR s.user_id IS NULL)  -- Merging barcodes for user-specific data
JOIN
    categories c ON COALESCE(ub.category_id, b.category_id) = c.id  -- Use user barcode category if available
GROUP BY
    s.id, s.user_id, c.id, LOWER(TRIM(COALESCE(NULLIF(ub.name, ''), b.name)));  -- Normalizing the item name






drop function get_item_storage_counts;
CREATE OR REPLACE FUNCTION get_item_storage_counts(user_uuid UUID, barcode_selected UUID)
RETURNS TABLE(item_id UUID, storage_id UUID, barcode_id UUID, item_count BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        i.id,
        i.storage_id, 
        i.barcode_id, 
        SUM(i.quantity) AS item_count
    FROM items i
    JOIN barcodes b ON i.barcode_id = b.id
    WHERE i.user_id = user_uuid AND i.barcode_id = barcode_selected
    GROUP BY i.id, i.storage_id, i.barcode_id;
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS get_all_barcodes;
CREATE OR REPLACE FUNCTION get_all_barcodes(barcode_selected TEXT, user_uuid UUID DEFAULT NULL)
RETURNS TABLE (
    id UUID,
    barcode TEXT,
    name TEXT,
    brand TEXT,
    category_id UUID,
    package_size TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.id,
        b.barcode,
        COALESCE(NULLIF(ub.name, ''), b.name) AS name,  -- Use user_barcodes name if not empty
        COALESCE(NULLIF(ub.brand, ''), b.brand) AS brand,  -- Use user_barcodes brand if not empty
        COALESCE(NULLIF(ub.category_id, NULL), b.category_id) AS category_id,  -- Use user_barcodes category_id if not null
        COALESCE(NULLIF(ub.package_size, ''), b.package_size) AS package_size  -- Use user_barcodes package_size if not empty
    FROM 
        barcodes b
    LEFT JOIN 
        user_barcodes ub ON b.barcode = ub.barcode
    WHERE
        (ub.user_id = user_uuid OR user_uuid IS NULL)
        AND b.barcode = barcode_selected;
END;
$$ LANGUAGE plpgsql;




-- inserts a row into public.profiles
create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.raw_user_meta_data ->> 'email');
  return new;
end;
$$;

-- trigger the function every time a user is created
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


