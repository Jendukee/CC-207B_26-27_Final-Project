# checklist

- **Owner:** Member 3
- **Purpose:** Release (pickup) and return checklists: inclusions, condition, photos, damage, penalty.
- **Tables (read):** bookings, booking_items, items, profiles. SELECT grants come from `0006_table_grants.sql`.
- **Writes:** only through `save_checklist(...)` in `supabase/migrations/0003_checklist.sql`. It inserts into `checklists` and calls `update_booking_status` (0002) in one transaction:
  - release: booking must be reserved, every inclusion ticked, balance paid, then rented_out.
  - return: booking must be rented_out, missing items allowed, penalty 0 or more, then returned, items set to cleaning_repair.
- **Storage:** private bucket `checklist-photos`, path `<booking_id>/<kind>/<timestamp>.jpg`. The staff-only policies are in 0001. Paths are saved in `checklists.photo_urls`.
- **Routes:** `/shop/checklist/release/:bookingId` and `/shop/checklist/return/:bookingId` (see `checklist_routes.dart`). Opened by path from the shop booking details screen. "Record payment" opens `/shop/bookings/:bookingId/payment` by path.

## Folder

| Path | What it is |
| --- | --- |
| `models/checklist_rules.dart` | Checkbox lines (garment + inclusions), release rule, penalty validation. Unit tested. |
| `models/checklist_booking.dart` | Booking plus customer name and items with inclusions. |
| `models/checklist_photo.dart` | A picked photo and its storage path once uploaded. |
| `models/checklist_kind.dart` | release / return. |
| `services/checklist_service.dart` | Load booking, upload photos, save checklist, friendly errors. |
| `screens/checklist_screen.dart` | The shared form; release and return screens are thin wrappers. |
| `widgets/` | Inclusion checkboxes, photo thumbnails, notice box (balance due, error with Retry). |

## How saving works

1. Photos are uploaded one by one, with "Uploading photo 1 of 3..." shown.
2. `save_checklist` is called.
3. If anything fails, an error with **Retry** appears. Photos that were already uploaded are not uploaded again.
