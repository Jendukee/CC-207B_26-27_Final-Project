// Profile tab for customer contact details, measurements and privacy.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/services/session_controller.dart';
import 'package:orange150_rental/core/widgets/sign_in_prompt.dart';
import 'package:orange150_rental/features/profile/models/data_deletion_request.dart';
import 'package:orange150_rental/features/profile/models/profile_data.dart';
import 'package:orange150_rental/features/profile/services/profile_service.dart';
import 'package:orange150_rental/features/profile/widgets/profile_contact_editor.dart';
import 'package:orange150_rental/features/profile/widgets/profile_measurements_editor.dart';

/// Signed-in customer profile and privacy settings.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _service = ProfileService();
  Future<ProfileData>? _profileFuture;
  Future<DataDeletionRequest?>? _deletionRequestFuture;
  String? _loadedForUserId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final userId = SessionController.instance.user?.id;
    if (userId != null) {
      _loadForUser(userId);
    }
  }

  void _loadForUser(String userId) {
    _loadedForUserId = userId;
    _profileFuture = _service.getProfileData();
    _deletionRequestFuture = _service.getOpenDeletionRequest();
  }

  void _refresh() {
    final userId = SessionController.instance.user?.id;
    if (userId == null) return;
    setState(() => _loadForUser(userId));
  }

  void _refreshDeletionRequest() {
    if (_deletionRequestFuture == null) return;
    setState(() {
      _deletionRequestFuture = _service.getOpenDeletionRequest();
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editContact(ProfileData profile) async {
    final update = await showProfileContactEditor(
      context,
      fullName: profile.fullName,
      phone: profile.phone,
    );
    if (update == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await _service.updateContact(
        fullName: update.fullName,
        phone: update.phone,
      );
      await SessionController.instance.reload();
      if (!mounted) return;
      _refresh();
      _showMessage('Contact details updated.');
    } catch (error) {
      _showMessage('Could not update contact details: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editMeasurements(ProfileData profile) async {
    final updated = await showProfileMeasurementsEditor(
      context,
      initial: profile.measurements,
    );
    if (updated == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await _service.saveMeasurements(updated);
      if (!mounted) return;
      _refresh();
      _showMessage('Measurements saved.');
    } catch (error) {
      _showMessage('Could not save measurements: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
      _refresh();
      _showMessage(
        consented ? 'Privacy consent recorded.' : 'Privacy consent withdrawn.',
      );
    } catch (error) {
      _showMessage('Could not update privacy consent: $error');
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
      _refreshDeletionRequest();
      _showMessage('Your data deletion request was sent for review.');
    } catch (error) {
      _showMessage('Could not submit deletion request: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    try {
      await SessionController.instance.signOut();
    } catch (error) {
      _showMessage('Could not sign out: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionController.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (session.isSignedIn)
            IconButton(
              tooltip: 'Refresh profile',
              onPressed: _busy ? null : _refresh,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          if (!session.isSignedIn) {
            _loadedForUserId = null;
            return const SignInPrompt(
              message:
                  'Sign in to see your measurements, contact details '
                  'and privacy settings.',
              from: RoutePaths.profile,
              showStaffLink: true,
            );
          }
          final userId = session.user!.id;
          if (_loadedForUserId != userId) {
            _loadForUser(userId);
          }
          return FutureBuilder<ProfileData>(
            future: _profileFuture!,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _ProfileLoadError(
                  message: 'Could not load your profile: ${snapshot.error}',
                  onRetry: _refresh,
                );
              }
              return _profileContent(snapshot.requireData);
            },
          );
        },
      ),
    );
  }

  Widget _profileContent(ProfileData profile) {
    final dateFormat = DateFormat.yMMMd().add_jm();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(
                    profile.fullName.trim().isEmpty
                        ? (profile.email.isEmpty
                              ? '?'
                              : profile.email.substring(0, 1).toUpperCase())
                        : profile.fullName.trim().substring(0, 1).toUpperCase(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName.trim().isEmpty
                            ? 'Your profile'
                            : profile.fullName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(profile.email),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Contact details'),
                subtitle: Text(
                  'Name: ${profile.fullName.isEmpty ? 'Not set' : profile.fullName}\n'
                  'Mobile: ${profile.phone?.isNotEmpty == true ? profile.phone : 'Not set'}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  tooltip: 'Edit contact details',
                  onPressed: _busy ? null : () => _editContact(profile),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ),
            ],
          ),
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Measurements'),
                subtitle: Text(
                  profile.measurements?.hasValues == true
                      ? _measurementSummary(profile.measurements!)
                      : 'No measurements saved.',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  tooltip: 'Edit measurements',
                  onPressed: _busy ? null : () => _editMeasurements(profile),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ),
              if (profile.measurements?.updatedAt != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Updated ${dateFormat.format(profile.measurements!.updatedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              if (profile.measurements?.notes?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Notes: ${profile.measurements!.notes}'),
                  ),
                ),
            ],
          ),
        ),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: profile.hasPrivacyConsent,
                onChanged: _busy ? null : _updatePrivacyConsent,
                title: const Text('Privacy consent'),
                subtitle: Text(
                  profile.hasPrivacyConsent
                      ? 'Consent recorded ${dateFormat.format(profile.privacyConsentAt!)}.'
                      : 'Consent is currently withdrawn.',
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Changing consent does not delete your profile or existing '
                    'booking records. Use the deletion request below to ask '
                    'the shop to review your data.',
                  ),
                ),
              ),
            ],
          ),
        ),
        _deletionRequestSection(),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy ? null : _signOut,
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _deletionRequestSection() {
    return FutureBuilder<DataDeletionRequest?>(
      future: _deletionRequestFuture!,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasError) {
          return Card(
            child: ListTile(
              title: const Text('Data deletion request'),
              subtitle: Text(
                'Could not load requests. Run migration '
                '0007_data_deletion_requests.sql in Supabase and retry.\n'
                '${snapshot.error}',
              ),
              trailing: IconButton(
                tooltip: 'Retry',
                onPressed: _busy ? null : _refreshDeletionRequest,
                icon: const Icon(Icons.refresh),
              ),
            ),
          );
        }

        final request = snapshot.data;
        if (request != null) {
          final created = DateFormat.yMMMd().format(request.createdAt);
          return Card(
            child: ListTile(
              title: const Text('Data deletion request'),
              subtitle: Text(
                '${request.statusLabel} · submitted $created'
                '${request.reason?.isNotEmpty == true ? '\nReason: ${request.reason}' : ''}',
              ),
              isThreeLine: request.reason?.isNotEmpty == true,
              leading: const Icon(Icons.pending_actions),
            ),
          );
        }

        return Card(
          child: ListTile(
            title: const Text('Request data deletion'),
            subtitle: const Text(
              'Send a request to shop staff for review. This does not '
              'automatically delete your account or data.',
            ),
            trailing: IconButton(
              tooltip: 'Request data deletion',
              onPressed: _busy ? null : _requestDeletion,
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
        );
      },
    );
  }

  String _measurementSummary(ProfileMeasurements measurements) {
    final values = <String, double?>{
      'Chest': measurements.chest,
      'Waist': measurements.waist,
      'Hips': measurements.hips,
      'Shoulder': measurements.shoulder,
      'Height': measurements.height,
      'Inseam': measurements.inseam,
    };
    return values.entries
        .where((entry) => entry.value != null)
        .map((entry) => '${entry.key}: ${_number(entry.value!)} in')
        .join(' · ');
  }

  String _number(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

class _ProfileLoadError extends StatelessWidget {
  const _ProfileLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
