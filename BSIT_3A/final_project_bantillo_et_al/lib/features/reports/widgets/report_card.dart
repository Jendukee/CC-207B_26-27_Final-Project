// A titled card that shows one report with its own loading, empty and
// error (Retry) states, so one failing report does not hide the others.
//
// Display only: the screen passes in the Future (from the service).
//
// OWNER: Member 3.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/widgets/empty_view.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/core/widgets/loading_view.dart';
import 'package:orange150_rental/features/reports/services/reports_service.dart';

/// One report card.
class ReportCard<T> extends StatelessWidget {
  /// Creates the card.
  const ReportCard({
    super.key,
    required this.title,
    required this.icon,
    required this.future,
    required this.isEmpty,
    required this.emptyMessage,
    required this.builder,
    required this.onRetry,
    this.subtitle,
  });

  /// Card heading, e.g. "Rentals per month".
  final String title;

  /// Heading icon.
  final IconData icon;

  /// The report data, loading.
  final Future<T> future;

  /// True when the loaded data has nothing to show.
  final bool Function(T data) isEmpty;

  /// Shown when [isEmpty] is true, e.g. "No rentals yet".
  final String emptyMessage;

  /// Builds the chart or list from the data.
  final Widget Function(BuildContext context, T data) builder;

  /// Reloads only this report.
  final VoidCallback onRetry;

  /// Optional line under the title, e.g. a total. Built from the data.
  final String Function(T data)? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<T>(
          future: future,
          builder: (context, snapshot) {
            final done = snapshot.connectionState == ConnectionState.done;
            final data = snapshot.data;
            final hasData = done && !snapshot.hasError && data != null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(title, style: theme.textTheme.titleMedium),
                      ),
                    ),
                  ],
                ),
                if (hasData && subtitle != null && !isEmpty(data))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitle!(data),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                const SizedBox(height: 16),
                if (!done)
                  const SizedBox(height: 180, child: LoadingView())
                else if (snapshot.hasError)
                  ErrorView(
                    message: snapshot.error is ReportsException
                        ? (snapshot.error! as ReportsException).message
                        : 'Could not load this report. Please try again.',
                    onRetry: onRetry,
                  )
                else if (data == null || isEmpty(data))
                  EmptyView(
                    icon: Icons.insert_chart_outlined,
                    message: emptyMessage,
                  )
                else
                  builder(context, data),
              ],
            );
          },
        ),
      ),
    );
  }
}
