-- Pool-car access policy: a company's pool fleet only serves its own
-- employees by default. Sharing with another participating organisation is
-- opt-in on two levels (company-wide toggle + an explicit per-partner
-- agreement), and per-employee pool access plus daily/weekly/monthly usage
-- rations are configurable by the company's own admin.

CREATE TABLE "company_pool_policies" (
  "id" BIGSERIAL PRIMARY KEY,
  "company_id" UUID NOT NULL UNIQUE,
  "allow_external_sharing" BOOLEAN NOT NULL DEFAULT false,
  "daily_limit" INTEGER,
  "weekly_limit" INTEGER,
  "monthly_limit" INTEGER,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "company_pool_policies_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE
);

CREATE TABLE "pool_sharing_agreements" (
  "id" BIGSERIAL PRIMARY KEY,
  "company_id" UUID NOT NULL,
  "partner_company_id" UUID NOT NULL,
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "created_by_id" BIGINT NOT NULL,
  CONSTRAINT "pool_sharing_agreements_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE,
  CONSTRAINT "pool_sharing_agreements_partner_company_id_fkey" FOREIGN KEY ("partner_company_id") REFERENCES "companies"("id") ON DELETE CASCADE,
  CONSTRAINT "pool_sharing_agreements_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "admin_users"("id")
);

CREATE UNIQUE INDEX "pool_sharing_agreements_company_id_partner_company_id_key" ON "pool_sharing_agreements"("company_id", "partner_company_id");

ALTER TABLE "company_employees"
  ADD COLUMN "pool_access_enabled" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN "pool_daily_limit" INTEGER,
  ADD COLUMN "pool_weekly_limit" INTEGER,
  ADD COLUMN "pool_monthly_limit" INTEGER;
