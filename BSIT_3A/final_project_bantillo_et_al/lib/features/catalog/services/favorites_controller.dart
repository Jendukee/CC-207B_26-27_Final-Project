// The customer's favorites, shared by every heart in the app (Browse cards,
// Item details, the Favorites screen and the Browse "Favorites" badge), so
// tapping one heart updates all of them at once (customer redesign 2,
// Phase 1).
//
// * Optimistic update: the heart changes IMMEDIATELY, then the database
//   call runs. If the call fails, the heart goes back to what it was and
//   the error is passed on so the screen can say so (H1 status, H5).
// * It reloads the saved ids whenever a different user signs in, and
//   clears them on sign out.
// * A save that is still running wins over a reload that finishes first,
//   so a heart never flickers back off (e.g. the save right after sign in).
//
// Use [FavoritesController.instance] in the app; tests create their own
// with a fake [FavoritesApi].
//
// OWNER: Member 1.

import 'package:flutter/foundation.dart';

import 'package:orange150_rental/core/services/session_controller.dart';
import 'package:orange150_rental/features/catalog/services/favorites_service.dart';

/// Saved item ids with optimistic add / remove.
class FavoritesController extends ChangeNotifier {
  /// Creates a controller. [isSignedIn] and [userId] default to the app's
  /// session.
  FavoritesController({
    required this._api,
    bool Function()? isSignedIn,
    String? Function()? userId,
  }) : _isSignedIn =
           isSignedIn ?? (() => SessionController.instance.isSignedIn),
       _userId = userId ?? (() => SessionController.instance.user?.id);

  /// The app's controller. It follows sign in / sign out.
  static final FavoritesController instance = _createInstance();

  static FavoritesController _createInstance() {
    final controller = FavoritesController(api: FavoritesService());
    SessionController.instance.addListener(controller._onSessionChanged);
    controller._onSessionChanged();
    return controller;
  }

  final FavoritesApi _api;
  final bool Function() _isSignedIn;
  final String? Function() _userId;

  /// The API, for screens that load the saved items themselves.
  FavoritesApi get api => _api;

  Set<String> _ids = {};

  /// Saves / removes still running: item id -> the state they set.
  final Map<String, bool> _pending = {};

  /// The user the ids were loaded for (null = guest).
  String? _loadedFor;

  /// True when someone is signed in (guests are sent to Login instead).
  bool get isSignedIn => _isSignedIn();

  /// True if [itemId] is saved.
  bool isFavorite(String itemId) => _ids.contains(itemId);

  /// How many items are saved (the Browse badge).
  int get count => _ids.length;

  /// Reloads when a different user signs in; clears on sign out.
  void _onSessionChanged() {
    final user = _userId();
    if (user == _loadedFor) return;
    _loadedFor = user;
    if (user == null) {
      _ids = {};
      notifyListeners();
    } else {
      refresh().ignore(); // a failed load just shows empty hearts
    }
  }

  /// Loads the saved ids from the database.
  Future<void> refresh() async {
    if (!isSignedIn) {
      _ids = {};
      notifyListeners();
      return;
    }
    final loaded = await _api.myFavoriteIds();
    // Saves / removes still running win over the (older) loaded list.
    _pending.forEach((id, saved) => saved ? loaded.add(id) : loaded.remove(id));
    _ids = loaded;
    notifyListeners();
  }

  /// Saves ([saved] true) or removes [itemId], updating the heart first.
  /// On failure the heart is put back and the error is rethrown.
  Future<void> setFavorite(String itemId, bool saved) async {
    if (isFavorite(itemId) == saved) return;
    final before = isFavorite(itemId);
    _apply(itemId, saved);
    _pending[itemId] = saved;
    try {
      await (saved ? _api.add(itemId) : _api.remove(itemId));
    } catch (_) {
      _apply(itemId, before); // roll back
      rethrow;
    } finally {
      if (_pending[itemId] == saved) _pending.remove(itemId);
    }
  }

  /// Flips [itemId] and returns the new state (true = saved).
  Future<bool> toggle(String itemId) async {
    final saved = !isFavorite(itemId);
    await setFavorite(itemId, saved);
    return saved;
  }

  void _apply(String itemId, bool saved) {
    saved ? _ids.add(itemId) : _ids.remove(itemId);
    notifyListeners();
  }
}
