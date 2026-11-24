// "Privacy and data" page, opened from the Me page (customer redesign,
// Phase 1). The privacy consent switch and the data deletion request moved
// here from the old Profile screen, unchanged in behaviour:
//   * the switch applies immediately (withdrawing asks first)
//   * a deletion request is sent to staff for review (0007)
//
// OWNER: Member 2.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/services/session_controller.dart';
import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/utils/error_messages.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/widgets/brand_app_bar.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/core/widgets/loading_view.dart';
import 'package:orange150_rental/core/widgets/section_card.dart';
import 'package:orange150_rental/features/profile/models/data_deletion_request.dart';
import 'package:orange150_rental/features/profile/models/profile_data.dart';
import 'package:orange150_rental/features/profile/services/profile_service.dart';

/// Privacy consent and data deletion.
class PrivacyScreen extends StatefulWidget {
  /// Creates the page.
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  final ProfileService _service = ProfileService();
  late Future<ProfileData> _profile = _service.getProfileData();
  late Future<DataDeletionRequest?> _request = _service
      .getOpenDeletionRequest();
  bool _busy = false;

  void _reload() => setState(() {
    _profile = _service.getProfileData();
    _request = _service.getOpenDeletionRequest();
  });

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _updatePrivacyConsent(bool consented) async {
    if (!consented) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Withdraw privacy consent?'),
          content: const Text(
            'This will record that you withdrew consent. It will not delete '
            'your profile or booking data. You can submit a separate deletion '
            'request below.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep consent'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.deepRed),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Withdraw'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _busy = true);
    try {
      await _service.updatePrivacyConsent(consented: consented);
      await SessionController.instance.reload();
      if (!mounted) return;
      _reload();
      _showMessage(
        consented ? 'Privacy consent recorded.' : 'Privacy consent withdrawn.',
      );
    } catch (error) {
      _showMessage(
        friendlyErrorMessage(
          error,
          fallback: 'Could not update privacy consent. Please try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestDeletion() async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request data deletion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This sends a request to shop staff for review. Your account '
              'and data will not be deleted immediately.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(reasonController.text.trim()),
            child: const Text('Send request'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await _service.requestDataDeletion(reason: reason);
      if (!mounted) return;
      _reload();
      _showMessage('Your data deletion request was sent for review.');
    } catch (error) {
      _showMessage(
        friendlyErrorMessage(
          error,
          fallback: 'Could not send the deletion request. Please try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const gap = EdgeInsets.fromLTRB(8, 8, 8, 0);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      // Customer redesign 2: shared header with the Orange 150 mark (H4).
      appBar: const BrandAppBar(title: 'Privacy and data'),
      body: FutureBuilder<ProfileData>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: friendlyErrorMessage(
                snapshot.error!,
                fallback: 'Could not load your privacy settings.',
              ),
              onRetry: _reload,
            );
          }
          final profile = snapshot.requireData;
          return ListView(
            children: [
              if (_busy) const LinearProgressIndicator(),
              SectionCard(
                margin: gap,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    // A Switch: the change applies immediately.
                    SwitchListTile(
                      value: profile.hasPrivacyConsent,
                      onChanged: _busy ? null : _updatePrivacyConsent,
                      title: const Text('Privacy consent'),
                      subtitle: Text(
                        profile.hasPrivacyConsent
                            ? 'Consent recorded ${Formatters.dateTime(profile.privacyConsentAt!)}.'
                            : 'Consent is currently withdrawn.',
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        'Changing consent does not delete your profile or '
                        'existing booking records. Use the deletion request '
                        'below to ask the shop to review your data.',
                      ),
                    ),
                  ],
                ),
              ),
              _deletionSection(gap),
            ],
          );
        },
      ),
    );
  }

  Widget _deletionSection(EdgeInsets gap) {
    return FutureBuilder<DataDeletionRequest?>(
      future: _request,
      builder: (context, snapshot) {
        Widget tile;
        if (snapshot.connectionState != ConnectionState.done) {
          tile = const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          tile = ListTile(
            title: const Text('Data deletion request'),
            subtitle: const Text(
              'Could not load your deletion request. Please try again.',
            ),
            trailing: IconButton(
              tooltip: 'Retry',
              onPressed: _busy ? null : _reload,
              icon: const Icon(Icons.refresh),
            ),
          );
        } else if (snapshot.data != null) {
          final request = snapshot.data!;
          tile = ListTile(
            leading: const Icon(Icons.pending_actions),
            title: const Text('Data deletion request'),
            subtitle: Text(
              '${request.statusLabel} · submitted '
              '${Formatters.date(request.createdAt)}'
              '${request.reason?.isNotEmpty == true ? '\nReason: ${request.reason}' : ''}',
            ),
            isThreeLine: request.reason?.isNotEmpty == true,
          );
        } else {
          tile = ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Request data deletion'),
            subtitle: const Text(
              'Send a request to shop staff for review. This does not '
              'automatically delete your account or data.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _busy ? null : _requestDeletion,
          );
        }
        return SectionCard(margin: gap, padding: EdgeInsets.zero, child: tile);
      },
    );
  }
}
