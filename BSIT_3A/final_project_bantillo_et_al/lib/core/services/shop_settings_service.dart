// Loads the shop settings ONCE and shares them app-wide (shop_settings
// table, 0016_shop_settings.sql).
//
//   * [current] is always usable: it starts as ShopSettings.defaults (the
//     shop_contact.dart values) and becomes the database row once loaded.
//   * [load] never throws: on failure it keeps the defaults, so payment
//     instructions and the Contact the shop dialog always show numbers.
//     The result is cached; a failed load is retried on the next call.
//   * [fetch] DOES throw (friendly message): the Shop settings screen uses
//     it to show the error with Retry instead of silently editing defaults.
//   * [save] calls update_shop_settings (owner only, checked in SQL) and
//     updates the cache, so every screen shows the new values at once.
//   * It is a ChangeNotifier: widgets wrap themselves in a
//     ListenableBuilder and redraw when the settings arrive or change.
//
// Example:
//   final settings = await ShopSettingsService.instance.load();
//   ChecklistRules.lateFee(..., perDay: settings.lateFeePerDay);
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/foundation.dart';

import 'package:orange150_rental/core/config/shop_settings.dart';
import 'package:orange150_rental/core/services/supabase_service.dart';
import 'package:orange150_rental/core/utils/error_messages.dart';

/// Thrown by [ShopSettingsService.fetch] and [ShopSettingsService.save] with
/// a message that is safe to show.
class ShopSettingsException implements Exception {
  /// Creates the exception.
  const ShopSettingsException(this.message);

  /// Friendly text.
  final String message;

  @override
  String toString() => message;
}

/// Where the settings row comes from. Replaced by a fake in tests.
abstract interface class ShopSettingsApi {
  /// The shop_settings row (null when there is none).
  Future<Map<String, dynamic>?> readRow();

  /// Calls update_shop_settings and returns the saved row.
  Future<Map<String, dynamic>> update(Map<String, dynamic> params);
}

/// The real Supabase calls.
class SupabaseShopSettingsApi implements ShopSettingsApi {
  /// Creates it.
  const SupabaseShopSettingsApi();

  @override
  Future<Map<String, dynamic>?> readRow() => SupabaseService.client
      .from('shop_settings')
      .select()
      .eq('id', 1)
      .maybeSingle();

  @override
  Future<Map<String, dynamic>> update(Map<String, dynamic> params) async {
    final row = await SupabaseService.client.rpc(
      'update_shop_settings',
      params: params,
    );
    return Map<String, dynamic>.from(row as Map);
  }
}

/// App-wide shop settings with a cache.
class ShopSettingsService extends ChangeNotifier {
  /// Creates a service; tests pass a fake [api].
  ShopSettingsService({this._api = const SupabaseShopSettingsApi()});

  /// The shared instance used by the app.
  static final ShopSettingsService instance = ShopSettingsService();

  final ShopSettingsApi _api;
  ShopSettings _current = ShopSettings.defaults;
  bool _loaded = false;
  Future<ShopSettings>? _inFlight;

  /// The settings to show right now (defaults until loaded).
  ShopSettings get current => _current;

  /// True once the database row has been read.
  bool get isLoaded => _loaded;

  /// Starts loading if that has not happened yet. Safe to call from build.
  void ensureLoaded() {
    if (!_loaded && _inFlight == null) load();
  }

  /// The settings, loaded once and cached. Never throws: falls back to
  /// [ShopSettings.defaults] (or the last loaded values).
  Future<ShopSettings> load() async {
    if (_loaded) return _current;
    try {
      return await fetch();
    } catch (error) {
      debugPrint('Shop settings not loaded, using defaults: $error');
      return _current;
    }
  }

  /// Reads the row from the database (concurrent calls share one request).
  /// Throws [ShopSettingsException] when it cannot be read.
  Future<ShopSettings> fetch() =>
      _inFlight ??= _read().whenComplete(() => _inFlight = null);

  Future<ShopSettings> _read() async {
    try {
      final row = await _api.readRow();
      _set(row == null ? ShopSettings.defaults : ShopSettings.fromMap(row));
      return _current;
    } catch (error) {
      throw ShopSettingsException(
        friendlyErrorMessage(
          error,
          fallback: 'Could not load the shop settings. Please try again.',
        ),
      );
    }
  }

  /// Saves new values (owner only; the database checks every value) and
  /// updates the cache. Throws [ShopSettingsException] on failure.
  Future<ShopSettings> save({
    required String? shopHours,
    required int paymentWindowHours,
    required double lateFeePerDay,
    required String address,
    required List<String> contactNumbers,
    required String gcashNumber,
  }) async {
    try {
      final row = await _api.update({
        'p_shop_hours': shopHours,
        'p_payment_window_hours': paymentWindowHours,
        'p_late_fee_per_day': lateFeePerDay,
        'p_address': address,
        'p_contact_numbers': contactNumbers,
        'p_gcash_number': gcashNumber,
      });
      _set(ShopSettings.fromMap(row));
      return _current;
    } catch (error) {
      throw ShopSettingsException(
        friendlyErrorMessage(
          error,
          fallback: 'Could not save the shop settings. Please try again.',
        ),
      );
    }
  }

  void _set(ShopSettings settings) {
    _current = settings;
    _loaded = true;
    notifyListeners();
  }
}
