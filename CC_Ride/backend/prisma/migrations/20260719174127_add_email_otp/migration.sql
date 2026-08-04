-- Email verification: a short-lived OTP code stored server-side, so
-- verify_email.php can check the code the passenger submits against the one
-- actually sent to their address, rather than trusting a client claim.
ALTER TABLE "users"
  ADD COLUMN "email_otp_code" TEXT,
  ADD COLUMN "email_otp_expires_at" TIMESTAMP(3);
