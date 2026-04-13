import { relationalStore } from '@kit.ArkData'
import { util } from '@kit.ArkTS'
import { promptAction } from '@kit.ArkUI'
import { batteryInfo, power } from '@kit.BasicServicesKit'
import { fileIo } from '@kit.CoreFileKit'
import { distributedDeviceManager } from '@kit.DistributedServiceKit'
import { rcp } from '@kit.RemoteCommunicationKit'
import { encrypt, EncryptData, getKeyAlg } from './Crypto'
import { getInfoList, getPasswordList, getTagList } from './Dataget'
import { write } from './File'
import { getFlushPreference } from './Preference'
import { getWebdavServerInfo } from './Webdavserver'
import { InfoOutItem, PasswordOutItem, TagOutItem } from '../pages/DataInOut'

interface Item {
  deviceId: string,
  deviceName: string,
  deviceType: string,
  networkId: string
}

export async function syncTable(context: Context, table: string, networkId: string,
  syncMode: relationalStore.SyncMode) {
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
    const devices =
      distributedDeviceManager.createDeviceManager('com.zhangxm.aipasswordmemo').getAvailableDeviceListSync()
    const promises = autoSyncDevices.map(async (item) => {
      if (!devices.find(item => item.deviceId === fromDeviceId)) {
        await syncTable(context, table, item.networkId, relationalStore.SyncMode.SYNC_MODE_PUSH)
      }
    })
    await Promise.all(promises)
  }
}

export async function autoHuaweiCloudSyncTable(context: Context, table: string) {
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

async function getFileBackupString(context: Context, table: string, encrypted: boolean): Promise<string> {
  if (table === 'password') {
    const array = await getPasswordList(context)
    if (array.length > 0) {
      const arrayOut = array.map((item): PasswordOutItem => {
        let cloudBackupTime = JSON.stringify([])
        if (typeof (item.cloudBackupTime) === 'string') {
          cloudBackupTime = item.cloudBackupTime
        }
        return {
          id: item.id,
          name: item.name,
          info: item.info,
          tag: item.tag.map(item => item.value),
          updateTime: item.updateTime,
          cloudBackupTime: cloudBackupTime
        }
      })
      if (!encrypted) {
        return JSON.stringify({
          encrypted: false,
          data: arrayOut
        })
      }
      if (encrypted) {
        const encryptedArray: EncryptData[] = []
        const promises = arrayOut.map(async (item: PasswordOutItem) => {
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
    }
  }
  if (table === 'info') {
    const array = await getInfoList(context)
    if (array.length > 0) {
      const arrayOut = array.map((item): InfoOutItem => {
        let cloudBackupTime = JSON.stringify([])
        if (typeof (item.cloudBackupTime) === 'string') {
          cloudBackupTime = item.cloudBackupTime
        }
        return {
          id: item.id,
          type: item.type,
          value: item.value,
          updateTime: item.updateTime,
          cloudBackupTime: cloudBackupTime
        }
      })
      if (!encrypted) {
        return JSON.stringify({
          encrypted: false,
          data: arrayOut
        })
      }
      if (encrypted) {
        const encryptedArray: EncryptData[] = []
        const promises = arrayOut.map(async (item: InfoOutItem) => {
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
    }
  }
  if (table === 'tag') {
    const array = await getTagList(context)
    if (array.length > 0) {
      const arrayOut = array.map((item): TagOutItem => {
        let cloudBackupTime = JSON.stringify([])
        if (typeof (item.cloudBackupTime) === 'string') {
          cloudBackupTime = item.cloudBackupTime
        }
        return {
          id: item.id,
          value: item.value,
          color: item.color,
          updateTime: item.updateTime,
          cloudBackupTime: cloudBackupTime
        }
      })
      if (!encrypted) {
        return JSON.stringify({
          encrypted: false,
          data: arrayOut
        })
      }
      if (encrypted) {
        const encryptedArray: EncryptData[] = []
        const promises = arrayOut.map(async (item: TagOutItem) => {
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
    }
  }
  return 'fail'
}

export async function fileBackupTable(context: Context, table: string) {
  const encryptFileBackup = getFlushPreference(context, 'dataSetting', 'encryptFileBackup', true)
  let encrypted = false
  if (encryptFileBackup && getKeyAlg()) {
    encrypted = true
  }
  const datastring = await getFileBackupString(context, table, encrypted)
  if (datastring !== 'fail') {
    await write(context.filesDir + '/backup/' + table + '.txt', datastring)
  }
}

export async function webdavBackupTable(context: Context, table: string) {
  const webdavServerInfo = await getWebdavServerInfo()
  if (!webdavServerInfo.path) {
    return 'fail'
  }
  const encryptWebdavBackup = getFlushPreference(context, 'dataSetting', 'encryptWebdavBackup', true)
  let encrypted = false
  if (encryptWebdavBackup && getKeyAlg()) {
    encrypted = true
  }
  const datastring = await getFileBackupString(context, table, encrypted)
  if (datastring !== 'fail') {
    const session = rcp.createSession({
      requestConfiguration: {
        security: {
          tlsRange: {
            min: 'TlsV1.2'
          }
        }
      },
      headers: {
        Authorization: 'Basic ' +
          new util.Base64Helper().encodeToStringSync(new util.TextEncoder().encodeInto(webdavServerInfo.username + ':' +
            webdavServerInfo.password))
      }
    })
    try {
      const response = await session.put(webdavServerInfo.path + '/' + table + '.txt', datastring)
      session.close()
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
          message: '请求失败，错误码：' + response.statusCode
        })
        return 'fail'
      }
    } catch (err) {
      session.close()
      await promptAction.openToast({
        message: '发生错误，错误码：' + err.code
      })
      return 'fail'
    }
  }
  return 'success'
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
  if (autoFileBackupTables.includes(table)) {
    await fileBackupTable(context, table)
  }
  const autoWebdavBackupTables =
    getFlushPreference(context, 'dataSetting', 'autoWebdavBackupTables', ['password', 'info', 'tag']) as string[]
  if (autoWebdavBackupTables.includes(table)) {
    await webdavBackupTable(context, table)
  }
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