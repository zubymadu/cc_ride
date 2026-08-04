-- Separates "which email does this employment's correspondence go to"
-- (work_email, employer-provided, may differ from the person's own account)
-- from "which User account is this" (identity, resolved by mobile/personal
-- email at registration time — see registerCompanyEmployee).

ALTER TABLE "company_employees" ADD COLUMN "work_email" TEXT;
