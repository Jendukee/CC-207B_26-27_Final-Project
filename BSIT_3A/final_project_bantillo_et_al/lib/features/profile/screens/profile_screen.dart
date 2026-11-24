// Profile tab as a "Me" page (customer redesign, Phase 1):
//   * a maroon header with the customer's name and mobile
//   * "My bookings" shortcut icons for the 5 order tabs, with counts;
//     each opens /my-bookings?tab=...
//   * list tiles: Favorites (customer redesign 2), Measurements, Contact
//     details, Rental terms, Privacy and data (its own page), and Sign out
//     (asks first, shown in red)
// Guests see the sign-in prompt with the "Staff sign in" link.
//
// UI audit changes kept: friendly errors (#12), sign-out confirmation
// (#17), shared Formatters (#23).
//
// OWNER: Member 2.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/config/rental_terms.dart';
import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/services/session_controller.dart';
import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/utils/error_messages.dart';
import 'package:orange150_rental/core/widgets/brand_app_bar.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/core/widgets/loading_view.dart';
import 'package:orange150_rental/core/widgets/section_card.dart';
import 'package:orange150_rental/core/widgets/sign_in_prompt.dart';
import 'package:orange150_rental/features/profile/models/profile_data.dart';
import 'package:orange150_rental/features/profile/profile_routes.dart';
import 'package:orange150_rental/features/profile/services/profile_service.dart';
import 'package:orange150_rental/features/profile/widgets/profile_contact_editor.dart';
import 'package:orange150_rental/features/profile/widgets/profile_measurements_editor.dart';
import 'package:orange150_rental/shared/models/customer_booking_tab.dart';

/// The Me page.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _service = ProfileService();
  Future<ProfileData>? _profileFuture;
  Future<Map<CustomerBookingTab, int>>? _countsFuture;
  String? _loadedForUserId;
  bool _busy = false;

  void _loadForUser(String userId) {
    _loadedForUserId = userId;
    _profileFuture = _service.getProfileData();
    _countsFuture = _service.bookingCounts();
  }

  void _refresh() {
    final userId = SessionController.instance.user?.id;
    if (userId == null) return;
    setState(() => _loadForUser(userId));
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
      address: profile.address,
    );
    if (update == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await _service.updateContact(
        fullName: update.fullName,
        phone: update.phone,
        address: update.address,
      );
      await SessionController.instance.reload();
      if (!mounted) return;
      _refresh();
      _showMessage('Contact details updated.');
    } catch (error) {
      _showMessage(
        friendlyErrorMessage(
          error,
          fallback: 'Could not update contact details. Please try again.',
        ),
      );
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
      _showMessage(
        friendlyErrorMessage(
          error,
          fallback: 'Could not save measurements. Please try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showTerms() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rental terms'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < RentalTerms.items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('${i + 1}. ${RentalTerms.items[i]}'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// UI audit #17: asks before signing out (a destructive action).
  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to reserve or see your bookings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay signed in'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.deepRed),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await SessionController.instance.signOut();
    } catch (error) {
      _showMessage(
        friendlyErrorMessage(
          error,
          fallback: 'Could not sign out. Please try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionController.instance;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      // Customer redesign 2: shared header with the Orange 150 mark (H4).
      appBar: BrandAppBar(
        title: 'Profile',
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
                  'Sign in to see your bookings, measurements, contact '
                  'details and privacy settings.',
              from: RoutePaths.profile,
              showStaffLink: true,
            );
          }
          final userId = session.user!.id;
          if (_loadedForUserId != userId) _loadForUser(userId);
          return FutureBuilder<ProfileData>(
            future: _profileFuture!,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LoadingView(message: 'Loading your profile...');
              }
              if (snapshot.hasError) {
                return ErrorView(
                  message: friendlyErrorMessage(
                    snapshot.error!,
                    fallback: 'Could not load your profile. Please try again.',
                  ),
                  onRetry: _refresh,
                );
              }
              return _content(snapshot.requireData, theme);
            },
          );
        },
      ),
    );
  }

  Widget _content(ProfileData profile, ThemeData theme) {
    final name = profile.fullName.trim();
    final phone = profile.phone?.trim() ?? '';
    const gap = EdgeInsets.fromLTRB(8, 8, 8, 0);

    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: ListView(
        children: [
          if (_busy) const LinearProgressIndicator(),
          // Header.
          Container(
            color: AppColors.maroon,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.goldTint,
                  foregroundColor: AppColors.maroon,
                  child: Text(
                    name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Add your name' : name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.onMaroon,
                        ),
                      ),
                      Text(
                        phone.isEmpty ? 'No mobile number yet' : phone,
                        style: const TextStyle(color: AppColors.onMaroon),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Booking shortcuts with counts.
          SectionCard(
            title: 'My bookings',
            margin: gap,
            trailing: TextButton(
              onPressed: () => context.goNamed(RouteNames.myBookings),
              child: const Text('View all'),
            ),
            child: FutureBuilder<Map<CustomerBookingTab, int>>(
              future: _countsFuture,
              builder: (context, snapshot) {
                final counts = snapshot.data ?? const {};
                return Row(
                  children: [
                    for (final tab in CustomerBookingTab.values)
                      Expanded(child: _shortcut(tab, counts[tab] ?? 0, theme)),
                  ],
                );
              },
            ),
          ),

          SectionCard(
            margin: gap,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                // Customer redesign 2: saved items, one tap away (H6, H7).
                // By path only (catalog feature); it opens in the Browse tab.
                _tile(
                  Icons.favorite_border,
                  'Favorites',
                  'Gowns and suits you saved',
                  () => context.go(RoutePaths.favoritesFull),
                ),
                const Divider(height: 1),
                _tile(
                  Icons.straighten,
                  'Measurements',
                  profile.measurements?.hasValues == true
                      ? 'Saved'
                      : 'Not saved yet',
                  () => _editMeasurements(profile),
                ),
                const Divider(height: 1),
                _tile(
                  Icons.contact_phone_outlined,
                  'Contact details',
                  // Mobile and address (Phase 2), or a prompt to add them.
                  _contactSummary(phone, profile.address),
                  () => _editContact(profile),
                ),
                const Divider(height: 1),
                _tile(
                  Icons.assignment_outlined,
                  'Rental terms',
                  'What you agree to when you reserve',
                  _showTerms,
                ),
                const Divider(height: 1),
                _tile(
                  Icons.privacy_tip_outlined,
                  'Privacy and data',
                  'Consent and data deletion',
                  () => context.pushNamed(ProfileRoutes.privacyName),
                ),
              ],
            ),
          ),

          SectionCard(
            margin: gap,
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.deepRed),
              title: const Text(
                'Sign out',
                style: TextStyle(color: AppColors.deepRed),
              ),
              onTap: _busy ? null : _signOut,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// "09171234567 · Jaro, Iloilo City", or a prompt when both are empty.
  static String _contactSummary(String phone, String? address) {
    final parts = [
      if (phone.isNotEmpty) phone,
      if ((address ?? '').trim().isNotEmpty) address!.trim(),
    ];
    return parts.isEmpty
        ? 'Add your mobile number and address'
        : parts.join(' · ');
  }

  static const Map<CustomerBookingTab, IconData> _tabIcons = {
    CustomerBookingTab.toPay: Icons.account_balance_wallet_outlined,
    CustomerBookingTab.toPickUp: Icons.inventory_2_outlined,
    CustomerBookingTab.rented: Icons.checkroom_outlined,
    CustomerBookingTab.completed: Icons.task_alt,
    CustomerBookingTab.cancelled: Icons.cancel_outlined,
  };

  /// One shortcut icon with its count badge.
  Widget _shortcut(CustomerBookingTab tab, int count, ThemeData theme) {
    return Semantics(
      button: true,
      label: '${tab.label}: $count',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go('${RoutePaths.myBookings}?tab=${tab.key}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                backgroundColor: AppColors.deepRed,
                child: Icon(_tabIcons[tab], color: AppColors.maroon, size: 28),
              ),
              const SizedBox(height: 6),
              Text(
                tab.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) => ListTile(
    leading: Icon(icon, color: AppColors.maroon),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: _busy ? null : onTap,
  );
}
