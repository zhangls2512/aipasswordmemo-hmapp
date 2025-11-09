import { preferences, relationalStore } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { batteryInfo, power } from '@kit.BasicServicesKit'

interface Item {
  deviceId: string,
  deviceName: string,
  deviceType: string,
  networkId: string
}

export async function syncTable(table: string, networkId: string, syncMode: relationalStore.SyncMode) {
  const context = getContext()
  let securityLevel = 4
  if (table === 'tag') {
    securityLevel = 1
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
      promptAction.openToast({
        message: '同步失败，设备 ID：' + res[0][0] + '，错误码：' + res[0][1]
      })
    }
    if (res[0][1] === 0) {
      promptAction.openToast({
        message: '同步成功，设备 ID：' + res[0][0]
      })
    }
  } catch (err) {
    promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
  }
}

export async function autoSyncTable(table: string) {
  const context = getContext()
  const dataSettingDataPreferences = preferences.getPreferencesSync(context, {
    name: 'dataSetting'
  })
  const debugSettingDataPreferences = preferences.getPreferencesSync(context, {
    name: 'debugSetting'
  })
  const pauseAutoSyncWhenLowBatteryCapacityLevel =
    dataSettingDataPreferences.getSync('pauseAutoSyncWhenLowBatteryCapacityLevel', false)
  const pauseAutoSyncWhenPowerSave = dataSettingDataPreferences.getSync('pauseAutoSyncWhenPowerSave', false)
  const lowBatteryCapacityLevel = debugSettingDataPreferences.getSync('lowBatteryCapacityLevel', 4)
  if (pauseAutoSyncWhenLowBatteryCapacityLevel && batteryInfo.batteryCapacityLevel >= lowBatteryCapacityLevel) {
    promptAction.openToast({
      message: '电池电量低，自动暂停同步'
    })
    return
  }
  const currentPowerMode = power.getPowerMode()
  if (pauseAutoSyncWhenPowerSave && currentPowerMode !== power.DevicePowerMode.MODE_NORMAL &&
    currentPowerMode !== power.DevicePowerMode.MODE_PERFORMANCE) {
    let text = ''
    if (power.getPowerMode() === 603) {
      text = '超级'
    }
    promptAction.openToast({
      message: '系统开启' + text + '省电模式，暂停自动同步'
    })
    return
  }
  const autoSyncTables: string[] = dataSettingDataPreferences.getSync('autoSyncTables', []) as string[]
  if (autoSyncTables.includes(table)) {
    const autoSyncDevices: Item[] = dataSettingDataPreferences.getSync('autoSyncDevices', []) as Item[]
    const promises = autoSyncDevices.map(async (item) => {
      await syncTable(table, item.networkId, relationalStore.SyncMode.SYNC_MODE_PUSH)
    })
    await Promise.all(promises)
  }
}

export async function backupTable(table: string) {
  const context = getContext()
  let securityLevel = 4
  if (table === 'tag') {
    securityLevel = 1
  }
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
  dataSettingDataPreferences.putSync('isBackupTables', Array.from(new Set([...isBackupTables, table])))
  dataSettingDataPreferences.flushSync()
  promptAction.openToast({
    message: '备份成功'
  })
}

export async function autoBackupTable(table: string) {
  const context = getContext()
  const dataSettingDataPreferences = preferences.getPreferencesSync(context, {
    name: 'dataSetting'
  })
  const debugSettingDataPreferences = preferences.getPreferencesSync(context, {
    name: 'debugSetting'
  })
  const pauseAutoBackupWhenLowBatteryCapacityLevel =
    dataSettingDataPreferences.getSync('pauseAutoBackupWhenLowBatteryCapacityLevel', false)
  const pauseAutoBackupWhenPowerSave = dataSettingDataPreferences.getSync('pauseAutoBackupWhenPowerSave', false)
  const lowBatteryCapacityLevel = debugSettingDataPreferences.getSync('lowBatteryCapacityLevel', 4)
  if (pauseAutoBackupWhenLowBatteryCapacityLevel && batteryInfo.batteryCapacityLevel >= lowBatteryCapacityLevel) {
    promptAction.openToast({
      message: '电池电量低，自动暂停同步'
    })
    return
  }
  const currentPowerMode = power.getPowerMode()
  if (pauseAutoBackupWhenPowerSave && currentPowerMode !== power.DevicePowerMode.MODE_NORMAL &&
    currentPowerMode !== power.DevicePowerMode.MODE_PERFORMANCE) {
    let text = ''
    if (power.getPowerMode() === 603) {
      text = '超级'
    }
    promptAction.openToast({
      message: '系统开启' + text + '省电模式，暂停自动备份'
    })
    return
  }
  const autoBackupTables: string[] = dataSettingDataPreferences.getSync('autoBackupTables', []) as string[]
  if (autoBackupTables.includes(table)) {
    await backupTable(table)
  }
}

export async function recoveryTable(table: string) {
  const context = getContext()
  let securityLevel = 4
  if (table === 'tag') {
    securityLevel = 1
  }
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: table,
    securityLevel: securityLevel,
    encrypt: true,
    allowRebuild: true
  })
  await rdbStore.restore(table + 'Backup.db')
  promptAction.openToast({
    message: '恢复成功'
  })
}