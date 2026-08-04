-- Government identity anchor for account de-duplication — replaces mobile
-- number as the intended primary matching key for driver/corporate
-- registration, since a person can legitimately hold more than one mobile
-- number (personal + employer-issued) but only ever one NIN or passport.
-- Optional for an ordinary passenger; required (one or the other) for a
-- driver or corporate employee, enforced at the application layer.

ALTER TABLE "users"
  ADD COLUMN "nin" TEXT,
  ADD COLUMN "passport_number" TEXT;

CREATE UNIQUE INDEX "users_nin_key" ON "users"("nin");
CREATE UNIQUE INDEX "users_passport_number_key" ON "users"("passport_number");
