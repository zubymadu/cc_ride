-- Admin invite/claim flow: lets a company get a scoped admin account
-- provisioned automatically when it's approved, instead of requiring a
-- super-admin to manually create one every time an organisation signs on.
--
-- password_hash becomes nullable — an invited-but-unclaimed admin has no
-- credentials yet, only an invite_token, until they follow their emailed
-- link and set one via the claim endpoint (which clears both invite
-- columns together).

ALTER TABLE "admin_users"
  ALTER COLUMN "password_hash" DROP NOT NULL,
  ADD COLUMN "invite_token" TEXT,
  ADD COLUMN "invite_expires_at" TIMESTAMP(3);

CREATE UNIQUE INDEX "admin_users_invite_token_key" ON "admin_users"("invite_token");
