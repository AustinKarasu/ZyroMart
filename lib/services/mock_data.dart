import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/store.dart';
import '../models/user.dart';
import '../models/order.dart';
import '../models/cart_item.dart';

class MockData {
  static final List<Category> categories = [
    Category(id: 'cat1', name: 'Fruits & Vegetables', icon: Icons.eco, color: Colors.green),
    Category(id: 'cat2', name: 'Dairy & Bread', icon: Icons.breakfast_dining, color: Colors.orange),
    Category(id: 'cat3', name: 'Snacks', icon: Icons.cookie, color: Colors.amber),
    Category(id: 'cat4', name: 'Beverages', icon: Icons.local_drink, color: Colors.blue),
    Category(id: 'cat5', name: 'Meat & Fish', icon: Icons.set_meal, color: Colors.red),
    Category(id: 'cat6', name: 'Bakery', icon: Icons.cake, color: Colors.brown),
    Category(id: 'cat7', name: 'Personal Care', icon: Icons.face, color: Colors.pink),
    Category(id: 'cat8', name: 'Cleaning', icon: Icons.cleaning_services, color: Colors.teal),
    Category(id: 'cat9', name: 'Baby Care', icon: Icons.child_care, color: Colors.purple),
    Category(id: 'cat10', name: 'Frozen Foods', icon: Icons.ac_unit, color: Colors.cyan),
  ];

  static final List<Product> products = [
    // Fruits & Vegetables
    Product(id: 'p1', name: 'Fresh Bananas', description: 'Organically grown fresh bananas, rich in potassium and natural energy.', price: 45, originalPrice: 60, imageUrl: 'https://picsum.photos/seed/banana/200/200', categoryId: 'cat1', storeId: 's1', unit: 'dozen', rating: 4.5, reviewCount: 234),
    Product(id: 'p2', name: 'Red Apples', description: 'Crispy and sweet red apples from Himachal Pradesh.', price: 180, originalPrice: 220, imageUrl: 'https://picsum.photos/seed/apple/200/200', categoryId: 'cat1', storeId: 's1', unit: 'kg', rating: 4.3, reviewCount: 189),
    Product(id: 'p3', name: 'Baby Spinach', description: 'Fresh organic baby spinach leaves, washed and ready to use.', price: 35, imageUrl: 'https://picsum.photos/seed/spinach/200/200', categoryId: 'cat1', storeId: 's1', unit: 'bunch', rating: 4.2, reviewCount: 156),
    Product(id: 'p4', name: 'Tomatoes', description: 'Farm fresh vine-ripened tomatoes.', price: 40, originalPrice: 55, imageUrl: 'https://picsum.photos/seed/tomato/200/200', categoryId: 'cat1', storeId: 's1', unit: 'kg', rating: 4.1, reviewCount: 312),
    Product(id: 'p5', name: 'Onions', description: 'Red onions, essential for every kitchen.', price: 30, imageUrl: 'https://picsum.photos/seed/onion/200/200', categoryId: 'cat1', storeId: 's1', unit: 'kg', rating: 4.0, reviewCount: 445),
    Product(id: 'p6', name: 'Potatoes', description: 'Fresh potatoes, versatile for any cooking style.', price: 35, imageUrl: 'https://picsum.photos/seed/potato/200/200', categoryId: 'cat1', storeId: 's1', unit: 'kg', rating: 4.0, reviewCount: 389),

    // Dairy & Bread
    Product(id: 'p7', name: 'Full Cream Milk', description: 'Farm fresh pasteurized full cream milk, 500ml.', price: 30, imageUrl: 'https://picsum.photos/seed/milk/200/200', categoryId: 'cat2', storeId: 's1', unit: 'packet', rating: 4.6, reviewCount: 567),
    Product(id: 'p8', name: 'Brown Bread', description: 'Whole wheat brown bread, freshly baked.', price: 45, imageUrl: 'https://picsum.photos/seed/bread/200/200', categoryId: 'cat2', storeId: 's1', unit: 'loaf', rating: 4.4, reviewCount: 290),
    Product(id: 'p9', name: 'Butter (100g)', description: 'Creamy salted butter made from fresh cream.', price: 55, imageUrl: 'https://picsum.photos/seed/butter/200/200', categoryId: 'cat2', storeId: 's1', unit: 'pack', rating: 4.5, reviewCount: 203),
    Product(id: 'p10', name: 'Curd (400g)', description: 'Fresh, creamy and naturally set curd.', price: 40, imageUrl: 'https://picsum.photos/seed/curd/200/200', categoryId: 'cat2', storeId: 's1', unit: 'cup', rating: 4.3, reviewCount: 178),
    Product(id: 'p11', name: 'Paneer (200g)', description: 'Soft and fresh cottage cheese.', price: 90, originalPrice: 110, imageUrl: 'https://picsum.photos/seed/paneer/200/200', categoryId: 'cat2', storeId: 's1', unit: 'pack', rating: 4.7, reviewCount: 345),
    Product(id: 'p12', name: 'Eggs (12 pcs)', description: 'Farm fresh brown eggs, protein rich.', price: 85, imageUrl: 'https://picsum.photos/seed/eggs/200/200', categoryId: 'cat2', storeId: 's1', unit: 'tray', rating: 4.4, reviewCount: 412),

    // Snacks
    Product(id: 'p13', name: 'Potato Chips', description: 'Crispy salted potato chips, perfect for snacking.', price: 20, imageUrl: 'https://picsum.photos/seed/chips/200/200', categoryId: 'cat3', storeId: 's1', unit: 'pack', rating: 4.2, reviewCount: 523),
    Product(id: 'p14', name: 'Chocolate Cookies', description: 'Crunchy cookies with chocolate chips.', price: 30, imageUrl: 'https://picsum.photos/seed/cookie/200/200', categoryId: 'cat3', storeId: 's1', unit: 'pack', rating: 4.5, reviewCount: 289),
    Product(id: 'p15', name: 'Mixed Nuts', description: 'Premium assorted mixed nuts, roasted and salted.', price: 250, originalPrice: 350, imageUrl: 'https://picsum.photos/seed/nuts/200/200', categoryId: 'cat3', storeId: 's1', unit: '200g', rating: 4.8, reviewCount: 167),
    Product(id: 'p16', name: 'Namkeen Mix', description: 'Traditional spicy namkeen snack mix.', price: 45, imageUrl: 'https://picsum.photos/seed/namkeen/200/200', categoryId: 'cat3', storeId: 's1', unit: 'pack', rating: 4.1, reviewCount: 234),

    // Beverages
    Product(id: 'p17', name: 'Orange Juice (1L)', description: 'Fresh squeezed orange juice, no added sugar.', price: 120, originalPrice: 150, imageUrl: 'https://picsum.photos/seed/ojuice/200/200', categoryId: 'cat4', storeId: 's1', unit: 'bottle', rating: 4.3, reviewCount: 198),
    Product(id: 'p18', name: 'Cola (2L)', description: 'Chilled cola soft drink, family pack.', price: 85, imageUrl: 'https://picsum.photos/seed/cola/200/200', categoryId: 'cat4', storeId: 's1', unit: 'bottle', rating: 4.0, reviewCount: 356),
    Product(id: 'p19', name: 'Green Tea (25 bags)', description: 'Premium green tea for a healthy lifestyle.', price: 180, imageUrl: 'https://picsum.photos/seed/tea/200/200', categoryId: 'cat4', storeId: 's1', unit: 'box', rating: 4.6, reviewCount: 145),
    Product(id: 'p20', name: 'Mineral Water (1L)', description: 'Pure mineral water, naturally filtered.', price: 20, imageUrl: 'https://picsum.photos/seed/water/200/200', categoryId: 'cat4', storeId: 's1', unit: 'bottle', rating: 4.1, reviewCount: 678),

    // Meat & Fish
    Product(id: 'p21', name: 'Chicken Breast (500g)', description: 'Fresh boneless chicken breast, cleaned and ready to cook.', price: 200, originalPrice: 250, imageUrl: 'https://picsum.photos/seed/chicken/200/200', categoryId: 'cat5', storeId: 's1', unit: 'pack', rating: 4.4, reviewCount: 234),
    Product(id: 'p22', name: 'Fresh Salmon (300g)', description: 'Norwegian salmon fillet, premium quality.', price: 650, imageUrl: 'https://picsum.photos/seed/salmon/200/200', categoryId: 'cat5', storeId: 's1', unit: 'pack', rating: 4.7, reviewCount: 89),

    // Bakery
    Product(id: 'p23', name: 'Croissants (4 pcs)', description: 'Freshly baked buttery croissants.', price: 120, imageUrl: 'https://picsum.photos/seed/croissant/200/200', categoryId: 'cat6', storeId: 's1', unit: 'box', rating: 4.5, reviewCount: 167),
    Product(id: 'p24', name: 'Chocolate Cake', description: 'Rich dark chocolate cake, 500g.', price: 350, originalPrice: 450, imageUrl: 'https://picsum.photos/seed/chocake/200/200', categoryId: 'cat6', storeId: 's1', unit: 'piece', rating: 4.8, reviewCount: 234),

    // Personal Care
    Product(id: 'p25', name: 'Shampoo (200ml)', description: 'Anti-dandruff shampoo for healthy hair.', price: 180, imageUrl: 'https://picsum.photos/seed/shampoo/200/200', categoryId: 'cat7', storeId: 's1', unit: 'bottle', rating: 4.3, reviewCount: 345),
    Product(id: 'p26', name: 'Face Wash', description: 'Gentle face wash for daily use.', price: 150, originalPrice: 200, imageUrl: 'https://picsum.photos/seed/facewash/200/200', categoryId: 'cat7', storeId: 's1', unit: 'tube', rating: 4.4, reviewCount: 256),

    // Cleaning
    Product(id: 'p27', name: 'Dish Soap (500ml)', description: 'Powerful grease-cutting dish soap with lemon.', price: 65, imageUrl: 'https://picsum.photos/seed/dishsoap/200/200', categoryId: 'cat8', storeId: 's1', unit: 'bottle', rating: 4.2, reviewCount: 189),
    Product(id: 'p28', name: 'Floor Cleaner (1L)', description: 'Disinfecting floor cleaner with lavender fragrance.', price: 120, imageUrl: 'https://picsum.photos/seed/cleaner/200/200', categoryId: 'cat8', storeId: 's1', unit: 'bottle', rating: 4.1, reviewCount: 234),
  ];

  static final List<Store> stores = [
    Store(
      id: 's1',
      name: 'ZyroMart Central',
      address: '123 Main Street, Sector 15, Noida',
      location: const LatLng(28.5850, 77.3100),
      rating: 4.6,
      imageUrl: 'https://picsum.photos/seed/store1/400/200',
      ownerId: 'owner1',
      phone: '+91 9876543210',
      totalOrders: 1245,
      totalRevenue: 345670.0,
    ),
    Store(
      id: 's2',
      name: 'ZyroMart Express',
      address: '45 Park Avenue, Sector 18, Noida',
      location: const LatLng(28.5700, 77.3200),
      rating: 4.4,
      imageUrl: 'https://picsum.photos/seed/store2/400/200',
      ownerId: 'owner2',
      phone: '+91 9876543211',
      totalOrders: 890,
      totalRevenue: 234560.0,
    ),
  ];

  static final List<AppUser> deliveryPersons = [
    AppUser(
      id: 'del1',
      name: 'Rahul Kumar',
      email: 'rahul@zyromart.com',
      phone: '+91 9876543215',
      role: UserRole.delivery,
      location: const LatLng(28.5800, 77.3150),
      deliveryRating: 4.7,
      completedDeliveries: 456,
    ),
    AppUser(
      id: 'del2',
      name: 'Amit Singh',
      email: 'amit@zyromart.com',
      phone: '+91 9876543216',
      role: UserRole.delivery,
      location: const LatLng(28.5750, 77.3100),
      deliveryRating: 4.5,
      completedDeliveries: 312,
    ),
  ];

  static AppUser get defaultCustomer => AppUser(
    id: 'cust1',
    name: 'Aayan',
    email: 'aayan@gmail.com',
    phone: '+91 9876543220',
    role: UserRole.customer,
    address: '78 Residency Road, Sector 22, Noida',
    location: const LatLng(28.5900, 77.3050),
  );

  static AppUser get defaultStoreOwner => AppUser(
    id: 'owner1',
    name: 'Priya Sharma',
    email: 'priya@zyromart.com',
    phone: '+91 9876543210',
    role: UserRole.storeOwner,
    address: '123 Main Street, Sector 15, Noida',
    location: const LatLng(28.5850, 77.3100),
  );

  static List<Order> get sampleOrders {
    final now = DateTime.now();
    return [
      Order(
        id: 'ORD001',
        items: [
          CartItem(product: products[0], quantity: 2),
          CartItem(product: products[6], quantity: 3),
          CartItem(product: products[7], quantity: 1),
        ],
        totalAmount: 225,
        status: OrderStatus.outForDelivery,
        customerId: 'cust1',
        customerName: 'Aayan',
        storeId: 's1',
        storeName: 'ZyroMart Central',
        deliveryPersonId: 'del1',
        deliveryPersonName: 'Rahul Kumar',
        deliveryAddress: '78 Residency Road, Sector 22, Noida',
        placedAt: now.subtract(const Duration(hours: 2)),
        estimatedDelivery: now.add(const Duration(hours: 22)),
        customerLocation: const LatLng(28.5900, 77.3050),
        storeLocation: const LatLng(28.5850, 77.3100),
        deliveryPersonLocation: const LatLng(28.5870, 77.3080),
      ),
      Order(
        id: 'ORD002',
        items: [
          CartItem(product: products[14], quantity: 1),
          CartItem(product: products[16], quantity: 2),
        ],
        totalAmount: 490,
        status: OrderStatus.preparing,
        customerId: 'cust1',
        customerName: 'Aayan',
        storeId: 's1',
        storeName: 'ZyroMart Central',
        deliveryAddress: '78 Residency Road, Sector 22, Noida',
        placedAt: now.subtract(const Duration(hours: 1)),
        estimatedDelivery: now.add(const Duration(hours: 23)),
        customerLocation: const LatLng(28.5900, 77.3050),
        storeLocation: const LatLng(28.5850, 77.3100),
      ),
      Order(
        id: 'ORD003',
        items: [
          CartItem(product: products[10], quantity: 2),
          CartItem(product: products[8], quantity: 1),
          CartItem(product: products[11], quantity: 1),
        ],
        totalAmount: 320,
        status: OrderStatus.delivered,
        customerId: 'cust1',
        customerName: 'Aayan',
        storeId: 's1',
        storeName: 'ZyroMart Central',
        deliveryPersonId: 'del2',
        deliveryPersonName: 'Amit Singh',
        deliveryAddress: '78 Residency Road, Sector 22, Noida',
        placedAt: now.subtract(const Duration(days: 1)),
        estimatedDelivery: now.subtract(const Duration(hours: 1)),
        customerLocation: const LatLng(28.5900, 77.3050),
        storeLocation: const LatLng(28.5850, 77.3100),
      ),
    ];
  }
}
