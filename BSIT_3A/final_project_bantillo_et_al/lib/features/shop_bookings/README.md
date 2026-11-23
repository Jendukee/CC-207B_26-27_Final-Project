# shop_bookings

- **Owner:** Member 3
- **Purpose:** Staff booking list and details, record payment, status changes.
- **Tables (read):** bookings, booking_items, items, payments, profiles. SELECT grants come from `0006_table_grants.sql`.
- **Writes:** only through the SQL functions in `supabase/migrations/0002_shop_bookings.sql`:
  - `record_payment(p_booking_id, p_amount, p_kind, p_method)`: payment, amount_paid and pending to reserved in one transaction.
  - `update_booking_status(p_booking_id, p_new_status)`: cancel, rented_out (needs release checklist and full payment), returned (needs return checklist; items go to cleaning_repair).
- **Routes:** see `shop_bookings_routes.dart`. Navigate to other features by path or `RouteNames` only.

## Folder

| Path | What it is |
| --- | --- |
| `models/payment_rules.dart` | Amount rules for Record Payment (same as the SQL). Unit tested. |
| `models/booking_rules.dart` | Displayed status (pending past expiry = expired) and which buttons show. Unit tested. |
| `models/shop_booking_filter.dart` | Search/status/date filter, also read from the URL query. |
| `models/shop_booking.dart` | Booking plus customer, items and payments. |
| `services/shop_bookings_service.dart` | All Supabase calls and friendly error messages. |
| `screens/` | List (details side by side at 840 px or wider), details, record payment. |
| `widgets/` | Booking card, filter bar, detail section helpers. |

## Opening a filtered list from another feature

```dart
context.go('/shop/bookings?status=reserved&from=2026-12-01&to=2026-12-31');
```

Query keys: `status` (a `bookings.status` value), `q` (search text), `from` / `to` (event date, `yyyy-MM-dd`).

## Status buttons on the details screen

| Displayed status | Buttons |
| --- | --- |
| Pending | Record payment to reserve, Cancel |
| Expired (pending past `expires_at`) | Cancel |
| Reserved | Record balance payment (if owing), Mark picked up (opens release checklist), Cancel |
| Rented Out | Mark returned (opens return checklist) |
| Returned / Cancelled | None |
