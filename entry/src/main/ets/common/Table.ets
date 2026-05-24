import { relationalStore } from '@kit.ArkData'
import { util } from '@kit.ArkTS'
import { promptAction } from '@kit.ArkUI'
import { batteryInfo, power } from '@kit.BasicServicesKit'
import { fileIo } from '@kit.CoreFileKit'
import { rcp } from '@kit.RemoteCommunicationKit'
import { encrypt, EncryptData, getKeyAlg } from './Crypto'
import { getInfoList, getPasswordList, getTagList, Info, Tag } from './Dataget'
import { PasswordItem } from './Dataimport'
import { write } from './File'
import { getPermission } from './Permission'
import { getFlushPreference } from './Preference'
import { globalSession } from './Request'
import { getWebdavServerInfo } from './Webdavserver'

interface Item {
  deviceId: string,
  deviceName: string,
  deviceType: string,
  networkId: string
}

export async function autoSyncTable(context: Context, table: string, fromDeviceId?: string) {
  const pauseAutoSyncWhenLowBatteryCapacityLevel =
    getFlushPreference(context, 'dataSetting', 'pauseAutoSyncWhenLowBatteryCapacityLevel', false)
  const pauseAutoSyncWhenPowerSave = getFlushPreference(context, 'dataSetting', 'pauseAutoSyncWhenPowerSave', false)
  const lowBatteryCapacityLevel =
    getFlushPreference(context, 'debugSetting', 'lowBatteryCapacityLevel', batteryInfo.BatteryCapacityLevel.LEVEL_LOW)
  if (pauseAutoSyncWhenLowBatteryCapacityLevel && batteryInfo.batteryCapacityLevel >= lowBatteryCapacityLevel) {
    return
  }
  const currentPowerMode = power.getPowerMode()
  if (pauseAutoSyncWhenPowerSave && currentPowerMode !== power.DevicePowerMode.MODE_NORMAL &&
    currentPowerMode !== power.DevicePowerMode.MODE_PERFORMANCE) {
    return
  }
  const autoSyncTables = getFlushPreference(context, 'dataSetting', 'autoSyncTables', []) as string[]
  if (autoSyncTables.includes(table)) {
    const autoSyncDevices: Item[] = getFlushPreference(context, 'dataSetting', 'autoSyncDevices', []) as Item[]
    const promises = autoSyncDevices.map(async (item) => {
      if (item.deviceId !== fromDeviceId) {
        await syncTable(context, table, item.networkId, relationalStore.SyncMode.SYNC_MODE_PUSH)
      }
    })
    await Promise.all(promises)
  }
  await huaweiCloudSyncTable(context, table)
}

export async function syncTable(context: Context, table: string, networkId: string,
  syncMode: relationalStore.SyncMode) {
  const permission = getPermission('ohos.permission.DISTRIBUTED_DATASYNC')
  if (!permission) {
    await promptAction.openToast({
      message: '同步失败，原因：无权限'
    })
  }
  if (permission) {
    let securityLevel = relationalStore.SecurityLevel.S4
    if (table === 'tag') {
      securityLevel = relationalStore.SecurityLevel.S1
    }
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: table,
      securityLevel: securityLevel,
      encrypt: true,
      allowRebuild: true
    })
    const predicates = new relationalStore.RdbPredicates(table)
    predicates.inDevices([networkId])
    try {
      const res = await rdbStore.sync(syncMode, predicates)
      if (res[0][1] !== 0) {
        await promptAction.openToast({
          message: '同步失败，设备 ID：' + res[0][0] + '，错误码：' + res[0][1]
        })
      }
      if (res[0][1] === 0) {
        await promptAction.openToast({
          message: '同步成功，设备 ID：' + res[0][0]
        })
      }
    } catch (err) {
      await promptAction.openToast({
        message: '发生错误，错误码：' + err.code
      })
    }
  }
}

async function huaweiCloudSyncTable(context: Context, table: string) {
  const autoHuaweiCloudSyncTables =
    getFlushPreference(context, 'dataSetting', 'autoHuaweiCloudSyncTables', []) as string[]
  if (autoHuaweiCloudSyncTables.includes(table)) {
    const huaweiCloudSyncRdbStore = await relationalStore.getRdbStore(context, {
      name: 'huaweicloudsync',
      securityLevel: relationalStore.SecurityLevel.S3,
      encrypt: true,
      allowRebuild: true
    })
    await huaweiCloudSyncRdbStore.cloudSync(relationalStore.SyncMode.SYNC_MODE_TIME_FIRST, [table], () => {
    })
  }
}

export async function autoBackupTable(context: Context, table: string) {
  const pauseAutoBackupWhenLowBatteryCapacityLevel =
    getFlushPreference(context, 'dataSetting', 'pauseAutoSyncWhenLowBatteryCapacityLevel', false)
  const pauseAutoBackupWhenPowerSave = getFlushPreference(context, 'dataSetting', 'pauseAutoSyncWhenPowerSave', false)
  const lowBatteryCapacityLevel =
    getFlushPreference(context, 'debugSetting', 'lowBatteryCapacityLevel', batteryInfo.BatteryCapacityLevel.LEVEL_LOW)
  if (pauseAutoBackupWhenLowBatteryCapacityLevel && batteryInfo.batteryCapacityLevel >= lowBatteryCapacityLevel) {
    return
  }
  const currentPowerMode = power.getPowerMode()
  if (pauseAutoBackupWhenPowerSave && currentPowerMode !== power.DevicePowerMode.MODE_NORMAL &&
    currentPowerMode !== power.DevicePowerMode.MODE_PERFORMANCE) {
    return
  }
  const autoBackupTables =
    getFlushPreference(context, 'dataSetting', 'autoBackupTables', ['password', 'info', 'tag']) as string[]
  if (autoBackupTables.includes(table)) {
    await backupTable(context, table)
  }
  const autoFileBackupTables =
    getFlushPreference(context, 'dataSetting', 'autoFileBackupTables', ['password', 'info', 'tag']) as string[]
  const autoWebdavBackupTables =
    getFlushPreference(context, 'dataSetting', 'autoWebdavBackupTables', ['password', 'info', 'tag']) as string[]
  const fileBackup = autoFileBackupTables.includes(table)
  const webdavBackup = autoWebdavBackupTables.includes(table)
  let array: PasswordItem[] | Info[] | Tag[] = []
  if (fileBackup || webdavBackup) {
    if (table === 'password') {
      array = await getPasswordList(context)
    }
    if (table === 'info') {
      array = await getInfoList(context)
    }
    if (table === 'tag') {
      array = await getTagList(context)
    }
  }
  if (fileBackup) {
    await fileBackupTable(context, table, array)
  }
  if (webdavBackup) {
    await webdavBackupTable(context, table, array)
  }
}

export async function backupTable(context: Context, table: string) {
  let securityLevel = relationalStore.SecurityLevel.S4
  if (table === 'tag') {
    securityLevel = relationalStore.SecurityLevel.S1
  }
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: table,
    securityLevel: securityLevel,
    encrypt: true,
    allowRebuild: true
  })
  await rdbStore.backup(table + 'backup.db')
  const oldFilePath = context.databaseDir + '/rdb/' + table + 'Backup.db'
  if (fileIo.accessSync(oldFilePath)) {
    await fileIo.unlink(oldFilePath)
  }
}

async function getFileBackupString(array: PasswordItem[] | Info[] | Tag[], encrypted: boolean) {
  if (!encrypted) {
    return JSON.stringify({
      encrypted: false,
      data: array
    })
  }
  if (encrypted) {
    const encryptedArray: EncryptData[] = []
    const promises = array.map(async (item: PasswordItem | Info | Tag) => {
      const res = await encrypt(JSON.stringify(item))
      encryptedArray.push({
        content: res.content,
        iv: res.iv
      })
    })
    await Promise.all(promises)
    return JSON.stringify({
      encrypted: true,
      data: encryptedArray
    })
  }
  return 'fail'
}

export async function fileBackupTable(context: Context, table: string, dataArray?: PasswordItem[] | Info[] | Tag[]) {
  const encryptFileBackup = getFlushPreference(context, 'dataSetting', 'encryptFileBackup', true)
  let encrypted = false
  if (encryptFileBackup && getKeyAlg()) {
    encrypted = true
  }
  let array: PasswordItem[] | Info[] | Tag[] = []
  if (!dataArray) {
    if (table === 'password') {
      array = await getPasswordList(context)
    }
    if (table === 'info') {
      array = await getInfoList(context)
    }
    if (table === 'tag') {
      array = await getTagList(context)
    }
  }
  if (dataArray) {
    array = dataArray
  }
  const datastring = await getFileBackupString(array, encrypted)
  if (datastring !== 'fail') {
    await write(context.filesDir + '/backup/' + table + '.txt', datastring)
  }
}

export async function webdavBackupTable(context: Context, table: string, dataArray?: PasswordItem[] | Info[] | Tag[]) {
  const webdavServerInfo = await getWebdavServerInfo()
  if (!webdavServerInfo.path) {
    return 'fail'
  }
  const encryptWebdavBackup = getFlushPreference(context, 'dataSetting', 'encryptWebdavBackup', true)
  let encrypted = false
  if (encryptWebdavBackup && getKeyAlg()) {
    encrypted = true
  }
  let array: PasswordItem[] | Info[] | Tag[] = []
  if (!dataArray) {
    if (table === 'password') {
      array = await getPasswordList(context)
    }
    if (table === 'info') {
      array = await getInfoList(context)
    }
    if (table === 'tag') {
      array = await getTagList(context)
    }
  }
  if (dataArray) {
    array = dataArray
  }
  const datastring = await getFileBackupString(array, encrypted)
  if (datastring !== 'fail') {
    try {
      const response = await globalSession.fetch(new rcp.Request(webdavServerInfo.path + '/' + table + '.txt', 'PUT', {
        Authorization: 'Basic ' + new util.Base64Helper().encodeToStringSync(
          new util.TextEncoder().encodeInto(webdavServerInfo.username + ':' + webdavServerInfo.password))
      }, datastring))
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return 'success'
      } else {
        const statusCodeMap: Record<number, string> = {
          401: '账号密码错误',
          405: '目录不存在或无权限'
        }
        const reason = statusCodeMap[response.statusCode]
        if (reason) {
          await promptAction.openToast({
            message: '备份失败，原因：' + reason
          })
          return 'fail'
        }
        await promptAction.openToast({
          message: 'HTTP 请求失败，状态码：' + response.statusCode
        })
        return 'fail'
      }
    } catch (err) {
      await promptAction.openToast({
        message: '发生错误，错误码：' + err.code
      })
      return 'fail'
    }
  }
  return 'fail'
}

export async function recoveryTable(context: Context, table: string) {
  let securityLevel = relationalStore.SecurityLevel.S4
  if (table === 'tag') {
    securityLevel = relationalStore.SecurityLevel.S1
  }
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: table,
    securityLevel: securityLevel,
    encrypt: true,
    allowRebuild: true
  })
  await rdbStore.restore(table + 'backup.db')
}