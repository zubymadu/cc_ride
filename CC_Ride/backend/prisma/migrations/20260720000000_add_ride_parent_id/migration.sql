-- Links a lazily-materialized daily occurrence of an ad-hoc recurring_daily
-- ride back to the original ride the driver posted (its "template"). Null
-- for the template itself and for ordinary one_time rides.
ALTER TABLE "rides"
  ADD COLUMN "parent_ride_id" UUID;

ALTER TABLE "rides"
  ADD CONSTRAINT "rides_parent_ride_id_fkey"
  FOREIGN KEY ("parent_ride_id") REFERENCES "rides"("id");

CREATE INDEX "rides_parent_ride_id_scheduled_at_idx"
  ON "rides" ("parent_ride_id", "scheduled_at");
