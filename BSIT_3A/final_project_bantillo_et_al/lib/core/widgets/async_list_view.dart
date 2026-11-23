// Generic list that handles the four async states in one place:
// loading -> LoadingView, error -> ErrorView (with Retry),
// empty -> EmptyView, data -> ListView with pull-to-refresh.
//
// Example:
//   AsyncListView<Booking>(
//     load: () => service.listMyBookings(),
//     itemBuilder: (context, booking) => BookingTile(booking: booking),
//     emptyMessage: 'You have no bookings yet.',
//   )
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/widgets/empty_view.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/core/widgets/loading_view.dart';

/// A list backed by a Future, with built-in loading / empty / error states.
class AsyncListView<T> extends StatefulWidget {
  /// Creates the list. [load] is called on first build, on Retry and on
  /// pull-to-refresh.
  const AsyncListView({
    super.key,
    required this.load,
    required this.itemBuilder,
    this.emptyMessage = 'Nothing here yet.',
    this.errorMessage = 'Something went wrong. Please try again.',
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  /// Fetches the items (usually a method on a feature service).
  final Future<List<T>> Function() load;

  /// Builds one row.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Shown when [load] returns an empty list.
  final String emptyMessage;

  /// Shown when [load] throws.
  final String errorMessage;

  /// Padding around the list.
  final EdgeInsetsGeometry padding;

  @override
  State<AsyncListView<T>> createState() => _AsyncListViewState<T>();
}

class _AsyncListViewState<T> extends State<AsyncListView<T>> {
  late Future<List<T>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  /// Starts a new load and rebuilds.
  void _retry() {
    setState(() => _future = widget.load());
  }

  /// Pull-to-refresh handler; errors are shown by the FutureBuilder.
  Future<void> _refresh() async {
    _retry();
    try {
      await _future;
    } catch (_) {
      // ErrorView will show the failure.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (snapshot.hasError) {
          debugPrint('AsyncListView error: ${snapshot.error}');
          return ErrorView(message: widget.errorMessage, onRetry: _retry);
        }
        final items = snapshot.data ?? <T>[];
        if (items.isEmpty) {
          return EmptyView(message: widget.emptyMessage);
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: widget.padding,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                widget.itemBuilder(context, items[index]),
          ),
        );
      },
    );
  }
}
