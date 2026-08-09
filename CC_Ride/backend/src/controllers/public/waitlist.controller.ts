import { Request, Response } from 'express'
import fs from 'fs'
import path from 'path'
import { z } from 'zod'
import { sendMail } from '../../lib/mail'
import { ok, fail, serverError } from '../../lib/response'

const NOTIFY_TO = 'hello@equiviral.com, hello@ccride.ng'

// SMTP is opt-in (PlatformSettings) and silently no-ops when unconfigured
// (see lib/mail.ts) — for a public marketing-site form, a lost submission
// is a lost lead, so every submission is also appended to a local log file
// as a backup regardless of whether the email actually sends.
const LOG_PATH = path.join('/app/uploads', 'waitlist-submissions.jsonl')

const WaitlistSchema = z.object({
  type: z.enum(['general', 'organisation', 'investor']),
  name: z.string().min(1),
  email: z.string().email(),
  organisation: z.string().optional(),
  message: z.string().optional(),
})

const TYPE_LABEL: Record<string, string> = {
  general: 'Waitlist signup',
  organisation: 'Organisation interest',
  investor: 'Investor interest',
}

export async function submitWaitlist(req: Request, res: Response) {
  try {
    const data = WaitlistSchema.parse(req.body)

    const entry = { ...data, submittedAt: new Date().toISOString() }
    try {
      fs.appendFileSync(LOG_PATH, JSON.stringify(entry) + '\n')
    } catch (err) {
      console.error('waitlist log write failed:', err)
    }

    const html = `
      <h2>${TYPE_LABEL[data.type]} — ccride.ng</h2>
      <p><strong>Name:</strong> ${data.name}</p>
      <p><strong>Email:</strong> ${data.email}</p>
      ${data.organisation ? `<p><strong>Organisation:</strong> ${data.organisation}</p>` : ''}
      ${data.message ? `<p><strong>Message:</strong> ${data.message}</p>` : ''}
    `
    await sendMail(NOTIFY_TO, `${TYPE_LABEL[data.type]}: ${data.name}`, html).catch((err) => {
      console.error('waitlist sendMail failed:', err)
    })

    ok(res, {}, "Thanks — we'll be in touch.")
  } catch (err: any) {
    if (err?.issues) { fail(res, 'Please fill in your name and a valid email address'); return }
    serverError(res, err)
  }
}
