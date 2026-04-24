import { fileIo } from '@kit.CoreFileKit'
import { getPasswordList, getTypeInfoList } from './Dataget'

export async function clearNouseData(context: Context) {
  const tempDir = context.tempDir
  const tempFiles = await fileIo.listFile(tempDir)
  tempFiles.forEach(async (item) => {
    const path = tempDir + '/' + item
    const isDirectory = fileIo.statSync(path)
    if (!isDirectory) {
      await fileIo.unlink(path)
    }
    if (isDirectory) {
      await fileIo.rmdir(path)
    }
  })
  const nousePasswordIconFilePathArray = await getNousePasswordIconFilePathArray(context)
  const promises = nousePasswordIconFilePathArray.map(async (item) => {
    await fileIo.unlink(item)
  })
  await Promise.all(promises)
}

async function getNousePasswordIconFilePathArray(context: Context) {
  const passwordIconDir = context.filesDir + '/media/passwordicon/'
  if (!fileIo.accessSync(passwordIconDir)) {
    return []
  }
  const passwordIconFileNameArray = await fileIo.listFile(passwordIconDir)
  const passwordIconFilePathArray = passwordIconFileNameArray.map(item => passwordIconDir + item)
  const passwordArray = await getPasswordList(context)
  const passwordIconPathArray: string[] = []
  passwordArray.forEach(item => {
    const infoItem = item.info.find(infoItem => infoItem.type === '图标')
    if (infoItem) {
      passwordIconPathArray.push(infoItem.value.replace('file://com.zhangxm.aipasswordmemo', ''))
    }
  })
  const infoArray = await getTypeInfoList(context, '图标')
  const infoIconPathArray = infoArray.map(item => item.replace('file://com.zhangxm.aipasswordmemo', ''))
  const iconPathSet = new Set(passwordIconPathArray.concat(infoIconPathArray))
  return passwordIconFilePathArray.filter(item => !iconPathSet.has(item))
}