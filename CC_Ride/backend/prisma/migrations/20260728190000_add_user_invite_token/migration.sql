-- Employee first-access invite: an org admin registering an employee gets
-- a claim link/token instead of a temp password emailed in plaintext.
-- users.password_hash stays NOT NULL (unlike admin_users) — it's set to an
-- unguessable random value at creation that the user never sees; the
-- invite_token is what actually gates setting a real password.

ALTER TABLE "users"
  ADD COLUMN "invite_token" TEXT,
  ADD COLUMN "invite_expires_at" TIMESTAMP(3);

CREATE UNIQUE INDEX "users_invite_token_key" ON "users"("invite_token");
