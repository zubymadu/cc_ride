-- Real-time company-wallet ride payment. company_credits.amount already
-- supported negative (debit) values in its own column comment, but every
-- row was previously admin-initiated (credited_by required). This makes
-- room for system-generated ride-payment debits, traced back to the
-- booking instead of an admin.

ALTER TABLE "company_credits"
  ALTER COLUMN "credited_by" DROP NOT NULL,
  ADD COLUMN "booking_id" UUID;

ALTER TABLE "company_credits"
  ADD CONSTRAINT "company_credits_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "bookings"("id");
