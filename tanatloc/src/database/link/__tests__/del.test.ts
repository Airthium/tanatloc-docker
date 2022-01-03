import { del } from '../del'

const mockDelete = jest.fn()
jest.mock('../..', () => ({
  deleter: async () => mockDelete()
}))

describe('database/link/delete', () => {
  test('call', async () => {
    await del({ id: 'id' })
    expect(mockDelete).toHaveBeenCalledTimes(1)
  })
})
