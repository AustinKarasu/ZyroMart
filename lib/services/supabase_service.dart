import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static String? _initializationError;
  static bool _initialized = false;

  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError(
        'Supabase is not initialized. Verify SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
    return Supabase.instance.client;
  }

  static void _ensureInitialized() {
    if (!isInitialized) {
      throw StateError(
        'Supabase is not initialized. Verify SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
  }

  static Future<void> initialize() async {
    if (_initialized) return;
    _initializationError = null;
    final url = SupabaseConfig.supabaseUrl;
    final anonKey = SupabaseConfig.supabaseAnonKey;
    if (url.isEmpty || anonKey.isEmpty) {
      _initialized = false;
      _initializationError =
          'Supabase URL or anon key is missing in this build configuration.';
      return;
    }
    try {
      await Supabase.initialize(url: url, anonKey: anonKey);
      _initialized = true;
    } catch (error) {
      _initialized = false;
      _initializationError = error.toString();
      rethrow;
    }
  }

  static bool get isInitialized => _initialized;
  static String? get initializationError => _initializationError;
  static String get backendStatusMessage =>
      _initializationError ??
      'Supabase is not initialized. Verify SUPABASE_URL and SUPABASE_ANON_KEY.';

  // â”€â”€â”€ Products â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
    String id,
    Map<String, dynamic> updates,
  ) async {
    if (!isInitialized) return;
    await client.from('products').update(updates).eq('id', id);
  }

  static Future<void> deleteProduct(String id) async {
    if (!isInitialized) return;
    await client.from('products').delete().eq('id', id);
  }

  static Future<Map<String, dynamic>?> getProductMetadata(
    String productId,
  ) async {
    if (!isInitialized) return null;
    final response = await client
        .from('product_catalog_metadata')
        .select()
        .eq('product_id', productId)
        .maybeSingle();
    return response == null ? null : Map<String, dynamic>.from(response);
  }

  static Future<void> upsertProductMetadata(
    Map<String, dynamic> metadata,
  ) async {
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
    await client
        .from('search_keywords')
        .insert(
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

  // â”€â”€â”€ Orders â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<List<Map<String, dynamic>>> getOrders() async {
    if (!isInitialized) return [];
    final response = await client
        .from('orders')
        .select('*, order_items(*, products(*))')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>> createOrder(
    Map<String, dynamic> order,
  ) async {
    if (!isInitialized) return {};
    final response = await client
        .from('orders')
        .insert(order)
        .select()
        .single();
    return response;
  }

  static Future<void> createOrderItems(List<Map<String, dynamic>> items) async {
    if (!isInitialized || items.isEmpty) return;
    await client.from('order_items').insert(items);
  }

  static Future<void> updateOrderStatus(String id, String status) async {
    if (!isInitialized) return;
    await client.from('orders').update({'status': status}).eq('id', id);
  }

  static Future<void> updateOrder(
    String id,
    Map<String, dynamic> updates,
  ) async {
    if (!isInitialized || id.isEmpty || updates.isEmpty) return;
    await client.from('orders').update(updates).eq('id', id);
  }

  static Future<void> insertOrderStatusEvent(Map<String, dynamic> event) async {
    if (!isInitialized) return;
    await client.from('order_status_events').insert(event);
  }

  static Future<List<Map<String, dynamic>>> getOrderStatusEvents(
    String orderId,
  ) async {
    if (!isInitialized) return [];
    final response = await client
        .from('order_status_events')
        .select()
        .eq('order_id', orderId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> reserveInventory(
    List<Map<String, dynamic>> reservations,
  ) async {
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
          'released_at': status == 'released'
              ? DateTime.now().toIso8601String()
              : null,
        })
        .eq('order_id', orderId);
  }

  static Future<List<Map<String, dynamic>>> getInventoryReservations(
    String orderId,
  ) async {
    if (!isInitialized) return [];
    final response = await client
        .from('inventory_reservations')
        .select()
        .eq('order_id', orderId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> insertDeliveryRouteUpdate(
    Map<String, dynamic> update,
  ) async {
    if (!isInitialized) return;
    await client.from('delivery_route_updates').insert(update);
  }

  static Future<List<Map<String, dynamic>>> getDeliveryRouteUpdates(
    String orderId,
  ) async {
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
    await client
        .from('proof_of_delivery')
        .upsert(proof, onConflict: 'order_id');
  }

  static Future<Map<String, dynamic>?> getProofOfDelivery(
    String orderId,
  ) async {
    if (!isInitialized) return null;
    final response = await client
        .from('proof_of_delivery')
        .select()
        .eq('order_id', orderId)
        .maybeSingle();
    return response == null ? null : Map<String, dynamic>.from(response);
  }

  // â”€â”€â”€ Stores â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<List<Map<String, dynamic>>> getStores() async {
    if (!isInitialized) return [];
    final response = await client.from('stores').select();
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> getStoreByOwner(String ownerId) async {
    if (!isInitialized || ownerId.isEmpty) return null;
    final response = await client
        .from('stores')
        .select()
        .eq('owner_id', ownerId)
        .maybeSingle();
    return response == null ? null : Map<String, dynamic>.from(response);
  }

  static Future<void> updateStore(
    String storeId,
    Map<String, dynamic> payload,
  ) async {
    _ensureInitialized();
    if (storeId.isEmpty) return;
    await client.from('stores').update(payload).eq('id', storeId);
  }

  static Future<Map<String, dynamic>?> upsertOwnerStore({
    required String ownerId,
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    String? phone,
  }) async {
    _ensureInitialized();
    if (ownerId.isEmpty) return null;
    final existing = await getStoreByOwner(ownerId);
    final payload = <String, dynamic>{
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'owner_id': ownerId,
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
    };

    if (existing != null) {
      await client.from('stores').update(payload).eq('id', existing['id']);
      return await getStoreByOwner(ownerId);
    }

    final response = await client
        .from('stores')
        .insert(payload)
        .select()
        .single();
    return Map<String, dynamic>.from(response);
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

  static Future<Map<String, dynamic>?> getProfileByPhone(String phone) async {
    if (!isInitialized || phone.trim().isEmpty) return null;
    final response = await client
        .from('profiles')
        .select()
        .eq('phone', phone.trim())
        .maybeSingle();
    return response == null ? null : Map<String, dynamic>.from(response);
  }

  static Future<void> upsertProfile(Map<String, dynamic> profile) async {
    _ensureInitialized();
    await client.from('profiles').upsert(profile);
  }

  static Future<Map<String, dynamic>> updateProfileRole({
    required String profileId,
    required String role,
  }) async {
    _ensureInitialized();
    final response = await client
        .from('profiles')
        .update({'role': role})
        .eq('id', profileId)
        .select('id, role')
        .single();
    return Map<String, dynamic>.from(response);
  }

  static Future<Map<String, dynamic>?> getPlatformAdminEntry() async {
    if (!isInitialized || currentUser == null) return null;
    try {
      final adminAllowed = await client.rpc(
        'is_platform_admin',
        params: {'candidate_user_id': currentUser!.id},
      );
      if (adminAllowed != true) {
        return null;
      }
    } catch (_) {
      // Fall back to direct table access for projects that have not applied the
      // helper function yet.
    }
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

  static Future<Map<String, dynamic>?> getUserAccountState() async {
    if (!isInitialized || currentUser == null) return null;
    final response = await client
        .from('user_account_state')
        .select()
        .eq('user_id', currentUser!.id)
        .maybeSingle();
    return response == null ? null : Map<String, dynamic>.from(response);
  }

  static Future<void> upsertUserAccountState(
    Map<String, dynamic> payload,
  ) async {
    _ensureInitialized();
    if (currentUser == null) {
      throw StateError('You need to be signed in to save account state.');
    }
    await client.from('user_account_state').upsert({
      ...payload,
      'user_id': currentUser!.id,
    });
  }

  static Future<Map<String, dynamic>?> getOperatorPreferences({
    required String appVariant,
  }) async {
    if (!isInitialized || currentUser == null) return null;
    final response = await client
        .from('operator_preferences')
        .select()
        .eq('user_id', currentUser!.id)
        .eq('app_variant', appVariant)
        .maybeSingle();
    return response == null ? null : Map<String, dynamic>.from(response);
  }

  static Future<void> upsertOperatorPreferences({
    required String appVariant,
    required Map<String, dynamic> settings,
  }) async {
    _ensureInitialized();
    if (currentUser == null) {
      throw StateError('You need to be signed in to save operator preferences.');
    }
    await client.from('operator_preferences').upsert({
      'user_id': currentUser!.id,
      'app_variant': appVariant,
      'settings': settings,
    });
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
      UserAttributes(email: email, password: password, data: data),
    );
  }

  // â”€â”€â”€ Users / Auth â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<AuthResponse> signUp(String email, String password) async {
    _ensureInitialized();
    return await client.auth.signUp(email: email, password: password);
  }

  static Future<AuthResponse> signIn(String email, String password) async {
    _ensureInitialized();
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> requestEmailOtp({
    required String email,
    required String userName,
    required String role,
  }) async {
    _ensureInitialized();
    await client.auth.signInWithOtp(
      email: email,
      data: {'name': userName, 'role': role},
    );
  }

  static Future<void> requestPhoneOtp({
    required String phone,
    required String userName,
    required String role,
    String? email,
  }) async {
    _ensureInitialized();
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
    _ensureInitialized();
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
    _ensureInitialized();
    return await client.auth.verifyOTP(
      phone: phone,
      token: otpCode,
      type: OtpType.sms,
    );
  }

  static Future<void> signOut() async {
    _ensureInitialized();
    await client.auth.signOut();
  }

  static User? get currentUser =>
      isInitialized ? client.auth.currentUser : null;

  static Future<void> upsertNotificationDevice({
    required String deviceToken,
    required String platform,
    required String appVariant,
    String localeCode = 'en-IN',
    String? timezoneName,
    bool pushEnabled = true,
  }) async {
    _ensureInitialized();
    if (currentUser == null) {
      throw StateError('You need to be signed in to register this device.');
    }
    await client.from('notification_devices').upsert({
      'user_id': currentUser!.id,
      'device_token': deviceToken,
      'platform': platform,
      'app_variant': appVariant,
      'locale_code': localeCode,
      'timezone_name': timezoneName,
      'push_enabled': pushEnabled,
      'last_seen_at': DateTime.now().toIso8601String(),
    }, onConflict: 'device_token');
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


  static Future<Map<String, dynamic>?> getNotificationPreferences() async {
    if (!isInitialized || currentUser == null) return null;
    final response = await client
        .from('notification_preferences')
        .select()
        .eq('user_id', currentUser!.id)
        .maybeSingle();
    return response == null ? null : Map<String, dynamic>.from(response);
  }

  static Future<void> upsertNotificationPreferences(
    Map<String, dynamic> payload,
  ) async {
    _ensureInitialized();
    if (currentUser == null) {
      throw StateError('You need to be signed in to save notification preferences.');
    }
    await client.from('notification_preferences').upsert({
      ...payload,
      'user_id': currentUser!.id,
    });
  }
  static Future<void> insertAppUsageEvent(Map<String, dynamic> payload) async {
    if (!isInitialized) return;
    await client.from('app_usage_events').insert({
      ...payload,
      if (currentUser != null) 'user_id': currentUser!.id,
    });
  }

  static Future<void> insertCrashReport(Map<String, dynamic> payload) async {
    if (!isInitialized) return;
    await client.from('app_crash_reports').insert({
      ...payload,
      if (currentUser != null) 'user_id': currentUser!.id,
    });
  }

  static Future<List<Map<String, dynamic>>> getAppUsageEvents({
    int limit = 100,
  }) async {
    if (!isInitialized) return [];
    final response = await client
        .from('app_usage_events')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getCrashReports({
    int limit = 50,
  }) async {
    if (!isInitialized) return [];
    final response = await client
        .from('app_crash_reports')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
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

  static Future<List<Map<String, dynamic>>> getStoreFeedback({
    String? orderId,
    String? storeId,
  }) async {
    if (!isInitialized) return [];
    var query = client.from('store_feedback').select();
    if (orderId != null && orderId.isNotEmpty) {
      query = query.eq('order_id', orderId);
    }
    if (storeId != null && storeId.isNotEmpty) {
      query = query.eq('store_id', storeId);
    }
    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
  static Future<void> insertStoreFeedback(Map<String, dynamic> payload) async {
    if (!isInitialized || currentUser == null) return;
    await client.from('store_feedback').insert({
      ...payload,
      'customer_id': currentUser!.id,
    });
  }
  static Future<List<Map<String, dynamic>>> getDeliveryFeedback({
    String? orderId,
    String? deliveryPersonId,
  }) async {
    if (!isInitialized) return [];
    var query = client.from('delivery_feedback').select();
    if (orderId != null && orderId.isNotEmpty) {
      query = query.eq('order_id', orderId);
    }
    if (deliveryPersonId != null && deliveryPersonId.isNotEmpty) {
      query = query.eq('delivery_person_id', deliveryPersonId);
    }
    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
  static Future<void> insertDeliveryFeedback(
    Map<String, dynamic> payload,
  ) async {
    if (!isInitialized || currentUser == null) return;
    await client.from('delivery_feedback').insert({
      ...payload,
      'customer_id': currentUser!.id,
    });
  }
  static Future<void> upsertRestockSubscription(
    Map<String, dynamic> payload,
  ) async {
    _ensureInitialized();
    if (currentUser == null) {
      throw StateError('You need to be signed in to save restock subscriptions.');
    }
    await client.from('user_restock_subscriptions').upsert({
      ...payload,
      'user_id': currentUser!.id,
    });
  }

  static Future<List<Map<String, dynamic>>> getRestockSubscriptions() async {
    if (!isInitialized || currentUser == null) return [];
    final subscriptions = await client
        .from('user_restock_subscriptions')
        .select()
        .eq('user_id', currentUser!.id)
        .order('next_run_at', ascending: true);

    final rows = List<Map<String, dynamic>>.from(subscriptions);
    if (rows.isEmpty) return rows;

    final productIds = rows
        .map((row) => row['product_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (productIds.isEmpty) return rows;

    final products = await client
        .from('products')
        .select('id,name')
        .inFilter('id', productIds);
    final nameById = <String, String>{};
    for (final row in List<Map<String, dynamic>>.from(products)) {
      final id = row['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      nameById[id] = (row['name'] ?? '').toString();
    }

    return rows
        .map((row) => {
              ...row,
              'products': {
                'name': nameById[row['product_id']?.toString() ?? ''] ?? '',
              },
            })
        .toList();
  }

  // â”€â”€â”€ Real-time subscriptions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static RealtimeChannel subscribeToOrders(
    void Function(Map<String, dynamic>) onUpdate,
  ) {
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
    String orderId,
    void Function(Map<String, dynamic>) onUpdate,
  ) {
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
    void Function(Map<String, dynamic>) onInsert,
  ) {
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
    String orderId,
    void Function(Map<String, dynamic>) onInsert,
  ) {
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





