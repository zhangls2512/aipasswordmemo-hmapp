import { common } from '@kit.AbilityKit'
import { relationalStore } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { BusinessError } from '@kit.BasicServicesKit'
import { get } from './Accesstoken'
import { encrypt, EncryptData, getKey } from './Crypto'
import request from './Request'
import { autoBackupTable, autoSyncTable } from './Table'

interface PasswordInfoItem {
  type: string,
  value: string
}

interface PasswordInput {
  name: string,
  info: PasswordInfoItem[],
  tag: string[],
  cloudBackup: boolean
}

interface InfoInput {
  type: string,
  value: string,
  cloudBackup: boolean
}

interface TagInput {
  value: string,
  color: string,
  cloudBackup: boolean
}

interface CloudBackupItem {
  type: string,
  id: number,
  content?: string
}

export async function newPassword(data: PasswordInput): Promise<string | number> {
  const context = getContext() as common.UIAbilityContext
  try {
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'password',
      securityLevel: 4,
      encrypt: true,
      allowRebuild: true
    })
    const updateTime = Date.now()
    const rowId = rdbStore.insertSync('password', {
      name: data.name,
      info: JSON.stringify(data.info),
      tag: JSON.stringify(data.tag),
      updateTime: updateTime,
      cloudBackupTime: 0
    })
    promptAction.showToast({
      message: '新增成功'
    })
    autoSyncTable('password')
    autoBackupTable('password')
    if (data.cloudBackup) {
      setCloudBackup({
        type: 'password',
        id: rowId,
        content: JSON.stringify({
          name: data.name,
          info: JSON.stringify(data.info),
          tag: JSON.stringify(data.tag),
          updateTime: updateTime,
          cloudBackupTime: updateTime
        })
      })
    }
    return rowId
  } catch (err) {
    promptAction.showToast({
      message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
      (err as BusinessError).message
    })
    return 'fail'
  }
}

export async function updatePassword(rowId: number, data: PasswordInput): Promise<boolean> {
  const context = getContext() as common.UIAbilityContext
  try {
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'password',
      securityLevel: 4,
      encrypt: true,
      allowRebuild: true
    })
    const predicates = new relationalStore.RdbPredicates('password')
    predicates.equalTo('rowId', rowId)
    const updateTime = Date.now()
    rdbStore.updateSync({
      name: data.name,
      info: JSON.stringify(data.info),
      tag: JSON.stringify(data.tag),
      updateTime: updateTime
    }, predicates)
    promptAction.showToast({
      message: '修改成功'
    })
    autoSyncTable('password')
    autoBackupTable('password')
    if (data.cloudBackup) {
      setCloudBackup({
        type: 'password',
        id: rowId,
        content: JSON.stringify({
          name: data.name,
          info: JSON.stringify(data.info),
          tag: JSON.stringify(data.tag),
          updateTime: updateTime,
          cloudBackupTime: updateTime
        })
      })
    }
    return true
  } catch (err) {
    promptAction.showToast({
      message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
      (err as BusinessError).message
    })
    return false
  }
}

export async function newInfo(data: InfoInput): Promise<string | number> {
  const context = getContext() as common.UIAbilityContext
  try {
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'info',
      securityLevel: 4,
      encrypt: true,
      allowRebuild: true
    })
    const updateTime = Date.now()
    const rowId = rdbStore.insertSync('info', {
      type: data.type,
      value: data.value,
      updateTime: updateTime,
      cloudBackupTime: 0
    })
    promptAction.showToast({
      message: '新增成功'
    })
    autoSyncTable('info')
    autoBackupTable('info')
    if (data.cloudBackup) {
      setCloudBackup({
        type: 'info',
        id: rowId,
        content: JSON.stringify({
          type: data.type,
          value: data.value,
          updateTime: updateTime,
          cloudBackupTime: updateTime
        })
      })
    }
    return rowId
  } catch (err) {
    promptAction.showToast({
      message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
      (err as BusinessError).message
    })
    return 'fail'
  }
}

export async function updateInfo(rowId: number, data: InfoInput): Promise<boolean> {
  const context = getContext() as common.UIAbilityContext
  try {
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'info',
      securityLevel: 4,
      encrypt: true,
      allowRebuild: true
    })
    const predicates = new relationalStore.RdbPredicates('info')
    predicates.equalTo('rowId', rowId)
    const updateTime = Date.now()
    rdbStore.updateSync({
      type: data.type,
      value: data.value,
      updateTime: updateTime
    }, predicates)
    promptAction.showToast({
      message: '修改成功'
    })
    autoSyncTable('info')
    autoBackupTable('info')
    if (data.cloudBackup) {
      setCloudBackup({
        type: 'info',
        id: rowId,
        content: JSON.stringify({
          type: data.type,
          value: data.value,
          updateTime: updateTime,
          cloudBackupTime: updateTime
        })
      })
    }
    return true
  } catch (err) {
    promptAction.showToast({
      message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
      (err as BusinessError).message
    })
    return false
  }
}

export async function newTag(data: TagInput): Promise<string | number> {
  const context = getContext() as common.UIAbilityContext
  try {
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'tag',
      securityLevel: 1,
      encrypt: true,
      allowRebuild: true
    })
    const updateTime = Date.now()
    const rowId = rdbStore.insertSync('tag', {
      value: data.value,
      color: data.color,
      updateTime: updateTime,
      cloudBackupTime: 0
    })
    promptAction.showToast({
      message: '新增成功'
    })
    autoSyncTable('tag')
    autoBackupTable('tag')
    if (data.cloudBackup) {
      setCloudBackup({
        type: 'tag',
        id: rowId,
        content: JSON.stringify({
          value: data.value,
          color: data.color,
          updateTime: updateTime,
          cloudBackupTime: updateTime
        })
      })
    }
    return rowId
  } catch (err) {
    promptAction.showToast({
      message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
      (err as BusinessError).message
    })
    return 'fail'
  }
}

export async function updateTag(rowId: number, data: TagInput): Promise<boolean> {
  const context = getContext() as common.UIAbilityContext
  try {
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'tag',
      securityLevel: 1,
      encrypt: true,
      allowRebuild: true
    })
    const predicates = new relationalStore.RdbPredicates('tag')
    predicates.equalTo('rowId', rowId)
    const updateTime = Date.now()
    rdbStore.updateSync({
      value: data.value,
      color: data.color,
      updateTime: updateTime
    }, predicates)
    promptAction.showToast({
      message: '修改成功'
    })
    autoSyncTable('tag')
    autoBackupTable('tag')
    if (data.cloudBackup) {
      setCloudBackup({
        type: 'tag',
        id: rowId,
        content: JSON.stringify({
          value: data.value,
          color: data.color,
          updateTime: updateTime,
          cloudBackupTime: updateTime
        })
      })
    }
    return true
  } catch (err) {
    promptAction.showToast({
      message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
      (err as BusinessError).message
    })
    return false
  }
}

export async function deleteData(type: string, rowId: number, deletecloudbackup: boolean = false): Promise<boolean> {
  const context = getContext() as common.UIAbilityContext
  let securityLevel = 4
  if (type === 'tag') {
    securityLevel = 1
  }
  try {
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: type,
      securityLevel: securityLevel,
      encrypt: true,
      allowRebuild: true
    })
    const predicates = new relationalStore.RdbPredicates(type)
    predicates.equalTo('rowId', rowId)
    rdbStore.deleteSync(predicates)
    promptAction.showToast({
      message: '删除成功'
    })
    autoSyncTable(type)
    autoBackupTable(type)
    if (deletecloudbackup) {
      deleteCloudBackup({
        type: type,
        id: rowId
      })
    }
    return true
  } catch (err) {
    promptAction.showToast({
      message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
      (err as BusinessError).message
    })
    return false
  }
}

export async function setCloudBackup(data: CloudBackupItem): Promise<boolean> {
  const key = getKey()
  if (!key) {
    promptAction.showDialog({
      title: '云备份失败',
      message: '未导入密钥。请前往“我的”>“设置”>“密钥”导入密钥',
      buttons: [
        {
          text: '确定',
          color: $r('sys.color.font_emphasize')
        }
      ]
    })
    return false
  }
  let content = data.content as string
  const encryptres = await encrypt(content)
  if (encryptres !== 'fail') {
    content = (encryptres as EncryptData).content
    const res = await request('/password/setBackup', {
      accessToken: get(),
      type: data.type,
      id: data.id,
      content: content,
      iv: (encryptres as EncryptData).iv
    })
    if (res !== 'fail') {
      const context = getContext() as common.UIAbilityContext
      let securityLevel = 4
      if (data.type === 'tag') {
        securityLevel = 1
      }
      try {
        const rdbStore = await relationalStore.getRdbStore(context, {
          name: data.type,
          securityLevel: securityLevel,
          encrypt: true,
          allowRebuild: true
        })
        const predicates = new relationalStore.RdbPredicates(data.type)
        predicates.equalTo('rowId', data.id)
        rdbStore.updateSync({
          cloudBackupTime: Date.now()
        }, predicates)
        promptAction.showToast({
          message: '云备份成功'
        })
        return true
      } catch (err) {
        promptAction.showToast({
          message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
          (err as BusinessError).message
        })
        return false
      }
    }
    return false
  }
  return false
}

export async function deleteCloudBackup(data: CloudBackupItem): Promise<boolean> {
  const res = await request('/password/deleteBackup', {
    accessToken: get(),
    type: data.type,
    id: data.id
  })
  if (res !== 'fail') {
    promptAction.showToast({
      message: '删除云备份成功'
    })
    return true
  }
  return false
}