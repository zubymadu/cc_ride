import nodemailer from 'nodemailer'
import { prisma } from './prisma'

// SMTP config lives in PlatformSettings (the admin Settings page manages
// smtp_host/smtp_port/smtp_username/smtp_password/smtp_from_email) — this
// used to read process.env.SMTP_* instead, which nothing in the admin UI
// could ever actually set, so email silently never worked regardless of
// what an admin configured. PlatformSettings is now the single source of
// truth; env vars are no longer consulted here.
//
// No-ops when SMTP isn't configured rather than throwing — callers decide
// what to do when mail can't actually be sent (e.g. falling back to a
// dev-mode response).
export async function sendMail(to: string, subject: string, html: string): Promise<boolean> {
  const settings = await prisma.platformSettings.findUnique({ where: { id: 1 } })
  if (!settings?.smtpHost || !settings.smtpUsername || !settings.smtpPassword) return false

  const transporter = nodemailer.createTransport({
    host: settings.smtpHost,
    port: settings.smtpPort ?? 587,
    auth: { user: settings.smtpUsername, pass: settings.smtpPassword },
  })

  await transporter.sendMail({
    from: `"${settings.appName ?? 'CC Ride'}" <${settings.smtpFromEmail || settings.smtpUsername}>`,
    to,
    subject,
    html,
  })
  return true
}
