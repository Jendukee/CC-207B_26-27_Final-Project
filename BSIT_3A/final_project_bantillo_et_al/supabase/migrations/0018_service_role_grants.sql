-- =============================================================================
-- 0018_service_role_grants.sql : let the manage-staff Edge Function use the
-- profiles table (fix for "error 500" when the owner creates a staff login).
--
-- Why: this project does not give new tables to the API roles by default
-- (see 0006). 0006 granted anon / authenticated, but nothing ever granted
-- service_role, the role the manage-staff function uses. service_role
-- skips Row Level Security, but it still needs ordinary table privileges,
-- so every profiles read / write failed with
--   42501 "permission denied for table profiles"
-- and the function answered 500:
--   * checking the owner  -> "Could not check your account."
--   * making the new login staff (upsert) or setting is_disabled
--                         -> "Could not create the staff account." /
--                            "Could not update this account."
--
-- Only service_role gets these. It exists only on the server (the key is a
-- function secret, never in the app), so app users gain nothing.
-- The 0017 trigger still allows service_role to change role / is_disabled.
--
-- Run AFTER 0017. Safe to run more than once.
--
-- OWNER: Member 3 (shop_dashboard).
-- =============================================================================

grant usage on schema public to service_role;

-- manage-staff: read the caller's role and the target account (select),
-- upsert the new staff profile (insert + update), set is_disabled (update).
grant select, insert, update on public.profiles to service_role;

-- =============================================================================
-- Check (SQL Editor): should list SELECT, INSERT and UPDATE for
-- service_role.
--   select grantee, privilege_type
--     from information_schema.role_table_grants
--    where table_schema = 'public' and table_name = 'profiles'
--    order by grantee, privilege_type;
-- =============================================================================
