import multer from 'multer'
import path from 'path'

/** Shared multer instance for participating-organisation logo uploads. */
export const logoUpload = multer({
  dest: '/app/uploads/company-logos/',
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const ok = /\.(jpe?g|png|webp|svg)$/i.test(path.extname(file.originalname))
    cb(null, ok)
  },
})

/** In-memory upload for CSV bulk-imports — the file is parsed and discarded,
 * never written to disk. */
export const csvUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 2 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const ok = /\.csv$/i.test(path.extname(file.originalname))
    cb(null, ok)
  },
})
