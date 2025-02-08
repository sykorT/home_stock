
-- This script creates a PostgreSQL database schema for a home stock management system.

-- Enable the 'unaccent' extension if it is not already enabled.
CREATE EXTENSION IF NOT EXISTS unaccent;

-- Create the 'users' table to store user information.
-- Fields:
-- - id: Primary key, auto-incremented.
-- - email: Unique email address of the user.
-- - password_hash: Hashed password of the user.
-- - created_at: Timestamp of when the user was created, defaults to the current time.
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create the 'stocks' table to store stock information.
-- Fields:
-- - id: Primary key, auto-incremented.
-- - name: Name of the stock.
-- - created_at: Timestamp of when the stock was created, defaults to the current time.
CREATE TABLE stocks (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create the 'barcodes' table to store barcode information.
-- Fields:
-- - id: Primary key, auto-incremented.
-- - barcode: Unique barcode of the product.
-- - product_name: Name of the product.
-- - category: Category of the product.
-- - created_at: Timestamp of when the barcode was created, defaults to the current time.
CREATE TABLE barcodes (
    id SERIAL PRIMARY KEY,
    barcode TEXT UNIQUE NOT NULL,
    product_name TEXT NOT NULL,
    category TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create the 'items' table to store items in stock.
-- Fields:
-- - id: Primary key, auto-incremented.
-- - stock_id: Foreign key referencing the 'stocks' table, cascades on delete.
-- - barcode: Barcode referencing the 'barcodes' table, sets to NULL on delete.
-- - quantity: Quantity of the item, defaults to 1.
-- - expiration_date: Expiration date of the item.
-- - created_at: Timestamp of when the item was created, defaults to the current time.
CREATE TABLE items (
    id SERIAL PRIMARY KEY,
    stock_id INT REFERENCES stocks(id) ON DELETE CASCADE,
    barcode TEXT REFERENCES barcodes(barcode) ON DELETE SET NULL,
    quantity INT NOT NULL DEFAULT 1,
    expiration_date DATE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create a function 'add_missing_barcode' to add a new barcode to the 'barcodes' table if it does not already exist.
-- This function is triggered before inserting a new item into the 'items' table.
CREATE OR REPLACE FUNCTION add_missing_barcode()
RETURNS TRIGGER AS $$
BEGIN
    -- If the barcode is not NULL and does not exist in the 'barcodes' table, insert a new record.
    IF NEW.barcode IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM barcodes WHERE barcode = NEW.barcode
    ) THEN
        INSERT INTO barcodes (barcode, product_name, category, created_at)
        VALUES (NEW.barcode, NEW.name, NULL, NOW());
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger 'trigger_add_barcode' to execute the 'add_missing_barcode' function before inserting a new item into the 'items' table.
CREATE TRIGGER trigger_add_barcode
BEFORE INSERT ON items
FOR EACH ROW
EXECUTE FUNCTION add_missing_barcode();

-- Create a view 'aggregated_items' to aggregate item information.
-- The view normalizes product names by converting them to lowercase and removing accents.
-- It also calculates the total quantity and the nearest expiration date for each product.
CREATE VIEW aggregated_items AS
SELECT 
    unaccent(LOWER(b.product_name)) AS normalized_name,
    SUM(i.quantity) AS total_quantity,
    MIN(i.expiration_date) AS nearest_expiration
FROM items i
JOIN barcodes b ON i.barcode = b.barcode
GROUP BY normalized_name;
