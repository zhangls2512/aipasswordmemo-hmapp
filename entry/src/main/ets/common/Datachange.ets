import { relationalStore } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { get, getAccountInfo } from './Accesstoken'
import { encrypt } from './Crypto'
import { CloudBackupTimeItem } from './Dataget'
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
    cloudBackupTime: JSON.stringify([])
  })
  promptAction.openToast({
    message: '新增成功'
  })
  autoSyncTable('password')
  autoBackupTable('password')
  if (data.cloudBackup) {
    const accountInfo = await getAccountInfo()
    const cloudBackupTime: CloudBackupTimeItem[] = [{
      uid: accountInfo.uid,
      time: updateTime
    }]
    setCloudBackup({
      type: 'password',
      id: id,
      content: JSON.stringify({
        name: data.name,
        info: JSON.stringify(data.info),
        tag: JSON.stringify(data.tag),
        updateTime: updateTime,
        cloudBackupTime: JSON.stringify(cloudBackupTime)
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
  const resultSet = await rdbStore.query(predicates)
  let cloudBackupTime = JSON.stringify([])
  if (resultSet.goToNextRow()) {
    const oldCloudBackupTime = resultSet.getValue(resultSet.getColumnIndex('cloudBackupTime')) as string | number
    resultSet.close()
    if (typeof (oldCloudBackupTime) === 'string') {
      cloudBackupTime = oldCloudBackupTime
    }
  }
  rdbStore.updateSync({
    name: data.name,
    info: JSON.stringify(data.info),
    tag: JSON.stringify(data.tag),
    updateTime: updateTime,
    cloudBackupTime: cloudBackupTime
  }, predicates)
  promptAction.openToast({
    message: '修改成功'
  })
  autoSyncTable('password')
  autoBackupTable('password')
  if (data.cloudBackup) {
    const cloudBackupTimeArray = JSON.parse(cloudBackupTime) as CloudBackupTimeItem[]
    const accountInfo = await getAccountInfo()
    const cloudBackupTimeIndex = cloudBackupTimeArray.findIndex(item => item.uid === accountInfo.uid)
    if (cloudBackupTimeIndex !== -1) {
      cloudBackupTimeArray[cloudBackupTimeIndex].time = Date.now()
    }
    if (cloudBackupTimeIndex === -1) {
      cloudBackupTimeArray.push({
        uid: accountInfo.uid,
        time: Date.now()
      })
    }
    setCloudBackup({
      type: 'password',
      id: id,
      content: JSON.stringify({
        name: data.name,
        info: JSON.stringify(data.info),
        tag: JSON.stringify(data.tag),
        updateTime: updateTime,
        cloudBackupTime: JSON.stringify(cloudBackupTimeArray)
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
    resultSet.close()
    promptAction.openToast({
      message: '新增失败：已存在'
    })
    return 'fail'
  }
  resultSet.close()
  const updateTime = Date.now()
  const id = rdbStore.insertSync('info', {
    type: data.type,
    value: data.value,
    updateTime: updateTime,
    cloudBackupTime: JSON.stringify([])
  })
  promptAction.openToast({
    message: '新增成功'
  })
  autoSyncTable('info')
  autoBackupTable('info')
  if (data.cloudBackup) {
    const accountInfo = await getAccountInfo()
    const cloudBackupTime: CloudBackupTimeItem[] = [{
      uid: accountInfo.uid,
      time: updateTime
    }]
    setCloudBackup({
      type: 'info',
      id: id,
      content: JSON.stringify({
        type: data.type,
        value: data.value,
        updateTime: updateTime,
        cloudBackupTime: JSON.stringify(cloudBackupTime)
      })
    })
  }
  return 'success'
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
  const resultSeta = await rdbStore.query(predicatesa)
  if (resultSeta.goToNextRow()) {
    resultSeta.close()
    promptAction.openToast({
      message: '修改失败：已存在'
    })
    return 'fail'
  }
  resultSeta.close()
  const predicatesb = new relationalStore.RdbPredicates('info')
  predicatesb.equalTo('id', id)
  const updateTime = Date.now()
  const resultSetb = await rdbStore.query(predicatesb)
  let cloudBackupTime = JSON.stringify([])
  if (resultSetb.goToNextRow()) {
    const oldCloudBackupTime = resultSetb.getValue(resultSetb.getColumnIndex('cloudBackupTime')) as string | number
    resultSetb.close()
    if (typeof (oldCloudBackupTime) === 'string') {
      cloudBackupTime = oldCloudBackupTime
    }
  }
  rdbStore.updateSync({
    type: data.type,
    value: data.value,
    updateTime: updateTime,
    cloudBackupTime: cloudBackupTime
  }, predicatesb)
  promptAction.openToast({
    message: '修改成功'
  })
  autoSyncTable('info')
  autoBackupTable('info')
  if (data.cloudBackup) {
    const cloudBackupTimeArray = JSON.parse(cloudBackupTime) as CloudBackupTimeItem[]
    const accountInfo = await getAccountInfo()
    const cloudBackupTimeIndex = cloudBackupTimeArray.findIndex(item => item.uid === accountInfo.uid)
    if (cloudBackupTimeIndex !== -1) {
      cloudBackupTimeArray[cloudBackupTimeIndex].time = Date.now()
    }
    if (cloudBackupTimeIndex === -1) {
      cloudBackupTimeArray.push({
        uid: accountInfo.uid,
        time: Date.now()
      })
    }
    setCloudBackup({
      type: 'info',
      id: id,
      content: JSON.stringify({
        type: data.type,
        value: data.value,
        updateTime: updateTime,
        cloudBackupTime: JSON.stringify(cloudBackupTimeArray)
      })
    })
  }
  return 'success'
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
    resultSet.close()
    promptAction.openToast({
      message: '新增失败：已存在'
    })
    return 'fail'
  }
  resultSet.close()
  const updateTime = Date.now()
  const id = rdbStore.insertSync('tag', {
    value: data.value,
    color: data.color,
    updateTime: updateTime,
    cloudBackupTime: JSON.stringify([])
  })
  promptAction.openToast({
    message: '新增成功'
  })
  autoSyncTable('tag')
  autoBackupTable('tag')
  if (data.cloudBackup) {
    const accountInfo = await getAccountInfo()
    const cloudBackupTime: CloudBackupTimeItem[] = [{
      uid: accountInfo.uid,
      time: updateTime
    }]
    setCloudBackup({
      type: 'tag',
      id: id,
      content: JSON.stringify({
        value: data.value,
        color: data.color,
        updateTime: updateTime,
        cloudBackupTime: JSON.stringify(cloudBackupTime)
      })
    })
  }
  return 'success'
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
  const resultSeta = await rdbStore.query(predicatesa)
  const colorIndex = resultSeta.getColumnIndex('color')
  if (resultSeta.goToNextRow() && resultSeta.getValue(colorIndex) as string === data.color) {
    resultSeta.close()
    promptAction.openToast({
      message: '修改失败：已存在'
    })
    return 'fail'
  }
  resultSeta.close()
  const predicatesb = new relationalStore.RdbPredicates('tag')
  predicatesb.equalTo('id', id)
  const updateTime = Date.now()
  const resultSetb = await rdbStore.query(predicatesb)
  let cloudBackupTime = JSON.stringify([])
  if (resultSetb.goToNextRow()) {
    const oldCloudBackupTime = resultSetb.getValue(resultSetb.getColumnIndex('cloudBackupTime')) as string | number
    resultSetb.close()
    if (typeof (oldCloudBackupTime) === 'string') {
      cloudBackupTime = oldCloudBackupTime
    }
  }
  rdbStore.updateSync({
    value: data.value,
    color: data.color,
    updateTime: updateTime,
    cloudBackupTime: cloudBackupTime
  }, predicatesb)
  promptAction.openToast({
    message: '修改成功'
  })
  autoSyncTable('tag')
  autoBackupTable('tag')
  if (data.cloudBackup) {
    const cloudBackupTimeArray = JSON.parse(cloudBackupTime) as CloudBackupTimeItem[]
    const accountInfo = await getAccountInfo()
    const cloudBackupTimeIndex = cloudBackupTimeArray.findIndex(item => item.uid === accountInfo.uid)
    if (cloudBackupTimeIndex !== -1) {
      cloudBackupTimeArray[cloudBackupTimeIndex].time = Date.now()
    }
    if (cloudBackupTimeIndex === -1) {
      cloudBackupTimeArray.push({
        uid: accountInfo.uid,
        time: Date.now()
      })
    }
    setCloudBackup({
      type: 'tag',
      id: id,
      content: JSON.stringify({
        value: data.value,
        color: data.color,
        updateTime: updateTime,
        cloudBackupTime: JSON.stringify(cloudBackupTimeArray)
      })
    })
  }
  return 'success'
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
  promptAction.openToast({
    message: '删除成功'
  })
  autoSyncTable(type)
  autoBackupTable(type)
}

export async function setCloudBackup(data: CloudBackupItem) {
  const content = data.content as string
  const encryptres = await encrypt(content)
  const accessToken = await get()
  const accountInfo = await getAccountInfo()
  if (accessToken) {
    const res = await request('/password/setBackup', {
      accessToken: accessToken,
      type: data.type,
      id: data.id,
      content: encryptres.content,
      iv: encryptres.iv
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
      const resultSet = await rdbStore.query(predicates)
      let cloudBackupTime: CloudBackupTimeItem[] = []
      if (resultSet.goToNextRow()) {
        const oldCloudBackupTime = resultSet.getValue(resultSet.getColumnIndex('cloudBackupTime')) as string | number
        resultSet.close()
        if (typeof (oldCloudBackupTime) === 'number') {
          cloudBackupTime.push({
            uid: accountInfo.uid,
            time: Date.now()
          })
        }
        if (typeof (oldCloudBackupTime) === 'string') {
          const oldCloudBackupTimeArray = JSON.parse(oldCloudBackupTime) as CloudBackupTimeItem[]
          const oldCloudBackupTimeIndex = oldCloudBackupTimeArray.findIndex(item => item.uid === accountInfo.uid)
          if (oldCloudBackupTimeIndex !== -1) {
            oldCloudBackupTimeArray[oldCloudBackupTimeIndex].time = Date.now()
          }
          if (oldCloudBackupTimeIndex === -1) {
            oldCloudBackupTimeArray.push({
              uid: accountInfo.uid,
              time: Date.now()
            })
          }
          cloudBackupTime = oldCloudBackupTimeArray
        }
      }
      rdbStore.updateSync({
        cloudBackupTime: JSON.stringify(cloudBackupTime)
      }, predicates)
      promptAction.openToast({
        message: '云备份成功'
      })
    }
  }
}

export async function deleteCloudBackup(data: CloudBackupItem) {
  const accessToken = await get()
  const accountInfo = await getAccountInfo()
  if (accessToken) {
    const res = await request('/password/deleteBackup', {
      accessToken: accessToken,
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
      const resultSet = await rdbStore.query(predicates)
      let cloudBackupTime: CloudBackupTimeItem[] = []
      if (resultSet.goToNextRow()) {
        const oldCloudBackupTime = resultSet.getValue(resultSet.getColumnIndex('cloudBackupTime')) as string | number
        resultSet.close()
        if (typeof (oldCloudBackupTime) === 'string') {
          const oldCloudBackupTimeArray = JSON.parse(oldCloudBackupTime) as CloudBackupTimeItem[]
          const oldCloudBackupTimeIndex = oldCloudBackupTimeArray.findIndex(item => item.uid === accountInfo.uid)
          if (oldCloudBackupTimeIndex !== -1) {
            oldCloudBackupTimeArray.splice(oldCloudBackupTimeIndex, 1)
          }
          cloudBackupTime = oldCloudBackupTimeArray
        }
      }
      rdbStore.updateSync({
        cloudBackupTime: JSON.stringify(cloudBackupTime)
      }, predicates)
      promptAction.openToast({
        message: '删除云备份成功'
      })
    }
  }
}