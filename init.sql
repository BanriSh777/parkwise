-- =============================================================================
-- ParkWise — init.sql
-- Seed data: one admin, sample customers (covering both account statuses),
-- two floors with mixed-vehicle-type spaces (some walk-in eligible), and
-- sample reservations covering every reservation status.
--
-- Run this AFTER schema.sql. UUIDs are hardcoded (not gen_random_uuid()) so
-- seed data is reproducible and reservations can deterministically reference
-- specific users/spaces.
-- =============================================================================

-- =============================================================================
-- Users
-- =============================================================================

-- Admin — full account, password already set (bcrypt hash below is a placeholder;
-- replace with a real bcrypt hash of a known password before actual use).
INSERT INTO users (id, mobile_number, email, password_hash, role, account_status, created_at, updated_at)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    '9999999999',
    'admin@parkwise.local',
    '$2a$10$replaceWithRealBcryptHashXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    'ADMIN',
    'FULL_ACCOUNT',
    now(), now()
);

-- Customer 1 — full account (completed an OTP-verified booking, has since set a password).
INSERT INTO users (id, mobile_number, email, password_hash, role, account_status, created_at, updated_at)
VALUES (
    '00000000-0000-0000-0000-000000000002',
    '9000000001',
    'priya.customer@example.com',
    '$2a$10$replaceWithRealBcryptHashXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    'CUSTOMER',
    'FULL_ACCOUNT',
    now(), now()
);

-- Customer 2 — verified only, has an OTP-verified advance booking but hasn't set a password yet.
INSERT INTO users (id, mobile_number, email, password_hash, role, account_status, created_at, updated_at)
VALUES (
    '00000000-0000-0000-0000-000000000003',
    '9000000002',
    NULL,
    NULL,
    'CUSTOMER',
    'VERIFIED_ONLY',
    now(), now()
);

-- Customer 3 — walk-in only, mobile number captured, never OTP-verified, no login capability.
INSERT INTO users (id, mobile_number, email, password_hash, role, account_status, created_at, updated_at)
VALUES (
    '00000000-0000-0000-0000-000000000004',
    '9000000003',
    NULL,
    NULL,
    'CUSTOMER',
    'VERIFIED_ONLY',
    now(), now()
);

-- =============================================================================
-- Floors
-- =============================================================================

INSERT INTO floors (id, name, floor_number, total_capacity, walk_in_cap_count, active, created_at, updated_at)
VALUES (
    '10000000-0000-0000-0000-000000000001',
    'Ground Floor',
    0,
    10,
    3,
    TRUE,
    now(), now()
);

INSERT INTO floors (id, name, floor_number, total_capacity, walk_in_cap_count, active, created_at, updated_at)
VALUES (
    '10000000-0000-0000-0000-000000000002',
    'First Floor',
    1,
    10,
    2,
    TRUE,
    now(), now()
);

-- =============================================================================
-- Parking Spaces — Ground Floor (5 four-wheeler, 5 two-wheeler; 3 walk-in eligible)
-- =============================================================================

INSERT INTO parking_spaces (id, floor_id, space_number, vehicle_type, status, walk_in_eligible, active, created_at, updated_at) VALUES
    ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'G-01', 'FOUR_WHEELER', 'AVAILABLE', TRUE,  TRUE, now(), now()),
    ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', 'G-02', 'FOUR_WHEELER', 'AVAILABLE', TRUE,  TRUE, now(), now()),
    ('20000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', 'G-03', 'FOUR_WHEELER', 'AVAILABLE', FALSE, TRUE, now(), now()),
    ('20000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000001', 'G-04', 'FOUR_WHEELER', 'AVAILABLE', FALSE, TRUE, now(), now()),
    ('20000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000001', 'G-05', 'FOUR_WHEELER', 'UNDER_MAINTENANCE', FALSE, TRUE, now(), now()),
    ('20000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000001', 'G-06', 'TWO_WHEELER',  'AVAILABLE', TRUE,  TRUE, now(), now()),
    ('20000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000001', 'G-07', 'TWO_WHEELER',  'AVAILABLE', FALSE, TRUE, now(), now()),
    ('20000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000001', 'G-08', 'TWO_WHEELER',  'AVAILABLE', FALSE, TRUE, now(), now()),
    ('20000000-0000-0000-0000-000000000009', '10000000-0000-0000-0000-000000000001', 'G-09', 'TWO_WHEELER',  'AVAILABLE', FALSE, TRUE, now(), now()),
    ('20000000-0000-0000-0000-000000000010', '10000000-0000-0000-0000-000000000001', 'G-10', 'TWO_WHEELER',  'AVAILABLE', FALSE, TRUE, now(), now());

-- =============================================================================
-- Parking Spaces — First Floor (5 four-wheeler, 5 two-wheeler; 2 walk-in eligible)
-- =============================================================================

INSERT INTO parking_spaces (id, floor_id, space_number, vehicle_type, status, walk_in_eligible, active, created_at, updated_at) VALUES
    ('20000000-0000-0000-0000-000000000011', '10000000-0000-0000-0000-000000000002', 'F-01', 'FOUR_WHEELER', 'AVAILABLE', TRUE,  TRUE, now(), now()),
    ('20000000-0000-0000-0000-000000000012', '10000000-0000-0000-0000-000000000002', 'F-02', 'FOUR_WHEELER', 'AVAILABLE', FALSE, TRUE, now(), now()),
    ('20000000-0000-0000-0000-000000000013', '10000000-0000-0000-0000-000000000002', 'F-03', 'FOUR_WHEELER', 'AVAILABLE', FALSE, TRUE, now(), now()),
    ('20000000-0000-0000-0000-000000000014', '10000000-0000-0000-0000-000000000002', 'F-04', 'FOUR_WHEELER', 'AVAILABLE', FALSE, TRUE, now(), now()),
    ('20000000-0000-0000-0000-000000000015', '10000000-0000-0000-0000-000000000002', 'F-05', 'FOUR_WHEELER', 'AVAILABLE', FALSE, TRUE, now(), now()),
    ('20000000-0000-0000-0000-000000000016', '10000000-0000-0000-0000-000000000002', 'F-06', 'TWO_WHEELER',  'AVAILABLE', TRUE,  TRUE, now(), now()),
    ('20000000-0000-0000-0000-000000000017', '10000000-0000-0000-0000-000000000002', 'F-07', 'TWO_WHEELER',  'AVAILABLE', FALSE, TRUE, now(), now()),
    ('20000000-0000-0000-0000-000000000018', '10000000-0000-0000-0000-000000000002', 'F-08', 'TWO_WHEELER',  'AVAILABLE', FALSE, TRUE, now(), now()),
    ('20000000-0000-0000-0000-000000000019', '10000000-0000-0000-0000-000000000002', 'F-09', 'TWO_WHEELER',  'AVAILABLE', FALSE, TRUE, now(), now()),
    ('20000000-0000-0000-0000-000000000020', '10000000-0000-0000-0000-000000000002', 'F-10', 'TWO_WHEELER',  'AVAILABLE', FALSE, TRUE, now(), now());

-- =============================================================================
-- Sample Reservations — one of each status, so all lifecycle states have data
-- =============================================================================

-- 1) PENDING advance reservation (Customer 1, Ground Floor G-03, starts in the future).
--    Space status reflects the reservation: RESERVED.
UPDATE parking_spaces SET status = 'RESERVED', updated_at = now() WHERE id = '20000000-0000-0000-0000-000000000003';

INSERT INTO reservations (id, user_id, space_id, type, status, start_time, end_time, cancelled_at, created_at, updated_at)
VALUES (
    '30000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000003',
    'ADVANCE',
    'PENDING',
    now() + INTERVAL '2 hours',
    now() + INTERVAL '4 hours',
    NULL,
    now(), now()
);

-- 2) ACTIVE walk-in reservation (Customer 3, Ground Floor G-01, started now).
UPDATE parking_spaces SET status = 'RESERVED', updated_at = now() WHERE id = '20000000-0000-0000-0000-000000000001';

INSERT INTO reservations (id, user_id, space_id, type, status, start_time, end_time, cancelled_at, created_at, updated_at)
VALUES (
    '30000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000004',
    '20000000-0000-0000-0000-000000000001',
    'WALK_IN',
    'ACTIVE',
    now(),
    now() + INTERVAL '3 hours',
    NULL,
    now(), now()
);

-- 3) COMPLETED advance reservation (Customer 2, First Floor F-02, already elapsed).
--    Space has since reverted to AVAILABLE (default status, no update needed).
INSERT INTO reservations (id, user_id, space_id, type, status, start_time, end_time, cancelled_at, created_at, updated_at)
VALUES (
    '30000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000003',
    '20000000-0000-0000-0000-000000000012',
    'ADVANCE',
    'COMPLETED',
    now() - INTERVAL '6 hours',
    now() - INTERVAL '3 hours',
    NULL,
    now() - INTERVAL '6 hours', now() - INTERVAL '3 hours'
);

-- 4) CANCELLED advance reservation (Customer 1, First Floor F-06, user cancelled before start).
--    Space has since reverted to AVAILABLE (default status, no update needed).
INSERT INTO reservations (id, user_id, space_id, type, status, start_time, end_time, cancelled_at, created_at, updated_at)
VALUES (
    '30000000-0000-0000-0000-000000000004',
    '00000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000016',
    'ADVANCE',
    'CANCELLED',
    now() + INTERVAL '5 hours',
    now() + INTERVAL '7 hours',
    now() - INTERVAL '1 hour',
    now() - INTERVAL '2 hours', now() - INTERVAL '1 hour'
);
