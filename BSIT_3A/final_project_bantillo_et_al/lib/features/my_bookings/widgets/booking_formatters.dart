// Shared formatting helpers for the my_bookings feature.
//
// OWNER: Member 2.

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// e.g. "Dec 5, 2026".
String formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

/// Same as [formatDate] but shows an en dash for null.
String formatDateOrDash(DateTime? d) => d == null ? '–' : formatDate(d);

/// e.g. "₱1,500.00".
String formatPeso(num amount) {
  final fixed = amount.toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '₱$whole.${parts[1]}';
}