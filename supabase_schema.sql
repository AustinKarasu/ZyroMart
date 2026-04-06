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

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'orders'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE orders;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'delivery_tracking'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE delivery_tracking;
  END IF;
END $$;

-- Backend foundation: admin, payouts, ratings, notifications, radius, recommendations

CREATE TABLE IF NOT EXISTS platform_admins (
  user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  access_level TEXT NOT NULL DEFAULT 'admin'
    CHECK (access_level IN ('admin', 'super_admin', 'support')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS payout_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  account_type TEXT NOT NULL CHECK (account_type IN ('bank', 'upi')),
  account_holder_name TEXT NOT NULL,
  bank_name TEXT,
  account_last4 TEXT,
  ifsc_code TEXT,
  upi_id TEXT,
  provider_name TEXT DEFAULT 'manual_settlement',
  verification_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (verification_status IN ('pending', 'verified', 'failed')),
  is_primary BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS earnings_ledger (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  beneficiary_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  beneficiary_role TEXT NOT NULL
    CHECK (beneficiary_role IN ('platform', 'store_owner', 'delivery')),
  entry_type TEXT NOT NULL
    CHECK (entry_type IN ('commission_hold', 'commission_release', 'delivery_fee_hold', 'delivery_fee_release', 'store_sale_hold', 'store_sale_release', 'refund', 'adjustment')),
  gross_amount DOUBLE PRECISION NOT NULL DEFAULT 0 CHECK (gross_amount >= 0),
  commission_amount DOUBLE PRECISION NOT NULL DEFAULT 0 CHECK (commission_amount >= 0),
  net_amount DOUBLE PRECISION NOT NULL DEFAULT 0,
  settlement_state TEXT NOT NULL DEFAULT 'held'
    CHECK (settlement_state IN ('held', 'pending_payout', 'paid_out', 'reversed')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS payouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payout_account_id UUID REFERENCES payout_accounts(id) ON DELETE SET NULL,
  beneficiary_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  payout_provider TEXT NOT NULL DEFAULT 'manual_settlement',
  payout_reference TEXT,
  amount DOUBLE PRECISION NOT NULL CHECK (amount >= 0),
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'processing', 'paid', 'failed', 'cancelled')),
  triggered_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS delivery_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL UNIQUE REFERENCES orders(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  delivery_person_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  feedback_text TEXT,
  tags TEXT[] DEFAULT ARRAY[]::TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notification_preferences (
  user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  order_updates BOOLEAN DEFAULT TRUE,
  marketing_updates BOOLEAN DEFAULT TRUE,
  recommendations BOOLEAN DEFAULT TRUE,
  earnings_alerts BOOLEAN DEFAULT TRUE,
  account_alerts BOOLEAN DEFAULT TRUE,
  quiet_hours_start TIME,
  quiet_hours_end TIME,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  category TEXT NOT NULL
    CHECK (category IN ('order', 'promotion', 'earning', 'system', 'recommendation')),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  action_type TEXT DEFAULT 'none'
    CHECK (action_type IN ('none', 'open_order', 'open_cart', 'open_product', 'open_wallet')),
  action_target TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  delivered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS store_service_areas (
  store_id UUID PRIMARY KEY REFERENCES stores(id) ON DELETE CASCADE,
  radius_km DOUBLE PRECISION NOT NULL DEFAULT 5 CHECK (radius_km > 0),
  minimum_order_amount DOUBLE PRECISION NOT NULL DEFAULT 0 CHECK (minimum_order_amount >= 0),
  is_active BOOLEAN DEFAULT TRUE,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_activity_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE SET NULL,
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  event_type TEXT NOT NULL
    CHECK (event_type IN ('view_product', 'add_to_cart', 'remove_from_cart', 'place_order', 'repeat_order', 'search', 'open_notification')),
  event_value TEXT,
  budget_hint DOUBLE PRECISION,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS product_recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  recommendation_reason TEXT NOT NULL,
  score DOUBLE PRECISION NOT NULL DEFAULT 0,
  valid_until TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, product_id, recommendation_reason)
);

CREATE TABLE IF NOT EXISTS platform_daily_metrics (
  metric_date DATE PRIMARY KEY,
  gross_merchandise_value DOUBLE PRECISION NOT NULL DEFAULT 0,
  platform_commission_earned DOUBLE PRECISION NOT NULL DEFAULT 0,
  delivery_payout_due DOUBLE PRECISION NOT NULL DEFAULT 0,
  store_payout_due DOUBLE PRECISION NOT NULL DEFAULT 0,
  completed_orders INTEGER NOT NULL DEFAULT 0,
  cancelled_orders INTEGER NOT NULL DEFAULT 0,
  active_customers INTEGER NOT NULL DEFAULT 0,
  active_delivery_partners INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS product_catalog_metadata (
  product_id UUID PRIMARY KEY REFERENCES products(id) ON DELETE CASCADE,
  brand_name TEXT,
  localized_name_hi TEXT,
  localized_description_hi TEXT,
  tags TEXT[] DEFAULT ARRAY[]::TEXT[],
  diet_labels TEXT[] DEFAULT ARRAY[]::TEXT[],
  barcode_value TEXT UNIQUE,
  replacement_group TEXT,
  shelf_life_days INTEGER CHECK (shelf_life_days IS NULL OR shelf_life_days >= 0),
  is_perishable BOOLEAN DEFAULT FALSE,
  temperature_min_c DOUBLE PRECISION,
  temperature_max_c DOUBLE PRECISION,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS search_keywords (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  locale_code TEXT NOT NULL DEFAULT 'en-IN',
  keyword TEXT NOT NULL,
  keyword_source TEXT NOT NULL DEFAULT 'manual'
    CHECK (keyword_source IN ('name', 'category', 'tag', 'brand', 'manual')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (product_id, locale_code, keyword)
);

CREATE TABLE IF NOT EXISTS inventory_reservations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  reserved_quantity INTEGER NOT NULL CHECK (reserved_quantity > 0),
  reservation_status TEXT NOT NULL DEFAULT 'reserved'
    CHECK (reservation_status IN ('reserved', 'released', 'consumed', 'substituted')),
  expires_at TIMESTAMPTZ,
  released_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS order_status_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  actor_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  actor_role TEXT NOT NULL DEFAULT 'system'
    CHECK (actor_role IN ('customer', 'store_owner', 'delivery', 'admin', 'system')),
  previous_status TEXT,
  next_status TEXT NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS delivery_route_updates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  delivery_person_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  accuracy_meters DOUBLE PRECISION,
  speed_kmph DOUBLE PRECISION,
  heading_degrees DOUBLE PRECISION,
  eta_minutes INTEGER CHECK (eta_minutes IS NULL OR eta_minutes >= 0),
  captured_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS proof_of_delivery (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL UNIQUE REFERENCES orders(id) ON DELETE CASCADE,
  delivery_person_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  photo_url TEXT,
  signature_name TEXT,
  signature_vector JSONB,
  handed_to_name TEXT,
  otp_verified BOOLEAN NOT NULL DEFAULT FALSE,
  notes TEXT,
  delivered_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notification_devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  platform TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  device_token TEXT NOT NULL UNIQUE,
  locale_code TEXT NOT NULL DEFAULT 'en-IN',
  timezone_name TEXT,
  app_variant TEXT NOT NULL DEFAULT 'storefront'
    CHECK (app_variant IN ('storefront', 'admin')),
  push_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  last_seen_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_restock_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  cadence TEXT NOT NULL CHECK (cadence IN ('daily', 'weekly', 'monthly')),
  quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
  next_run_at TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, product_id, cadence)
);

CREATE INDEX IF NOT EXISTS idx_payout_accounts_user ON payout_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_earnings_ledger_order ON earnings_ledger(order_id);
CREATE INDEX IF NOT EXISTS idx_earnings_ledger_beneficiary ON earnings_ledger(beneficiary_user_id, settlement_state);
CREATE INDEX IF NOT EXISTS idx_payouts_beneficiary ON payouts(beneficiary_user_id, status);
CREATE INDEX IF NOT EXISTS idx_delivery_feedback_delivery ON delivery_feedback(delivery_person_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, is_read, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_activity_events_user ON user_activity_events(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_product_recommendations_user ON product_recommendations(user_id, score DESC);
CREATE INDEX IF NOT EXISTS idx_search_keywords_lookup ON search_keywords(locale_code, keyword);
CREATE INDEX IF NOT EXISTS idx_inventory_reservations_order ON inventory_reservations(order_id, reservation_status);
CREATE INDEX IF NOT EXISTS idx_inventory_reservations_product ON inventory_reservations(product_id, store_id, reservation_status);
CREATE INDEX IF NOT EXISTS idx_order_status_events_order ON order_status_events(order_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_delivery_route_updates_order ON delivery_route_updates(order_id, captured_at DESC);
CREATE INDEX IF NOT EXISTS idx_notification_devices_user ON notification_devices(user_id, push_enabled);
CREATE INDEX IF NOT EXISTS idx_user_restock_subscriptions_user ON user_restock_subscriptions(user_id, is_active);

DROP TRIGGER IF EXISTS set_payout_accounts_updated_at ON payout_accounts;
CREATE TRIGGER set_payout_accounts_updated_at
BEFORE UPDATE ON payout_accounts
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_payouts_updated_at ON payouts;
CREATE TRIGGER set_payouts_updated_at
BEFORE UPDATE ON payouts
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_notification_preferences_updated_at ON notification_preferences;
CREATE TRIGGER set_notification_preferences_updated_at
BEFORE UPDATE ON notification_preferences
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_store_service_areas_updated_at ON store_service_areas;
CREATE TRIGGER set_store_service_areas_updated_at
BEFORE UPDATE ON store_service_areas
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_platform_daily_metrics_updated_at ON platform_daily_metrics;
CREATE TRIGGER set_platform_daily_metrics_updated_at
BEFORE UPDATE ON platform_daily_metrics
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_product_catalog_metadata_updated_at ON product_catalog_metadata;
CREATE TRIGGER set_product_catalog_metadata_updated_at
BEFORE UPDATE ON product_catalog_metadata
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_inventory_reservations_updated_at ON inventory_reservations;
CREATE TRIGGER set_inventory_reservations_updated_at
BEFORE UPDATE ON inventory_reservations
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_notification_devices_updated_at ON notification_devices;
CREATE TRIGGER set_notification_devices_updated_at
BEFORE UPDATE ON notification_devices
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_user_restock_subscriptions_updated_at ON user_restock_subscriptions;
CREATE TRIGGER set_user_restock_subscriptions_updated_at
BEFORE UPDATE ON user_restock_subscriptions
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE platform_admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE payout_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE earnings_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE store_service_areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_activity_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform_daily_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_catalog_metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE search_keywords ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_status_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_route_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE proof_of_delivery ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_restock_subscriptions ENABLE ROW LEVEL SECURITY;

ALTER TABLE platform_admins FORCE ROW LEVEL SECURITY;
ALTER TABLE payout_accounts FORCE ROW LEVEL SECURITY;
ALTER TABLE earnings_ledger FORCE ROW LEVEL SECURITY;
ALTER TABLE payouts FORCE ROW LEVEL SECURITY;
ALTER TABLE delivery_feedback FORCE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences FORCE ROW LEVEL SECURITY;
ALTER TABLE notifications FORCE ROW LEVEL SECURITY;
ALTER TABLE store_service_areas FORCE ROW LEVEL SECURITY;
ALTER TABLE user_activity_events FORCE ROW LEVEL SECURITY;
ALTER TABLE product_recommendations FORCE ROW LEVEL SECURITY;
ALTER TABLE platform_daily_metrics FORCE ROW LEVEL SECURITY;
ALTER TABLE product_catalog_metadata FORCE ROW LEVEL SECURITY;
ALTER TABLE search_keywords FORCE ROW LEVEL SECURITY;
ALTER TABLE inventory_reservations FORCE ROW LEVEL SECURITY;
ALTER TABLE order_status_events FORCE ROW LEVEL SECURITY;
ALTER TABLE delivery_route_updates FORCE ROW LEVEL SECURITY;
ALTER TABLE proof_of_delivery FORCE ROW LEVEL SECURITY;
ALTER TABLE notification_devices FORCE ROW LEVEL SECURITY;
ALTER TABLE user_restock_subscriptions FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins read platform admins" ON platform_admins;
DROP POLICY IF EXISTS "Users manage own payout accounts" ON payout_accounts;
DROP POLICY IF EXISTS "Admins manage payout accounts" ON payout_accounts;
DROP POLICY IF EXISTS "Users read own earnings ledger" ON earnings_ledger;
DROP POLICY IF EXISTS "Admins manage earnings ledger" ON earnings_ledger;
DROP POLICY IF EXISTS "Users read own payouts" ON payouts;
DROP POLICY IF EXISTS "Admins manage payouts" ON payouts;
DROP POLICY IF EXISTS "Users read related feedback" ON delivery_feedback;
DROP POLICY IF EXISTS "Customers insert delivery feedback" ON delivery_feedback;
DROP POLICY IF EXISTS "Users manage own notification preferences" ON notification_preferences;
DROP POLICY IF EXISTS "Users read own notifications" ON notifications;
DROP POLICY IF EXISTS "Admins insert notifications" ON notifications;
DROP POLICY IF EXISTS "Users update own notifications" ON notifications;
DROP POLICY IF EXISTS "Public read service areas" ON store_service_areas;
DROP POLICY IF EXISTS "Owners manage service areas" ON store_service_areas;
DROP POLICY IF EXISTS "Users insert own activity events" ON user_activity_events;
DROP POLICY IF EXISTS "Users read own activity events" ON user_activity_events;
DROP POLICY IF EXISTS "Users read own recommendations" ON product_recommendations;
DROP POLICY IF EXISTS "Admins manage recommendations" ON product_recommendations;
DROP POLICY IF EXISTS "Admins read daily metrics" ON platform_daily_metrics;
DROP POLICY IF EXISTS "Admins manage daily metrics" ON platform_daily_metrics;
DROP POLICY IF EXISTS "Public read product metadata" ON product_catalog_metadata;
DROP POLICY IF EXISTS "Owners manage product metadata" ON product_catalog_metadata;
DROP POLICY IF EXISTS "Public read search keywords" ON search_keywords;
DROP POLICY IF EXISTS "Owners manage search keywords" ON search_keywords;
DROP POLICY IF EXISTS "Users read related inventory reservations" ON inventory_reservations;
DROP POLICY IF EXISTS "Owners manage inventory reservations" ON inventory_reservations;
DROP POLICY IF EXISTS "Delivery read assigned inventory reservations" ON inventory_reservations;
DROP POLICY IF EXISTS "Users read related order status events" ON order_status_events;
DROP POLICY IF EXISTS "Authorized insert order status events" ON order_status_events;
DROP POLICY IF EXISTS "Users read related route updates" ON delivery_route_updates;
DROP POLICY IF EXISTS "Delivery manage own route updates" ON delivery_route_updates;
DROP POLICY IF EXISTS "Users read related proof of delivery" ON proof_of_delivery;
DROP POLICY IF EXISTS "Delivery insert proof of delivery" ON proof_of_delivery;
DROP POLICY IF EXISTS "Users manage own notification devices" ON notification_devices;
DROP POLICY IF EXISTS "Users manage own restock subscriptions" ON user_restock_subscriptions;

CREATE POLICY "Admins read platform admins" ON platform_admins FOR SELECT
  USING (EXISTS (SELECT 1 FROM platform_admins pa WHERE pa.user_id = auth.uid()));

CREATE POLICY "Users manage own payout accounts" ON payout_accounts FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins manage payout accounts" ON payout_accounts FOR ALL
  USING (EXISTS (SELECT 1 FROM platform_admins pa WHERE pa.user_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM platform_admins pa WHERE pa.user_id = auth.uid()));

CREATE POLICY "Users read own earnings ledger" ON earnings_ledger FOR SELECT
  USING (
    auth.uid() = beneficiary_user_id
    OR (beneficiary_role = 'platform' AND EXISTS (SELECT 1 FROM platform_admins pa WHERE pa.user_id = auth.uid()))
  );

CREATE POLICY "Admins manage earnings ledger" ON earnings_ledger FOR ALL
  USING (EXISTS (SELECT 1 FROM platform_admins pa WHERE pa.user_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM platform_admins pa WHERE pa.user_id = auth.uid()));

CREATE POLICY "Users read own payouts" ON payouts FOR SELECT
  USING (auth.uid() = beneficiary_user_id);

CREATE POLICY "Admins manage payouts" ON payouts FOR ALL
  USING (EXISTS (SELECT 1 FROM platform_admins pa WHERE pa.user_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM platform_admins pa WHERE pa.user_id = auth.uid()));

CREATE POLICY "Users read related feedback" ON delivery_feedback FOR SELECT
  USING (
    auth.uid() = customer_id
    OR auth.uid() = delivery_person_id
    OR EXISTS (
      SELECT 1 FROM orders
      JOIN stores ON stores.id = orders.store_id
      WHERE orders.id = delivery_feedback.order_id
        AND stores.owner_id = auth.uid()
    )
  );

CREATE POLICY "Customers insert delivery feedback" ON delivery_feedback FOR INSERT
  WITH CHECK (
    auth.uid() = customer_id
    AND EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = delivery_feedback.order_id
        AND orders.customer_id = auth.uid()
        AND orders.delivery_person_id = delivery_feedback.delivery_person_id
        AND orders.status = 'delivered'
    )
  );

CREATE POLICY "Users manage own notification preferences" ON notification_preferences FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users read own notifications" ON notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users update own notifications" ON notifications FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins insert notifications" ON notifications FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM platform_admins pa WHERE pa.user_id = auth.uid()));

CREATE POLICY "Public read service areas" ON store_service_areas FOR SELECT
  USING (true);

CREATE POLICY "Owners manage service areas" ON store_service_areas FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM stores
      WHERE stores.id = store_service_areas.store_id
        AND stores.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM stores
      WHERE stores.id = store_service_areas.store_id
        AND stores.owner_id = auth.uid()
    )
  );

CREATE POLICY "Users insert own activity events" ON user_activity_events FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users read own activity events" ON user_activity_events FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users read own recommendations" ON product_recommendations FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Admins manage recommendations" ON product_recommendations FOR ALL
  USING (EXISTS (SELECT 1 FROM platform_admins pa WHERE pa.user_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM platform_admins pa WHERE pa.user_id = auth.uid()));

CREATE POLICY "Admins read daily metrics" ON platform_daily_metrics FOR SELECT
  USING (EXISTS (SELECT 1 FROM platform_admins pa WHERE pa.user_id = auth.uid()));

CREATE POLICY "Admins manage daily metrics" ON platform_daily_metrics FOR ALL
  USING (EXISTS (SELECT 1 FROM platform_admins pa WHERE pa.user_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM platform_admins pa WHERE pa.user_id = auth.uid()));

CREATE POLICY "Public read product metadata" ON product_catalog_metadata FOR SELECT
  USING (true);

CREATE POLICY "Owners manage product metadata" ON product_catalog_metadata FOR ALL
  USING (
    EXISTS (
      SELECT 1
      FROM products
      JOIN stores ON stores.id = products.store_id
      WHERE products.id = product_catalog_metadata.product_id
        AND stores.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM products
      JOIN stores ON stores.id = products.store_id
      WHERE products.id = product_catalog_metadata.product_id
        AND stores.owner_id = auth.uid()
    )
  );

CREATE POLICY "Public read search keywords" ON search_keywords FOR SELECT
  USING (true);

CREATE POLICY "Owners manage search keywords" ON search_keywords FOR ALL
  USING (
    EXISTS (
      SELECT 1
      FROM products
      JOIN stores ON stores.id = products.store_id
      WHERE products.id = search_keywords.product_id
        AND stores.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM products
      JOIN stores ON stores.id = products.store_id
      WHERE products.id = search_keywords.product_id
        AND stores.owner_id = auth.uid()
    )
  );

CREATE POLICY "Users read related inventory reservations" ON inventory_reservations FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM orders
      JOIN stores ON stores.id = orders.store_id
      WHERE orders.id = inventory_reservations.order_id
        AND (
          orders.customer_id = auth.uid()
          OR stores.owner_id = auth.uid()
          OR orders.delivery_person_id = auth.uid()
        )
    )
  );

CREATE POLICY "Owners manage inventory reservations" ON inventory_reservations FOR ALL
  USING (
    EXISTS (
      SELECT 1
      FROM stores
      WHERE stores.id = inventory_reservations.store_id
        AND stores.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM stores
      WHERE stores.id = inventory_reservations.store_id
        AND stores.owner_id = auth.uid()
    )
  );

CREATE POLICY "Delivery read assigned inventory reservations" ON inventory_reservations FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM orders
      WHERE orders.id = inventory_reservations.order_id
        AND orders.delivery_person_id = auth.uid()
    )
  );

CREATE POLICY "Users read related order status events" ON order_status_events FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM orders
      JOIN stores ON stores.id = orders.store_id
      WHERE orders.id = order_status_events.order_id
        AND (
          orders.customer_id = auth.uid()
          OR stores.owner_id = auth.uid()
          OR orders.delivery_person_id = auth.uid()
          OR EXISTS (SELECT 1 FROM platform_admins pa WHERE pa.user_id = auth.uid())
        )
    )
  );

CREATE POLICY "Authorized insert order status events" ON order_status_events FOR INSERT
  WITH CHECK (
    auth.uid() = actor_user_id
    OR actor_role = 'system'
    OR EXISTS (SELECT 1 FROM platform_admins pa WHERE pa.user_id = auth.uid())
  );

CREATE POLICY "Users read related route updates" ON delivery_route_updates FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM orders
      JOIN stores ON stores.id = orders.store_id
      WHERE orders.id = delivery_route_updates.order_id
        AND (
          orders.customer_id = auth.uid()
          OR stores.owner_id = auth.uid()
          OR orders.delivery_person_id = auth.uid()
        )
    )
  );

CREATE POLICY "Delivery manage own route updates" ON delivery_route_updates FOR ALL
  USING (auth.uid() = delivery_person_id)
  WITH CHECK (auth.uid() = delivery_person_id);

CREATE POLICY "Users read related proof of delivery" ON proof_of_delivery FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM orders
      JOIN stores ON stores.id = orders.store_id
      WHERE orders.id = proof_of_delivery.order_id
        AND (
          orders.customer_id = auth.uid()
          OR stores.owner_id = auth.uid()
          OR orders.delivery_person_id = auth.uid()
          OR EXISTS (SELECT 1 FROM platform_admins pa WHERE pa.user_id = auth.uid())
        )
    )
  );

CREATE POLICY "Delivery insert proof of delivery" ON proof_of_delivery FOR INSERT
  WITH CHECK (auth.uid() = delivery_person_id);

CREATE POLICY "Users manage own notification devices" ON notification_devices FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users manage own restock subscriptions" ON user_restock_subscriptions FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'order_status_events'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE order_status_events;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'delivery_route_updates'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE delivery_route_updates;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'proof_of_delivery'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE proof_of_delivery;
  END IF;
END $$;
