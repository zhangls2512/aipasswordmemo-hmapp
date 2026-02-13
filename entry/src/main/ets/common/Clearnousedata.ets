import { preferences } from '@kit.ArkData'
import { asset } from '@kit.AssetStoreKit'
import { fileIo } from '@kit.CoreFileKit'
import { stringToArray } from './Crypto'
import { getPasswordList, getTypeInfoList } from './Dataget'

export async function clearNouseData(context: Context) {
  const dataPreferences = preferences.getPreferencesSync(context, {
    name: 'dataSetting'
  })
  dataPreferences.deleteSync('isBackupTables')
  await preferences.deletePreferences(context, 'speakSetting')
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
  try {
    const query: asset.AssetMap = new Map()
    query.set(asset.Tag.ALIAS, stringToArray('accessToken'))
    asset.removeSync(query)
    await preferences.deletePreferences(context, {
      name: 'login'
    })
  } catch {
  }
  const nousePasswordIconFilePathArray = await getNousePasswordIconFilePathArray(context)
  const promises = nousePasswordIconFilePathArray.map(async (item) => {
    await fileIo.unlink(item)
  })
  await Promise.all(promises)
  const oldInvitationQrcodeDir = context.filesDir + '/media/invitationqrcode'
  if (fileIo.accessSync(oldInvitationQrcodeDir)) {
    await fileIo.rmdir(oldInvitationQrcodeDir)
  }
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