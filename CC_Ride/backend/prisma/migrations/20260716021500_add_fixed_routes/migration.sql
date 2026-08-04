-- Fixed routes for "Find Shared Route": route templates that lazily
-- generate ordinary rides at search time. Purely additive — new nullable
-- columns on rides/bookings, four new tables. No existing data touched.

-- 1. routes: the template (code, name, fixed origin/destination, optionally
--    scoped to a participating organisation)
CREATE TABLE "routes" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "code" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "company_id" UUID,
  "origin_name" TEXT NOT NULL,
  "origin_lat" DECIMAL(10,7) NOT NULL,
  "origin_lng" DECIMAL(10,7) NOT NULL,
  "destination_name" TEXT NOT NULL,
  "destination_lat" DECIMAL(10,7) NOT NULL,
  "destination_lng" DECIMAL(10,7) NOT NULL,
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "routes_code_key" UNIQUE ("code"),
  CONSTRAINT "routes_company_id_fkey"
    FOREIGN KEY ("company_id") REFERENCES "companies"("id")
);

CREATE INDEX "routes_company_id_idx" ON "routes" ("company_id");

-- 2. route_stops: the fixed, ordered list of boardable stops for a route
CREATE TABLE "route_stops" (
  "id" BIGSERIAL PRIMARY KEY,
  "route_id" UUID NOT NULL,
  "stop_order" SMALLINT NOT NULL,
  "name" TEXT NOT NULL,
  "lat" DECIMAL(10,7) NOT NULL,
  "lng" DECIMAL(10,7) NOT NULL,
  CONSTRAINT "route_stops_route_id_fkey"
    FOREIGN KEY ("route_id") REFERENCES "routes"("id") ON DELETE CASCADE
);

-- 3. route_schedules: recurring departure templates (time + days of week),
--    each optionally assigned a pool driver + pool vehicle
CREATE TABLE "route_schedules" (
  "id" BIGSERIAL PRIMARY KEY,
  "route_id" UUID NOT NULL,
  "departure_time" TEXT NOT NULL,
  "days_of_week" INTEGER[] NOT NULL,
  "driver_id" UUID,
  "vehicle_id" BIGINT,
  "seat_capacity" SMALLINT NOT NULL,
  "fare" DECIMAL(15,2) NOT NULL,
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  CONSTRAINT "route_schedules_route_id_fkey"
    FOREIGN KEY ("route_id") REFERENCES "routes"("id") ON DELETE CASCADE,
  CONSTRAINT "route_schedules_driver_id_fkey"
    FOREIGN KEY ("driver_id") REFERENCES "users"("id"),
  CONSTRAINT "route_schedules_vehicle_id_fkey"
    FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id")
);

CREATE INDEX "route_schedules_route_id_idx" ON "route_schedules" ("route_id");

-- 4. waitlist status enum + ride_waitlist: queued seat requests for a sold
--    out route-based ride, promoted in order as seats free up
CREATE TYPE "waitlist_status" AS ENUM ('waiting', 'promoted', 'expired');

CREATE TABLE "ride_waitlist" (
  "id" BIGSERIAL PRIMARY KEY,
  "ride_id" UUID NOT NULL,
  "user_id" UUID NOT NULL,
  "seats_requested" SMALLINT NOT NULL,
  "status" "waitlist_status" NOT NULL DEFAULT 'waiting',
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "promoted_at" TIMESTAMP(3),
  CONSTRAINT "ride_waitlist_ride_id_fkey"
    FOREIGN KEY ("ride_id") REFERENCES "rides"("id") ON DELETE CASCADE,
  CONSTRAINT "ride_waitlist_user_id_fkey"
    FOREIGN KEY ("user_id") REFERENCES "users"("id")
);

CREATE INDEX "ride_waitlist_ride_id_created_at_idx"
  ON "ride_waitlist" ("ride_id", "created_at");

-- 5. rides: tag which route (if any) generated this occurrence
ALTER TABLE "rides"
  ADD COLUMN "route_id" UUID;

ALTER TABLE "rides"
  ADD CONSTRAINT "rides_route_id_fkey"
  FOREIGN KEY ("route_id") REFERENCES "routes"("id");

CREATE INDEX "rides_route_id_scheduled_at_idx"
  ON "rides" ("route_id", "scheduled_at");

-- 6. bookings: which stop the passenger boards/alights at (route rides only)
ALTER TABLE "bookings"
  ADD COLUMN "pickup_stop_id" BIGINT,
  ADD COLUMN "dropoff_stop_id" BIGINT;

ALTER TABLE "bookings"
  ADD CONSTRAINT "bookings_pickup_stop_id_fkey"
  FOREIGN KEY ("pickup_stop_id") REFERENCES "route_stops"("id");

ALTER TABLE "bookings"
  ADD CONSTRAINT "bookings_dropoff_stop_id_fkey"
  FOREIGN KEY ("dropoff_stop_id") REFERENCES "route_stops"("id");
