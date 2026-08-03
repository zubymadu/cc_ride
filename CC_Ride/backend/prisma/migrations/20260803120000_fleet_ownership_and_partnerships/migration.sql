-- AlterTable
ALTER TABLE "driver_profiles" ADD COLUMN     "pool_branch_id" BIGINT,
ADD COLUMN     "pool_company_id" UUID;

-- AlterTable
ALTER TABLE "vehicles" ADD COLUMN     "owner_branch_id" BIGINT,
ADD COLUMN     "owner_company_id" UUID;

-- CreateTable
CREATE TABLE "branch_partnerships" (
    "id" BIGSERIAL NOT NULL,
    "owner_branch_id" BIGINT NOT NULL,
    "partner_branch_id" BIGINT NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_by" BIGINT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "branch_partnerships_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "branch_partnerships_owner_branch_id_partner_branch_id_key" ON "branch_partnerships"("owner_branch_id", "partner_branch_id");

-- CreateIndex
CREATE INDEX "driver_profiles_pool_branch_id_idx" ON "driver_profiles"("pool_branch_id");

-- CreateIndex
CREATE INDEX "vehicles_owner_branch_id_idx" ON "vehicles"("owner_branch_id");

-- AddForeignKey
ALTER TABLE "driver_profiles" ADD CONSTRAINT "driver_profiles_pool_company_id_fkey" FOREIGN KEY ("pool_company_id") REFERENCES "companies"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "driver_profiles" ADD CONSTRAINT "driver_profiles_pool_branch_id_fkey" FOREIGN KEY ("pool_branch_id") REFERENCES "company_branches"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vehicles" ADD CONSTRAINT "vehicles_owner_company_id_fkey" FOREIGN KEY ("owner_company_id") REFERENCES "companies"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vehicles" ADD CONSTRAINT "vehicles_owner_branch_id_fkey" FOREIGN KEY ("owner_branch_id") REFERENCES "company_branches"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "branch_partnerships" ADD CONSTRAINT "branch_partnerships_owner_branch_id_fkey" FOREIGN KEY ("owner_branch_id") REFERENCES "company_branches"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "branch_partnerships" ADD CONSTRAINT "branch_partnerships_partner_branch_id_fkey" FOREIGN KEY ("partner_branch_id") REFERENCES "company_branches"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "branch_partnerships" ADD CONSTRAINT "branch_partnerships_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "admin_users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

