-- ZyroMart seed data
-- Run after supabase_schema.sql

BEGIN;

TRUNCATE TABLE delivery_tracking RESTART IDENTITY CASCADE;
TRUNCATE TABLE order_items RESTART IDENTITY CASCADE;
TRUNCATE TABLE orders RESTART IDENTITY CASCADE;
TRUNCATE TABLE products RESTART IDENTITY CASCADE;
TRUNCATE TABLE stores RESTART IDENTITY CASCADE;
TRUNCATE TABLE categories RESTART IDENTITY CASCADE;

INSERT INTO categories (id, name, icon_name, color, image_url, sort_order) VALUES
('11111111-1111-1111-1111-111111111111', 'Fruits & Vegetables', 'eco', '#43A047', 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=800&q=80', 1),
('22222222-2222-2222-2222-222222222222', 'Dairy & Breakfast', 'breakfast_dining', '#FB8C00', 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=800&q=80', 2),
('33333333-3333-3333-3333-333333333333', 'Snacks & Munchies', 'cookie', '#F9A825', 'https://images.unsplash.com/photo-1585238342024-78d387f4a707?auto=format&fit=crop&w=800&q=80', 3),
('44444444-4444-4444-4444-444444444444', 'Cold Drinks & Juices', 'local_drink', '#1E88E5', 'https://images.unsplash.com/photo-1544145945-f90425340c7e?auto=format&fit=crop&w=800&q=80', 4),
('55555555-5555-5555-5555-555555555555', 'Bakery & Desserts', 'cake', '#8D6E63', 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=800&q=80', 5),
('66666666-6666-6666-6666-666666666666', 'Personal Care', 'face', '#D81B60', 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=800&q=80', 6);

INSERT INTO stores (
  id, name, address, latitude, longitude, rating, image_url, is_open, phone,
  open_time, close_time, total_orders, total_revenue
) VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'ZyroMart Central', '123 Main Street, Sector 15, Noida', 28.5850, 77.3100, 4.7, 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=80', true, '+91 9876543210', '08:00 AM', '11:00 PM', 1245, 345670),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'ZyroMart Express', '45 Park Avenue, Sector 18, Noida', 28.5700, 77.3200, 4.5, 'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?auto=format&fit=crop&w=1200&q=80', true, '+91 9876543211', '07:00 AM', '11:30 PM', 890, 234560),
('cccccccc-cccc-cccc-cccc-cccccccccccc', 'ZyroMart Fresh Hub', '92 Residency Road, Sector 22, Noida', 28.5905, 77.3045, 4.6, 'https://images.unsplash.com/photo-1579113800032-c38bd7635818?auto=format&fit=crop&w=1200&q=80', true, '+91 9876543212', '08:00 AM', '10:30 PM', 1044, 298420);

INSERT INTO products (
  id, name, description, price, original_price, image_url, category_id, store_id,
  in_stock, stock_quantity, unit, rating, review_count
) VALUES
('10000000-0000-0000-0000-000000000001', 'Fresh Bananas', 'Farm fresh bananas rich in potassium and natural energy.', 45, 60, 'https://images.unsplash.com/photo-1574226516831-e1dff420e43e?auto=format&fit=crop&w=800&q=80', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', true, 120, 'dozen', 4.5, 234),
('10000000-0000-0000-0000-000000000002', 'Red Apples', 'Crisp Himachali apples selected for everyday freshness.', 179, 219, 'https://images.unsplash.com/photo-1567306226416-28f0efdc88ce?auto=format&fit=crop&w=800&q=80', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', true, 90, 'kg', 4.4, 189),
('10000000-0000-0000-0000-000000000003', 'Tomatoes', 'Vine-ripened tomatoes for curries, salads, and sandwiches.', 39, 52, 'https://images.unsplash.com/photo-1546094096-0df4bcaaa337?auto=format&fit=crop&w=800&q=80', '11111111-1111-1111-1111-111111111111', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', true, 140, 'kg', 4.1, 312),
('10000000-0000-0000-0000-000000000004', 'Baby Spinach', 'Clean, ready-to-cook spinach leaves packed fresh.', 35, NULL, 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?auto=format&fit=crop&w=800&q=80', '11111111-1111-1111-1111-111111111111', 'cccccccc-cccc-cccc-cccc-cccccccccccc', true, 70, 'bunch', 4.2, 156),
('10000000-0000-0000-0000-000000000005', 'Full Cream Milk', 'Pasteurized full cream milk, morning delivery favourite.', 32, NULL, 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=800&q=80', '22222222-2222-2222-2222-222222222222', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', true, 180, '500 ml', 4.6, 567),
('10000000-0000-0000-0000-000000000006', 'Brown Bread', 'Soft whole wheat loaf baked for daily breakfast.', 45, NULL, 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=800&q=80', '22222222-2222-2222-2222-222222222222', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', true, 85, 'loaf', 4.4, 290),
('10000000-0000-0000-0000-000000000007', 'Paneer', 'Soft paneer cubes for curries, snacks, and wraps.', 92, 110, 'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?auto=format&fit=crop&w=800&q=80', '22222222-2222-2222-2222-222222222222', 'cccccccc-cccc-cccc-cccc-cccccccccccc', true, 60, '200 g', 4.7, 345),
('10000000-0000-0000-0000-000000000008', 'Potato Chips', 'Classic salted chips for instant snack cravings.', 20, NULL, 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?auto=format&fit=crop&w=800&q=80', '33333333-3333-3333-3333-333333333333', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', true, 250, 'pack', 4.2, 523),
('10000000-0000-0000-0000-000000000009', 'Chocolate Cookies', 'Crunchy chocolate chip cookies for tea-time.', 30, NULL, 'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?auto=format&fit=crop&w=800&q=80', '33333333-3333-3333-3333-333333333333', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', true, 160, 'pack', 4.5, 289),
('10000000-0000-0000-0000-000000000010', 'Mixed Nuts', 'Premium roasted mix of almonds, cashews, and raisins.', 249, 349, 'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?auto=format&fit=crop&w=800&q=80', '33333333-3333-3333-3333-333333333333', 'cccccccc-cccc-cccc-cccc-cccccccccccc', true, 45, '200 g', 4.8, 167),
('10000000-0000-0000-0000-000000000011', 'Orange Juice', 'Refreshing pulp-rich orange juice with no added fizz.', 119, 149, 'https://images.unsplash.com/photo-1600271886742-f049cd451bba?auto=format&fit=crop&w=800&q=80', '44444444-4444-4444-4444-444444444444', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', true, 75, '1 L', 4.3, 198),
('10000000-0000-0000-0000-000000000012', 'Cola', 'Family pack cola for parties and quick meals.', 85, NULL, 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&w=800&q=80', '44444444-4444-4444-4444-444444444444', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', true, 110, '2 L', 4.0, 356),
('10000000-0000-0000-0000-000000000013', 'Mineral Water', 'Purified mineral water, chilled and sealed.', 20, NULL, 'https://images.unsplash.com/photo-1564419320408-38e24e038739?auto=format&fit=crop&w=800&q=80', '44444444-4444-4444-4444-444444444444', 'cccccccc-cccc-cccc-cccc-cccccccccccc', true, 220, '1 L', 4.1, 678),
('10000000-0000-0000-0000-000000000014', 'Butter Croissants', 'Flaky all-butter croissants baked fresh every morning.', 120, NULL, 'https://images.unsplash.com/photo-1555507036-ab794f4afe5a?auto=format&fit=crop&w=800&q=80', '55555555-5555-5555-5555-555555555555', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', true, 38, 'box of 4', 4.5, 167),
('10000000-0000-0000-0000-000000000015', 'Chocolate Cake', 'Rich chocolate celebration cake with soft sponge.', 349, 449, 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?auto=format&fit=crop&w=800&q=80', '55555555-5555-5555-5555-555555555555', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', true, 16, '500 g', 4.8, 234),
('10000000-0000-0000-0000-000000000016', 'Face Wash', 'Gentle daily cleanser with a soft foaming formula.', 149, 199, 'https://images.unsplash.com/photo-1556228578-8c89e6adf883?auto=format&fit=crop&w=800&q=80', '66666666-6666-6666-6666-666666666666', 'cccccccc-cccc-cccc-cccc-cccccccccccc', true, 55, 'tube', 4.4, 256),
('10000000-0000-0000-0000-000000000017', 'Shampoo', 'Smoothening shampoo for everyday use and shine.', 179, NULL, 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=800&q=80', '66666666-6666-6666-6666-666666666666', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', true, 63, '200 ml', 4.3, 345),
('10000000-0000-0000-0000-000000000018', 'Body Lotion', 'Hydrating body lotion with long-lasting moisture.', 210, 260, 'https://images.unsplash.com/photo-1612817159949-195b6eb9e31a?auto=format&fit=crop&w=800&q=80', '66666666-6666-6666-6666-666666666666', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', true, 41, '250 ml', 4.5, 188);

COMMIT;
