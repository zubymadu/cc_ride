CREATE TABLE "adverts" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "image_url" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT,
    "link_url" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "adverts_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "adverts_is_active_sort_order_idx" ON "adverts"("is_active", "sort_order");
