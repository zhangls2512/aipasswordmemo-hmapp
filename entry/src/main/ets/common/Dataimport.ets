import { relationalStore } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { Info, Password, Tag } from './Dataget'
import { autoBackupTable, autoSyncTable } from './Table'

export async function importPassword(data: string, conflict: relationalStore.ConflictResolution) {
  try {
    const array = JSON.parse(data.replace(/[\r\n\s\u0000]/g, '')) as Password[]
    const context = getContext()
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'password',
      securityLevel: 4,
      encrypt: true,
      allowRebuild: true
    })
    array.forEach((item: Password) => {
      rdbStore.insertSync('password', {
        id: item.id,
        name: item.name,
        info: JSON.stringify(item.info),
        tag: JSON.stringify(item.tag),
        updateTime: item.updateTime,
        cloudBackupTime: item.cloudBackupTime
      }, conflict)
    })
    autoSyncTable('password')
    autoBackupTable('password')
  } catch (err) {
    promptAction.showToast({
      message: '发生错误，错误码：' + err.code
    })
  }
}

export async function importInfo(data: string, conflict: relationalStore.ConflictResolution) {
  try {
    const array = JSON.parse(data.replace(/[\r\n\s\u0000]/g, '')) as Info[]
    const context = getContext()
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'info',
      securityLevel: 4,
      encrypt: true,
      allowRebuild: true
    })
    array.forEach((item: Info) => {
      rdbStore.insertSync('info', {
        id: item.id,
        type: item.type,
        value: item.value,
        updateTime: item.updateTime,
        cloudBackupTime: item.cloudBackupTime
      }, conflict)
    })
    autoSyncTable('info')
    autoBackupTable('info')
  } catch (err) {
    promptAction.showToast({
      message: '发生错误，错误码：' + err.code
    })
  }
}

export async function importTag(data: string, conflict: relationalStore.ConflictResolution) {
  try {
    const array = JSON.parse(data.replace(/[\r\n\s\u0000]/g, '')) as Tag[]
    const context = getContext()
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'tag',
      securityLevel: 1,
      encrypt: true,
      allowRebuild: true
    })
    array.forEach((item: Tag) => {
      rdbStore.insertSync('tag', {
        id: item.id,
        value: item.value,
        color: item.color,
        updateTime: item.updateTime,
        cloudBackupTime: item.cloudBackupTime
      }, conflict)
    })
    autoSyncTable('tag')
    autoBackupTable('tag')
  } catch (err) {
    promptAction.showToast({
      message: '发生错误，错误码：' + err.code
    })
  }
}