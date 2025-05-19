import { relationalStore } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { get } from './Accesstoken'
import { encrypt } from './Crypto'
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

export async function newPassword(data: PasswordInput) {
  const context = getContext()
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'password',
    securityLevel: 4,
    encrypt: true,
    allowRebuild: true
  })
  const updateTime = Date.now()
  const id = rdbStore.insertSync('password', {
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
      id: id,
      content: JSON.stringify({
        name: data.name,
        info: JSON.stringify(data.info),
        tag: JSON.stringify(data.tag),
        updateTime: updateTime,
        cloudBackupTime: updateTime
      })
    })
  }
}

export async function updatePassword(id: number, data: PasswordInput) {
  const context = getContext()
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'password',
    securityLevel: 4,
    encrypt: true,
    allowRebuild: true
  })
  const predicates = new relationalStore.RdbPredicates('password')
  predicates.equalTo('id', id)
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
      id: id,
      content: JSON.stringify({
        name: data.name,
        info: JSON.stringify(data.info),
        tag: JSON.stringify(data.tag),
        updateTime: updateTime,
        cloudBackupTime: updateTime
      })
    })
  }
}

export async function newInfo(data: InfoInput) {
  const context = getContext()
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'info',
    securityLevel: 4,
    encrypt: true,
    allowRebuild: true
  })
  const predicates = new relationalStore.RdbPredicates('info')
  predicates.equalTo('type', data.type)
  predicates.equalTo('value', data.value)
  const resultSet = await rdbStore.query(predicates)
  if (resultSet.goToNextRow()) {
    promptAction.showToast({
      message: '新增失败：已存在'
    })
    resultSet.close()
    throw new Error('fail')
  }
  const updateTime = Date.now()
  const id = rdbStore.insertSync('info', {
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
      id: id,
      content: JSON.stringify({
        type: data.type,
        value: data.value,
        updateTime: updateTime,
        cloudBackupTime: updateTime
      })
    })
  }
}

export async function updateInfo(id: number, data: InfoInput) {
  const context = getContext()
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'info',
    securityLevel: 4,
    encrypt: true,
    allowRebuild: true
  })
  const predicatesa = new relationalStore.RdbPredicates('info')
  predicatesa.equalTo('type', data.type)
  predicatesa.equalTo('value', data.value)
  const resultSet = await rdbStore.query(predicatesa)
  if (resultSet.goToNextRow()) {
    promptAction.showToast({
      message: '修改失败：已存在'
    })
    resultSet.close()
    throw new Error('fail')
  }
  const predicatesb = new relationalStore.RdbPredicates('info')
  predicatesb.equalTo('id', id)
  const updateTime = Date.now()
  rdbStore.updateSync({
    type: data.type,
    value: data.value,
    updateTime: updateTime
  }, predicatesb)
  promptAction.showToast({
    message: '修改成功'
  })
  autoSyncTable('info')
  autoBackupTable('info')
  if (data.cloudBackup) {
    setCloudBackup({
      type: 'info',
      id: id,
      content: JSON.stringify({
        type: data.type,
        value: data.value,
        updateTime: updateTime,
        cloudBackupTime: updateTime
      })
    })
  }
}

export async function newTag(data: TagInput) {
  const context = getContext()
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'tag',
    securityLevel: 1,
    encrypt: true,
    allowRebuild: true
  })
  const predicates = new relationalStore.RdbPredicates('tag')
  predicates.equalTo('value', data.value)
  const resultSet = await rdbStore.query(predicates)
  if (resultSet.goToNextRow()) {
    promptAction.showToast({
      message: '新增失败：已存在'
    })
    resultSet.close()
    throw new Error('fail')
  }
  const updateTime = Date.now()
  const id = rdbStore.insertSync('tag', {
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
      id: id,
      content: JSON.stringify({
        value: data.value,
        color: data.color,
        updateTime: updateTime,
        cloudBackupTime: updateTime
      })
    })
  }
}

export async function updateTag(id: number, data: TagInput) {
  const context = getContext()
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'tag',
    securityLevel: 1,
    encrypt: true,
    allowRebuild: true
  })
  const predicatesa = new relationalStore.RdbPredicates('tag')
  predicatesa.equalTo('value', data.value)
  const resultSet = await rdbStore.query(predicatesa)
  const colorIndex = resultSet.getColumnIndex('color')
  if (resultSet.goToNextRow() && resultSet.getValue(colorIndex) as string === data.color) {
    promptAction.showToast({
      message: '修改失败：已存在'
    })
    resultSet.close()
    throw new Error('fail')
  }
  const predicatesb = new relationalStore.RdbPredicates('tag')
  predicatesb.equalTo('id', id)
  const updateTime = Date.now()
  rdbStore.updateSync({
    value: data.value,
    color: data.color,
    updateTime: updateTime
  }, predicatesb)
  promptAction.showToast({
    message: '修改成功'
  })
  autoSyncTable('tag')
  autoBackupTable('tag')
  if (data.cloudBackup) {
    setCloudBackup({
      type: 'tag',
      id: id,
      content: JSON.stringify({
        value: data.value,
        color: data.color,
        updateTime: updateTime,
        cloudBackupTime: updateTime
      })
    })
  }
}

export async function deleteData(type: string, id: number) {
  const context = getContext()
  let securityLevel = 4
  if (type === 'tag') {
    securityLevel = 1
  }
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: type,
    securityLevel: securityLevel,
    encrypt: true,
    allowRebuild: true
  })
  const predicates = new relationalStore.RdbPredicates(type)
  predicates.equalTo('id', id)
  rdbStore.deleteSync(predicates)
  promptAction.showToast({
    message: '删除成功'
  })
  autoSyncTable(type)
  autoBackupTable(type)
}

export async function setCloudBackup(data: CloudBackupItem) {
  let content = data.content as string
  const encryptres = await encrypt(content)
  const encryptData = encryptres
  const res = await request('/password/setBackup', {
    accessToken: get(),
    type: data.type,
    id: data.id,
    content: encryptData.content,
    iv: encryptData.iv
  })
  if (res !== 'fail') {
    const context = getContext()
    let securityLevel = 4
    if (data.type === 'tag') {
      securityLevel = 1
    }
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: data.type,
      securityLevel: securityLevel,
      encrypt: true,
      allowRebuild: true
    })
    const predicates = new relationalStore.RdbPredicates(data.type)
    predicates.equalTo('id', data.id)
    rdbStore.updateSync({
      cloudBackupTime: Date.now()
    }, predicates)
    promptAction.showToast({
      message: '云备份成功'
    })
  }
}

export async function deleteCloudBackup(data: CloudBackupItem) {
  const res = await request('/password/deleteBackup', {
    accessToken: get(),
    type: data.type,
    id: data.id
  })
  if (res !== 'fail') {
    const context = getContext()
    let securityLevel = 4
    if (data.type === 'tag') {
      securityLevel = 1
    }
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: data.type,
      securityLevel: securityLevel,
      encrypt: true,
      allowRebuild: true
    })
    const predicates = new relationalStore.RdbPredicates(data.type)
    predicates.equalTo('id', data.id)
    rdbStore.updateSync({
      cloudBackupTime: 0
    }, predicates)
    promptAction.showToast({
      message: '删除云备份成功'
    })
  }
}