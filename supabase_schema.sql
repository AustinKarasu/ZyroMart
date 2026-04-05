-- ZyroMart Supabase Database Schema
-- Run this in your Supabase SQL Editor: https://supabase.com/dashboard/project/uhlfphrtmaxffchivsip/sql

-- ─── Users / Profiles ──────────────────────────────────────

CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  phone TEXT UNIQUE,
  role TEXT NOT NULL CHECK (role IN ('customer', 'store_owner', 'delivery')),
  address TEXT,
  latitude DOUBLE PRECISION CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
  longitude DOUBLE PRECISION CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180),
  profile_image_url TEXT,
  delivery_rating DOUBLE PRECISION DEFAULT 0 CHECK (delivery_rating BETWEEN 0 AND 5),
  completed_deliveries INTEGER DEFAULT 0 CHECK (completed_deliveries >= 0),
  is_online BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Stores ────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS stores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  latitude DOUBLE PRECISION NOT NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  rating DOUBLE PRECISION DEFAULT 4.5 CHECK (rating BETWEEN 0 AND 5),
  image_url TEXT,
  is_open BOOLEAN DEFAULT TRUE,
  owner_id UUID REFERENCES profiles(id),
  phone TEXT,
  open_time TEXT DEFAULT '08:00 AM',
  close_time TEXT DEFAULT '10:00 PM',
  total_orders INTEGER DEFAULT 0 CHECK (total_orders >= 0),
  total_revenue DOUBLE PRECISION DEFAULT 0 CHECK (total_revenue >= 0),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Categories ────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  icon_name TEXT NOT NULL,
  color TEXT NOT NULL,
  image_url TEXT,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Products ──────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  price DOUBLE PRECISION NOT NULL CHECK (price >= 0),
  original_price DOUBLE PRECISION CHECK (original_price IS NULL OR original_price >= price),
  image_url TEXT,
  category_id UUID REFERENCES categories(id),
  store_id UUID REFERENCES stores(id),
  in_stock BOOLEAN DEFAULT TRUE,
  stock_quantity INTEGER DEFAULT 100 CHECK (stock_quantity >= 0),
  unit TEXT DEFAULT 'piece',
  rating DOUBLE PRECISION DEFAULT 4.0 CHECK (rating BETWEEN 0 AND 5),
  review_count INTEGER DEFAULT 0 CHECK (review_count >= 0),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Orders ────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number TEXT UNIQUE NOT NULL,
  total_amount DOUBLE PRECISION NOT NULL CHECK (total_amount >= 0),
  delivery_fee DOUBLE PRECISION DEFAULT 29.0 CHECK (delivery_fee >= 0),
  status TEXT NOT NULL DEFAULT 'placed'
    CHECK (status IN ('placed', 'confirmed', 'preparing', 'ready_for_pickup', 'out_for_delivery', 'delivered', 'cancelled')),
  customer_id UUID REFERENCES profiles(id),
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,
  store_id UUID REFERENCES stores(id),
  store_name TEXT NOT NULL,
  delivery_person_id UUID REFERENCES profiles(id),
  delivery_person_name TEXT,
  delivery_address TEXT NOT NULL,
  customer_latitude DOUBLE PRECISION CHECK (customer_latitude IS NULL OR customer_latitude BETWEEN -90 AND 90),
  customer_longitude DOUBLE PRECISION CHECK (customer_longitude IS NULL OR customer_longitude BETWEEN -180 AND 180),
  store_latitude DOUBLE PRECISION CHECK (store_latitude IS NULL OR store_latitude BETWEEN -90 AND 90),
  store_longitude DOUBLE PRECISION CHECK (store_longitude IS NULL OR store_longitude BETWEEN -180 AND 180),
  notes TEXT,
  payment_method TEXT DEFAULT 'cod',
  estimated_delivery TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Order Items ───────────────────────────────────────────

CREATE TABLE IF NOT EXISTS order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  product_name TEXT NOT NULL,
  product_price DOUBLE PRECISION NOT NULL CHECK (product_price >= 0),
  quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Delivery Tracking ────────────────────────────────────

CREATE TABLE IF NOT EXISTS delivery_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  delivery_person_id UUID REFERENCES profiles(id),
  latitude DOUBLE PRECISION NOT NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Indexes ───────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_store ON products(store_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_store ON orders(store_id);
CREATE INDEX IF NOT EXISTS idx_orders_delivery ON orders(delivery_person_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_delivery_tracking_order ON delivery_tracking(order_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_delivery_tracking_order_unique ON delivery_tracking(order_id);

-- Timestamp maintenance
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION guard_order_update()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.id IS DISTINCT FROM OLD.id
    OR NEW.order_number IS DISTINCT FROM OLD.order_number
    OR NEW.total_amount IS DISTINCT FROM OLD.total_amount
    OR NEW.delivery_fee IS DISTINCT FROM OLD.delivery_fee
    OR NEW.customer_id IS DISTINCT FROM OLD.customer_id
    OR NEW.customer_name IS DISTINCT FROM OLD.customer_name
    OR NEW.customer_phone IS DISTINCT FROM OLD.customer_phone
    OR NEW.store_id IS DISTINCT FROM OLD.store_id
    OR NEW.store_name IS DISTINCT FROM OLD.store_name
    OR NEW.delivery_address IS DISTINCT FROM OLD.delivery_address
    OR NEW.customer_latitude IS DISTINCT FROM OLD.customer_latitude
    OR NEW.customer_longitude IS DISTINCT FROM OLD.customer_longitude
    OR NEW.store_latitude IS DISTINCT FROM OLD.store_latitude
    OR NEW.store_longitude IS DISTINCT FROM OLD.store_longitude
    OR NEW.payment_method IS DISTINCT FROM OLD.payment_method
    OR NEW.notes IS DISTINCT FROM OLD.notes
    OR NEW.created_at IS DISTINCT FROM OLD.created_at THEN
    RAISE EXCEPTION 'Protected order fields cannot be changed';
  END IF;

  IF auth.uid() = OLD.customer_id THEN
    IF NEW.status <> 'cancelled' OR OLD.status NOT IN ('placed', 'confirmed', 'preparing') THEN
      RAISE EXCEPTION 'Customers may only cancel eligible orders';
    END IF;

    IF NEW.delivery_person_id IS DISTINCT FROM OLD.delivery_person_id
      OR NEW.delivery_person_name IS DISTINCT FROM OLD.delivery_person_name
      OR NEW.estimated_delivery IS DISTINCT FROM OLD.estimated_delivery THEN
      RAISE EXCEPTION 'Customers cannot edit delivery assignment details';
    END IF;
  ELSIF auth.uid() = OLD.delivery_person_id THEN
    IF NEW.status NOT IN ('out_for_delivery', 'delivered') THEN
      RAISE EXCEPTION 'Delivery partners may only update delivery statuses';
    END IF;

    IF NEW.delivery_person_id IS DISTINCT FROM OLD.delivery_person_id
      OR NEW.delivery_person_name IS DISTINCT FROM OLD.delivery_person_name
      OR NEW.estimated_delivery IS DISTINCT FROM OLD.estimated_delivery THEN
      RAISE EXCEPTION 'Delivery partners cannot reassign orders';
    END IF;
  ELSIF EXISTS (
    SELECT 1 FROM stores
    WHERE stores.id = OLD.store_id
      AND stores.owner_id = auth.uid()
  ) THEN
    IF NEW.status NOT IN ('confirmed', 'preparing', 'ready_for_pickup', 'out_for_delivery', 'delivered', 'cancelled') THEN
      RAISE EXCEPTION 'Invalid status update for store owner';
    END IF;
  ELSE
    RAISE EXCEPTION 'Unauthorized order update';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION guard_delivery_tracking_update()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.order_id IS DISTINCT FROM OLD.order_id
    OR NEW.delivery_person_id IS DISTINCT FROM OLD.delivery_person_id THEN
    RAISE EXCEPTION 'Tracking identity fields cannot be changed';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_profiles_updated_at ON profiles;
CREATE TRIGGER set_profiles_updated_at
BEFORE UPDATE ON profiles
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_stores_updated_at ON stores;
CREATE TRIGGER set_stores_updated_at
BEFORE UPDATE ON stores
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_products_updated_at ON products;
CREATE TRIGGER set_products_updated_at
BEFORE UPDATE ON products
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_orders_updated_at ON orders;
CREATE TRIGGER set_orders_updated_at
BEFORE UPDATE ON orders
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS guard_orders_update ON orders;
CREATE TRIGGER guard_orders_update
BEFORE UPDATE ON orders
FOR EACH ROW EXECUTE FUNCTION guard_order_update();

DROP TRIGGER IF EXISTS guard_delivery_tracking_update ON delivery_tracking;
CREATE TRIGGER guard_delivery_tracking_update
BEFORE UPDATE ON delivery_tracking
FOR EACH ROW EXECUTE FUNCTION guard_delivery_tracking_update();

-- ─── Row Level Security ───────────────────────────────────

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles FORCE ROW LEVEL SECURITY;
ALTER TABLE stores FORCE ROW LEVEL SECURITY;
ALTER TABLE categories FORCE ROW LEVEL SECURITY;
ALTER TABLE products FORCE ROW LEVEL SECURITY;
ALTER TABLE orders FORCE ROW LEVEL SECURITY;
ALTER TABLE order_items FORCE ROW LEVEL SECURITY;
ALTER TABLE delivery_tracking FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read categories" ON categories;
DROP POLICY IF EXISTS "Public read products" ON products;
DROP POLICY IF EXISTS "Public read stores" ON stores;
DROP POLICY IF EXISTS "Users read own profile" ON profiles;
DROP POLICY IF EXISTS "Users update own profile" ON profiles;
DROP POLICY IF EXISTS "Customers read own orders" ON orders;
DROP POLICY IF EXISTS "Customers create orders" ON orders;
DROP POLICY IF EXISTS "Read order items" ON order_items;
DROP POLICY IF EXISTS "Public read tracking" ON delivery_tracking;
DROP POLICY IF EXISTS "Delivery update tracking" ON delivery_tracking;
DROP POLICY IF EXISTS "Delivery update tracking update" ON delivery_tracking;

-- Allow public catalog reads only
CREATE POLICY "Public read categories" ON categories FOR SELECT USING (true);
CREATE POLICY "Public read products" ON products FOR SELECT USING (true);
CREATE POLICY "Public read stores" ON stores FOR SELECT USING (true);

-- Users can read their own profile
CREATE POLICY "Users read own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Store owners manage only their own stores and products
CREATE POLICY "Owners insert stores" ON stores FOR INSERT
  WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Owners update stores" ON stores FOR UPDATE
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Owners insert products" ON products FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM stores
      WHERE stores.id = products.store_id
        AND stores.owner_id = auth.uid()
    )
  );
CREATE POLICY "Owners update products" ON products FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM stores
      WHERE stores.id = products.store_id
        AND stores.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM stores
      WHERE stores.id = products.store_id
        AND stores.owner_id = auth.uid()
    )
  );
CREATE POLICY "Owners delete products" ON products FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM stores
      WHERE stores.id = products.store_id
        AND stores.owner_id = auth.uid()
    )
  );

-- Orders: customers see their own, store owners see store orders, delivery sees assigned
CREATE POLICY "Users read related orders" ON orders FOR SELECT
  USING (
    auth.uid() = customer_id
    OR auth.uid() = delivery_person_id
    OR EXISTS (
      SELECT 1 FROM stores
      WHERE stores.id = orders.store_id
        AND stores.owner_id = auth.uid()
    )
  );
CREATE POLICY "Customers create orders" ON orders FOR INSERT
  WITH CHECK (
    auth.uid() = customer_id
    AND EXISTS (
      SELECT 1 FROM stores
      WHERE stores.id = orders.store_id
    )
  );
CREATE POLICY "Customers cancel own orders" ON orders FOR UPDATE
  USING (auth.uid() = customer_id)
  WITH CHECK (auth.uid() = customer_id);
CREATE POLICY "Store owners update store orders" ON orders FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM stores
      WHERE stores.id = orders.store_id
        AND stores.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM stores
      WHERE stores.id = orders.store_id
        AND stores.owner_id = auth.uid()
    )
  );
CREATE POLICY "Delivery updates assigned orders" ON orders FOR UPDATE
  USING (auth.uid() = delivery_person_id)
  WITH CHECK (auth.uid() = delivery_person_id);

-- Order items follow order access
CREATE POLICY "Read related order items" ON order_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
        AND (
          orders.customer_id = auth.uid()
          OR orders.delivery_person_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM stores
            WHERE stores.id = orders.store_id
              AND stores.owner_id = auth.uid()
          )
        )
    )
  );
CREATE POLICY "Customers insert own order items" ON order_items FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
        AND orders.customer_id = auth.uid()
    )
  );

-- Delivery tracking must stay tied to the assigned delivery person and related order
CREATE POLICY "Users read related tracking" ON delivery_tracking FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = delivery_tracking.order_id
        AND (
          orders.customer_id = auth.uid()
          OR orders.delivery_person_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM stores
            WHERE stores.id = orders.store_id
              AND stores.owner_id = auth.uid()
          )
        )
    )
  );
CREATE POLICY "Assigned delivery insert tracking" ON delivery_tracking FOR INSERT
  WITH CHECK (
    auth.uid() = delivery_person_id
    AND EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = delivery_tracking.order_id
        AND orders.delivery_person_id = auth.uid()
    )
  );
CREATE POLICY "Assigned delivery update tracking" ON delivery_tracking FOR UPDATE
  USING (auth.uid() = delivery_person_id)
  WITH CHECK (
    auth.uid() = delivery_person_id
    AND EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = delivery_tracking.order_id
        AND orders.delivery_person_id = auth.uid()
    )
  );

-- ─── Realtime ──────────────────────────────────────────────

ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE delivery_tracking;
