// Fallback app shown when env.json is missing, incomplete, or Supabase
// fails to start. It replaces a crash with clear setup instructions.
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/theme/app_theme.dart';

/// A tiny standalone app that explains how to fix the configuration.
class MissingEnvApp extends StatelessWidget {
  /// Creates the setup error app.
  ///
  /// [missingKeys] lists the env.json keys that are empty.
  /// [detail] is an optional extra message (for example a startup error).
  const MissingEnvApp({super.key, required this.missingKeys, this.detail});

  /// env.json keys that are empty or still placeholders.
  final List<String> missingKeys;

  /// Optional technical detail shown under the main message.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Setup required',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        appBar: AppBar(title: const Text('Setup required')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.settings_suggest,
                      size: 64, color: AppColors.deepRed),
                  const SizedBox(height: 16),
                  const Text(
                    'Missing env.json. Copy env.example.json to env.json '
                    'and fill in your keys.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  if (missingKeys.isNotEmpty)
                    Text(
                      'Empty or placeholder values: ${missingKeys.join(', ')}',
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 8),
                  const SelectableText(
                    'Then run: flutter run --dart-define-from-file=env.json\n'
                    '(or press F5 in VS Code, which already passes it).',
                    textAlign: TextAlign.center,
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 16),
                    SelectableText(detail!, textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
