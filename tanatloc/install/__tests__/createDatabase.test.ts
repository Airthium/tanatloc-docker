/**
 * @jest-environment node
 */

import { createDatabase } from '../createDatabase'

const mockQuery = jest.fn()
jest.mock('@/database', () => ({
  query: async (query: string) => mockQuery(query)
}))

const mockClient = jest.fn()
jest.mock('pg', () => ({
  Pool: jest.fn().mockImplementation(() => ({
    connect: () => mockClient(),
    end: jest.fn()
  }))
}))

describe('install/dB', () => {
  beforeEach(() => {
    mockClient.mockImplementation(() => ({
      query: async () => ({
        rowCount: 0
      }),
      release: jest.fn()
    }))
    mockQuery.mockImplementation(() => ({ rows: [{}] }))
  })

  test('alreadyExists', async () => {
    mockClient.mockImplementation(() => ({
      query: async () => ({
        rowCount: 1
      }),
      release: jest.fn()
    }))
    await createDatabase()
  })

  test('database error', async () => {
    mockClient.mockImplementation(() => ({}))
    await createDatabase()
  })

  test('empty', async () => {
    await createDatabase()
  })

  test('admin & exists', async () => {
    let fixConstraint = true
    let fix = true
    mockQuery.mockImplementation((query) => {
      if (query.includes('SELECT id FROM')) return { rows: [] }
      else if (
        query.includes('SELECT column_name') &&
        query.includes('tanatloc_system')
      )
        return {
          rows: [
            {
              column_name: 'allowsignup',
              data_type: 'boolean',
              is_nullable: 'NO'
            },
            {
              column_name: 'password',
              data_type: 'jsonb'
            }
          ]
        }
      else if (query.includes('SELECT column_name'))
        return {
          rows: [
            {
              column_name: 'name',
              data_type: 'jsonb'
            },
            {
              column_name: 'owners',
              data_type: 'ARRAY',
              is_nullable: 'NO'
            },
            {
              column_name: 'id',
              data_type: 'UUID',
              is_nullable: 'YES'
            }
          ]
        }
      else if (query.includes('ALTER TABLE'))
        if (query.includes('ALTER COLUMN') && query.includes('TEXT')) {
          if (fixConstraint) return {}
          else throw new Error()
        } else {
          if (fix) return {}
          else throw new Error()
        }
      else return { rows: [{ exists: true }] }
    })
    await createDatabase()

    // Fix error
    fix = false
    await createDatabase()

    fixConstraint = false
    fix = false
    await createDatabase()
  })

  test('tables error', async () => {
    mockQuery.mockImplementation(() => {
      throw new Error()
    })
    await createDatabase()
  })
})
