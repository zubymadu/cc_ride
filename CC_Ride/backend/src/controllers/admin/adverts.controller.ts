import { Request, Response } from 'express'
import { z } from 'zod'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'

// GET /admin/adverts — full list (active and inactive), for management.
export async function listAdverts(_req: Request, res: Response) {
  try {
    const adverts = await prisma.advert.findMany({
      orderBy: [{ sortOrder: 'asc' }, { createdAt: 'desc' }],
    })
    ok(res, adverts.map((a) => ({
      id:         a.id,
      image_url:  a.imageUrl,
      title:      a.title,
      body:       a.body ?? '',
      link_url:   a.linkUrl ?? '',
      is_active:  a.isActive,
      sort_order: a.sortOrder,
      created_at: a.createdAt.toISOString(),
    })))
  } catch (err) {
    serverError(res, err)
  }
}

const CreateAdvertSchema = z.object({
  title:      z.string().min(1),
  body:       z.string().optional(),
  link_url:   z.string().url().optional().or(z.literal('')),
  sort_order: z.coerce.number().int().optional(),
})

// POST /admin/adverts — multipart (image file + fields), mirrors
// uploadCompanyLogo's storage convention.
export async function createAdvert(req: Request, res: Response) {
  try {
    const file = (req as any).file as { filename?: string } | undefined
    if (!file?.filename) { fail(res, 'image file required'); return }

    const data = CreateAdvertSchema.parse(req.body)

    const advert = await prisma.advert.create({
      data: {
        imageUrl:  `/api/uploads/adverts/${file.filename}`,
        title:     data.title,
        body:      data.body || null,
        linkUrl:   data.link_url || null,
        sortOrder: data.sort_order ?? 0,
      },
    })
    ok(res, { id: advert.id }, 'Advert created')
  } catch (err) {
    serverError(res, err)
  }
}

const UpdateAdvertSchema = z.object({
  title:      z.string().min(1).optional(),
  body:       z.string().optional(),
  link_url:   z.string().url().optional().or(z.literal('')),
  is_active:  z.boolean().optional(),
  sort_order: z.coerce.number().int().optional(),
})

// PATCH /admin/adverts/:id — text fields only; image replacement (if ever
// needed) is a delete-and-recreate rather than adding a second multipart
// path for what's otherwise a plain JSON update.
export async function updateAdvert(req: Request, res: Response) {
  try {
    const id = String(req.params.id)
    const data = UpdateAdvertSchema.parse(req.body)

    const existing = await prisma.advert.findUnique({ where: { id } })
    if (!existing) { fail(res, 'Advert not found'); return }

    const updated = await prisma.advert.update({
      where: { id },
      data: {
        ...(data.title !== undefined      ? { title: data.title }                          : {}),
        ...(data.body !== undefined       ? { body: data.body || null }                     : {}),
        ...(data.link_url !== undefined   ? { linkUrl: data.link_url || null }               : {}),
        ...(data.is_active !== undefined  ? { isActive: data.is_active }                     : {}),
        ...(data.sort_order !== undefined ? { sortOrder: data.sort_order }                   : {}),
      },
    })
    ok(res, { id: updated.id }, 'Advert updated')
  } catch (err) {
    serverError(res, err)
  }
}

// DELETE /admin/adverts/:id
export async function deleteAdvert(req: Request, res: Response) {
  try {
    const id = String(req.params.id)
    await prisma.advert.delete({ where: { id } })
    ok(res, {}, 'Advert deleted')
  } catch (err) {
    serverError(res, err)
  }
}
