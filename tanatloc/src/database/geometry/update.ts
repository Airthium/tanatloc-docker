import { tables } from '@/config/db'

import { updater } from '..'
import { IDataBaseEntry } from '../index.d'

/**
 * Update
 * @memberof Database.Geometry
 * @param geometry Geometry
 * @param data Data
 */
export const update = async (
  geometry: { id: string },
  data: Array<IDataBaseEntry>
) => {
  await updater(tables.GEOMETRIES, geometry.id, data)
}
