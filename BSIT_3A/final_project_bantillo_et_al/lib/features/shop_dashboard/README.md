# shop_dashboard

- **Owner:** Member 3
- **Purpose:** The staff home (Dashboard tab) and the More tab.
- **Tables (read):** bookings, profiles (customer name). SELECT grants come from `0006_table_grants.sql`. No new SQL.
- **Routes:** see `shop_dashboard_routes.dart`: `/shop/dashboard`, `/shop/more`, `/shop/more/settings`, `/shop/more/staff`.

## Dashboard cards

| Card | Query | Tapping the card opens |
| --- | --- | --- |
| Pick-ups today | `pickup_date = today`, reserved | `/shop/bookings?status=reserved&from=<tomorrow>&to=<tomorrow>` |
| Returns today | `return_date = today`, rented_out | `/shop/bookings?status=rented_out&from=<yesterday>&to=<yesterday>` |
| Overdue returns | `return_date < today`, rented_out | `/shop/bookings?status=rented_out&from=2000-01-01&to=<2 days ago>` |
| Requests expiring in 24 h | pending, `expires_at` in the next 24 h | `/shop/bookings?status=pending` |
| New requests since yesterday | pending, created since yesterday 00:00 (not yet expired) | `/shop/bookings?status=pending` |

The bookings list filters by **event** date. Pick-up is the day before the event and return is the day after, which is why the links shift the dates. Tapping a booking opens `/shop/bookings/<id>`.

Each card has its own loading, empty ("Nothing scheduled today" for pick-ups and returns) and error (Retry) state. Pull to refresh reloads all cards. Wide screens (840 px or wider) show a 2-column grid.

## Folder

| Path | What it is |
| --- | --- |
| `models/dashboard_section.dart` | The five cards, link building and date maths. Unit tested. |
| `models/dashboard_booking.dart` | Booking plus customer name. |
| `services/shop_dashboard_service.dart` | One query per card and friendly errors. |
| `screens/shop_dashboard_screen.dart` | The dashboard. |
| `screens/shop_more_screen.dart` | Account info, Reports, Settings / Staff placeholders, Sign out. |
| `screens/shop_settings_screen.dart` | Shop settings (owner edits, staff view; 0016). |
| `screens/staff_accounts_screen.dart` | Staff accounts (owner only; 0015). |
| `widgets/dashboard_glance_card.dart` | "Today at a glance" card: summary, View more, bookings, states. |
| `widgets/dashboard_requests_panel.dart` | "New requests since yesterday" panel. |
