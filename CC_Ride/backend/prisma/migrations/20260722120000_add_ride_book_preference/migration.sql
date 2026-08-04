-- The Flutter app has always sent book_preference ("Manual"/"Auto") on
-- post_trip.php, but nothing on the backend ever stored or acted on it —
-- every booking auto-confirmed regardless. This adds the column so
-- legacyPostTrip can persist the driver's choice and legacyBookSeat can gate
-- manual rides into a pending Booking instead of auto-confirming.
ALTER TABLE "rides"
  ADD COLUMN "book_preference" TEXT NOT NULL DEFAULT 'Auto';

-- Same opt-in flag, but on the published-route schedule itself so a
-- materialized Ride can inherit it (see materializeRouteRidesForDate).
ALTER TABLE "route_schedules"
  ADD COLUMN "book_preference" TEXT NOT NULL DEFAULT 'Auto';
