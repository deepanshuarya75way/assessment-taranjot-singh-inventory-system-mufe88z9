-- ============================================================
-- Inventory & Order Management System — initial schema
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ------------------------------------------------------------
-- customers
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customers (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name   VARCHAR(255) NOT NULL,
    email       VARCHAR(255) NOT NULL UNIQUE,
    phone       VARCHAR(50),
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);

-- ------------------------------------------------------------
-- products
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS products (
    id          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(255)  NOT NULL,
    sku         VARCHAR(100)  NOT NULL UNIQUE,
    price       NUMERIC(10,2) NOT NULL,
    quantity    INTEGER       NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_products_sku ON products(sku);

-- ------------------------------------------------------------
-- locations
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS locations (
    id          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(255)  NOT NULL,
    type        VARCHAR(50)   NOT NULL,
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_locations_type ON locations(type);

-- ------------------------------------------------------------
-- inventory
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS inventory (
    id          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    produt_id   UUID          NOT NULL      REFERENCES products(id)     ON DELETE CASCADE,
    location_id UUID          NOT NULL      REFERENCES locations(id)     ON DELETE CASCADE,
    quantity    INTEGER       NOT NULL      DEFAULT 0,
    CONSTRAINT chk_inventory_product_location       UNIQUE(product_id,location_id),
    CONSTRAINT chk_inventory_quantity_non_negative  CHECK(quantity >=0 ),
);
CREATE INDEX IF NOT EXISTS idx_inventory_locations_id ON inventory(locations_id);
CREATE INDEX IF NOT EXISTS idx_inventory_product_id ON inventory(product_id);

-- ------------------------------------------------------------
-- orders
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS orders (
    id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id   UUID          NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    total_amount  NUMERIC(12,2) NOT NULL DEFAULT 0,
    status        VARCHAR(20)   NOT NULL DEFAULT 'pending',
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);

-- ------------------------------------------------------------
-- order_items
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS order_items (
    id          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id    UUID          NOT NULL REFERENCES orders(id)   ON DELETE CASCADE,
    product_id  UUID          NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    quantity    INTEGER       NOT NULL,
    unit_price  NUMERIC(10,2) NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id   ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);

-- ------------------------------------------------------------
-- order_item_allocations
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS order_item_allocations (
    id          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    order_item_id    UUID          NOT NULL REFERENCES orders(id)   ON DELETE CASCADE,
    location_id  UUID          NOT NULL REFERENCES locations(id) ON DELETE RESTRICT,
    quantity    INTEGER       NOT NULL,
    CONSTRAINT chk_allocation_quantity_positive CHECK (quantity > 0)
);
CREATE INDEX IF NOT EXISTS idx_allocations_order_item_id   ON order_item_allocations(order_item_id);
CREATE INDEX IF NOT EXISTS idx_allocations_locations_id ON order_item_allocations(location_id);

-- ============================================================
-- Seed data
-- ============================================================

-- Sample products (5)
INSERT INTO products (id, name, sku, price, quantity) VALUES
    ('a1b2c3d4-0001-4000-8000-000000000001', 'Wireless Bluetooth Headphones', 'ELEC-WBH-001', 79.99,  150),
    ('a1b2c3d4-0002-4000-8000-000000000002', 'Mechanical Keyboard – TKL',     'ELEC-MKB-002', 129.00,  80),
    ('a1b2c3d4-0003-4000-8000-000000000003', 'USB-C Charging Hub (7-Port)',    'ELEC-UCH-003',  49.95, 200),
    ('a1b2c3d4-0004-4000-8000-000000000004', 'Ergonomic Office Chair',         'FURN-EOC-004', 349.00,  30),
    ('a1b2c3d4-0005-4000-8000-000000000005', 'Standing Desk Converter',        'FURN-SDC-005', 199.50,  55)
ON CONFLICT (id) DO NOTHING;

-- Sample customers (3)
INSERT INTO customers (id, full_name, email, phone) VALUES
    ('b2c3d4e5-0001-4000-8000-000000000001', 'Priya Sharma',    'priya.sharma@example.com',    '+1-415-555-0101'),
    ('b2c3d4e5-0002-4000-8000-000000000002', 'James O''Brien',  'james.obrien@example.com',    '+1-212-555-0187'),
    ('b2c3d4e5-0003-4000-8000-000000000003', 'Aisha Nkemdirim', 'aisha.nkemdirim@example.com', '+44-20-5550-0243')
ON CONFLICT (id) DO NOTHING;

--sample locations(3)
INSERT INTO locations (id,name,type) VALUES
    ('c1b2d3e4-0001-4000-8000-000000000001','Main Warehouse','warehouse'),
    ('c1b2d3e4-0002-4000-8000-000000000002','Downtown Store','store'),
    ('c1b2d3e4-0003-4000-8000-000000000003','Up Warehouse','warehouse')
ON CONFLICT (id) DO NOTHING;

--sample inventory(3)
INSERT INTO inventory (product_id,location_id,quantity) VALUES
    ('a1b2c3d4-0001-4000-8000-000000000001','c1b2d3e4-0001-4000-8000-000000000001',80),
    ('a1b2c3d4-0002-4000-8000-000000000002','c1b2d3e4-0002-4000-8000-000000000002',40),
    ('a1b2c3d4-0003-4000-8000-000000000003','c1b2d3e4-0003-4000-8000-000000000003',30)
ON CONFLICT (product_id,location_id) DO NOTHING;

