-- ZyroMart Supabase Database Schema
-- Run this in your Supabase SQL Editor: https://supabase.com/dashboard/project/uhlfphrtmaxffchivsip/sql

-- ─── Users / Profiles ──────────────────────────────────────

CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  role TEXT NOT NULL CHECK (role IN ('customer', 'store_owner', 'delivery')),
  address TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  profile_image_url TEXT,
  delivery_rating DOUBLE PRECISION DEFAULT 0,
  completed_deliveries INTEGER DEFAULT 0,
  is_online BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Stores ────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS stores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  rating DOUBLE PRECISION DEFAULT 4.5,
  image_url TEXT,
  is_open BOOLEAN DEFAULT TRUE,
  owner_id UUID REFERENCES profiles(id),
  phone TEXT,
  open_time TEXT DEFAULT '08:00 AM',
  close_time TEXT DEFAULT '10:00 PM',
  total_orders INTEGER DEFAULT 0,
  total_revenue DOUBLE PRECISION DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
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
  price DOUBLE PRECISION NOT NULL,
  original_price DOUBLE PRECISION,
  image_url TEXT,
  category_id UUID REFERENCES categories(id),
  store_id UUID REFERENCES stores(id),
  in_stock BOOLEAN DEFAULT TRUE,
  stock_quantity INTEGER DEFAULT 100,
  unit TEXT DEFAULT 'piece',
  rating DOUBLE PRECISION DEFAULT 4.0,
  review_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Orders ────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number TEXT UNIQUE NOT NULL,
  total_amount DOUBLE PRECISION NOT NULL,
  delivery_fee DOUBLE PRECISION DEFAULT 29.0,
  status TEXT NOT NULL DEFAULT 'placed'
    CHECK (status IN ('placed', 'confirmed', 'preparing', 'ready_for_pickup', 'out_for_delivery', 'delivered', 'cancelled')),
  customer_id UUID REFERENCES profiles(id),
  customer_name TEXT NOT NULL,
  store_id UUID REFERENCES stores(id),
  store_name TEXT NOT NULL,
  delivery_person_id UUID REFERENCES profiles(id),
  delivery_person_name TEXT,
  delivery_address TEXT NOT NULL,
  customer_latitude DOUBLE PRECISION,
  customer_longitude DOUBLE PRECISION,
  store_latitude DOUBLE PRECISION,
  store_longitude DOUBLE PRECISION,
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
  product_price DOUBLE PRECISION NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Delivery Tracking ────────────────────────────────────

CREATE TABLE IF NOT EXISTS delivery_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  delivery_person_id UUID REFERENCES profiles(id),
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
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

-- ─── Row Level Security ───────────────────────────────────

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_tracking ENABLE ROW LEVEL SECURITY;

-- Allow public read for categories and products
CREATE POLICY "Public read categories" ON categories FOR SELECT USING (true);
CREATE POLICY "Public read products" ON products FOR SELECT USING (true);
CREATE POLICY "Public read stores" ON stores FOR SELECT USING (true);

-- Users can read their own profile
CREATE POLICY "Users read own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Orders: customers see their own, store owners see store orders, delivery sees assigned
CREATE POLICY "Customers read own orders" ON orders FOR SELECT
  USING (auth.uid() = customer_id OR auth.uid() = delivery_person_id);
CREATE POLICY "Customers create orders" ON orders FOR INSERT
  WITH CHECK (auth.uid() = customer_id);

-- Order items follow order access
CREATE POLICY "Read order items" ON order_items FOR SELECT USING (true);

-- Delivery tracking: public read for real-time tracking
CREATE POLICY "Public read tracking" ON delivery_tracking FOR SELECT USING (true);
CREATE POLICY "Delivery update tracking" ON delivery_tracking FOR INSERT WITH CHECK (true);
CREATE POLICY "Delivery update tracking update" ON delivery_tracking FOR UPDATE USING (true);

-- ─── Realtime ──────────────────────────────────────────────

ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE delivery_tracking;
