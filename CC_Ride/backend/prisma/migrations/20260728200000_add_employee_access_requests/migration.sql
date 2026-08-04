-- Per-employee facility access windows (pool car + company wallet payment)
-- and the employee-initiated request/approval flow for granting them.
-- Purely additive — no existing table touched beyond new columns on
-- company_employees.

ALTER TABLE "company_employees"
  ADD COLUMN "pool_access_days_of_week" INTEGER[] NOT NULL DEFAULT '{}',
  ADD COLUMN "pool_access_time_from" TEXT,
  ADD COLUMN "pool_access_time_to" TEXT,
  ADD COLUMN "wallet_access_enabled" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN "wallet_access_days_of_week" INTEGER[] NOT NULL DEFAULT '{}',
  ADD COLUMN "wallet_access_time_from" TEXT,
  ADD COLUMN "wallet_access_time_to" TEXT;

CREATE TYPE "access_request_type" AS ENUM ('pool_car', 'wallet_payment');
CREATE TYPE "access_request_status" AS ENUM ('pending', 'approved', 'denied');

CREATE TABLE "employee_access_requests" (
  "id" BIGSERIAL PRIMARY KEY,
  "company_id" UUID NOT NULL,
  "employee_id" BIGINT NOT NULL,
  "request_type" "access_request_type" NOT NULL,
  "status" "access_request_status" NOT NULL DEFAULT 'pending',
  "note" TEXT,
  "requested_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "decided_at" TIMESTAMP(3),
  "decided_by_id" BIGINT,
  "decision_note" TEXT,
  CONSTRAINT "employee_access_requests_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE,
  CONSTRAINT "employee_access_requests_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "company_employees"("id") ON DELETE CASCADE,
  CONSTRAINT "employee_access_requests_decided_by_id_fkey" FOREIGN KEY ("decided_by_id") REFERENCES "admin_users"("id")
);

CREATE INDEX "employee_access_requests_company_id_status_idx" ON "employee_access_requests"("company_id", "status");
CREATE INDEX "employee_access_requests_employee_id_idx" ON "employee_access_requests"("employee_id");
