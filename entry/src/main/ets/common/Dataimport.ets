import { relationalStore } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { PasswordInfoItem } from './Dataget'
import { autoBackupTable, autoHuaweiCloudSyncTable, autoSyncTable } from './Table'

export interface PasswordInItem {
  id: number,
  name: string,
  info: PasswordInfoItem[],
  tag: string[],
  updateTime: number,
  cloudBackupTime: string | number
}

export interface InfoInItem {
  id: number,
  type: string,
  value: string,
  updateTime: number,
  cloudBackupTime: string | number
}

export interface TagInItem {
  id: number,
  value: string,
  color: string,
  updateTime: number,
  cloudBackupTime: string | number
}

export async function importPassword(context: Context, data: string, conflict: relationalStore.ConflictResolution) {
  try {
    const array = JSON.parse(data.replace(/[\r\n\s\u0000]/g, '')) as PasswordInItem[]
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'password',
      securityLevel: relationalStore.SecurityLevel.S4,
      encrypt: true,
      allowRebuild: true
    })
    const huaweiCloudSyncRdbStore = await relationalStore.getRdbStore(context, {
      name: 'huaweicloudsync',
      securityLevel: relationalStore.SecurityLevel.S3,
      encrypt: true,
      allowRebuild: true
    })
    array.map(item => {
      let cloudBackupTime = JSON.stringify([])
      if (typeof (item.cloudBackupTime) === 'string') {
        cloudBackupTime = item.cloudBackupTime
      }
      rdbStore.insertSync('password', {
        id: item.id,
        name: item.name,
        info: JSON.stringify(item.info),
        tag: JSON.stringify(item.tag),
        updateTime: item.updateTime,
        cloudBackupTime: cloudBackupTime
      }, conflict)
      huaweiCloudSyncRdbStore.insertSync('password', {
        id: String(item.id),
        name: item.name,
        info: JSON.stringify(item.info),
        tag: JSON.stringify(item.tag),
        updateTime: item.updateTime,
        cloudBackupTime: cloudBackupTime
      }, conflict)
    })
    await autoSyncTable(context, 'password')
    await autoBackupTable(context, 'password')
    await autoHuaweiCloudSyncTable(context, 'password')
  } catch {
    await promptAction.openToast({
      message: '导入失败'
    })
  }
}

export async function importInfo(context: Context, data: string, conflict: relationalStore.ConflictResolution) {
  try {
    const array = JSON.parse(data.replace(/[\r\n\s\u0000]/g, '')) as InfoInItem[]
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'info',
      securityLevel: relationalStore.SecurityLevel.S4,
      encrypt: true,
      allowRebuild: true
    })
    const huaweiCloudSyncRdbStore = await relationalStore.getRdbStore(context, {
      name: 'huaweicloudsync',
      securityLevel: relationalStore.SecurityLevel.S3,
      encrypt: true,
      allowRebuild: true
    })
    array.map(item => {
      let cloudBackupTime = JSON.stringify([])
      if (typeof (item.cloudBackupTime) === 'string') {
        cloudBackupTime = item.cloudBackupTime
      }
      rdbStore.insertSync('info', {
        id: item.id,
        type: item.type,
        value: item.value,
        updateTime: item.updateTime,
        cloudBackupTime: cloudBackupTime
      }, conflict)
      huaweiCloudSyncRdbStore.insertSync('info', {
        id: String(item.id),
        type: item.type,
        value: item.value,
        updateTime: item.updateTime,
        cloudBackupTime: cloudBackupTime
      }, conflict)
    })
    await autoSyncTable(context, 'info')
    await autoBackupTable(context, 'info')
    await autoHuaweiCloudSyncTable(context, 'info')
  } catch {
    await promptAction.openToast({
      message: '导入失败'
    })
  }
}

export async function importTag(context: Context, data: string, conflict: relationalStore.ConflictResolution) {
  try {
    const array = JSON.parse(data.replace(/[\r\n\s\u0000]/g, '')) as TagInItem[]
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'tag',
      securityLevel: relationalStore.SecurityLevel.S1,
      encrypt: true,
      allowRebuild: true
    })
    const huaweiCloudSyncRdbStore = await relationalStore.getRdbStore(context, {
      name: 'huaweicloudsync',
      securityLevel: relationalStore.SecurityLevel.S3,
      encrypt: true,
      allowRebuild: true
    })
    array.map(item => {
      let cloudBackupTime = JSON.stringify([])
      if (typeof (item.cloudBackupTime) === 'string') {
        cloudBackupTime = item.cloudBackupTime
      }
      rdbStore.insertSync('tag', {
        id: item.id,
        value: item.value,
        color: item.color,
        updateTime: item.updateTime,
        cloudBackupTime: cloudBackupTime
      }, conflict)
      huaweiCloudSyncRdbStore.insertSync('tag', {
        id: String(item.id),
        value: item.value,
        color: item.color,
        updateTime: item.updateTime,
        cloudBackupTime: cloudBackupTime
      }, conflict)
    })
    await autoSyncTable(context, 'tag')
    await autoBackupTable(context, 'tag')
    await autoHuaweiCloudSyncTable(context, 'tag')
  } catch {
    await promptAction.openToast({
      message: '导入失败'
    })
  }
}