/** Minimal RFC4180-ish CSV parser — no external dependency needed for the
 * small, well-structured files (employees / departments) this app imports. */
export function parseCsv(text: string): Record<string, string>[] {
  const rows = splitCsvRows(text)
  if (rows.length === 0) return []

  const headers = rows[0].map((h) => h.trim().toLowerCase())
  return rows
    .slice(1)
    .filter((row) => row.some((cell) => cell.trim() !== ''))
    .map((row) => {
      const record: Record<string, string> = {}
      headers.forEach((header, i) => { record[header] = (row[i] ?? '').trim() })
      return record
    })
}

function splitCsvRows(text: string): string[][] {
  const rows: string[][] = []
  let row: string[] = []
  let field = ''
  let inQuotes = false

  const normalized = text.replace(/\r\n/g, '\n').replace(/\r/g, '\n')

  for (let i = 0; i < normalized.length; i++) {
    const ch = normalized[i]

    if (inQuotes) {
      if (ch === '"') {
        if (normalized[i + 1] === '"') { field += '"'; i++ } else { inQuotes = false }
      } else {
        field += ch
      }
      continue
    }

    if (ch === '"') { inQuotes = true; continue }
    if (ch === ',') { row.push(field); field = ''; continue }
    if (ch === '\n') { row.push(field); rows.push(row); row = []; field = ''; continue }
    field += ch
  }
  if (field.length > 0 || row.length > 0) { row.push(field); rows.push(row) }

  return rows.filter((r) => !(r.length === 1 && r[0].trim() === ''))
}
