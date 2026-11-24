// Favorites (customer redesign 2, Phase 1), no Supabase needed:
//   * the optimistic toggle, and its rollback when saving fails
//   * the heart button: the heart flips back and an error is shown
//   * a guest's heart goes to Login with "?reason=favorites" and a `from`
//     that carries the item, which is saved only after signing in
// Run with: flutter test test/features/catalog

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/theme/app_theme.dart';
import 'package:orange150_rental/features/catalog/models/favorite_links.dart';
import 'package:orange150_rental/features/catalog/services/favorites_controller.dart';
import 'package:orange150_rental/features/catalog/services/favorites_service.dart';
import 'package:orange150_rental/features/catalog/widgets/favorite_button.dart';
import 'package:orange150_rental/shared/models/item.dart';

/// In-memory favorites; [fail] makes add / remove throw.
class _FakeApi implements FavoritesApi {
  _FakeApi([Set<String>? ids]) : ids = ids ?? {};

  final Set<String> ids;
  bool fail = false;

  /// When set, add / remove wait for it (to see the optimistic state).
  Completer<void>? gate;

  Future<void> _maybeFail() async {
    if (gate != null) await gate!.future;
    if (fail) throw Exception('network down');
  }

  @override
  Future<Set<String>> myFavoriteIds() async => {...ids};

  @override
  Future<void> add(String itemId) async {
    await _maybeFail();
    ids.add(itemId);
  }

  @override
  Future<void> remove(String itemId) async {
    await _maybeFail();
    ids.remove(itemId);
  }

  @override
  Future<List<Item>> myFavoriteItems() async => const [];
}

FavoritesController _controller(_FakeApi api, {bool signedIn = true}) =>
    FavoritesController(
      api: api,
      isSignedIn: () => signedIn,
      userId: () => signedIn ? 'u1' : null,
    );

void main() {
  group('FavoritesController', () {
    test('toggle saves at once, before the database answers', () async {
      final api = _FakeApi()..gate = Completer<void>();
      final favorites = _controller(api);

      final pending = favorites.toggle('i1');
      expect(favorites.isFavorite('i1'), isTrue); // optimistic
      expect(favorites.count, 1);

      api.gate!.complete();
      expect(await pending, isTrue);
      expect(api.ids, {'i1'});
    });

    test('a failed save is rolled back and the error passed on', () async {
      final api = _FakeApi()..fail = true;
      final favorites = _controller(api);

      await expectLater(favorites.toggle('i1'), throwsException);
      expect(favorites.isFavorite('i1'), isFalse); // rolled back
      expect(favorites.count, 0);
    });

    test('a failed remove puts the heart back', () async {
      final api = _FakeApi({'i1'});
      final favorites = _controller(api);
      await favorites.refresh();
      expect(favorites.isFavorite('i1'), isTrue);

      api.fail = true;
      await expectLater(favorites.toggle('i1'), throwsException);
      expect(favorites.isFavorite('i1'), isTrue);
    });

    test('a running save wins over an older reload', () async {
      final api = _FakeApi()..gate = Completer<void>();
      final favorites = _controller(api);

      final save = favorites.setFavorite('i1', true);
      await favorites.refresh(); // database does not have i1 yet
      expect(favorites.isFavorite('i1'), isTrue);

      api.gate!.complete();
      await save;
      expect(favorites.isFavorite('i1'), isTrue);
    });
  });

  testWidgets('heart: rolls back and shows an error when saving fails', (
    tester,
  ) async {
    final api = _FakeApi()..fail = true;
    final favorites = _controller(api);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: FavoriteButton(itemId: 'i1', controller: favorites),
          ),
        ),
      ),
    );
    expect(find.byTooltip('Add to favorites'), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pump(); // optimistic state, then the failure
    await tester.pump();

    expect(favorites.isFavorite('i1'), isFalse);
    expect(find.byTooltip('Add to favorites'), findsOneWidget);
    expect(
      find.text('Could not save to favorites. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('heart: saved shows "Saved to favorites" with Undo', (
    tester,
  ) async {
    final api = _FakeApi();
    final favorites = _controller(api);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FavoriteButton(itemId: 'i1', controller: favorites),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(find.text('Saved to favorites'), findsOneWidget);
    expect(find.byTooltip('Remove from favorites'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500)); // snackbar in
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(favorites.isFavorite('i1'), isFalse);
  });

  group('guest redirect', () {
    test('loginFor carries the item and the reason', () {
      final login = Uri.parse(
        FavoriteLinks.loginFor(Uri.parse('/browse/item/i9'), 'i9'),
      );
      expect(login.path, '/login');
      expect(login.queryParameters['reason'], 'favorites');
      expect(login.queryParameters['from'], '/browse/item/i9?fav=i9');
    });

    test('after sign in the item is saved and ?fav is removed', () {
      final saved = <String>[];
      final next = FavoriteLinks.pendingRedirect(
        Uri.parse('/browse?fav=i9'),
        signedIn: true,
        save: saved.add,
      );
      expect(saved, ['i9']);
      expect(next, '/browse');
    });

    test('a guest (Back from Login) saves nothing', () {
      final saved = <String>[];
      final next = FavoriteLinks.pendingRedirect(
        Uri.parse('/browse/item/i9?fav=i9'),
        signedIn: false,
        save: saved.add,
      );
      expect(saved, isEmpty);
      expect(next, '/browse/item/i9');
    });

    test('no pending favorite: no redirect', () {
      expect(
        FavoriteLinks.pendingRedirect(
          Uri.parse('/browse'),
          signedIn: true,
          save: (_) => fail('nothing to save'),
        ),
        isNull,
      );
    });

    testWidgets('a guest tapping a heart is sent to Login', (tester) async {
      final favorites = _controller(_FakeApi(), signedIn: false);
      Uri? loginUri; // the Login address the heart opened
      final router = GoRouter(
        initialLocation: '/browse',
        routes: [
          GoRoute(
            path: '/browse',
            builder: (_, _) => Scaffold(
              body: Center(
                child: FavoriteButton(itemId: 'i9', controller: favorites),
              ),
            ),
          ),
          GoRoute(
            path: '/login',
            builder: (_, state) {
              loginUri = state.uri;
              return Scaffold(
                body: Text('login ${state.uri.queryParameters['reason']}'),
              );
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(find.text('login favorites'), findsOneWidget);
      expect(loginUri!.queryParameters['from'], '/browse?fav=i9');
      expect(favorites.isFavorite('i9'), isFalse); // not saved yet
      // Pushed, so Back returns to Browse.
      expect(router.canPop(), isTrue);
    });
  });
}
