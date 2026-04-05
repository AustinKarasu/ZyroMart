import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    final anonKey = SupabaseConfig.supabaseAnonKey;
    if (anonKey.isEmpty) {
      // Skip Supabase initialization if no key is configured.
      // The app will use mock data instead.
      return;
    }
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: anonKey,
    );
  }

  static bool get isInitialized {
    try {
      Supabase.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Products ────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getProducts() async {
    if (!isInitialized) return [];
    final response = await client.from('products').select();
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> addProduct(Map<String, dynamic> product) async {
    if (!isInitialized) return;
    await client.from('products').insert(product);
  }

  static Future<void> updateProduct(
      String id, Map<String, dynamic> updates) async {
    if (!isInitialized) return;
    await client.from('products').update(updates).eq('id', id);
  }

  static Future<void> deleteProduct(String id) async {
    if (!isInitialized) return;
    await client.from('products').delete().eq('id', id);
  }

  // ─── Orders ──────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getOrders() async {
    if (!isInitialized) return [];
    final response = await client
        .from('orders')
        .select('*, order_items(*, products(*))')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>> createOrder(
      Map<String, dynamic> order) async {
    if (!isInitialized) return {};
    final response =
        await client.from('orders').insert(order).select().single();
    return response;
  }

  static Future<void> updateOrderStatus(String id, String status) async {
    if (!isInitialized) return;
    await client.from('orders').update({'status': status}).eq('id', id);
  }

  // ─── Stores ──────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getStores() async {
    if (!isInitialized) return [];
    final response = await client.from('stores').select();
    return List<Map<String, dynamic>>.from(response);
  }

  // ─── Users / Auth ────────────────────────────────────────

  static Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(email: email, password: password);
  }

  static Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth
        .signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static User? get currentUser => isInitialized ? client.auth.currentUser : null;

  // ─── Real-time subscriptions ─────────────────────────────

  static RealtimeChannel subscribeToOrders(
      void Function(Map<String, dynamic>) onUpdate) {
    return client
        .channel('orders_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
  }

  static RealtimeChannel subscribeToDeliveryLocation(
      String orderId, void Function(Map<String, dynamic>) onUpdate) {
    return client
        .channel('delivery_$orderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'delivery_tracking',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'order_id',
            value: orderId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
  }
}
