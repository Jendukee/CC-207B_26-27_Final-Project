# shop_calendar

- **Owner:** Member 3
- **Purpose:** Staff calendar of bookings (pick-up to return), with conflict check and filters.
- **Tables (read):** bookings, profiles (customer name), booking_items, items. SELECT grants come from `0006_table_grants.sql`. No new SQL.
- **Routes:** `/shop/calendar` (see `shop_calendar_routes.dart`). Tapping a booking opens `/shop/bookings/<id>` by path.

## What it shows

- **Calendar:** month or week view. Each day gets one dot per booking, in the StatusChip color of its status (Pending, Reserved, Rented Out, Returned). After 3 dots it shows "+N".
- **Hidden bookings:** cancelled and expired bookings, and pending requests past `expires_at`, hold no dates, so they're not shown.
- **Conflict:** two or more blocking bookings (reserved or rented out) holding the same item on the same day. The day gets a red ring and a warning icon, and those bookings get a red "Conflict" chip. The database exclusion constraint should prevent this; the calendar still checks, so any bad data is visible.
- **Filter:** All, Gowns or Suits, and one item. The filter runs in Dart on the month's bookings. Conflicts are always checked against all loaded bookings.
- **Day list:** tapping a day lists its bookings, marked Pick-up, Event or Return, below the calendar. At 900 px or wider it appears in a side panel instead.
- **Loading:** data is loaded per visible month, padded by a week on each side so neighbouring days in the month or week view are covered.

## Folder

| Path | What it is |
| --- | --- |
| `models/calendar_rules.dart` | Days, roles, conflicts, filter, load range. Unit tested. |
| `models/calendar_booking.dart` | Booking plus customer name and items. |
| `services/shop_calendar_service.dart` | Month query, item list, friendly errors. |
| `screens/shop_calendar_screen.dart` | The calendar screen. |
| `widgets/` | Legend, day markers, booking tile. |
