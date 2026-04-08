class ErrorMessageService {
  static String from(
    Object error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    final raw = error.toString().replaceFirst('Bad state: ', '').trim();
    final lowered = raw.toLowerCase();

    if (lowered.contains('invalid login credentials') ||
        lowered.contains('invalid_credentials')) {
      return 'The sign-in details are incorrect. Check them and try again.';
    }
    if (lowered.contains('infinite recursion') &&
        lowered.contains('platform_admins')) {
      return 'Admin access is blocked by an outdated backend policy. Apply the latest database schema and try again.';
    }
    if (lowered.contains('profiles_phone') && lowered.contains('duplicate')) {
      return 'That phone number is already linked to another account.';
    }
    if (lowered.contains('user_restock_subscriptions') ||
        lowered.contains('store_feedback') ||
        lowered.contains('schema cache') ||
        lowered.contains('pgrst205')) {
      return 'The live backend schema is not fully applied yet. Refresh the database schema and try again.';
    }
    if (lowered.contains('supabase is not initialized')) {
      return 'The live backend is not available in this build.';
    }
    if (lowered.contains('no store currently serves your delivery location')) {
      return 'No live store is serving this address yet. Refresh location or ask a nearby store to extend its service radius.';
    }
    if (lowered.contains('row-level security') ||
        lowered.contains('permission denied')) {
      return 'This action is not available for the current account.';
    }
    if (lowered.contains('network') ||
        lowered.contains('socketexception') ||
        lowered.contains('timed out')) {
      return 'The network connection is unstable right now. Please try again.';
    }
    return fallback;
  }
}
