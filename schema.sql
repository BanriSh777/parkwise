-- =============================================================================
-- ParkWise — schema.sql
-- Full PostgreSQL schema: tables, constraints, indexes.
-- Target: PostgreSQL 15+
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto; -- provides gen_random_uuid()

-- =============================================================================
-- Table: users
-- Identity is keyed by mobile_number. A user row is created implicitly at
-- first booking (either OTP-verified advance booking, or mobile-only walk-in).
-- password_hash is nullable: only set once a user has completed at least one
-- OTP-verified booking (account_status = FULL_ACCOUNT), per Business Rule #11.
-- =============================================================================
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mobile_number   VARCHAR(15) NOT NULL,
    email           VARCHAR(255),
    password_hash   VARCHAR(255),
    role            VARCHAR(20) NOT NULL DEFAULT 'CUSTOMER',
    account_status  VARCHAR(20) NOT NULL DEFAULT 'VERIFIED_ONLY',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT uq_users_mobile_number UNIQUE (mobile_number),
    CONSTRAINT chk_users_role CHECK (role IN ('CUSTOMER', 'ADMIN')),
    CONSTRAINT chk_users_account_status CHECK (account_status IN ('VERIFIED_ONLY', 'FULL_ACCOUNT'))
);

-- Email is optional but must be unique when present.
CREATE UNIQUE INDEX uq_users_email ON users (email) WHERE email IS NOT NULL;

COMMENT ON TABLE users IS 'User identity, keyed by mobile number. password_hash is null until user completes deferred password setup.';
COMMENT ON COLUMN users.account_status IS 'VERIFIED_ONLY = has never completed an OTP-verified booking (no login capability). FULL_ACCOUNT = eligible for/has set a password.';

-- =============================================================================
-- Table: floors
-- Admin-managed physical inventory. walk_in_cap_count bounds how many
-- concurrently ACTIVE/PENDING walk-in reservations this floor allows.
-- =============================================================================
CREATE TABLE floors (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                VARCHAR(100) NOT NULL,
    floor_number        INT NOT NULL,
    total_capacity      INT NOT NULL,
    walk_in_cap_count   INT NOT NULL DEFAULT 0,
    active              BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT uq_floors_floor_number UNIQUE (floor_number),
    CONSTRAINT chk_floors_total_capacity_positive CHECK (total_capacity > 0),
    CONSTRAINT chk_floors_walk_in_cap_nonnegative CHECK (walk_in_cap_count >= 0),
    CONSTRAINT chk_floors_walk_in_cap_within_capacity CHECK (walk_in_cap_count <= total_capacity)
);

COMMENT ON TABLE floors IS 'Physical floors of the facility. Soft-deleted via active flag, never hard-deleted once spaces/reservations reference them.';

-- =============================================================================
-- Table: parking_spaces
-- Current, mutable state snapshot of each space. status is written by the
-- reservation module (via FacilityService.markSpaceStatus), not derived by
-- querying reservations on every read — a deliberate performance/consistency
-- tradeoff documented in the Database Design phase.
-- =============================================================================
CREATE TABLE parking_spaces (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    floor_id            UUID NOT NULL REFERENCES floors(id) ON DELETE RESTRICT,
    space_number        VARCHAR(20) NOT NULL,
    vehicle_type        VARCHAR(20) NOT NULL,
    status              VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE',
    walk_in_eligible    BOOLEAN NOT NULL DEFAULT FALSE,
    active              BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT uq_spaces_floor_space_number UNIQUE (floor_id, space_number),
    CONSTRAINT chk_spaces_vehicle_type CHECK (vehicle_type IN ('TWO_WHEELER', 'FOUR_WHEELER')),
    CONSTRAINT chk_spaces_status CHECK (status IN ('AVAILABLE', 'RESERVED', 'OCCUPIED', 'UNDER_MAINTENANCE'))
);

-- Primary read path: "spaces on floor X, for vehicle type Y, in status Z" (the live map query).
CREATE INDEX idx_spaces_floor_vehicle_status ON parking_spaces (floor_id, vehicle_type, status);

COMMENT ON TABLE parking_spaces IS 'Individual parking spaces. status is the live, authoritative snapshot used by the parking map; kept in sync transactionally by the reservation module.';

-- =============================================================================
-- Table: reservations
-- Historical booking record. One row per booking attempt that succeeded.
-- The two partial unique indexes below are the actual double-booking and
-- duplicate-active-reservation guarantees, enforced at the database level
-- as defense-in-depth beyond the application's pessimistic locking.
-- =============================================================================
CREATE TABLE reservations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    space_id        UUID NOT NULL REFERENCES parking_spaces(id) ON DELETE RESTRICT,
    type            VARCHAR(20) NOT NULL,
    status          VARCHAR(20) NOT NULL,
    start_time      TIMESTAMPTZ NOT NULL,
    end_time        TIMESTAMPTZ NOT NULL,
    cancelled_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT chk_reservations_type CHECK (type IN ('ADVANCE', 'WALK_IN')),
    CONSTRAINT chk_reservations_status CHECK (status IN ('PENDING', 'ACTIVE', 'COMPLETED', 'CANCELLED')),
    CONSTRAINT chk_reservations_time_order CHECK (end_time > start_time),
    CONSTRAINT chk_reservations_max_duration CHECK (end_time <= start_time + INTERVAL '5 hours')
);

-- Business Rule #3: at most one PENDING/ACTIVE reservation per user, enforced at the DB level.
CREATE UNIQUE INDEX uq_one_active_reservation_per_user
    ON reservations (user_id)
    WHERE status IN ('PENDING', 'ACTIVE');

-- Business Rule #6: a space cannot be double-booked, enforced at the DB level.
CREATE UNIQUE INDEX uq_one_active_reservation_per_space
    ON reservations (space_id)
    WHERE status IN ('PENDING', 'ACTIVE');

-- Supports "does this user have an active/pending reservation" + history queries.
CREATE INDEX idx_reservations_user_status ON reservations (user_id, status);

-- Supports lock-adjacent lookups during the reservation transaction.
CREATE INDEX idx_reservations_space_status ON reservations (space_id, status);

-- Supports the expiry job's scan: "ACTIVE reservations where end_time has elapsed."
CREATE INDEX idx_reservations_status_endtime ON reservations (status, end_time);

COMMENT ON TABLE reservations IS 'Historical booking records. Partial unique indexes enforce single-active-reservation-per-user and no-double-booking-per-space at the database level.';
COMMENT ON COLUMN reservations.type IS 'ADVANCE (OTP-verified, future start time, PENDING initially) or WALK_IN (mobile-only, starts immediately as ACTIVE).';
