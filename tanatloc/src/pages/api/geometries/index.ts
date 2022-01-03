import { Request, Response } from 'express'

import route from '@/route/geometries'

/**
 * Geometries API from [ids]
 * @memberof Pages.API
 * @param req Request
 * @param res Response
 */
const api = async (req: Request, res: Response): Promise<void> => {
  await route(req, res)
}

export default api
