-- Pricing engine (super-admin configurable rate factors, layered by scope)
-- and corporate savings reporting (shadow-priced, kept separate from the
-- live fare calculation so a savings figure never derives from CC Ride's
-- own formula). Purely additive — no existing table touched.

-- 1. pricing_scope enum + pricing_rate_cards: layered fare factors.
--    Resolution order at ride-time is time_window > company > vehicle_type
--    > global. Rows are never edited in place — a factor change closes the
--    current row (effective_to) and opens a new one.
CREATE TYPE "pricing_scope" AS ENUM ('global', 'vehicle_type', 'company', 'time_window');

CREATE TABLE "pricing_rate_cards" (
  "id" BIGSERIAL PRIMARY KEY,
  "scope" "pricing_scope" NOT NULL DEFAULT 'global',
  "vehicle_type_id" BIGINT,
  "company_id" UUID,
  "days_of_week" INTEGER[] NOT NULL DEFAULT '{}',
  "time_from" TEXT,
  "time_to" TEXT,
  "base_fare" DECIMAL(15,2),
  "fare_per_km" DECIMAL(15,2),
  "fare_per_min" DECIMAL(15,2),
  "min_fare_floor" DECIMAL(15,2),
  "driver_earnings_floor" DECIMAL(15,2),
  "commission_rate" DECIMAL(5,2),
  "surge_multiplier" DECIMAL(5,2),
  "effective_from" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "effective_to" TIMESTAMP(3),
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "created_by" BIGINT NOT NULL,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "pricing_rate_cards_vehicle_type_id_fkey"
    FOREIGN KEY ("vehicle_type_id") REFERENCES "vehicle_types"("id"),
  CONSTRAINT "pricing_rate_cards_company_id_fkey"
    FOREIGN KEY ("company_id") REFERENCES "companies"("id"),
  CONSTRAINT "pricing_rate_cards_created_by_fkey"
    FOREIGN KEY ("created_by") REFERENCES "admin_users"("id")
);

CREATE INDEX "pricing_rate_cards_scope_is_active_idx" ON "pricing_rate_cards" ("scope", "is_active");
CREATE INDEX "pricing_rate_cards_vehicle_type_id_is_active_idx" ON "pricing_rate_cards" ("vehicle_type_id", "is_active");
CREATE INDEX "pricing_rate_cards_company_id_is_active_idx" ON "pricing_rate_cards" ("company_id", "is_active");

-- 2. pricing_factor_change_log: audit trail for every factor edit a
--    super-admin makes, so a disputed fare can be traced to who changed
--    what, when, and why.
CREATE TABLE "pricing_factor_change_log" (
  "id" BIGSERIAL PRIMARY KEY,
  "rate_card_id" BIGINT NOT NULL,
  "field_changed" TEXT NOT NULL,
  "old_value" TEXT,
  "new_value" TEXT,
  "reason" TEXT,
  "changed_by" BIGINT NOT NULL,
  "changed_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "pricing_factor_change_log_rate_card_id_fkey"
    FOREIGN KEY ("rate_card_id") REFERENCES "pricing_rate_cards"("id") ON DELETE CASCADE,
  CONSTRAINT "pricing_factor_change_log_changed_by_fkey"
    FOREIGN KEY ("changed_by") REFERENCES "admin_users"("id")
);

CREATE INDEX "pricing_factor_change_log_rate_card_id_changed_at_idx"
  ON "pricing_factor_change_log" ("rate_card_id", "changed_at" DESC);

-- 3. market_benchmark_rates: admin-entered samples of what competitors
--    (Uber/Bolt/inDrive) charge on comparable trips. Deliberately separate
--    from pricing_rate_cards so a savings report is never computed against
--    CC Ride's own fare formula.
CREATE TABLE "market_benchmark_rates" (
  "id" BIGSERIAL PRIMARY KEY,
  "vehicle_type_id" BIGINT,
  "distance_band_km" TEXT NOT NULL,
  "competitor" TEXT,
  "sampled_fare" DECIMAL(15,2) NOT NULL,
  "sampled_at" TIMESTAMP(3) NOT NULL,
  "source" TEXT NOT NULL DEFAULT 'manual',
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "entered_by" BIGINT NOT NULL,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "market_benchmark_rates_vehicle_type_id_fkey"
    FOREIGN KEY ("vehicle_type_id") REFERENCES "vehicle_types"("id"),
  CONSTRAINT "market_benchmark_rates_entered_by_fkey"
    FOREIGN KEY ("entered_by") REFERENCES "admin_users"("id")
);

CREATE INDEX "market_benchmark_rates_distance_band_km_is_active_idx"
  ON "market_benchmark_rates" ("distance_band_km", "is_active");

-- 4. ride_savings_records: one row per corporate booking, written at ride
--    completion. Purely for reporting — never affects what's actually
--    charged. computed_market_benchmark is what a savings figure is based
--    on, never computed_fair_fare.
CREATE TABLE "ride_savings_records" (
  "id" BIGSERIAL PRIMARY KEY,
  "booking_id" UUID NOT NULL,
  "company_id" UUID NOT NULL,
  "employee_id" BIGINT,
  "computed_fair_fare" DECIMAL(15,2) NOT NULL,
  "computed_market_benchmark" DECIMAL(15,2),
  "actual_org_cost" DECIMAL(15,2) NOT NULL,
  "driver_points_awarded" INTEGER NOT NULL DEFAULT 0,
  "distance_km" DECIMAL(8,2),
  "duration_minutes" INTEGER,
  "ride_date" DATE NOT NULL,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "ride_savings_records_booking_id_key" UNIQUE ("booking_id"),
  CONSTRAINT "ride_savings_records_booking_id_fkey"
    FOREIGN KEY ("booking_id") REFERENCES "bookings"("id") ON DELETE CASCADE,
  CONSTRAINT "ride_savings_records_company_id_fkey"
    FOREIGN KEY ("company_id") REFERENCES "companies"("id"),
  CONSTRAINT "ride_savings_records_employee_id_fkey"
    FOREIGN KEY ("employee_id") REFERENCES "company_employees"("id")
);

CREATE INDEX "ride_savings_records_company_id_ride_date_idx"
  ON "ride_savings_records" ("company_id", "ride_date");

-- 5. savings_report_status enum + corporate_savings_reports: generated
--    monthly per company. total_savings is always
--    total_market_benchmark_cost - total_org_spend, never derived from
--    CC Ride's internal fare formula.
CREATE TYPE "savings_report_status" AS ENUM ('draft', 'sent', 'archived');

CREATE TABLE "corporate_savings_reports" (
  "id" BIGSERIAL PRIMARY KEY,
  "company_id" UUID NOT NULL,
  "period_start" DATE NOT NULL,
  "period_end" DATE NOT NULL,
  "total_rides" INTEGER NOT NULL,
  "total_market_benchmark_cost" DECIMAL(15,2) NOT NULL,
  "total_org_spend" DECIMAL(15,2) NOT NULL,
  "total_savings" DECIMAL(15,2) NOT NULL,
  "savings_percentage" DECIMAL(5,2) NOT NULL,
  "status" "savings_report_status" NOT NULL DEFAULT 'draft',
  "pdf_url" TEXT,
  "generated_by" BIGINT NOT NULL,
  "generated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "corporate_savings_reports_company_id_fkey"
    FOREIGN KEY ("company_id") REFERENCES "companies"("id"),
  CONSTRAINT "corporate_savings_reports_generated_by_fkey"
    FOREIGN KEY ("generated_by") REFERENCES "admin_users"("id")
);

CREATE INDEX "corporate_savings_reports_company_id_period_start_idx"
  ON "corporate_savings_reports" ("company_id", "period_start");
