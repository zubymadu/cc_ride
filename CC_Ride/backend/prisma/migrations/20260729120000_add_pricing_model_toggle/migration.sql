-- Super-admin toggle between driver-set fares (existing default behavior)
-- and a platform-computed estimate for non-shared/ad-hoc rides, plus the
-- platform-wide default formula values used when no PricingRateCard
-- override applies. Purely additive.

CREATE TYPE "pricing_model" AS ENUM ('driver_set', 'platform_computed');

ALTER TABLE "platform_settings"
  ADD COLUMN "pricing_model" "pricing_model" NOT NULL DEFAULT 'driver_set',
  ADD COLUMN "default_base_fare" DECIMAL(15,2) NOT NULL DEFAULT 500.00,
  ADD COLUMN "default_fare_per_km" DECIMAL(15,2) NOT NULL DEFAULT 150.00,
  ADD COLUMN "default_fare_per_min" DECIMAL(15,2) NOT NULL DEFAULT 10.00;
