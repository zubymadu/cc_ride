import { Request, Response } from 'express'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'

// GET /admin/waitlist — ccride.ng's waitlist/organisation/investor interest
// submissions. Previously only reachable by email (silently lost if SMTP
// wasn't configured) or SSHing in to read a JSONL log file — this is now
// the real, browsable record.
export async function listWaitlistSubmissions(_req: Request, res: Response) {
  try {
    const submissions = await prisma.waitlistSubmission.findMany({
      orderBy: { createdAt: 'desc' },
    })
    ok(res, submissions.map((s) => ({
      id:           s.id,
      type:         s.type,
      name:         s.name,
      email:        s.email,
      organisation: s.organisation ?? '',
      message:      s.message ?? '',
      created_at:   s.createdAt.toISOString(),
    })))
  } catch (err) {
    serverError(res, err)
  }
}

// DELETE /admin/waitlist/:id — clear a submission once it's been actioned.
export async function deleteWaitlistSubmission(req: Request, res: Response) {
  try {
    const id = String(req.params.id)
    await prisma.waitlistSubmission.delete({ where: { id } })
    ok(res, {}, 'Submission deleted')
  } catch (err: any) {
    if (err.code === 'P2025') { fail(res, 'Submission not found'); return }
    serverError(res, err)
  }
}
