import { Request, Response } from 'express'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'

// ─── POST /corporate/company/logo ─────────────────────────────────────────────
// multipart/form-data: { company_id, logo (file) } — company_admin/finance/hr only,
// scoped to their own company via requireCompanyMember.

export async function uploadCompanyLogo(req: Request, res: Response) {
  try {
    const file = (req as any).file as Express.Multer.File | undefined
    if (!file) { fail(res, 'Logo image required'); return }

    const companyId = req.companyId!
    const logoUrl = `/api/uploads/company-logos/${file.filename}`
    await prisma.company.update({ where: { id: companyId }, data: { logoUrl } })

    ok(res, { company_id: companyId, logo_url: logoUrl }, 'Logo updated')
  } catch (err) {
    serverError(res, err)
  }
}
