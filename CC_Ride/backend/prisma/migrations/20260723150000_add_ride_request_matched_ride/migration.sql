-- A driver committing a route/trip against a passenger's request no longer
-- immediately closes it out — it stays open (is_active) but now points at
-- the matching ride, and the passenger explicitly confirms (proceeds to
-- book) or declines (kills the request) from there.
ALTER TABLE "ride_requests"
  ADD COLUMN "matched_ride_id" UUID;

ALTER TABLE "ride_requests"
  ADD CONSTRAINT "ride_requests_matched_ride_id_fkey"
  FOREIGN KEY ("matched_ride_id") REFERENCES "rides"("id");
