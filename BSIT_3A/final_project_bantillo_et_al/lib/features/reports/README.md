# reports

- **Owner:** Member 3
- **Purpose:** Rentals per month, most-rented items and revenue per month (fl_chart).
- **SQL:** `supabase/migrations/0004_reports.sql`. These functions are read-only, staff-only and SECURITY DEFINER:
  - `report_rentals_per_month(p_months)`
  - `report_top_items(p_months, p_limit)`
  - `report_revenue_per_month(p_months)`
- **Routes:** `/shop/reports`, opened from More, then Reports (see `reports_routes.dart`).

## Definitions

- **Rental:** a booking that was actually picked up (status `rented_out` or `returned`). It's counted in its pick-up month.
- **Revenue:** the sum of `payments.amount`, counted in the month the payment was recorded (Philippine time). Refunds aren't modelled.
- **Range:** the last 3, 6 (default) or 12 months, including the current one. Months with nothing in them show as 0.

## Screen

- **Charts:** bar charts for rentals and revenue. Tap a bar to see the month and its value. Each chart also gives screen readers a text summary.
- **Top items:** a ranked list of the top 5, with a bar relative to the number 1 item.
- **States:** each report has its own loading, empty ("No rentals yet" or "No payments recorded yet") and error (Retry) state.
- **Refresh:** pull down, or use the refresh button.
- **Layout:** the two charts sit side by side at 900 px or wider.

## Folder

| Path | What it is |
| --- | --- |
| `models/report_data.dart` | Rows, range selector, chart maths. Unit tested. |
| `services/reports_service.dart` | RPC calls and friendly errors. |
| `screens/reports_screen.dart` | The screen. |
| `widgets/` | Month bar chart, report card (states), top items list. |
