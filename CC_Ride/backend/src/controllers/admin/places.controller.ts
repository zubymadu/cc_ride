import { Request, Response } from 'express'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'

// ─── GET /admin/places/search?query= ──────────────────────────────────────────
// Server-side proxy to Google's Places Text Search API — the admin console is
// a browser app, and Google's Places Web Service does not allow CORS calls
// from client-side JS, so the request has to be relayed through the backend
// (which also keeps the API key out of the browser bundle).

export async function searchPlaces(req: Request, res: Response) {
  try {
    const query = String(req.query.query ?? '').trim()
    if (query.length < 3) { ok(res, []); return }

    const settings = await prisma.platformSettings.findUnique({ where: { id: 1 } })
    const apiKey = settings?.googleMapsKey
    if (!apiKey) { fail(res, 'Google Maps API key is not configured'); return }

    const url = `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${encodeURIComponent(query)}&region=ng&key=${apiKey}`
    const response = await fetch(url)
    const data = await response.json() as {
      status: string
      results?: { name: string; formatted_address: string; geometry?: { location?: { lat: number; lng: number } } }[]
    }

    if (data.status !== 'OK') { ok(res, []); return }

    ok(res, (data.results ?? []).slice(0, 8).map((r) => ({
      name:             r.name,
      formatted_address: r.formatted_address,
      lat:              r.geometry?.location?.lat ?? null,
      lng:              r.geometry?.location?.lng ?? null,
    })))
  } catch (err) {
    serverError(res, err)
  }
}
