// Holds who is signed in and what their role is (customer / staff / owner).
//
// - On startup it restores the saved Supabase session and looks up the
//   role from the `profiles` table.
// - It listens to Supabase auth changes and reloads the role on sign-in.
// - It is a ChangeNotifier: go_router uses it as refreshListenable so the
//   auth guard re-runs whenever the session changes.
//
// OWNER: team lead. Change only via a reviewed PR.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:orange150_rental/core/services/supabase_service.dart';
import 'package:orange150_rental/shared/models/app_user.dart';

/// App-wide session state. Use [SessionController.instance].
class SessionController extends ChangeNotifier {
  SessionController._();

  /// The single shared instance.
  static final SessionController instance = SessionController._();

  StreamSubscription<AuthState>? _authSubscription;
  Future<void>? _inFlight;
  bool _isReady = false;
  AppUser? _user;
  String? _loadedForUserId;

  /// True after the saved session (if any) and role have been loaded.
  bool get isReady => _isReady;

  /// The signed-in user with role, or null for guests.
  AppUser? get user => _user;

  /// True when someone is signed in.
  bool get isSignedIn => _user != null;

  /// True for staff and owner accounts.
  bool get isStaff => _user?.role.isStaff ?? false;

  /// Starts listening to auth changes and loads the current session.
  /// Safe to call once from main(); never throws.
  Future<void> start() async {
    _authSubscription ??= SupabaseService.auth.onAuthStateChange.listen(
      _onAuthChange,
      onError: (Object error) => debugPrint('Auth stream error: $error'),
    );
    try {
      await reload();
    } catch (error) {
      debugPrint('Session restore failed: $error');
    }
    _isReady = true;
    notifyListeners();
  }

  /// Re-reads the current user and role from Supabase.
  /// Concurrent calls share one request.
  Future<void> reload() =>
      _inFlight ??= _load().whenComplete(() => _inFlight = null);

  /// Signs out of Supabase and clears the cached user.
  Future<void> signOut() async {
    await SupabaseService.auth.signOut();
    _user = null;
    _loadedForUserId = null;
    notifyListeners();
  }

  /// Reacts to sign-in / sign-out events coming from Supabase.
  void _onAuthChange(AuthState state) {
    final authUser = state.session?.user;
    if (authUser == null) {
      if (_user != null) {
        _user = null;
        _loadedForUserId = null;
        notifyListeners();
      }
      return;
    }
    if (authUser.id != _loadedForUserId) {
      unawaited(reload());
    }
  }

  /// Loads the profile row (role, name, phone) for the current auth user.
  /// If the profile cannot be read, the user is treated as a customer.
  Future<void> _load() async {
    String? targetId;
    do {
      final authUser = SupabaseService.auth.currentUser;
      targetId = authUser?.id;
      AppUser? loaded;
      if (authUser != null) {
        Map<String, dynamic>? profile;
        try {
          profile = await SupabaseService.client
              .from('profiles')
              .select('id, full_name, phone, role')
              .eq('id', authUser.id)
              .maybeSingle();
        } catch (error) {
          debugPrint('Could not load role from profiles: $error');
        }
        loaded = AppUser.fromProfile(
          profile,
          id: authUser.id,
          email: authUser.email,
        );
      }
      _user = loaded;
      _loadedForUserId = targetId;
      // Repeat if the user changed while we were waiting for the network.
    } while (SupabaseService.auth.currentUser?.id != targetId);
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
