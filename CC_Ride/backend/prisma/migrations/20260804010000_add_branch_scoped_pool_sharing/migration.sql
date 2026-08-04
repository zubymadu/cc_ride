-- Lets a pool vehicle belong to a specific branch, and a pool-sharing
-- agreement be scoped to just that branch's fleet rather than the whole
-- company — so one branch (e.g. Lagos) can share with a partner org while
-- another branch of the same company (e.g. Abuja) shares with nobody,
-- because it simply has no agreement naming it.

ALTER TABLE "vehicles"
  ADD COLUMN "branch_id" BIGINT;

ALTER TABLE "vehicles"
  ADD CONSTRAINT "vehicles_branch_id_fkey"
  FOREIGN KEY ("branch_id") REFERENCES "company_branches"("id");

ALTER TABLE "pool_sharing_agreements"
  ADD COLUMN "branch_id" BIGINT;

ALTER TABLE "pool_sharing_agreements"
  ADD CONSTRAINT "pool_sharing_agreements_branch_id_fkey"
  FOREIGN KEY ("branch_id") REFERENCES "company_branches"("id") ON DELETE CASCADE;

-- Replaces the old (company_id, partner_company_id) unique index —
-- Postgres treats NULL branch_id values as distinct from each other, so
-- this alone doesn't prevent duplicate company-wide agreements; that's
-- enforced at the application level in addPoolSharingAgreement instead.
DROP INDEX IF EXISTS "pool_sharing_agreements_company_id_partner_company_id_key";

CREATE UNIQUE INDEX "pool_sharing_agreements_company_id_branch_id_partner_compan_key"
  ON "pool_sharing_agreements"("company_id", "branch_id", "partner_company_id");
