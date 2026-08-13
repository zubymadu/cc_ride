-- CreateEnum
CREATE TYPE "WaitlistSubmissionType" AS ENUM ('general', 'organisation', 'investor');

-- CreateTable
CREATE TABLE "waitlist_submissions" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "type" "WaitlistSubmissionType" NOT NULL,
    "name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "organisation" TEXT,
    "message" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "waitlist_submissions_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "waitlist_submissions_created_at_idx" ON "waitlist_submissions"("created_at");
