import { relationalStore } from '@kit.ArkData'
import { PasswordInfoItem } from './Dataget'
import { autoBackupTable, autoSyncTable } from './Table'
import promptAction from '@ohos.promptAction'

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

export async function importPassword(data: string, conflict: relationalStore.ConflictResolution) {
  try {
    const array = JSON.parse(data.replace(/[\r\n\s\u0000]/g, '')) as PasswordInItem[]
    const context = getContext()
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'password',
      securityLevel: 4,
      encrypt: true,
      allowRebuild: true
    })
    array.forEach((item: PasswordInItem) => {
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
    })
    autoSyncTable('password')
    autoBackupTable('password')
  } catch {
    promptAction.showToast({
      message: '发生错误'
    })
  }
}

export async function importInfo(data: string, conflict: relationalStore.ConflictResolution) {
  try {
    const array = JSON.parse(data.replace(/[\r\n\s\u0000]/g, '')) as InfoInItem[]
    const context = getContext()
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'info',
      securityLevel: 4,
      encrypt: true,
      allowRebuild: true
    })
    array.forEach((item: InfoInItem) => {
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
    })
    autoSyncTable('info')
    autoBackupTable('info')
  } catch {
    promptAction.showToast({
      message: '发生错误'
    })
  }
}

export async function importTag(data: string, conflict: relationalStore.ConflictResolution) {
  try {
    const array = JSON.parse(data.replace(/[\r\n\s\u0000]/g, '')) as TagInItem[]
    const context = getContext()
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'tag',
      securityLevel: 1,
      encrypt: true,
      allowRebuild: true
    })
    array.forEach((item: TagInItem) => {
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
    })
    autoSyncTable('tag')
    autoBackupTable('tag')
  } catch {
    promptAction.showToast({
      message: '发生错误'
    })
  }
}