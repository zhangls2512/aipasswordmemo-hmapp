import { relationalStore } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { getKeyAlg, EncryptData, decrypt } from './Crypto'
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

interface FileBackupObject {
  encrypted: boolean,
  data: EncryptData[]
}

async function getImportString(filestring: string) {
  if (filestring.startsWith('[')) {
    return filestring
  } else {
    try {
      const fileBackupObject = JSON.parse(filestring) as FileBackupObject
      if (!fileBackupObject.encrypted) {
        return JSON.stringify(fileBackupObject.data)
      } else {
        if (!getKeyAlg()) {
          await promptAction.openToast({
            message: '未导入密钥，无法解密加密数据'
          })
          return 'unabledecrypt'
        }
        const decryptedArray: object[] = []
        const promises = fileBackupObject.data.map(async (item: EncryptData) => {
          const res = await decrypt(item)
          decryptedArray.push(JSON.parse(res))
        })
        await Promise.all(promises)
        return JSON.stringify(decryptedArray)
      }
    } catch {
      return 'fail'
    }
  }
}

export async function importPassword(context: Context, data: string, conflict: relationalStore.ConflictResolution) {
  const importstring = await getImportString(data)
  if (importstring !== 'fail' && importstring !== 'unabledecrypt') {
    try {
      const array = JSON.parse(importstring) as PasswordInItem[]
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
      return 'success'
    } catch {
      await promptAction.openToast({
        message: '导入失败'
      })
      return 'fail'
    }
  } else {
    if (importstring === 'fail') {
      await promptAction.openToast({
        message: '导入失败'
      })
    }
    return 'fail'
  }
}

export async function importInfo(context: Context, data: string, conflict: relationalStore.ConflictResolution) {
  const importstring = await getImportString(data)
  if (importstring !== 'fail' && importstring !== 'unabledecrypt') {
    try {
      const array = JSON.parse(importstring) as InfoInItem[]
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
      return 'success'
    } catch {
      await promptAction.openToast({
        message: '导入失败'
      })
      return 'fail'
    }
  } else {
    if (importstring === 'fail') {
      await promptAction.openToast({
        message: '导入失败'
      })
    }
    return 'fail'
  }
}

export async function importTag(context: Context, data: string, conflict: relationalStore.ConflictResolution) {
  const importstring = await getImportString(data)
  if (importstring !== 'fail' && importstring !== 'unabledecrypt') {
    try {
      const array = JSON.parse(importstring) as TagInItem[]
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
      return 'success'
    } catch {
      await promptAction.openToast({
        message: '导入失败'
      })
      return 'fail'
    }
  } else {
    if (importstring === 'fail') {
      await promptAction.openToast({
        message: '导入失败'
      })
    }
    return 'fail'
  }
}