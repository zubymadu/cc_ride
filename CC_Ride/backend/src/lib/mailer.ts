import nodemailer from 'nodemailer'
import { prisma } from './prisma'

// Until the app is live on the Play Store / App Store, the invite CTA sends
// people to the internal APK download page instead of a store/deep link.
const APP_DOWNLOAD_URL = `${process.env.ADMIN_URL ?? 'https://admin.ccride.ng'}/download`

export async function sendInviteEmail(email: string, name: string, companyId: string) {
  if (!process.env.SMTP_HOST) return

  const settings = await prisma.platformSettings.findUnique({ where: { id: 1 } })
  const company  = await prisma.company.findUnique({ where: { id: companyId }, select: { name: true } })
  const companyName = company?.name ?? 'your company'

  const transporter = nodemailer.createTransport({
    host:   process.env.SMTP_HOST,
    port:   Number(process.env.SMTP_PORT ?? 587),
    auth:   { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
  })

  await transporter.sendMail({
    from:    `"${settings?.appName ?? 'CC Ride'}" <${process.env.SMTP_FROM ?? 'noreply@ccride.ng'}>`,
    to:      email,
    subject: `You've been invited to ${companyName} on CC Ride`,
    html: `
      <p>Hi ${name},</p>
      <p>You've been added to <strong>${companyName}</strong> on CC Ride. Download the app to get started and set up your account.</p>
      <p>
        <a href="${APP_DOWNLOAD_URL}"
           style="display:inline-block;padding:12px 24px;background:#4F46E5;color:#ffffff;
                  text-decoration:none;border-radius:8px;font-weight:600;">
          Download the CC Ride app
        </a>
      </p>
      <p style="color:#888;font-size:13px;">If the button doesn't work, copy and paste this link into your browser: ${APP_DOWNLOAD_URL}</p>
    `,
  })
}
