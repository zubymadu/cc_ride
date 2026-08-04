-- =============================================================================
-- CC Ride — PostgreSQL Schema
-- Migrated from GoCarPool MySQL template + full corporate layer
-- =============================================================================

-- Enable PostGIS for geospatial queries
CREATE EXTENSION IF NOT EXISTS postgis;
-- Enable pgcrypto for UUID generation
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =============================================================================
-- ENUMS
-- =============================================================================

CREATE TYPE ride_status AS ENUM ('pending', 'driver_assigned', 'driver_en_route', 'in_progress', 'completed', 'cancelled');
CREATE TYPE booking_status AS ENUM ('pending', 'confirmed', 'processing', 'completed', 'cancelled', 'no_show');
CREATE TYPE booking_method AS ENUM ('instant', 'scheduled');
CREATE TYPE user_status AS ENUM ('active', 'suspended', 'pending_verification', 'banned');
CREATE TYPE driver_status AS ENUM ('pending', 'active', 'suspended', 'offline', 'on_trip');
CREATE TYPE vehicle_status AS ENUM ('pending', 'approved', 'rejected', 'inactive');
CREATE TYPE document_status AS ENUM ('pending', 'approved', 'rejected', 'expired');
CREATE TYPE payout_status AS ENUM ('pending', 'processing', 'completed', 'failed', 'reversed');
CREATE TYPE payout_method AS ENUM ('paystack', 'flutterwave', 'bank_transfer');
CREATE TYPE payment_gateway AS ENUM ('paystack', 'flutterwave');
CREATE TYPE payment_status AS ENUM ('pending', 'successful', 'failed', 'reversed', 'refunded');
CREATE TYPE ride_schedule_type AS ENUM ('one_time', 'recurring_daily', 'recurring_weekly');
CREATE TYPE approval_action AS ENUM ('pending', 'approved', 'rejected', 'escalated');
CREATE TYPE budget_period_type AS ENUM ('monthly', 'quarterly', 'annual');
CREATE TYPE company_status AS ENUM ('active', 'suspended', 'pending_approval', 'inactive');
CREATE TYPE employee_role AS ENUM ('employee', 'manager', 'company_admin', 'company_finance', 'company_hr');
CREATE TYPE ticket_status AS ENUM ('open', 'in_progress', 'resolved', 'closed');
CREATE TYPE ticket_priority AS ENUM ('low', 'medium', 'high', 'urgent');
CREATE TYPE notification_type AS ENUM ('booking_confirmed', 'driver_assigned', 'driver_arrived', 'ride_started', 'ride_completed', 'payment_processed', 'approval_required', 'approval_decided', 'budget_alert', 'general');

-- =============================================================================
-- PLATFORM ADMINISTRATION
-- =============================================================================

CREATE TABLE platform_admins (
    id              BIGSERIAL PRIMARY KEY,
    username        TEXT NOT NULL UNIQUE,
    email           TEXT NOT NULL UNIQUE,
    password_hash   TEXT NOT NULL,
    is_super_admin  BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE platform_settings (
    id                  INT PRIMARY KEY DEFAULT 1 CHECK (id = 1), -- singleton row
    app_name            TEXT NOT NULL DEFAULT 'CC Ride',
    app_logo_url        TEXT,
    timezone            TEXT NOT NULL DEFAULT 'Africa/Lagos',
    currency            TEXT NOT NULL DEFAULT 'NGN',
    currency_symbol     TEXT NOT NULL DEFAULT '₦',
    platform_commission NUMERIC(5,2) NOT NULL DEFAULT 15.00, -- percentage
    min_payout_amount   NUMERIC(15,2) NOT NULL DEFAULT 5000.00,
    referral_bonus      NUMERIC(15,2) NOT NULL DEFAULT 500.00,
    signup_bonus        NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    -- Paystack
    paystack_public_key TEXT,
    paystack_secret_key TEXT,
    -- Flutterwave
    flutterwave_public_key  TEXT,
    flutterwave_secret_key  TEXT,
    flutterwave_enc_key     TEXT,
    -- Firebase
    fcm_server_key      TEXT,
    -- Google Maps
    google_maps_key     TEXT,
    -- SMTP
    smtp_host           TEXT,
    smtp_port           INT,
    smtp_username       TEXT,
    smtp_password       TEXT,
    smtp_from_email     TEXT,
    -- SMS (Termii for Nigeria)
    sms_api_key         TEXT,
    sms_sender_id       TEXT,
    -- App store
    ios_app_url         TEXT,
    android_app_url     TEXT,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO platform_settings (id) VALUES (1);

CREATE TABLE api_rate_limits (
    id              BIGSERIAL PRIMARY KEY,
    identifier      TEXT NOT NULL,   -- IP or user_id
    endpoint        TEXT NOT NULL,
    attempts        INT NOT NULL DEFAULT 1,
    last_attempt_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    blocked_until   TIMESTAMPTZ
);

CREATE UNIQUE INDEX idx_rate_limit_identifier_endpoint ON api_rate_limits (identifier, endpoint);

-- =============================================================================
-- USERS & DRIVERS
-- =============================================================================

CREATE TABLE users (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                TEXT NOT NULL,
    email               TEXT UNIQUE,
    mobile              TEXT NOT NULL,
    country_code        TEXT NOT NULL DEFAULT '+234',
    password_hash       TEXT NOT NULL,
    profile_pic_url     TEXT,
    date_of_birth       DATE,
    bio                 TEXT,
    -- Wallet
    wallet_balance      NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    -- Verification
    is_mobile_verified  BOOLEAN NOT NULL DEFAULT false,
    is_email_verified   BOOLEAN NOT NULL DEFAULT false,
    is_driver           BOOLEAN NOT NULL DEFAULT false,
    status              user_status NOT NULL DEFAULT 'pending_verification',
    -- Referral
    referral_code       TEXT UNIQUE,
    referred_by         UUID REFERENCES users(id),
    -- FCM
    fcm_token           TEXT,
    -- Timestamps
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_active_at      TIMESTAMPTZ,
    CONSTRAINT mobile_unique UNIQUE (mobile, country_code)
);

CREATE TABLE driver_profiles (
    user_id             UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    license_number      TEXT NOT NULL,
    license_expiry      DATE NOT NULL,
    nin                 TEXT,           -- National Identification Number (Nigeria)
    bvn                 TEXT,           -- Bank Verification Number (Nigeria)
    status              driver_status NOT NULL DEFAULT 'pending',
    average_rating      NUMERIC(3,2) NOT NULL DEFAULT 0.00,
    total_trips         INT NOT NULL DEFAULT 0,
    total_earnings      NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    -- Current location (PostGIS point)
    current_location    GEOGRAPHY(POINT, 4326),
    last_location_at    TIMESTAMPTZ,
    -- Bank details for payouts
    bank_name           TEXT,
    bank_account_number TEXT,
    bank_account_name   TEXT,
    paystack_recipient_code TEXT,       -- Paystack transfer recipient code
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE driver_documents (
    id              BIGSERIAL PRIMARY KEY,
    driver_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    document_type   TEXT NOT NULL, -- 'drivers_license', 'vehicle_insurance', 'road_worthiness', 'nin_slip', 'profile_photo'
    file_url        TEXT NOT NULL,
    status          document_status NOT NULL DEFAULT 'pending',
    rejection_note  TEXT,
    expires_at      DATE,
    reviewed_by     BIGINT REFERENCES platform_admins(id),
    reviewed_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
-- VEHICLES
-- =============================================================================

CREATE TABLE vehicle_types (
    id      BIGSERIAL PRIMARY KEY,
    title   TEXT NOT NULL UNIQUE,   -- 'Economy', 'Standard', 'Premium', 'SUV', 'Minivan'
    status  BOOLEAN NOT NULL DEFAULT true
);

INSERT INTO vehicle_types (title) VALUES ('Economy'), ('Standard'), ('Premium'), ('SUV'), ('Minivan');

CREATE TABLE vehicle_models (
    id      BIGSERIAL PRIMARY KEY,
    title   TEXT NOT NULL UNIQUE,
    status  BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE vehicle_colors (
    id      BIGSERIAL PRIMARY KEY,
    title   TEXT NOT NULL UNIQUE,
    status  BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE vehicles (
    id              BIGSERIAL PRIMARY KEY,
    driver_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    model_id        BIGINT NOT NULL REFERENCES vehicle_models(id),
    type_id         BIGINT NOT NULL REFERENCES vehicle_types(id),
    color_id        BIGINT NOT NULL REFERENCES vehicle_colors(id),
    year            SMALLINT NOT NULL,
    license_plate   TEXT NOT NULL UNIQUE,
    photo_url       TEXT,
    seat_capacity   SMALLINT NOT NULL DEFAULT 4,
    status          vehicle_status NOT NULL DEFAULT 'pending',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
-- RIDES & BOOKINGS
-- =============================================================================

CREATE TABLE rides (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id           UUID NOT NULL REFERENCES users(id),
    vehicle_id          BIGINT REFERENCES vehicles(id),
    -- Origin
    origin_address      TEXT NOT NULL,
    origin_location     GEOGRAPHY(POINT, 4326) NOT NULL,
    -- Destination
    destination_address TEXT NOT NULL,
    destination_location GEOGRAPHY(POINT, 4326) NOT NULL,
    -- Schedule
    schedule_type       ride_schedule_type NOT NULL DEFAULT 'one_time',
    scheduled_at        TIMESTAMPTZ NOT NULL,
    -- Pricing
    base_fare           NUMERIC(15,2) NOT NULL,
    fare_per_km         NUMERIC(15,2),
    estimated_distance_km NUMERIC(8,2),
    estimated_duration_min INT,
    -- Capacity
    available_seats     SMALLINT NOT NULL,
    -- Preferences
    luggage_allowed     TEXT NOT NULL DEFAULT 'M',
    restrictions        TEXT[] DEFAULT '{}',
    trip_notes          TEXT,
    -- Status
    status              ride_status NOT NULL DEFAULT 'pending',
    -- OTP verification
    pickup_otp          TEXT NOT NULL,
    dropoff_otp         TEXT NOT NULL,
    -- Timestamps
    started_at          TIMESTAMPTZ,
    completed_at        TIMESTAMPTZ,
    cancelled_at        TIMESTAMPTZ,
    cancellation_reason TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE ride_stops (
    id              BIGSERIAL PRIMARY KEY,
    ride_id         UUID NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
    stop_order      SMALLINT NOT NULL,
    address         TEXT NOT NULL,
    location        GEOGRAPHY(POINT, 4326) NOT NULL
);

CREATE TABLE ride_tracking (
    id          BIGSERIAL PRIMARY KEY,
    ride_id     UUID NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
    driver_id   UUID NOT NULL REFERENCES users(id),
    location    GEOGRAPHY(POINT, 4326) NOT NULL,
    speed_kmh   NUMERIC(6,2),
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_ride_tracking_ride_id ON ride_tracking (ride_id, recorded_at DESC);

CREATE TABLE bookings (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ride_id             UUID NOT NULL REFERENCES rides(id),
    passenger_id        UUID NOT NULL REFERENCES users(id),
    -- Corporate fields (NULLable — individual bookings won't have these)
    company_id          UUID,           -- FK added after companies table created
    department_id       BIGINT,         -- FK added after departments table created
    cost_centre_id      BIGINT,         -- FK added after cost_centres table created
    approval_request_id BIGINT,         -- FK added after approval_requests table created
    -- Seats
    seats_booked        SMALLINT NOT NULL DEFAULT 1,
    -- Fares (stored in NGN)
    subtotal            NUMERIC(15,2) NOT NULL,
    coupon_discount     NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    wallet_amount_used  NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    total_amount        NUMERIC(15,2) NOT NULL,
    driver_earning      NUMERIC(15,2) NOT NULL,
    platform_commission NUMERIC(15,2) NOT NULL,
    booking_fee         NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    -- Payment
    payment_gateway     payment_gateway,
    payment_reference   TEXT UNIQUE,
    payment_status      payment_status NOT NULL DEFAULT 'pending',
    -- Method
    booking_method      booking_method NOT NULL DEFAULT 'instant',
    -- Rating
    passenger_rating    SMALLINT CHECK (passenger_rating BETWEEN 1 AND 5),
    passenger_review    TEXT,
    -- Status
    status              booking_status NOT NULL DEFAULT 'pending',
    -- Timestamps
    confirmed_at        TIMESTAMPTZ,
    completed_at        TIMESTAMPTZ,
    cancelled_at        TIMESTAMPTZ,
    cancellation_reason TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE ride_requests (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    passenger_id        UUID NOT NULL REFERENCES users(id),
    origin_address      TEXT NOT NULL,
    origin_location     GEOGRAPHY(POINT, 4326) NOT NULL,
    destination_address TEXT NOT NULL,
    destination_location GEOGRAPHY(POINT, 4326) NOT NULL,
    departure_date      DATE NOT NULL,
    seats_required      SMALLINT NOT NULL DEFAULT 1,
    notes               TEXT,
    is_active           BOOLEAN NOT NULL DEFAULT true,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
-- PAYMENTS & WALLET
-- =============================================================================

CREATE TABLE wallet_transactions (
    id              BIGSERIAL PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES users(id),
    booking_id      UUID REFERENCES bookings(id),
    amount          NUMERIC(15,2) NOT NULL,  -- positive = credit, negative = debit
    balance_after   NUMERIC(15,2) NOT NULL,
    description     TEXT NOT NULL,
    reference       TEXT UNIQUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE driver_payouts (
    id                  BIGSERIAL PRIMARY KEY,
    driver_id           UUID NOT NULL REFERENCES users(id),
    amount              NUMERIC(15,2) NOT NULL,
    method              payout_method NOT NULL,
    status              payout_status NOT NULL DEFAULT 'pending',
    gateway_reference   TEXT UNIQUE,
    bank_account_number TEXT,
    bank_name           TEXT,
    account_name        TEXT,
    failure_reason      TEXT,
    requested_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    processed_at        TIMESTAMPTZ,
    completed_at        TIMESTAMPTZ
);

-- =============================================================================
-- COUPONS & PROMOTIONS
-- =============================================================================

CREATE TABLE coupons (
    id              BIGSERIAL PRIMARY KEY,
    image_url       TEXT,
    title           TEXT NOT NULL,
    code            TEXT NOT NULL UNIQUE,
    subtitle        TEXT,
    description     TEXT,
    expires_at      TIMESTAMPTZ NOT NULL,
    min_amount      NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    discount_value  NUMERIC(15,2) NOT NULL,
    is_percentage   BOOLEAN NOT NULL DEFAULT false,
    max_uses        INT,
    uses_count      INT NOT NULL DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE coupon_redemptions (
    id          BIGSERIAL PRIMARY KEY,
    coupon_id   BIGINT NOT NULL REFERENCES coupons(id),
    user_id     UUID NOT NULL REFERENCES users(id),
    booking_id  UUID REFERENCES bookings(id),
    redeemed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (coupon_id, user_id)
);

-- =============================================================================
-- RATINGS & REVIEWS
-- =============================================================================

CREATE TABLE driver_ratings (
    id              BIGSERIAL PRIMARY KEY,
    booking_id      UUID NOT NULL UNIQUE REFERENCES bookings(id),
    driver_id       UUID NOT NULL REFERENCES users(id),
    passenger_id    UUID NOT NULL REFERENCES users(id),
    rating          SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review          TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
-- SUPPORT
-- =============================================================================

CREATE TABLE support_tickets (
    id              BIGSERIAL PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES users(id),
    booking_id      UUID REFERENCES bookings(id),
    subject         TEXT NOT NULL,
    description     TEXT NOT NULL,
    status          ticket_status NOT NULL DEFAULT 'open',
    priority        ticket_priority NOT NULL DEFAULT 'medium',
    assigned_to     BIGINT REFERENCES platform_admins(id),
    resolved_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE support_messages (
    id          BIGSERIAL PRIMARY KEY,
    ticket_id   BIGINT NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
    sender_user_id  UUID REFERENCES users(id),
    sender_admin_id BIGINT REFERENCES platform_admins(id),
    message     TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT message_has_one_sender CHECK (
        (sender_user_id IS NULL) <> (sender_admin_id IS NULL)
    )
);

-- =============================================================================
-- NOTIFICATIONS
-- =============================================================================

CREATE TABLE notifications (
    id              BIGSERIAL PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type            notification_type NOT NULL,
    title           TEXT NOT NULL,
    body            TEXT NOT NULL,
    data            JSONB,
    is_read         BOOLEAN NOT NULL DEFAULT false,
    sent_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    read_at         TIMESTAMPTZ
);

CREATE INDEX idx_notifications_user_unread ON notifications (user_id, is_read) WHERE is_read = false;

-- =============================================================================
-- CONTENT MANAGEMENT
-- =============================================================================

CREATE TABLE faqs (
    id          BIGSERIAL PRIMARY KEY,
    question    TEXT NOT NULL,
    answer      TEXT NOT NULL,
    sort_order  INT NOT NULL DEFAULT 0,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE content_pages (
    id          BIGSERIAL PRIMARY KEY,
    slug        TEXT NOT NULL UNIQUE,  -- 'terms', 'privacy', 'about'
    title       TEXT NOT NULL,
    content     TEXT NOT NULL,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
-- =============================================================================
-- CORPORATE LAYER
-- =============================================================================
-- =============================================================================

-- =============================================================================
-- COMPANIES
-- =============================================================================

CREATE TABLE companies (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                TEXT NOT NULL,
    registration_number TEXT UNIQUE,        -- CAC number (Nigeria)
    tax_id              TEXT,               -- TIN
    industry            TEXT,
    logo_url            TEXT,
    address             TEXT,
    city                TEXT,
    state               TEXT NOT NULL DEFAULT 'Lagos',
    contact_name        TEXT NOT NULL,
    contact_email       TEXT NOT NULL UNIQUE,
    contact_phone       TEXT NOT NULL,
    status              company_status NOT NULL DEFAULT 'pending_approval',
    -- Billing
    monthly_subscription NUMERIC(15,2) NOT NULL DEFAULT 50000.00,  -- in NGN
    subscription_active  BOOLEAN NOT NULL DEFAULT false,
    subscription_expires_at TIMESTAMPTZ,
    -- Platform commission override (NULL = use platform default)
    commission_override NUMERIC(5,2),
    -- Onboarded by
    onboarded_by        BIGINT REFERENCES platform_admins(id),
    -- Notes
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE departments (
    id          BIGSERIAL PRIMARY KEY,
    company_id  UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    name        TEXT NOT NULL,
    code        TEXT,               -- Internal dept code e.g. 'FIN', 'OPS'
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (company_id, name)
);

CREATE TABLE cost_centres (
    id              BIGSERIAL PRIMARY KEY,
    company_id      UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    department_id   BIGINT REFERENCES departments(id),
    name            TEXT NOT NULL,
    code            TEXT NOT NULL,
    description     TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (company_id, code)
);

CREATE TABLE company_employees (
    id              BIGSERIAL PRIMARY KEY,
    company_id      UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    department_id   BIGINT REFERENCES departments(id),
    cost_centre_id  BIGINT REFERENCES cost_centres(id),
    role            employee_role NOT NULL DEFAULT 'employee',
    employee_number TEXT,
    job_title       TEXT,
    -- Per-employee spend limit (NULL = use department/company limit)
    monthly_spend_limit NUMERIC(15,2),
    is_active       BOOLEAN NOT NULL DEFAULT true,
    invited_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    joined_at       TIMESTAMPTZ,
    deactivated_at  TIMESTAMPTZ,
    UNIQUE (company_id, user_id)
);

-- =============================================================================
-- BUDGETS
-- =============================================================================

CREATE TABLE budgets (
    id              BIGSERIAL PRIMARY KEY,
    company_id      UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    department_id   BIGINT REFERENCES departments(id),       -- NULL = company-wide budget
    cost_centre_id  BIGINT REFERENCES cost_centres(id),
    period_type     budget_period_type NOT NULL DEFAULT 'monthly',
    period_start    DATE NOT NULL,
    period_end      DATE NOT NULL,
    allocated_amount NUMERIC(15,2) NOT NULL,                 -- in NGN
    alert_threshold  NUMERIC(5,2) NOT NULL DEFAULT 80.00,   -- alert at 80% spend
    is_active        BOOLEAN NOT NULL DEFAULT true,
    created_by       UUID NOT NULL REFERENCES users(id),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT budget_period_valid CHECK (period_end > period_start)
);

CREATE TABLE budget_transactions (
    id              BIGSERIAL PRIMARY KEY,
    budget_id       BIGINT NOT NULL REFERENCES budgets(id),
    booking_id      UUID REFERENCES bookings(id),
    employee_id     UUID REFERENCES users(id),
    amount          NUMERIC(15,2) NOT NULL,  -- always positive (spend)
    description     TEXT NOT NULL,
    transacted_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- View: current spend per budget
CREATE VIEW budget_spend AS
SELECT
    b.id AS budget_id,
    b.company_id,
    b.department_id,
    b.allocated_amount,
    COALESCE(SUM(bt.amount), 0) AS spent_amount,
    b.allocated_amount - COALESCE(SUM(bt.amount), 0) AS remaining_amount,
    ROUND(COALESCE(SUM(bt.amount), 0) / NULLIF(b.allocated_amount, 0) * 100, 2) AS spend_percentage
FROM budgets b
LEFT JOIN budget_transactions bt ON bt.budget_id = b.id
WHERE b.is_active = true
GROUP BY b.id, b.company_id, b.department_id, b.allocated_amount;

-- =============================================================================
-- APPROVAL WORKFLOWS
-- =============================================================================

CREATE TABLE approval_workflows (
    id                  BIGSERIAL PRIMARY KEY,
    company_id          UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    department_id       BIGINT REFERENCES departments(id),   -- NULL = company-wide default
    name                TEXT NOT NULL,
    -- Trigger conditions
    requires_approval   BOOLEAN NOT NULL DEFAULT true,
    auto_approve_below  NUMERIC(15,2),                       -- NGN: auto-approve if fare < this
    -- Who approves
    approver_role       employee_role NOT NULL DEFAULT 'manager',
    specific_approver_id UUID REFERENCES users(id),          -- if specific person, not just role
    -- Escalation
    escalation_hours    INT NOT NULL DEFAULT 2,              -- escalate if no response in N hours
    escalation_approver_id UUID REFERENCES users(id),
    is_active           BOOLEAN NOT NULL DEFAULT true,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE approval_requests (
    id                  BIGSERIAL PRIMARY KEY,
    workflow_id         BIGINT NOT NULL REFERENCES approval_workflows(id),
    booking_id          UUID NOT NULL REFERENCES bookings(id),
    requester_id        UUID NOT NULL REFERENCES users(id),
    approver_id         UUID REFERENCES users(id),
    -- Ride details snapshot (denormalised for approver display)
    origin_address      TEXT NOT NULL,
    destination_address TEXT NOT NULL,
    estimated_fare      NUMERIC(15,2) NOT NULL,
    scheduled_at        TIMESTAMPTZ NOT NULL,
    -- Decision
    status              approval_action NOT NULL DEFAULT 'pending',
    decision_note       TEXT,
    decided_at          TIMESTAMPTZ,
    -- Escalation
    escalated_at        TIMESTAMPTZ,
    escalated_to        UUID REFERENCES users(id),
    -- Expiry
    expires_at          TIMESTAMPTZ NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Add FK back to bookings now that approval_requests exists
ALTER TABLE bookings ADD CONSTRAINT fk_bookings_approval
    FOREIGN KEY (approval_request_id) REFERENCES approval_requests(id);

-- =============================================================================
-- RIDE POLICIES
-- =============================================================================

CREATE TABLE ride_policies (
    id                      BIGSERIAL PRIMARY KEY,
    company_id              UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    department_id           BIGINT REFERENCES departments(id),   -- NULL = company-wide
    name                    TEXT NOT NULL,
    -- Time restrictions
    allowed_days            SMALLINT[] DEFAULT '{1,2,3,4,5}',   -- 1=Mon..7=Sun (ISO)
    allowed_time_from       TIME,                                -- e.g. 06:00
    allowed_time_to         TIME,                                -- e.g. 22:00
    -- Vehicle restrictions
    allowed_vehicle_types   BIGINT[],                            -- NULL = all types allowed
    max_vehicle_type_id     BIGINT REFERENCES vehicle_types(id), -- max tier allowed
    -- Spend restrictions
    max_fare_per_trip       NUMERIC(15,2),                       -- NGN cap per single ride
    max_monthly_spend       NUMERIC(15,2),                       -- NGN cap per employee per month
    -- Booking restrictions
    advance_booking_minutes INT,                                 -- min minutes before ride
    -- Policy config as JSONB for extensibility
    extra_rules             JSONB DEFAULT '{}',
    is_active               BOOLEAN NOT NULL DEFAULT true,
    created_by              UUID NOT NULL REFERENCES users(id),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
-- INVOICES & RECEIPTS
-- =============================================================================

CREATE TABLE ride_receipts (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id          UUID NOT NULL UNIQUE REFERENCES bookings(id),
    company_id          UUID REFERENCES companies(id),
    employee_id         UUID NOT NULL REFERENCES users(id),
    department_id       BIGINT REFERENCES departments(id),
    cost_centre_id      BIGINT REFERENCES cost_centres(id),
    -- Amounts in NGN
    base_fare           NUMERIC(15,2) NOT NULL,
    platform_fee        NUMERIC(15,2) NOT NULL,
    discount            NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    total_charged       NUMERIC(15,2) NOT NULL,
    -- Trip details
    origin_address      TEXT NOT NULL,
    destination_address TEXT NOT NULL,
    distance_km         NUMERIC(8,2),
    duration_minutes    INT,
    ride_started_at     TIMESTAMPTZ,
    ride_completed_at   TIMESTAMPTZ,
    -- Payment
    payment_reference   TEXT,
    payment_gateway     payment_gateway,
    -- Receipt number for accounting
    receipt_number      TEXT NOT NULL UNIQUE,
    pdf_url             TEXT,
    issued_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE SEQUENCE receipt_number_seq START 100001;

CREATE TABLE invoices (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id          UUID NOT NULL REFERENCES companies(id),
    invoice_number      TEXT NOT NULL UNIQUE,
    period_start        DATE NOT NULL,
    period_end          DATE NOT NULL,
    -- Amounts in NGN
    subtotal            NUMERIC(15,2) NOT NULL,
    vat_rate            NUMERIC(5,2) NOT NULL DEFAULT 7.50,  -- Nigeria VAT 7.5%
    vat_amount          NUMERIC(15,2) NOT NULL,
    total_amount        NUMERIC(15,2) NOT NULL,
    -- Status
    is_paid             BOOLEAN NOT NULL DEFAULT false,
    paid_at             TIMESTAMPTZ,
    payment_reference   TEXT,
    due_date            DATE NOT NULL,
    pdf_url             TEXT,
    notes               TEXT,
    generated_by        BIGINT REFERENCES platform_admins(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE SEQUENCE invoice_number_seq START 10001;

CREATE TABLE invoice_line_items (
    id              BIGSERIAL PRIMARY KEY,
    invoice_id      UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    receipt_id      UUID REFERENCES ride_receipts(id),
    description     TEXT NOT NULL,
    department_name TEXT,
    cost_centre     TEXT,
    employee_name   TEXT,
    quantity        INT NOT NULL DEFAULT 1,
    unit_price      NUMERIC(15,2) NOT NULL,
    total_price     NUMERIC(15,2) NOT NULL,
    ride_date       DATE
);

-- =============================================================================
-- CORPORATE FK BACKFILLS
-- These FKs reference corporate tables, added after those tables exist
-- =============================================================================

ALTER TABLE bookings
    ADD CONSTRAINT fk_bookings_company
        FOREIGN KEY (company_id) REFERENCES companies(id),
    ADD CONSTRAINT fk_bookings_department
        FOREIGN KEY (department_id) REFERENCES departments(id),
    ADD CONSTRAINT fk_bookings_cost_centre
        FOREIGN KEY (cost_centre_id) REFERENCES cost_centres(id);

-- =============================================================================
-- ROW-LEVEL SECURITY
-- All corporate data is isolated per company_id using RLS.
-- App sets: SET LOCAL app.company_id = '<uuid>' per request.
-- =============================================================================

ALTER TABLE companies             ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments           ENABLE ROW LEVEL SECURITY;
ALTER TABLE cost_centres          ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_employees     ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets                ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_transactions    ENABLE ROW LEVEL SECURITY;
ALTER TABLE approval_workflows     ENABLE ROW LEVEL SECURITY;
ALTER TABLE approval_requests      ENABLE ROW LEVEL SECURITY;
ALTER TABLE ride_policies          ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices               ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_line_items     ENABLE ROW LEVEL SECURITY;

-- Company members can only see their own company
CREATE POLICY company_isolation ON companies
    USING (id::TEXT = current_setting('app.company_id', true));

CREATE POLICY dept_isolation ON departments
    USING (company_id::TEXT = current_setting('app.company_id', true));

CREATE POLICY cost_centre_isolation ON cost_centres
    USING (company_id::TEXT = current_setting('app.company_id', true));

CREATE POLICY employee_isolation ON company_employees
    USING (company_id::TEXT = current_setting('app.company_id', true));

CREATE POLICY budget_isolation ON budgets
    USING (company_id::TEXT = current_setting('app.company_id', true));

CREATE POLICY budget_tx_isolation ON budget_transactions
    USING (budget_id IN (
        SELECT id FROM budgets
        WHERE company_id::TEXT = current_setting('app.company_id', true)
    ));

CREATE POLICY workflow_isolation ON approval_workflows
    USING (company_id::TEXT = current_setting('app.company_id', true));

CREATE POLICY approval_isolation ON approval_requests
    USING (workflow_id IN (
        SELECT id FROM approval_workflows
        WHERE company_id::TEXT = current_setting('app.company_id', true)
    ));

CREATE POLICY policy_isolation ON ride_policies
    USING (company_id::TEXT = current_setting('app.company_id', true));

CREATE POLICY invoice_isolation ON invoices
    USING (company_id::TEXT = current_setting('app.company_id', true));

CREATE POLICY invoice_item_isolation ON invoice_line_items
    USING (invoice_id IN (
        SELECT id FROM invoices
        WHERE company_id::TEXT = current_setting('app.company_id', true)
    ));

-- Super admin bypass role (platform admins bypass RLS)
CREATE ROLE ccride_app;
CREATE ROLE ccride_admin BYPASSRLS;

-- =============================================================================
-- INDEXES
-- =============================================================================

-- Users
CREATE INDEX idx_users_mobile ON users (mobile, country_code);
CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_users_referral_code ON users (referral_code);

-- Drivers
CREATE INDEX idx_driver_location ON driver_profiles USING GIST (current_location);
CREATE INDEX idx_driver_status ON driver_profiles (status);

-- Rides
CREATE INDEX idx_rides_driver ON rides (driver_id);
CREATE INDEX idx_rides_status ON rides (status);
CREATE INDEX idx_rides_scheduled_at ON rides (scheduled_at);
CREATE INDEX idx_rides_origin ON rides USING GIST (origin_location);
CREATE INDEX idx_rides_destination ON rides USING GIST (destination_location);

-- Bookings
CREATE INDEX idx_bookings_passenger ON bookings (passenger_id);
CREATE INDEX idx_bookings_ride ON bookings (ride_id);
CREATE INDEX idx_bookings_company ON bookings (company_id);
CREATE INDEX idx_bookings_department ON bookings (department_id);
CREATE INDEX idx_bookings_status ON bookings (status);
CREATE INDEX idx_bookings_created ON bookings (created_at DESC);

-- Ride requests
CREATE INDEX idx_ride_requests_origin ON ride_requests USING GIST (origin_location);
CREATE INDEX idx_ride_requests_destination ON ride_requests USING GIST (destination_location);
CREATE INDEX idx_ride_requests_active ON ride_requests (is_active, departure_date);

-- Corporate
CREATE INDEX idx_company_employees_company ON company_employees (company_id);
CREATE INDEX idx_company_employees_user ON company_employees (user_id);
CREATE INDEX idx_budgets_company_period ON budgets (company_id, period_start, period_end);
CREATE INDEX idx_approval_requests_approver ON approval_requests (approver_id, status);
CREATE INDEX idx_approval_requests_booking ON approval_requests (booking_id);
CREATE INDEX idx_receipts_company ON ride_receipts (company_id);
CREATE INDEX idx_invoices_company ON invoices (company_id, period_start);

-- Notifications
CREATE INDEX idx_notifications_user ON notifications (user_id, sent_at DESC);

-- Wallet
CREATE INDEX idx_wallet_user ON wallet_transactions (user_id, created_at DESC);

-- Rate limiting
CREATE INDEX idx_rate_limit_blocked ON api_rate_limits (identifier, blocked_until)
    WHERE blocked_until IS NOT NULL;

-- =============================================================================
-- FUNCTIONS & TRIGGERS
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_driver_profiles_updated_at
    BEFORE UPDATE ON driver_profiles
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_vehicles_updated_at
    BEFORE UPDATE ON vehicles
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_rides_updated_at
    BEFORE UPDATE ON rides
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_bookings_updated_at
    BEFORE UPDATE ON bookings
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_companies_updated_at
    BEFORE UPDATE ON companies
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_budgets_updated_at
    BEFORE UPDATE ON budgets
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_approval_workflows_updated_at
    BEFORE UPDATE ON approval_workflows
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_ride_policies_updated_at
    BEFORE UPDATE ON ride_policies
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Wallet balance guard: prevent negative balance
CREATE OR REPLACE FUNCTION check_wallet_balance()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.wallet_balance < 0 THEN
        RAISE EXCEPTION 'Insufficient wallet balance for user %', NEW.id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_wallet_balance_guard
    BEFORE UPDATE OF wallet_balance ON users
    FOR EACH ROW EXECUTE FUNCTION check_wallet_balance();

-- Budget overspend alert function
CREATE OR REPLACE FUNCTION check_budget_alert()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_budget budgets%ROWTYPE;
    v_total_spent NUMERIC(15,2);
    v_pct NUMERIC(5,2);
BEGIN
    SELECT * INTO v_budget FROM budgets WHERE id = NEW.budget_id;
    SELECT COALESCE(SUM(amount), 0) INTO v_total_spent
    FROM budget_transactions WHERE budget_id = NEW.budget_id;

    v_pct := (v_total_spent / NULLIF(v_budget.allocated_amount, 0)) * 100;

    IF v_pct >= v_budget.alert_threshold THEN
        INSERT INTO notifications (user_id, type, title, body, data)
        SELECT
            ce.user_id,
            'budget_alert',
            'Budget Alert',
            format('Department budget is at %s%% of allocation', ROUND(v_pct, 0)),
            jsonb_build_object(
                'budget_id', NEW.budget_id,
                'spend_percentage', v_pct,
                'company_id', v_budget.company_id
            )
        FROM company_employees ce
        WHERE ce.company_id = v_budget.company_id
          AND ce.role IN ('company_admin', 'company_finance')
          AND ce.is_active = true;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_budget_alert
    AFTER INSERT ON budget_transactions
    FOR EACH ROW EXECUTE FUNCTION check_budget_alert();

-- Auto-generate receipt number
CREATE OR REPLACE FUNCTION generate_receipt_number()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.receipt_number := 'RCP-' || to_char(now(), 'YYYYMM') || '-' || lpad(nextval('receipt_number_seq')::TEXT, 6, '0');
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_receipt_number
    BEFORE INSERT ON ride_receipts
    FOR EACH ROW WHEN (NEW.receipt_number IS NULL OR NEW.receipt_number = '')
    EXECUTE FUNCTION generate_receipt_number();

-- Auto-generate invoice number
CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.invoice_number := 'INV-' || to_char(now(), 'YYYY') || '-' || lpad(nextval('invoice_number_seq')::TEXT, 5, '0');
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_invoice_number
    BEFORE INSERT ON invoices
    FOR EACH ROW WHEN (NEW.invoice_number IS NULL OR NEW.invoice_number = '')
    EXECUTE FUNCTION generate_invoice_number();

-- =============================================================================
-- SEED DATA
-- =============================================================================

-- Vehicle types (Nigerian market)
INSERT INTO vehicle_types (title) VALUES
    ('Economy'),
    ('Standard'),
    ('Premium'),
    ('SUV'),
    ('Minivan')
ON CONFLICT (title) DO NOTHING;

-- Vehicle colors (trimmed to common Nigerian market colors)
INSERT INTO vehicle_colors (title) VALUES
    ('Black'), ('White'), ('Silver'), ('Gray'), ('Blue'),
    ('Red'), ('Gold'), ('Green'), ('Brown'), ('Champagne'),
    ('Pearl White'), ('Navy Blue'), ('Burgundy'), ('Dark Green')
ON CONFLICT (title) DO NOTHING;

-- Popular vehicle models in Nigeria
INSERT INTO vehicle_models (title) VALUES
    ('Toyota Camry'), ('Toyota Corolla'), ('Toyota Highlander'), ('Toyota RAV4'), ('Toyota Sienna'), ('Toyota Avalon'),
    ('Honda Accord'), ('Honda Civic'), ('Honda CR-V'), ('Honda Pilot'),
    ('Ford Explorer'), ('Ford Edge'),
    ('Lexus ES'), ('Lexus RX'), ('Lexus GX'), ('Lexus LX'),
    ('Mercedes-Benz C-Class'), ('Mercedes-Benz E-Class'), ('Mercedes-Benz GLE'),
    ('BMW 3 Series'), ('BMW 5 Series'), ('BMW X5'),
    ('Hyundai Sonata'), ('Hyundai Elantra'), ('Hyundai Santa Fe'),
    ('Kia Sportage'), ('Kia Sorento'),
    ('Nissan Altima'), ('Nissan Pathfinder'),
    ('Volkswagen Passat'),
    ('Innoson IVM G80'), ('Innoson IVM Fox')
ON CONFLICT (title) DO NOTHING;

-- Default FAQs (CC Ride branded)
INSERT INTO faqs (question, answer, sort_order) VALUES
    ('What is CC Ride?', 'CC Ride is a corporate ride-hailing platform built for Nigerian businesses. It allows companies to manage employee transport with full control over bookings, budgets, and spending.', 1),
    ('How does company billing work?', 'All rides booked through a corporate account are charged directly to the company. Employees do not pay out of pocket — their rides are reconciled to departmental budgets automatically.', 2),
    ('Which payment methods are supported?', 'CC Ride supports Paystack and Flutterwave, covering card payments, bank transfers, and USSD — all in Nigerian naira.', 3),
    ('How do approval workflows work?', 'Your company admin can configure ride approvals. Trips above a certain fare, or booked outside permitted hours, can be routed to a line manager for approval before a driver is dispatched.', 4),
    ('Can I get a receipt for my ride?', 'Yes. Every completed ride generates a receipt formatted for Nigerian corporate accounting, with cost centre and department tagging for expense reconciliation.', 5),
    ('How do I contact support?', 'Use the in-app support feature to raise a ticket. Our team responds within 2 business hours during weekday operating hours.', 6);

-- Default content pages
INSERT INTO content_pages (slug, title, content) VALUES
    ('terms', 'Terms of Service', 'Terms of Service content here.'),
    ('privacy', 'Privacy Policy', 'Privacy Policy content here.'),
    ('about', 'About CC Ride', 'CC Ride is a corporate mobility platform for Nigerian businesses.');

-- Platform settings baseline
UPDATE platform_settings SET
    app_name = 'CC Ride',
    timezone = 'Africa/Lagos',
    currency = 'NGN',
    currency_symbol = '₦',
    platform_commission = 15.00
WHERE id = 1;
