// The release / return checklist form, shared by ReleaseChecklistScreen
// and ReturnChecklistScreen (the [kind] decides the differences).
//
// Release (pickup day, booking must be Reserved):
//   * tick every garment and inclusion, condition notes, photos
//   * balance-due banner with a button to Record Payment
//   * "Release items" stays disabled until everything is ticked and the
//     balance is 0. Saving moves the booking to Rented Out.
// Return (return day, booking must be Rented Out):
//   * same checklist, but missing items may stay unticked
//   * condition notes, photos, damage notes, penalty (0 or more)
//   * "Mark returned" moves the booking to Returned and the items to
//     Cleaning / Repair.
//
// Saving: photos are uploaded one by one (with progress), then
// save_checklist is called. If anything fails, an error with Retry is
// shown; photos already uploaded are not uploaded again.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/core/widgets/loading_view.dart';
import 'package:orange150_rental/core/widgets/status_chip.dart';
import 'package:orange150_rental/features/checklist/models/checklist_booking.dart';
import 'package:orange150_rental/features/checklist/models/checklist_kind.dart';
import 'package:orange150_rental/features/checklist/models/checklist_photo.dart';
import 'package:orange150_rental/features/checklist/models/checklist_rules.dart';
import 'package:orange150_rental/features/checklist/services/checklist_service.dart';
import 'package:orange150_rental/features/checklist/widgets/checklist_notice.dart';
import 'package:orange150_rental/features/checklist/widgets/inclusion_checklist.dart';
import 'package:orange150_rental/features/checklist/widgets/photo_picker_grid.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';

/// Release or return checklist for one booking.
class ChecklistScreen extends StatefulWidget {
  /// Creates the screen for [bookingId] (from the route path).
  const ChecklistScreen({
    super.key,
    required this.bookingId,
    required this.kind,
  });

  /// Path parameter from the route (see checklist_routes.dart).
  final String bookingId;

  /// Release or return.
  final ChecklistKind kind;

  /// Content width from which the form uses two columns.
  static const double twoColumnBreakpoint = 840;

  /// Most photos per checklist.
  static const int maxPhotos = 10;

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final ChecklistService _service = ChecklistService();
  final ImagePicker _picker = ImagePicker();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _conditionNotes = TextEditingController();
  final TextEditingController _damageNotes = TextEditingController();
  final TextEditingController _penalty = TextEditingController(text: '0');

  // Loading the booking.
  ChecklistBooking? _booking;
  List<InclusionLine> _lines = const [];
  String? _loadError;
  bool _loading = true;

  // The form.
  final Set<String> _ticked = {};
  final List<ChecklistPhoto> _photos = [];

  // Saving.
  bool _saving = false;
  String _progress = '';
  String? _saveError;

  bool get _isRelease => widget.kind == ChecklistKind.release;

  /// The status the booking must have for this checklist.
  BookingStatus get _requiredStatus =>
      _isRelease ? BookingStatus.reserved : BookingStatus.rentedOut;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _conditionNotes.dispose();
    _damageNotes.dispose();
    _penalty.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  /// Retry button: show the spinner and load again.
  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    await _fetch();
  }

  /// Loads the booking and builds the checkbox lines. Ticks are kept for
  /// lines that still exist (e.g. after coming back from Record Payment).
  Future<void> _fetch() async {
    try {
      final booking = await _service.loadBooking(widget.bookingId);
      if (!mounted) return;
      final lines = ChecklistRules.buildLines(booking.items);
      setState(() {
        _booking = booking;
        _lines = lines;
        _ticked.retainAll(lines.map((l) => l.key));
        _loading = false;
      });
    } on ChecklistException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loading = false;
      });
    }
  }

  /// Opens Record Payment (shop_bookings feature, by path), then reloads
  /// the balance.
  Future<void> _openRecordPayment() async {
    await context.push<Object?>(
      '${RoutePaths.shopBookings}/${widget.bookingId}/payment',
    );
    if (mounted) await _fetch();
  }

  // ---------------------------------------------------------------------------
  // Photos
  // ---------------------------------------------------------------------------

  /// Takes one photo with the camera.
  Future<void> _pickFromCamera() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 75,
      );
      if (file != null) await _addFiles([file]);
    } catch (error) {
      _showSnack('Could not open the camera. Try Gallery instead.');
    }
  }

  /// Picks one or more photos from the gallery / files.
  Future<void> _pickFromGallery() async {
    try {
      final files = await _picker.pickMultiImage(
        maxWidth: 1600,
        imageQuality: 75,
      );
      await _addFiles(files);
    } catch (error) {
      _showSnack('Could not open the gallery.');
    }
  }

  /// Reads the picked files and adds them, up to the photo limit.
  Future<void> _addFiles(List<XFile> files) async {
    final room = ChecklistScreen.maxPhotos - _photos.length;
    if (files.length > room) {
      _showSnack('Only ${ChecklistScreen.maxPhotos} photos are allowed.');
    }
    final added = <ChecklistPhoto>[];
    for (final file in files.take(room)) {
      added.add(
        ChecklistPhoto(
          bytes: await file.readAsBytes(),
          mimeType: file.mimeType,
        ),
      );
    }
    if (!mounted || added.isEmpty) return;
    setState(() => _photos.addAll(added));
  }

  void _removePhoto(int index) => setState(() => _photos.removeAt(index));

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------------------------------------------------------------------
  // Saving
  // ---------------------------------------------------------------------------

  /// Uploads the photos that are not uploaded yet, then saves the
  /// checklist. Also used by the Retry button.
  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final booking = _booking!;
    if (_isRelease &&
        !ChecklistRules.canRelease(
          lines: _lines,
          ticked: _ticked,
          balance: booking.booking.balance,
        )) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() {
      _saving = true;
      _saveError = null;
    });

    try {
      // 1. Upload photos one at a time so staff can see progress.
      final toUpload = _photos.where((p) => !p.isUploaded).toList();
      for (var i = 0; i < toUpload.length; i++) {
        if (!mounted) return;
        setState(
          () => _progress = 'Uploading photo ${i + 1} of ${toUpload.length}...',
        );
        toUpload[i].storagePath = await _service.uploadPhoto(
          bookingId: widget.bookingId,
          kind: widget.kind,
          bytes: toUpload[i].bytes,
          mimeType: toUpload[i].mimeType,
        );
      }

      // 2. Save the checklist and change the status.
      if (!mounted) return;
      setState(() => _progress = 'Saving checklist...');
      await _service.saveChecklist(
        bookingId: widget.bookingId,
        kind: widget.kind,
        inclusionsChecked: ChecklistRules.checkedMap(_lines, _ticked),
        conditionNotes: _conditionNotes.text.trim(),
        photoPaths: [for (final p in _photos) p.storagePath!],
        damageNotes: _isRelease ? null : _damageNotes.text.trim(),
        penaltyAmount: _isRelease
            ? 0
            : ChecklistRules.parsePenalty(_penalty.text),
      );
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isRelease
                ? 'Items released. ${booking.booking.referenceNo} is now '
                      'Rented Out.'
                : '${booking.booking.referenceNo} marked as returned. '
                      'Items moved to Cleaning / Repair.',
          ),
        ),
      );
      // Back to the booking details (it reloads when we return).
      if (router.canPop()) {
        router.pop(true);
      } else {
        router.go('${RoutePaths.shopBookings}/${widget.bookingId}');
      }
    } on ChecklistException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = e.message;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRelease ? 'Release Checklist' : 'Return Checklist'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView(message: 'Loading booking...');
    final booking = _booking;
    if (_loadError != null || booking == null) {
      return ErrorView(
        message: _loadError ?? 'Could not load this booking.',
        onRetry: _reload,
      );
    }

    // Wrong status: e.g. already released, or not yet reserved.
    if (booking.booking.status != _requiredStatus) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _isRelease
                ? 'Only Reserved bookings can be released. This booking is '
                      '${booking.booking.status.label}.'
                : 'Only Rented Out bookings can be returned. This booking is '
                      '${booking.booking.status.label}.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoColumns =
              constraints.maxWidth >= ChecklistScreen.twoColumnBreakpoint;
          final left = [_summaryCard(booking), _inclusionsCard()];
          final right = [
            _notesCard(),
            _photosCard(),
            if (!_isRelease) _returnCard(),
            _saveArea(booking),
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: twoColumns
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Column(children: left)),
                      const SizedBox(width: 16),
                      Expanded(child: Column(children: right)),
                    ],
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Column(children: [...left, ...right]),
                    ),
                  ),
          );
        },
      ),
    );
  }

  /// Booking reference, customer, date and (for release) the balance.
  Widget _summaryCard(ChecklistBooking booking) {
    final row = booking.booking;
    final theme = Theme.of(context);
    return _card(
      title: row.referenceNo,
      icon: Icons.receipt_outlined,
      trailing: StatusChip.booking(row.status),
      children: [
        Text(booking.customerName, style: theme.textTheme.bodyLarge),
        Text(
          _isRelease
              ? 'Pick-up: ${Formatters.date(row.pickupDate)}'
              : 'Return due: ${Formatters.date(row.returnDate)}',
        ),
        if (_isRelease && row.balance > 0) ...[
          const SizedBox(height: 12),
          ChecklistNotice(
            icon: Icons.payments_outlined,
            color: AppColors.warningOrange,
            message:
                'Balance due: ${Formatters.peso(row.balance)}. Collect it '
                'before releasing the items.',
            actionLabel: 'Record payment',
            actionIcon: Icons.add_card,
            onAction: _saving ? null : _openRecordPayment,
          ),
        ],
        if (_isRelease && row.balance <= 0)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.success),
                SizedBox(width: 8),
                Text('Paid in full'),
              ],
            ),
          ),
      ],
    );
  }

  /// The checkbox list.
  Widget _inclusionsCard() {
    final total = _lines.length;
    final done = _lines.where((l) => _ticked.contains(l.key)).length;
    return _card(
      title: 'Inclusions ($done of $total)',
      icon: Icons.checklist,
      children: [
        Text(
          _isRelease
              ? 'Tick each item as you hand it to the customer.'
              : 'Tick each item the customer brought back. Leave missing '
                    'items unticked.',
        ),
        InclusionChecklist(
          lines: _lines,
          ticked: _ticked,
          enabled: !_saving,
          uncheckedHint: _isRelease ? null : 'Missing',
          onChanged: (key, value) => setState(() {
            value ? _ticked.add(key) : _ticked.remove(key);
          }),
        ),
      ],
    );
  }

  /// Condition notes.
  Widget _notesCard() {
    return _card(
      title: 'Condition',
      icon: Icons.edit_note,
      children: [
        TextFormField(
          controller: _conditionNotes,
          enabled: !_saving,
          maxLines: 3,
          maxLength: 1000,
          decoration: InputDecoration(
            labelText: 'Condition notes (optional)',
            hintText: _isRelease
                ? 'e.g. Clean, no stains, zipper OK'
                : 'e.g. Hem dirty, small tear on sleeve',
          ),
        ),
      ],
    );
  }

  /// Photo thumbnails and pickers.
  Widget _photosCard() {
    return _card(
      title: 'Photos',
      icon: Icons.photo_camera_outlined,
      children: [
        PhotoPickerGrid(
          photos: _photos,
          enabled: !_saving,
          maxPhotos: ChecklistScreen.maxPhotos,
          onCamera: _pickFromCamera,
          onGallery: _pickFromGallery,
          onRemove: _removePhoto,
        ),
      ],
    );
  }

  /// Return only: damage notes and penalty.
  Widget _returnCard() {
    return _card(
      title: 'Damage and penalty',
      icon: Icons.report_outlined,
      children: [
        TextFormField(
          controller: _damageNotes,
          enabled: !_saving,
          maxLines: 3,
          maxLength: 1000,
          decoration: const InputDecoration(
            labelText: 'Damage notes (optional)',
            hintText: 'e.g. Gloves not returned, wine stain on skirt',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _penalty,
          enabled: !_saving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: const InputDecoration(
            labelText: 'Penalty',
            prefixText: '₱ ',
            helperText: 'Enter 0 if there is no penalty.',
          ),
          validator: ChecklistRules.validatePenalty,
        ),
      ],
    );
  }

  /// Error with Retry, progress while saving, and the main button.
  Widget _saveArea(ChecklistBooking booking) {
    final blockedReason = _isRelease
        ? ChecklistRules.releaseBlockedReason(
            lines: _lines,
            ticked: _ticked,
            balance: booking.booking.balance,
          )
        : null;
    final canPress = !_saving && blockedReason == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_saveError != null) ...[
          ChecklistNotice(
            icon: Icons.error_outline,
            color: AppColors.deepRed,
            message: _saveError!,
            actionLabel: 'Retry',
            actionIcon: Icons.refresh,
            onAction: _saving ? null : _save,
          ),
          const SizedBox(height: 12),
        ],
        if (_saving) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(_progress, textAlign: TextAlign.center),
          const SizedBox(height: 12),
        ],
        if (blockedReason != null && !_saving)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(blockedReason, textAlign: TextAlign.center),
          ),
        FilledButton.icon(
          onPressed: canPress ? _save : null,
          icon: Icon(
            _isRelease ? Icons.outbox_outlined : Icons.assignment_return,
          ),
          label: Text(_isRelease ? 'Release items' : 'Mark returned'),
        ),
      ],
    );
  }

  /// A titled card section.
  Widget _card({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}
