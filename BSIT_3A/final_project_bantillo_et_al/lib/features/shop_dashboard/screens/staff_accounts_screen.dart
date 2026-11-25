// More -> Staff accounts (/shop/more/staff). The owner creates and manages
// staff logins here; staff no longer register as customers first.
//
// * Owner only. Staff who open it see "Only the owner can manage staff
//   accounts." and nothing is loaded. (list_staff() and the manage-staff
//   Edge Function check the owner again.)
// * The owner sees every staff and owner account as white cards (name,
//   email, phone, role chip, "Disabled" chip), owner first. Owner cards
//   have no actions. Staff cards have a menu:
//     - Reset password   bottom sheet, new password + confirm
//     - Disable account  red; asks "<name> will no longer be able to sign
//                        in. Their booking history is kept." (H3, H5)
//     - Enable account   when disabled
// * "Add staff" (bottom-right button, and in the empty state) opens the
//   sheet that creates the login. Afterwards a dialog says to share the
//   email and password privately, with Copy email.
// * States: skeleton cards while loading, "No staff yet. Add a staff
//   account." when only the owner is listed, error with Retry. Pull to
//   refresh reloads. Success snackbars after each action (H1, H9).
// * Same look as the rest of the staff side: BrandAppBar, light grey page,
//   SectionCards (H4).
//
// Data: StaffAccountsService -> list_staff() (0017) and manage-staff.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:orange150_rental/core/services/session_controller.dart';
import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/widgets/brand_app_bar.dart';
import 'package:orange150_rental/core/widgets/empty_view.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/core/widgets/list_skeleton.dart';
import 'package:orange150_rental/core/widgets/section_card.dart';
import 'package:orange150_rental/features/shop_dashboard/models/staff_member.dart';
import 'package:orange150_rental/features/shop_dashboard/services/staff_accounts_service.dart';
import 'package:orange150_rental/features/shop_dashboard/widgets/add_staff_sheet.dart';
import 'package:orange150_rental/features/shop_dashboard/widgets/reset_password_sheet.dart';
import 'package:orange150_rental/features/shop_dashboard/widgets/staff_member_card.dart';
import 'package:orange150_rental/shared/models/app_user.dart';

/// The owner's staff account manager.
class StaffAccountsScreen extends StatefulWidget {
  /// Creates the screen.
  const StaffAccountsScreen({super.key});

  /// Shown to staff (not the owner).
  static const String ownerOnlyMessage =
      'Only the owner can manage staff accounts.';

  /// Shown when nobody but the owner is listed.
  static const String emptyMessage = 'No staff yet. Add a staff account.';

  /// The confirmation text for disabling [name].
  static String disableMessage(String name) =>
      '$name will no longer be able to sign in. Their booking history is '
      'kept.';

  /// The text of the "Staff account created" dialog for [name].
  static String createdMessage(String name) =>
      'Staff account created. Share the email and password with $name '
      'privately. They can sign in through Staff sign in.';

  @override
  State<StaffAccountsScreen> createState() => _StaffAccountsScreenState();
}

class _StaffAccountsScreenState extends State<StaffAccountsScreen> {
  final StaffAccountsService _service = StaffAccountsService();

  /// The list, loading. Null for non-owners (nothing is loaded).
  Future<List<StaffMember>>? _future;

  /// The account an action is being saved for (spinner on its card).
  String? _busyId;

  bool get _isOwner => SessionController.instance.user?.role == UserRole.owner;

  @override
  void initState() {
    super.initState();
    if (_isOwner) _future = _service.listStaff();
  }

  /// Retry and pull to refresh.
  Future<void> _reload() {
    final future = _service.listStaff();
    setState(() => _future = future);
    // Errors are shown by the list itself.
    return future.then((_) {}, onError: (_) {});
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  // "Add staff" ----------------------------------------------------------------

  Future<void> _addStaff() async {
    final created = await showAddStaffSheet(
      context,
      onSubmit: (staff) async {
        try {
          await _service.createStaff(
            fullName: staff.fullName,
            email: staff.email,
            phone: staff.phone,
            password: staff.password,
          );
          return null;
        } on StaffAccountsException catch (e) {
          return e.message;
        }
      },
    );
    if (created == null || !mounted) return;
    _reload();
    await _showCreated(created.fullName, created.email);
  }

  /// "Staff account created ..." with Copy email. The password is never
  /// shown again or copied by the app.
  Future<void> _showCreated(String name, String email) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline, color: AppColors.success),
        title: const Text('Staff account created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(StaffAccountsScreen.createdMessage(name)),
            const SizedBox(height: 12),
            SelectableText(
              email,
              style: Theme.of(dialogContext).textTheme.titleMedium,
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: email));
              if (mounted) _snack('Email copied.');
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy email'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  // Card menu ------------------------------------------------------------------

  Future<void> _onAction(StaffMember member, StaffAction action) async {
    switch (action) {
      case StaffAction.resetPassword:
        final changed = await showResetPasswordSheet(
          context,
          name: member.displayName,
          onSubmit: (password) async {
            try {
              await _service.resetPassword(member.id, password);
              return null;
            } on StaffAccountsException catch (e) {
              return e.message;
            }
          },
        );
        if (changed == true && mounted) {
          _snack('Password changed for ${member.displayName}.');
        }
      case StaffAction.disable:
        if (!await _confirmDisable(member) || !mounted) return;
        await _run(
          member,
          () => _service.disable(member.id),
          '${member.displayName} can no longer sign in.',
        );
      case StaffAction.enable:
        await _run(
          member,
          () => _service.enable(member.id),
          '${member.displayName} can sign in again.',
        );
    }
  }

  /// Disabling asks first (red button).
  Future<bool> _confirmDisable(StaffMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable account?'),
        content: Text(StaffAccountsScreen.disableMessage(member.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep active'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Disable account'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  /// Runs one card action with a spinner, then reloads the list.
  Future<void> _run(
    StaffMember member,
    Future<void> Function() action,
    String success,
  ) async {
    setState(() => _busyId = member.id);
    try {
      await action();
      if (!mounted) return;
      _snack(success);
      await _reload();
    } on StaffAccountsException catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  // Layout ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final owner = _isOwner;
    return Scaffold(
      // Same grey page as the other staff screens.
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      appBar: const BrandAppBar(
        title: 'Staff accounts',
        backgroundColor: AppColors.maroonDeep, // as on the Dashboard
        showLogo: false, // no hanger mark on staff headers
      ),
      floatingActionButton: owner
          ? FloatingActionButton.extended(
              onPressed: _addStaff,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add staff'),
            )
          : null,
      body: owner
          ? _list()
          : const EmptyView(
              icon: Icons.lock_outline,
              message: StaffAccountsScreen.ownerOnlyMessage,
            ),
    );
  }

  /// The owner's list with its loading, empty and error states.
  Widget _list() {
    return FutureBuilder<List<StaffMember>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const ListSkeleton(
            count: 3,
            showPhoto: false,
            padding: EdgeInsets.all(16),
          );
        }
        if (snapshot.hasError) {
          return ErrorView(
            message: snapshot.error is StaffAccountsException
                ? (snapshot.error! as StaffAccountsException).message
                : 'Could not load staff accounts. Please try again.',
            onRetry: _reload,
          );
        }

        final members = snapshot.requireData;
        final hasStaff = members.any((m) => !m.isOwner);
        return RefreshIndicator(
          onRefresh: _reload,
          child: Center(
            child: ConstrainedBox(
              // Readable width on laptops.
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                // Bottom space so the last card is not under "Add staff".
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  const SectionCard(
                    margin: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Staff can manage bookings, payments, checklists and '
                      'inventory. Only the owner can add staff, reset '
                      'passwords or disable accounts.',
                    ),
                  ),
                  for (final m in members)
                    StaffMemberCard(
                      member: m,
                      busy: _busyId == m.id,
                      onAction: m.isOwner
                          ? null
                          : (action) => _onAction(m, action),
                    ),
                  if (!hasStaff) ...[
                    const SizedBox(height: 24),
                    EmptyView(
                      icon: Icons.badge_outlined,
                      message: StaffAccountsScreen.emptyMessage,
                      actionLabel: 'Add staff',
                      onAction: _addStaff,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
