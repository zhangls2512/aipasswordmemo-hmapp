import { common } from '@kit.AbilityKit'
import { preferences, relationalStore } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { batteryInfo, BusinessError, power } from '@kit.BasicServicesKit'

interface Item {
  deviceId: string,
  deviceName: string,
  deviceType: string,
  networkId: string
}

export async function syncTable(table: string, deviceId: string, type: relationalStore.SyncMode): Promise<boolean> {
  const context = getContext() as common.UIAbilityContext
  let securityLevel = 4
  if (table === 'tag') {
    securityLevel = 1
  }
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'password',
    securityLevel: securityLevel,
    encrypt: true,
    allowRebuild: true
  })
  const predicates = new relationalStore.RdbPredicates(table)
  predicates.inDevices([deviceId])
  try {
    const res = await rdbStore.sync(type, predicates)
    if (res[0][1] === 0) {
      promptAction.showToast({
        message: '同步成功'
      })
      return true
    } else {
      promptAction.showToast({
        message: '同步失败'
      })
      return false
    }
  } catch (err) {
    promptAction.showToast({
      message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
      (err as BusinessError).message
    })
    return false
  }
}

export async function autoSyncTable(table: string): Promise<boolean> {
  const context = getContext() as common.UIAbilityContext
  const dataSettingDataPreferences = preferences.getPreferencesSync(context, {
    name: 'dataSetting'
  })
  const debugSettingDataPreferences = preferences.getPreferencesSync(context, {
    name: 'debugSetting'
  })
  const pauseAutoSyncWhenLowBatteryCapacityLevel: preferences.ValueType =
    dataSettingDataPreferences.getSync('pauseAutoSyncWhenLowBatteryCapacityLevel', false) as boolean
  const pauseAutoSyncWhenPowerSave: preferences.ValueType =
    dataSettingDataPreferences.getSync('pauseAutoSyncWhenPowerSave', false) as boolean
  const lowBatteryCapacityLevel: preferences.ValueType =
    debugSettingDataPreferences.getSync('lowBatteryCapacityLevel', 4) as number
  if (pauseAutoSyncWhenLowBatteryCapacityLevel && batteryInfo.batteryCapacityLevel >= lowBatteryCapacityLevel) {
    promptAction.showToast({
      message: '电池电量低，自动暂停同步'
    })
    return false
  }
  if (pauseAutoSyncWhenPowerSave && (power.getPowerMode() === 600 || power.getPowerMode() === 603)) {
    let text = ''
    if (power.getPowerMode() === 603) {
      text = '超级'
    }
    promptAction.showToast({
      message: '系统开启' + text + '省电模式，暂停自动同步'
    })
    return false
  }
  const autoSyncTables: string[] = dataSettingDataPreferences.getSync('autoSyncTables', []) as string[]
  if (autoSyncTables.includes(table)) {
    const autoSyncDevices: Item[] = dataSettingDataPreferences.getSync('autoSyncDevices', []) as Item[]
    const promises = autoSyncDevices.map(async (item) => {
      await syncTable(table, item.deviceId, relationalStore.SyncMode.SYNC_MODE_PUSH)
    })
    await Promise.all(promises)
    return true
  } else {
    return false
  }
}

export async function backupTable(table: string): Promise<boolean> {
  const context = getContext() as common.UIAbilityContext
  let securityLevel = 4
  if (table === 'tag') {
    securityLevel = 1
  }
  try {
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: table,
      securityLevel: securityLevel,
      encrypt: true,
      allowRebuild: true
    })
    await rdbStore.backup(table + 'Backup.db')
    const dataSettingDataPreferences = preferences.getPreferencesSync(context, {
      name: 'dataSetting'
    })
    const isBackupTables: string[] = dataSettingDataPreferences.getSync('isBackupTables', []) as string[]
    dataSettingDataPreferences.putSync('isBackupTables', [...isBackupTables, table])
    dataSettingDataPreferences.flushSync()
    promptAction.showToast({
      message: '备份成功'
    })
    return true
  } catch (err) {
    promptAction.showToast({
      message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
      (err as BusinessError).message
    })
  }
  return false
}

export async function autoBackupTable(table: string): Promise<boolean> {
  const context = getContext() as common.UIAbilityContext
  const dataSettingDataPreferences = preferences.getPreferencesSync(context, {
    name: 'dataSetting'
  })
  const debugSettingDataPreferences = preferences.getPreferencesSync(context, {
    name: 'debugSetting'
  })
  const pauseAutoBackupWhenLowBatteryCapacityLevel: preferences.ValueType =
    dataSettingDataPreferences.getSync('pauseAutoBackupWhenLowBatteryCapacityLevel', false) as boolean
  const pauseAutoBackupWhenPowerSave: preferences.ValueType =
    dataSettingDataPreferences.getSync('pauseAutoBackupWhenPowerSave', false) as boolean
  const lowBatteryCapacityLevel: preferences.ValueType =
    debugSettingDataPreferences.getSync('lowBatteryCapacityLevel', 4) as number
  if (pauseAutoBackupWhenLowBatteryCapacityLevel && batteryInfo.batteryCapacityLevel >= lowBatteryCapacityLevel) {
    promptAction.showToast({
      message: '电池电量低，自动暂停同步'
    })
    return false
  }
  if (pauseAutoBackupWhenPowerSave && (power.getPowerMode() === 600 || power.getPowerMode() === 603)) {
    let text = ''
    if (power.getPowerMode() === 603) {
      text = '超级'
    }
    promptAction.showToast({
      message: '系统开启' + text + '省电模式，暂停自动备份'
    })
    return false
  }
  const autoBackupTables: string[] = dataSettingDataPreferences.getSync('autoBackupTables', []) as string[]
  if (autoBackupTables.includes(table)) {
    await backupTable(table)
    return true
  } else {
    return false
  }
}

export async function recoveryTable(table: string): Promise<boolean> {
  const context = getContext() as common.UIAbilityContext
  let securityLevel = 4
  if (table === 'tag') {
    securityLevel = 1
  }
  try {
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: table,
      securityLevel: securityLevel,
      encrypt: true,
      allowRebuild: true
    })
    await rdbStore.restore(table + 'Backup.db')
    promptAction.showToast({
      message: '恢复成功'
    })
    return true
  } catch (err) {
    promptAction.showToast({
      message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
      (err as BusinessError).message
    })
  }
  return false
}