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

  static Future<List<Map<String, dynamic>>> getCategories() async {
    if (!isInitialized) return [];
    final response = await client
        .from('categories')
        .select()
        .order('sort_order', ascending: true);
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

  static Future<Map<String, dynamic>?> getMyProfile() async {
    if (!isInitialized || currentUser == null) return null;
    final response = await client
        .from('profiles')
        .select()
        .eq('id', currentUser!.id)
        .maybeSingle();
    return response == null ? null : Map<String, dynamic>.from(response);
  }

  static Future<void> upsertProfile(Map<String, dynamic> profile) async {
    if (!isInitialized) return;
    await client.from('profiles').upsert(profile);
  }

  static Future<Map<String, dynamic>?> getPlatformAdminEntry() async {
    if (!isInitialized || currentUser == null) return null;
    final response = await client
        .from('platform_admins')
        .select()
        .eq('user_id', currentUser!.id)
        .maybeSingle();
    return response == null ? null : Map<String, dynamic>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getProfiles() async {
    if (!isInitialized) return [];
    final response = await client.from('profiles').select();
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getPlatformDailyMetrics({
    int limit = 7,
  }) async {
    if (!isInitialized) return [];
    final response = await client
        .from('platform_daily_metrics')
        .select()
        .order('metric_date', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getEarningsLedger({
    String? beneficiaryRole,
  }) async {
    if (!isInitialized) return [];
    var query = client.from('earnings_ledger').select();
    if (beneficiaryRole != null && beneficiaryRole.isNotEmpty) {
      query = query.eq('beneficiary_role', beneficiaryRole);
    }
    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> updateAccount({
    String? email,
    String? password,
    Map<String, dynamic>? data,
  }) async {
    if (!isInitialized) return;
    await client.auth.updateUser(
      UserAttributes(
        email: email,
        password: password,
        data: data,
      ),
    );
  }

  // ─── Users / Auth ────────────────────────────────────────

  static Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(email: email, password: password);
  }

  static Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth
        .signInWithPassword(email: email, password: password);
  }

  static Future<void> requestEmailOtp({
    required String email,
    required String userName,
    required String role,
  }) async {
    await client.auth.signInWithOtp(
      email: email,
      data: {
        'name': userName,
        'role': role,
      },
    );
  }

  static Future<void> requestPhoneOtp({
    required String phone,
    required String userName,
    required String role,
    String? email,
  }) async {
    await client.auth.signInWithOtp(
      phone: phone,
      data: {
        'name': userName,
        'role': role,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      },
    );
  }

  static Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String otpCode,
  }) async {
    return await client.auth.verifyOTP(
      email: email,
      token: otpCode,
      type: OtpType.email,
    );
  }

  static Future<AuthResponse> verifyPhoneOtp({
    required String phone,
    required String otpCode,
  }) async {
    return await client.auth.verifyOTP(
      phone: phone,
      token: otpCode,
      type: OtpType.sms,
    );
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
