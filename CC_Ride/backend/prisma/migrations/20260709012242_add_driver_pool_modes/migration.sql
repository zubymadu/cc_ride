-- Multi-mode drivers: Pool / Own-car / Independent
-- Purely additive: widens vehicles.driver_id to nullable, adds new nullable
-- columns with defaults, and two new tables. No existing data is dropped
-- or rewritten; every current vehicles row already has a non-null
-- driver_id, so this cannot violate any existing row.

-- 1. company_employees: personal vehicle approval gate
ALTER TABLE "company_employees"
  ADD COLUMN "personal_vehicle_approved" BOOLEAN NOT NULL DEFAULT false;

-- 2. vehicles: allow org-owned pool vehicles (no single driver owner)
ALTER TABLE "vehicles"
  ALTER COLUMN "driver_id" DROP NOT NULL;

ALTER TABLE "vehicles"
  ADD COLUMN "company_id" UUID;

ALTER TABLE "vehicles"
  ADD CONSTRAINT "vehicles_company_id_fkey"
  FOREIGN KEY ("company_id") REFERENCES "companies"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

-- 3. driver_profiles: points balance for pool drivers
ALTER TABLE "driver_profiles"
  ADD COLUMN "points_balance" INTEGER NOT NULL DEFAULT 0;

-- 4. platform_settings: flat points-per-trip rate
ALTER TABLE "platform_settings"
  ADD COLUMN "points_per_trip" INTEGER NOT NULL DEFAULT 10;

-- 5. driver_points_transactions: informational points ledger
CREATE TABLE "driver_points_transactions" (
  "id" BIGSERIAL PRIMARY KEY,
  "driver_id" UUID NOT NULL,
  "booking_id" UUID,
  "points" INTEGER NOT NULL,
  "balance_after" INTEGER NOT NULL,
  "description" TEXT NOT NULL,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "driver_points_transactions_driver_id_fkey"
    FOREIGN KEY ("driver_id") REFERENCES "users"("id"),
  CONSTRAINT "driver_points_transactions_booking_id_fkey"
    FOREIGN KEY ("booking_id") REFERENCES "bookings"("id")
);

CREATE INDEX "driver_points_transactions_driver_id_created_at_idx"
  ON "driver_points_transactions" ("driver_id", "created_at" DESC);
CREATE INDEX "driver_points_transactions_booking_id_idx"
  ON "driver_points_transactions" ("booking_id");

-- 6. driver_vehicle_access: pool car access grants (many-to-many)
CREATE TABLE "driver_vehicle_access" (
  "id" BIGSERIAL PRIMARY KEY,
  "vehicle_id" BIGINT NOT NULL,
  "driver_id" UUID NOT NULL,
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "granted_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "revoked_at" TIMESTAMP(3),
  CONSTRAINT "driver_vehicle_access_vehicle_id_fkey"
    FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id") ON DELETE CASCADE,
  CONSTRAINT "driver_vehicle_access_driver_id_fkey"
    FOREIGN KEY ("driver_id") REFERENCES "users"("id") ON DELETE CASCADE,
  CONSTRAINT "driver_vehicle_access_vehicle_id_driver_id_key"
    UNIQUE ("vehicle_id", "driver_id")
);

CREATE INDEX "driver_vehicle_access_driver_id_is_active_idx"
  ON "driver_vehicle_access" ("driver_id", "is_active");
