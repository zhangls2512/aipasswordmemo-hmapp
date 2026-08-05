import { fileIo } from '@kit.CoreFileKit'
import { read, write } from './File'

export async function getFavouriteColor(context: Context) {
  const filePath = context.filesDir + '/favouritecolor.txt'
  const exist = fileIo.accessSync(filePath)
  if (!exist) {
    return []
  }
  const res = await read(filePath)
  return JSON.parse(res) as string[]
}

export async function setFavouriteColor(context: Context, list: string[]) {
  await write(context.filesDir + '/favouritecolor.txt', JSON.stringify(list))
}