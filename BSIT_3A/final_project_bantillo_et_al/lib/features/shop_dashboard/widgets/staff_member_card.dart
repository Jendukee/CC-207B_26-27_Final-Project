// One account on the Staff accounts screen, as a white SectionCard:
//
//   Pearl Batumbakal              [Staff] [Disabled]   [⋮]
//   pearl@example.com                                   Reset password
//   09171234567                                         Disable account
//
// * Chips always have a text label (never color only): the role, plus
//   "Disabled" (grey) while the login is disabled.
// * Staff cards have a menu: "Reset password", then "Disable account"
//   (red) or "Enable account". The owner's card has no menu.
// * While an action is saving, the menu button becomes a spinner so it
//   cannot be used twice.
// * A disabled account's text is greyed so active staff stand out.
//
// Display only: the screen does the confirmation and the calls.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/widgets/section_card.dart';
import 'package:orange150_rental/core/widgets/status_chip.dart';
import 'package:orange150_rental/features/shop_dashboard/models/staff_member.dart';

/// The menu choices of a staff card.
enum StaffAction {
  /// Opens the Reset password sheet.
  resetPassword,

  /// Disables the login (asks first).
  disable,

  /// Enables the login again.
  enable,
}

/// A card for one staff or owner account.
class StaffMemberCard extends StatelessWidget {
  /// Creates it. [onAction] null (or an owner) hides the menu.
  const StaffMemberCard({
    super.key,
    required this.member,
    this.onAction,
    this.busy = false,
  });

  /// The account.
  final StaffMember member;

  /// Called with the chosen menu item.
  final ValueChanged<StaffAction>? onAction;

  /// True while an action for this account is being saved.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
    );
    final showMenu = onAction != null && !member.isOwner;
    return SectionCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                Text(
                  member.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: member.isDisabled ? AppColors.textSecondary : null,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StatusChip(
                      label: member.isOwner ? 'Owner' : 'Staff',
                      color: member.isOwner
                          ? AppColors.maroonDeep
                          : AppColors.maroon,
                      icon: member.isOwner
                          ? Icons.star_outline
                          : Icons.badge_outlined,
                    ),
                    if (member.isDisabled)
                      const StatusChip(
                        label: 'Disabled',
                        color: AppColors.neutralGrey,
                        icon: Icons.block,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _line(Icons.mail_outline, member.email ?? 'No email', muted),
                _line(Icons.phone_outlined, member.phone ?? 'No phone', muted),
              ],
            ),
          ),
          if (showMenu) _menu(),
        ],
      ),
    );
  }

  /// The ⋮ menu (48 px), or a spinner while saving.
  Widget _menu() {
    if (busy) {
      return const SizedBox.square(
        dimension: 48,
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              semanticsLabel: 'Saving',
            ),
          ),
        ),
      );
    }
    return PopupMenuButton<StaffAction>(
      tooltip: 'Actions for ${member.displayName}',
      onSelected: onAction,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: StaffAction.resetPassword,
          child: ListTile(
            leading: Icon(Icons.key),
            title: Text('Reset password'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (member.isDisabled)
          const PopupMenuItem(
            value: StaffAction.enable,
            child: ListTile(
              leading: Icon(Icons.check_circle_outline),
              title: Text('Enable account'),
              contentPadding: EdgeInsets.zero,
            ),
          )
        else
          const PopupMenuItem(
            value: StaffAction.disable,
            child: ListTile(
              leading: Icon(Icons.block, color: AppColors.deepRed),
              title: Text(
                'Disable account',
                style: TextStyle(color: AppColors.deepRed),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }

  /// An icon and one line of contact text.
  Widget _line(IconData icon, String text, TextStyle? style) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
