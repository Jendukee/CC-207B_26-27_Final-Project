-- =============================================================================
-- seed.sql : sample data for development. Run AFTER 0001_init.sql.
--   * Dashboard: SQL Editor -> paste -> Run
--   * CLI (local stack): supabase db reset   (runs migrations + this seed)
--
-- Photos are left empty; upload real ones to the item-photos bucket from the
-- Inventory screen once Member 1 builds it.
-- =============================================================================

insert into public.items (name, type, age_group, size, price, description, inclusions, condition)
values
  ('Ivory Ball Gown', 'gown', 'adult', 'M', 3500.00,
   'Ivory tulle ball gown with beaded bodice. Ideal for debuts and weddings.',
   array['Petticoat', 'Gloves'], 'available'),
  ('Maroon Filipiniana Terno', 'gown', 'adult', 'S', 2800.00,
   'Modern Filipiniana terno with butterfly sleeves in maroon satin.',
   array['Panuelo'], 'available'),
  ('Gold Flower Girl Dress', 'gown', 'kids', '6-8', 1200.00,
   'Gold-accented flower girl dress with a satin sash.',
   array['Hair clip', 'Petticoat'], 'available'),
  ('Classic Black Tuxedo', 'suit', 'adult', '40R', 2500.00,
   'Two-piece black tuxedo with satin lapels.',
   array['Bow tie', 'Cummerbund'], 'available'),
  ('Navy Slim-Fit Suit', 'suit', 'adult', '38R', 2200.00,
   'Navy slim-fit two-piece suit for formal events.',
   array['Necktie', 'Pocket square'], 'cleaning_repair'),
  ('Kids Barong Tagalog', 'suit', 'kids', '10-12', 900.00,
   'Pina-style barong for ring bearers and junior entourage.',
   array['Black slacks'], 'available');

-- -----------------------------------------------------------------------------
-- How to promote a user to staff or owner
-- -----------------------------------------------------------------------------
-- 1. The person registers normally in the app (they start as 'customer').
-- 2. In the Supabase SQL Editor, run ONE of these with their email:
--
--    update public.profiles set role = 'staff'
--    where id = (select id from auth.users where email = 'staff@example.com');
--
--    update public.profiles set role = 'owner'
--    where id = (select id from auth.users where email = 'owner@example.com');
--
-- 3. They sign out and sign in again (or restart the app). Splash now sends
--    them to the staff Dashboard.
--
-- Users cannot change their own role from the app: the profiles UPDATE grant
-- only covers full_name, phone and privacy_consent_at.
