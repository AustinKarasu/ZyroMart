# ZyroMart

A Blinkit-style delivery app with red premium branding, 24-hour delivery windows, and 3 app variants (Customer, Store Owner, Delivery Partner).

Built with Flutter, Supabase, and flutter_map.

## Features

- **Customer App**: Browse products, add to cart, place orders, track delivery live on map
- **Store Owner App**: Manage products, view orders, update order status, analytics dashboard
- **Delivery Partner App**: Accept deliveries, navigate with map, update delivery status
- **Red Premium Theme**: ZyroMart branded with `#B71C1C` red theme
- **24-Hour Delivery**: Extended delivery windows unlike Blinkit's 10-minute model
- **Live Tracking**: Real-time delivery person location on interactive map
- **Supabase Integration**: Database, auth, and real-time subscriptions

## Getting Started

```bash
flutter pub get
flutter run
```

## Supabase Setup

Run the SQL schema in `supabase_schema.sql` in your Supabase SQL Editor to create all required tables.

Set environment variables:
```bash
flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
```

## Build APK

```bash
flutter build apk --release --flavor storefront -t lib/main.dart
flutter build apk --release --flavor admin -t lib/admin_main.dart
```

PowerShell shortcuts:
```powershell
.\build_storefront.ps1
.\build_admin.ps1
```

## Build Web

```bash
flutter build web --release
```


## FEEL FREE TO CONTRIBUTE
