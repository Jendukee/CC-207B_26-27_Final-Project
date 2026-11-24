// How a guest's heart tap survives the trip through Login (customer
// redesign 2, Phase 1). Plain Dart, so it can be unit tested.
//
//   1. A guest taps the heart on item 42 while on /browse.
//   2. loginFor() sends them to
//        /login?from=/browse?fav=42&reason=favorites
//      (Login shows "Sign in to save favorites").
//   3a. They sign in: the auth guard returns them to /browse?fav=42. The
//       catalog route's redirect (pendingRedirect) saves item 42 and drops
//       ?fav=42 from the address, so a refresh does not save it again.
//   3b. They press Back instead: Login just goes back. Nothing is saved,
//       because the favorite only exists in the `from` link (H3).
//
// OWNER: Member 1.

import 'package:orange150_rental/core/router/route_names.dart';

/// Links for saving a favorite after sign-in.
abstract final class FavoriteLinks {
  /// Query parameter carrying the item to save after sign-in.
  static const String pendingParam = 'fav';

  /// The Login location for a guest who tapped the heart of [itemId]
  /// while on [here].
  static String loginFor(Uri here, String itemId) {
    final back = here.replace(
      queryParameters: {...here.queryParameters, pendingParam: itemId},
    );
    return Uri(
      path: RoutePaths.login,
      queryParameters: {
        'from': back.toString(),
        LoginReasons.param: LoginReasons.favorites,
      },
    ).toString();
  }

  /// The item waiting to be saved in [uri], or null.
  static String? pendingItem(Uri uri) {
    final id = uri.queryParameters[pendingParam]?.trim();
    return (id == null || id.isEmpty) ? null : id;
  }

  /// [uri] without the pending-favorite parameter.
  static String withoutPending(Uri uri) {
    final rest = Map.of(uri.queryParameters)..remove(pendingParam);
    return Uri(
      path: uri.path,
      queryParameters: rest.isEmpty ? null : rest,
    ).toString();
  }

  /// Route redirect for the catalog routes. When [uri] carries a pending
  /// favorite: if [signedIn], [save] is called with the item id; either
  /// way the parameter is removed. Returns null when there is nothing to do.
  static String? pendingRedirect(
    Uri uri, {
    required bool signedIn,
    required void Function(String itemId) save,
  }) {
    final itemId = pendingItem(uri);
    if (itemId == null) return null;
    if (signedIn) save(itemId);
    return withoutPending(uri);
  }
}
