import { preferences, relationalStore } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { getAccountAccessToken, getAccountInfo } from './Accesstoken'
import { encrypt } from './Crypto'
import { CloudBackupTimeItem, PasswordInfoItem } from './Dataget'
import request from './Request'
import { autoBackupTable, autoHuaweiCloudSyncTable, autoSyncTable } from './Table'

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

function getNewInfo(context: Context, oldInfo: PasswordInfoItem[], newInfo: PasswordInfoItem[], updateTime: number) {
  const commonSettingDataPreferences = preferences.getPreferencesSync(context, {
    name: 'commonSetting'
  })
  const storeValueHistoryPasswordInfoTypeArray =
    commonSettingDataPreferences.getSync('storeValueHistoryPasswordInfoType', ['密码']) as string[]
  return newInfo.map((newItem): PasswordInfoItem => {
    if (!storeValueHistoryPasswordInfoTypeArray.includes(newItem.type)) {
      return {
        type: newItem.type,
        value: newItem.value
      }
    }
    const oldItem = oldInfo.find(oldItem => oldItem.type === newItem.type)
    if (oldItem) {
      if (oldItem.value !== newItem.value) {
        let history = oldItem.history
        if (history) {
          history.unshift({
            value: newItem.value,
            updateTime: updateTime
          })
        }
        if (!history) {
          history = [
            {
              value: newItem.value,
              updateTime: updateTime
            },
            {
              value: oldItem.value,
              updateTime: NaN
            }
          ]
        }
        if (history.length > 11) {
          history.splice(11)
        }
        return {
          type: newItem.type,
          value: newItem.value,
          history: history
        }
      }
      if (!oldItem.history) {
        return {
          type: oldItem.type,
          value: oldItem.value
        }
      }
      if (oldItem.history) {
        return {
          type: oldItem.type,
          value: oldItem.value,
          history: oldItem.history
        }
      }
    }
    return {
      type: newItem.type,
      value: newItem.value,
      history: [
        {
          value: newItem.value,
          updateTime: updateTime
        }
      ]
    }
  })
}

export async function newPassword(context: Context, data: PasswordInput) {
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
  const updateTime = Date.now()
  const id = rdbStore.insertSync('password', {
    name: data.name,
    info: JSON.stringify(data.info.map((item): PasswordInfoItem => {
      return {
        type: item.type,
        value: item.value,
        history: [
          {
            value: item.value,
            updateTime: updateTime
          }
        ]
      }
    })),
    tag: JSON.stringify(data.tag),
    updateTime: updateTime,
    cloudBackupTime: JSON.stringify([])
  })
  huaweiCloudSyncRdbStore.insertSync('password', {
    id: String(id),
    name: data.name,
    info: JSON.stringify(data.info),
    tag: JSON.stringify(data.tag),
    updateTime: updateTime,
    cloudBackupTime: JSON.stringify([])
  })
  await promptAction.openToast({
    message: '新增成功'
  })
  await autoSyncTable(context, 'password')
  await autoBackupTable(context, 'password')
  await autoHuaweiCloudSyncTable(context, 'password')
  if (data.cloudBackup) {
    const accountInfo = await getAccountInfo()
    const cloudBackupTime: CloudBackupTimeItem[] = [{
      uid: accountInfo.uid,
      time: updateTime
    }]
    await setCloudBackup(context, {
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

export async function updatePassword(context: Context, id: number, data: PasswordInput) {
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
  const predicates = new relationalStore.RdbPredicates('password')
  predicates.equalTo('id', id)
  const updateTime = Date.now()
  const resultSet = await rdbStore.query(predicates)
  let info: PasswordInfoItem[] = []
  let cloudBackupTime = JSON.stringify([])
  if (resultSet.goToNextRow()) {
    info = JSON.parse(resultSet.getValue(resultSet.getColumnIndex('info')) as string)
    const oldCloudBackupTime = resultSet.getValue(resultSet.getColumnIndex('cloudBackupTime')) as string | number
    resultSet.close()
    if (typeof (oldCloudBackupTime) === 'string') {
      cloudBackupTime = oldCloudBackupTime
    }
  }
  info = getNewInfo(context, info, data.info, updateTime)
  rdbStore.updateSync({
    name: data.name,
    info: JSON.stringify(info),
    tag: JSON.stringify(data.tag),
    updateTime: updateTime,
    cloudBackupTime: cloudBackupTime
  }, predicates)
  const predicatesb = new relationalStore.RdbPredicates('password')
  predicatesb.equalTo('id', String(id))
  huaweiCloudSyncRdbStore.updateSync({
    name: data.name,
    info: JSON.stringify(info),
    tag: JSON.stringify(data.tag),
    updateTime: updateTime,
    cloudBackupTime: cloudBackupTime
  }, predicatesb)
  await promptAction.openToast({
    message: '修改成功'
  })
  await autoSyncTable(context, 'password')
  await autoBackupTable(context, 'password')
  await autoHuaweiCloudSyncTable(context, 'password')
  if (data.cloudBackup) {
    const cloudBackupTimeArray = JSON.parse(cloudBackupTime) as CloudBackupTimeItem[]
    const accountInfo = await getAccountInfo()
    const cloudBackupTime = cloudBackupTimeArray.find(item => item.uid === accountInfo.uid)
    if (cloudBackupTime) {
      cloudBackupTime.time = Date.now()
    }
    if (!cloudBackupTime) {
      cloudBackupTimeArray.push({
        uid: accountInfo.uid,
        time: Date.now()
      })
    }
    await setCloudBackup(context, {
      type: 'password',
      id: id,
      content: JSON.stringify({
        name: data.name,
        info: JSON.stringify(info),
        tag: JSON.stringify(data.tag),
        updateTime: updateTime,
        cloudBackupTime: JSON.stringify(cloudBackupTimeArray)
      })
    })
  }
}

export async function newInfo(context: Context, data: InfoInput) {
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
  const predicates = new relationalStore.RdbPredicates('info')
  predicates.equalTo('type', data.type)
  predicates.equalTo('value', data.value)
  const resultSet = await rdbStore.query(predicates)
  if (resultSet.goToNextRow()) {
    resultSet.close()
    await promptAction.openToast({
      message: '新增失败，原因：已存在'
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
  huaweiCloudSyncRdbStore.insertSync('info', {
    id: String(id),
    type: data.type,
    value: data.value,
    updateTime: updateTime,
    cloudBackupTime: JSON.stringify([])
  })
  await promptAction.openToast({
    message: '新增成功'
  })
  await autoSyncTable(context, 'info')
  await autoBackupTable(context, 'info')
  await autoHuaweiCloudSyncTable(context, 'info')
  if (data.cloudBackup) {
    const accountInfo = await getAccountInfo()
    const cloudBackupTime: CloudBackupTimeItem[] = [{
      uid: accountInfo.uid,
      time: updateTime
    }]
    await setCloudBackup(context, {
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

export async function updateInfo(context: Context, id: number, data: InfoInput) {
  if (data.type === '图标') {
    await promptAction.openToast({
      message: '修改失败，原因：图标类型不支持'
    })
    return 'fail'
  }
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
  const predicatesa = new relationalStore.RdbPredicates('info')
  predicatesa.equalTo('type', data.type)
  predicatesa.equalTo('value', data.value)
  const resultSeta = await rdbStore.query(predicatesa)
  if (resultSeta.goToNextRow()) {
    resultSeta.close()
    await promptAction.openToast({
      message: '修改失败，原因：已存在'
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
  const predicatesc = new relationalStore.RdbPredicates('info')
  predicatesc.equalTo('id', String(id))
  huaweiCloudSyncRdbStore.updateSync({
    type: data.type,
    value: data.value,
    updateTime: updateTime,
    cloudBackupTime: cloudBackupTime
  }, predicatesc)
  await promptAction.openToast({
    message: '修改成功'
  })
  await autoSyncTable(context, 'info')
  await autoBackupTable(context, 'info')
  await autoHuaweiCloudSyncTable(context, 'info')
  if (data.cloudBackup) {
    const cloudBackupTimeArray = JSON.parse(cloudBackupTime) as CloudBackupTimeItem[]
    const accountInfo = await getAccountInfo()
    const cloudBackupTime = cloudBackupTimeArray.find(item => item.uid === accountInfo.uid)
    if (cloudBackupTime) {
      cloudBackupTime.time = Date.now()
    }
    if (!cloudBackupTime) {
      cloudBackupTimeArray.push({
        uid: accountInfo.uid,
        time: Date.now()
      })
    }
    await setCloudBackup(context, {
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

export async function newTag(context: Context, data: TagInput) {
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
  const predicates = new relationalStore.RdbPredicates('tag')
  predicates.equalTo('value', data.value)
  const resultSet = await rdbStore.query(predicates)
  if (resultSet.goToNextRow()) {
    resultSet.close()
    await promptAction.openToast({
      message: '新增失败，原因：已存在'
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
  huaweiCloudSyncRdbStore.insertSync('tag', {
    id: String(id),
    value: data.value,
    color: data.color,
    updateTime: updateTime,
    cloudBackupTime: JSON.stringify([])
  })
  await promptAction.openToast({
    message: '新增成功'
  })
  await autoSyncTable(context, 'tag')
  await autoBackupTable(context, 'tag')
  await autoHuaweiCloudSyncTable(context, 'tag')
  if (data.cloudBackup) {
    const accountInfo = await getAccountInfo()
    const cloudBackupTime: CloudBackupTimeItem[] = [{
      uid: accountInfo.uid,
      time: updateTime
    }]
    await setCloudBackup(context, {
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

export async function updateTag(context: Context, id: number, data: TagInput) {
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
  const predicatesa = new relationalStore.RdbPredicates('tag')
  predicatesa.equalTo('value', data.value)
  predicatesa.equalTo('color', data.color)
  const resultSeta = await rdbStore.query(predicatesa)
  if (resultSeta.goToNextRow()) {
    resultSeta.close()
    await promptAction.openToast({
      message: '修改失败，原因：已存在'
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
  const predicatesc = new relationalStore.RdbPredicates('tag')
  predicatesc.equalTo('id', String(id))
  huaweiCloudSyncRdbStore.updateSync({
    value: data.value,
    color: data.color,
    updateTime: updateTime,
    cloudBackupTime: cloudBackupTime
  }, predicatesc)
  await promptAction.openToast({
    message: '修改成功'
  })
  await autoSyncTable(context, 'tag')
  await autoBackupTable(context, 'tag')
  await autoHuaweiCloudSyncTable(context, 'tag')
  if (data.cloudBackup) {
    const cloudBackupTimeArray = JSON.parse(cloudBackupTime) as CloudBackupTimeItem[]
    const accountInfo = await getAccountInfo()
    const cloudBackupTime = cloudBackupTimeArray.find(item => item.uid === accountInfo.uid)
    if (cloudBackupTime) {
      cloudBackupTime.time = Date.now()
    }
    if (!cloudBackupTime) {
      cloudBackupTimeArray.push({
        uid: accountInfo.uid,
        time: Date.now()
      })
    }
    await setCloudBackup(context, {
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

export async function deleteData(context: Context, type: string, id: number) {
  let securityLevel = relationalStore.SecurityLevel.S4
  if (type === 'tag') {
    securityLevel = relationalStore.SecurityLevel.S1
  }
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: type,
    securityLevel: securityLevel,
    encrypt: true,
    allowRebuild: true
  })
  const huaweiCloudSyncRdbStore = await relationalStore.getRdbStore(context, {
    name: 'huaweicloudsync',
    securityLevel: relationalStore.SecurityLevel.S3,
    encrypt: true,
    allowRebuild: true
  })
  const predicates = new relationalStore.RdbPredicates(type)
  predicates.equalTo('id', id)
  rdbStore.deleteSync(predicates)
  const predicatesb = new relationalStore.RdbPredicates(type)
  predicatesb.equalTo('id', String(id))
  huaweiCloudSyncRdbStore.deleteSync(predicatesb)
  await promptAction.openToast({
    message: '删除成功'
  })
  await autoSyncTable(context, type)
  await autoBackupTable(context, type)
  await autoHuaweiCloudSyncTable(context, type)
}

export async function setCloudBackup(context: Context, data: CloudBackupItem) {
  const content = data.content as string
  const encryptres = await encrypt(content)
  const accessToken = await getAccountAccessToken()
  const accountInfo = await getAccountInfo()
  if (accessToken) {
    const res = await request(context, '/password/setBackup', {
      accessToken: accessToken,
      type: data.type,
      id: data.id,
      content: encryptres.content,
      iv: encryptres.iv
    })
    if (res !== 'fail') {
      let securityLevel = relationalStore.SecurityLevel.S4
      if (data.type === 'tag') {
        securityLevel = relationalStore.SecurityLevel.S1
      }
      const rdbStore = await relationalStore.getRdbStore(context, {
        name: data.type,
        securityLevel: securityLevel,
        encrypt: true,
        allowRebuild: true
      })
      const huaweiCloudSyncRdbStore = await relationalStore.getRdbStore(context, {
        name: 'huaweicloudsync',
        securityLevel: relationalStore.SecurityLevel.S3,
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
          const oldCloudBackupTime = oldCloudBackupTimeArray.find(item => item.uid === accountInfo.uid)
          if (oldCloudBackupTime) {
            oldCloudBackupTime.time = Date.now()
          }
          if (!oldCloudBackupTime) {
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
      const predicatesb = new relationalStore.RdbPredicates(data.type)
      predicatesb.equalTo('id', String(data.id))
      huaweiCloudSyncRdbStore.updateSync({
        cloudBackupTime: JSON.stringify(cloudBackupTime)
      }, predicatesb)
      await promptAction.openToast({
        message: '云备份成功'
      })
      await autoSyncTable(context, data.type)
      await autoBackupTable(context, data.type)
      await autoHuaweiCloudSyncTable(context, data.type)
    }
  }
}

export async function deleteCloudBackup(context: Context, data: CloudBackupItem) {
  const accessToken = await getAccountAccessToken()
  const accountInfo = await getAccountInfo()
  if (accessToken) {
    const res = await request(context, '/password/deleteBackup', {
      accessToken: accessToken,
      type: data.type,
      id: data.id
    })
    if (res !== 'fail') {
      let securityLevel = relationalStore.SecurityLevel.S4
      if (data.type === 'tag') {
        securityLevel = relationalStore.SecurityLevel.S1
      }
      const rdbStore = await relationalStore.getRdbStore(context, {
        name: data.type,
        securityLevel: securityLevel,
        encrypt: true,
        allowRebuild: true
      })
      const huaweiCloudSyncRdbStore = await relationalStore.getRdbStore(context, {
        name: 'huaweicloudsync',
        securityLevel: relationalStore.SecurityLevel.S3,
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
      const predicatesb = new relationalStore.RdbPredicates(data.type)
      predicatesb.equalTo('id', String(data.id))
      huaweiCloudSyncRdbStore.updateSync({
        cloudBackupTime: JSON.stringify(cloudBackupTime)
      }, predicatesb)
      await promptAction.openToast({
        message: '取消云备份成功'
      })
      await autoSyncTable(context, data.type)
      await autoBackupTable(context, data.type)
      await autoHuaweiCloudSyncTable(context, data.type)
    }
  }
}