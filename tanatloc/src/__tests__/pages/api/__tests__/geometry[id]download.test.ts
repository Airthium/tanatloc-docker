import { Request, Response } from 'express'

import download from '@/pages/api/geometry/[id]/download'

jest.mock('@/route/geometry/[id]/download', () => jest.fn())

describe('pages/api/geometry/[id]/download', () => {
  const req = {} as Request
  const res = {} as Response

  test('call', async () => {
    await download(req, res)
  })
})
