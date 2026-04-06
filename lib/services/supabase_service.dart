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

  static Future<List<Map<String, dynamic>>> searchProducts({
    required String query,
    String localeCode = 'en-IN',
  }) async {
    if (!isInitialized || query.trim().isEmpty) return [];
    final trimmed = query.trim();
    final keywordRows = await client
        .from('search_keywords')
        .select('product_id')
        .eq('locale_code', localeCode)
        .ilike('keyword', '%$trimmed%');
    final keywordProductIds = keywordRows
        .map((row) => row['product_id']?.toString())
        .whereType<String>()
        .toSet();
    final directRows = await client
        .from('products')
        .select()
        .or('name.ilike.%$trimmed%,description.ilike.%$trimmed%');
    final merged = <String, Map<String, dynamic>>{};
    for (final row in List<Map<String, dynamic>>.from(directRows)) {
      merged[row['id'].toString()] = row;
    }
    if (keywordProductIds.isNotEmpty) {
      final keywordMatches = await client
          .from('products')
          .select()
          .inFilter('id', keywordProductIds.toList());
      for (final row in List<Map<String, dynamic>>.from(keywordMatches)) {
        merged[row['id'].toString()] = row;
      }
    }
    return merged.values.toList();
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

  static Future<Map<String, dynamic>?> getProductMetadata(String productId) async {
    if (!isInitialized) return null;
    final response = await client
        .from('product_catalog_metadata')
        .select()
        .eq('product_id', productId)
        .maybeSingle();
    return response == null ? null : Map<String, dynamic>.from(response);
  }

  static Future<void> upsertProductMetadata(Map<String, dynamic> metadata) async {
    if (!isInitialized) return;
    await client.from('product_catalog_metadata').upsert(metadata);
  }

  static Future<void> replaceSearchKeywords({
    required String productId,
    required String localeCode,
    required List<String> keywords,
  }) async {
    if (!isInitialized) return;
    await client
        .from('search_keywords')
        .delete()
        .eq('product_id', productId)
        .eq('locale_code', localeCode);
    if (keywords.isEmpty) return;
    await client.from('search_keywords').insert(
          keywords
              .map(
                (keyword) => {
                  'product_id': productId,
                  'locale_code': localeCode,
                  'keyword': keyword.trim(),
                },
              )
              .toList(),
        );
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

  static Future<void> createOrderItems(
      List<Map<String, dynamic>> items) async {
    if (!isInitialized || items.isEmpty) return;
    await client.from('order_items').insert(items);
  }

  static Future<void> updateOrderStatus(String id, String status) async {
    if (!isInitialized) return;
    await client.from('orders').update({'status': status}).eq('id', id);
  }

  static Future<void> insertOrderStatusEvent(Map<String, dynamic> event) async {
    if (!isInitialized) return;
    await client.from('order_status_events').insert(event);
  }

  static Future<List<Map<String, dynamic>>> getOrderStatusEvents(
      String orderId) async {
    if (!isInitialized) return [];
    final response = await client
        .from('order_status_events')
        .select()
        .eq('order_id', orderId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> reserveInventory(
      List<Map<String, dynamic>> reservations) async {
    if (!isInitialized || reservations.isEmpty) return;
    await client.from('inventory_reservations').insert(reservations);
  }

  static Future<void> updateInventoryReservationStatus({
    required String orderId,
    required String status,
  }) async {
    if (!isInitialized) return;
    await client
        .from('inventory_reservations')
        .update({
          'reservation_status': status,
          'released_at':
              status == 'released' ? DateTime.now().toIso8601String() : null,
        })
        .eq('order_id', orderId);
  }

  static Future<List<Map<String, dynamic>>> getInventoryReservations(
      String orderId) async {
    if (!isInitialized) return [];
    final response = await client
        .from('inventory_reservations')
        .select()
        .eq('order_id', orderId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> insertDeliveryRouteUpdate(
      Map<String, dynamic> update) async {
    if (!isInitialized) return;
    await client.from('delivery_route_updates').insert(update);
  }

  static Future<List<Map<String, dynamic>>> getDeliveryRouteUpdates(
      String orderId) async {
    if (!isInitialized) return [];
    final response = await client
        .from('delivery_route_updates')
        .select()
        .eq('order_id', orderId)
        .order('captured_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> saveProofOfDelivery(Map<String, dynamic> proof) async {
    if (!isInitialized) return;
    await client.from('proof_of_delivery').upsert(proof, onConflict: 'order_id');
  }

  static Future<Map<String, dynamic>?> getProofOfDelivery(String orderId) async {
    if (!isInitialized) return null;
    final response = await client
        .from('proof_of_delivery')
        .select()
        .eq('order_id', orderId)
        .maybeSingle();
    return response == null ? null : Map<String, dynamic>.from(response);
  }

  // ─── Stores ──────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getStores() async {
    if (!isInitialized) return [];
    final response = await client.from('stores').select();
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getStoreServiceAreas() async {
    if (!isInitialized) return [];
    final response = await client.from('store_service_areas').select();
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> upsertStoreServiceArea(Map<String, dynamic> area) async {
    if (!isInitialized) return;
    await client.from('store_service_areas').upsert(area);
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

  static Future<void> upsertNotificationDevice({
    required String deviceToken,
    required String platform,
    required String appVariant,
    String localeCode = 'en-IN',
    String? timezoneName,
    bool pushEnabled = true,
  }) async {
    if (!isInitialized || currentUser == null) return;
    await client.from('notification_devices').upsert(
      {
        'user_id': currentUser!.id,
        'device_token': deviceToken,
        'platform': platform,
        'app_variant': appVariant,
        'locale_code': localeCode,
        'timezone_name': timezoneName,
        'push_enabled': pushEnabled,
        'last_seen_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'device_token',
    );
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    if (!isInitialized || currentUser == null) return [];
    final response = await client
        .from('notifications')
        .select()
        .eq('user_id', currentUser!.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> markNotificationRead(String notificationId) async {
    if (!isInitialized || currentUser == null) return;
    await client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('user_id', currentUser!.id);
  }

  static Future<void> logUserActivity({
    required String eventType,
    String? productId,
    String? orderId,
    String? eventValue,
    double? budgetHint,
  }) async {
    if (!isInitialized || currentUser == null) return;
    await client.from('user_activity_events').insert({
      'user_id': currentUser!.id,
      'product_id': productId,
      'order_id': orderId,
      'event_type': eventType,
      'event_value': eventValue,
      'budget_hint': budgetHint,
    });
  }

  static Future<List<Map<String, dynamic>>> getRecommendations() async {
    if (!isInitialized || currentUser == null) return [];
    final response = await client
        .from('product_recommendations')
        .select('*, products(*)')
        .eq('user_id', currentUser!.id)
        .order('score', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> upsertRestockSubscription(
      Map<String, dynamic> payload) async {
    if (!isInitialized || currentUser == null) return;
    await client.from('user_restock_subscriptions').upsert({
      ...payload,
      'user_id': currentUser!.id,
    });
  }

  static Future<List<Map<String, dynamic>>> getRestockSubscriptions() async {
    if (!isInitialized || currentUser == null) return [];
    final response = await client
        .from('user_restock_subscriptions')
        .select('*, products(*)')
        .eq('user_id', currentUser!.id)
        .order('next_run_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

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

  static RealtimeChannel subscribeToNotifications(
      void Function(Map<String, dynamic>) onInsert) {
    return client
        .channel('notifications_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) => onInsert(payload.newRecord),
        )
        .subscribe();
  }

  static RealtimeChannel subscribeToOrderStatusEvents(
      String orderId, void Function(Map<String, dynamic>) onInsert) {
    return client
        .channel('order_events_$orderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'order_status_events',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'order_id',
            value: orderId,
          ),
          callback: (payload) => onInsert(payload.newRecord),
        )
        .subscribe();
  }
}
