import { relationalStore } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { PasswordInfoItem } from './Dataget'
import { autoBackupTable, autoSyncTable } from './Table'

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
      securityLevel: 4,
      encrypt: true,
      allowRebuild: true
    })
    array.forEach(async (item: PasswordInItem) => {
      let cloudBackupTime = JSON.stringify([])
      if (typeof (item.cloudBackupTime) === 'string') {
        cloudBackupTime = item.cloudBackupTime
      }
      try {
        await rdbStore.insert('password', {
          id: item.id,
          name: item.name,
          info: JSON.stringify(item.info.filter(itema => itema.type !== '图标')),
          tag: JSON.stringify(item.tag),
          updateTime: item.updateTime,
          cloudBackupTime: cloudBackupTime
        }, conflict)
      } catch (err) {
        if (err.code !== 14800032) {
          await promptAction.openToast({
            message: '发生错误，错误码：' + err.code
          })
        }
        if (err.code === 14800032) {
          await promptAction.openToast({
            message: '导入失败，原因：已存在'
          })
        }
      }
    })
    await autoSyncTable(context, 'password')
    await autoBackupTable(context, 'password')
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
  }
}

export async function importInfo(context: Context, data: string, conflict: relationalStore.ConflictResolution) {
  try {
    const array = JSON.parse(data.replace(/[\r\n\s\u0000]/g, '')) as InfoInItem[]
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'info',
      securityLevel: 4,
      encrypt: true,
      allowRebuild: true
    })
    array.forEach(async (item: InfoInItem) => {
      if (item.type !== '图标') {
        let cloudBackupTime = JSON.stringify([])
        if (typeof (item.cloudBackupTime) === 'string') {
          cloudBackupTime = item.cloudBackupTime
        }
        try {
          await rdbStore.insert('info', {
            id: item.id,
            type: item.type,
            value: item.value,
            updateTime: item.updateTime,
            cloudBackupTime: cloudBackupTime
          }, conflict)
        } catch (err) {
          if (err.code !== 14800032) {
            await promptAction.openToast({
              message: '发生错误，错误码：' + err.code
            })
          }
          if (err.code === 14800032) {
            await promptAction.openToast({
              message: '导入失败，原因：已存在'
            })
          }
        }
      }
    })
    await autoSyncTable(context, 'info')
    await autoBackupTable(context, 'info')
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
  }
}

export async function importTag(context: Context, data: string, conflict: relationalStore.ConflictResolution) {
  try {
    const array = JSON.parse(data.replace(/[\r\n\s\u0000]/g, '')) as TagInItem[]
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'tag',
      securityLevel: 1,
      encrypt: true,
      allowRebuild: true
    })
    array.forEach(async (item: TagInItem) => {
      let cloudBackupTime = JSON.stringify([])
      if (typeof (item.cloudBackupTime) === 'string') {
        cloudBackupTime = item.cloudBackupTime
      }
      try {
        await rdbStore.insert('tag', {
          id: item.id,
          value: item.value,
          color: item.color,
          updateTime: item.updateTime,
          cloudBackupTime: cloudBackupTime
        }, conflict)
      } catch (err) {
        if (err.code !== 14800032) {
          await promptAction.openToast({
            message: '发生错误，错误码：' + err.code
          })
        }
        if (err.code === 14800032) {
          await promptAction.openToast({
            message: '导入失败，原因：已存在'
          })
        }
      }
    })
    await autoSyncTable(context, 'tag')
    await autoBackupTable(context, 'tag')
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
  }
}