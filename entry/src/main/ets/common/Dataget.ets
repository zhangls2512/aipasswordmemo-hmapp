import { relationalStore } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { getAccountInfo } from './Account'
import { PasswordOutItem } from '../pages/DataInOut'

export interface CloudBackupTimeItem {
  uid: string,
  time: number
}

export interface PasswordInfoItem {
  type: string,
  value: string,
  history: PasswordInfoTypeValueHistoryItem[]
}

interface PasswordInfoTypeValueHistoryItem {
  value: string,
  updateTime: number
}

export interface PasswordTagItem {
  value: string,
  color: string
}

export interface Password {
  id: number,
  name: string,
  info: PasswordInfoItem[],
  tag: PasswordTagItem[],
  updateTime: number,
  cloudBackupTime: CloudBackupTimeItem[],
  isCloudBackup: boolean
}

export interface Info {
  id: number,
  type: string,
  value: string,
  updateTime: number,
  cloudBackupTime: CloudBackupTimeItem[],
  isCloudBackup: boolean
}

export interface Tag {
  id: number,
  value: string,
  color: string,
  updateTime: number,
  cloudBackupTime: CloudBackupTimeItem[],
  isCloudBackup: boolean
}

export async function getPasswordInfo(context: Context, id: number) {
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'password',
    securityLevel: relationalStore.SecurityLevel.S4,
    encrypt: true,
    allowRebuild: true
  })
  const predicates = new relationalStore.RdbPredicates('password')
  predicates.equalTo('id', id)
  const resultSet = await rdbStore.query(predicates)
  const idIndex = resultSet.getColumnIndex('id')
  const nameIndex = resultSet.getColumnIndex('name')
  const infoIndex = resultSet.getColumnIndex('info')
  const tagIndex = resultSet.getColumnIndex('tag')
  const updateTimeIndex = resultSet.getColumnIndex('updateTime')
  const cloudBackupTimeIndex = resultSet.getColumnIndex('cloudBackupTime')
  if (resultSet.goToNextRow()) {
    const tag = JSON.parse(resultSet.getValue(tagIndex) as string) as string[]
    const promises = tag.map(async (item): Promise<PasswordTagItem> => {
      return {
        value: item,
        color: await getTagColor(context, item)
      }
    })
    let cloudBackupTime: CloudBackupTimeItem[] = []
    try {
      cloudBackupTime = JSON.parse(resultSet.getValue(cloudBackupTimeIndex) as string) as CloudBackupTimeItem[]
    } catch {
    }
    const info: Password = {
      id: resultSet.getValue(idIndex) as number,
      name: resultSet.getValue(nameIndex) as string,
      info: JSON.parse(resultSet.getValue(infoIndex) as string) as PasswordInfoItem[],
      tag: await Promise.all(promises),
      updateTime: resultSet.getValue(updateTimeIndex) as number,
      cloudBackupTime: cloudBackupTime,
      isCloudBackup: false
    }
    resultSet.close()
    const accountInfo = await getAccountInfo()
    const cloudBackupTimeItem = cloudBackupTime.find(item => item.uid === accountInfo.uid)
    if (cloudBackupTimeItem && cloudBackupTimeItem.time >= info.updateTime) {
      info.isCloudBackup = true
    }
    return info
  }
  resultSet.close()
  return 'fail'
}

export async function getPasswordList(context: Context) {
  try {
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'password',
      securityLevel: relationalStore.SecurityLevel.S4,
      encrypt: true,
      allowRebuild: true
    })
    const predicates = new relationalStore.RdbPredicates('password')
    const resultSet = await rdbStore.query(predicates)
    const idIndex = resultSet.getColumnIndex('id')
    const nameIndex = resultSet.getColumnIndex('name')
    const infoIndex = resultSet.getColumnIndex('info')
    const tagIndex = resultSet.getColumnIndex('tag')
    const updateTimeIndex = resultSet.getColumnIndex('updateTime')
    const cloudBackupTimeIndex = resultSet.getColumnIndex('cloudBackupTime')
    const array: PasswordOutItem[] = []
    while (resultSet.goToNextRow()) {
      let cloudBackupTime: CloudBackupTimeItem[] = []
      try {
        cloudBackupTime = JSON.parse(resultSet.getValue(cloudBackupTimeIndex) as string) as CloudBackupTimeItem[]
      } catch {
      }
      const info: PasswordOutItem = {
        id: resultSet.getValue(idIndex) as number,
        name: resultSet.getValue(nameIndex) as string,
        info: JSON.parse(resultSet.getValue(infoIndex) as string) as PasswordInfoItem[],
        tag: JSON.parse(resultSet.getValue(tagIndex) as string) as string[],
        updateTime: resultSet.getValue(updateTimeIndex) as number,
        cloudBackupTime: cloudBackupTime
      }
      array.push(info)
    }
    resultSet.close()
    return array
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return []
  }
}

export async function getFilterPasswordList(context: Context, nameKeyword: string, info: PasswordInfoItem[],
  tag: string[],
  orderColumn: string = 'updateTime') {
  try {
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'password',
      securityLevel: relationalStore.SecurityLevel.S4,
      encrypt: true,
      allowRebuild: true
    })
    const predicates = new relationalStore.RdbPredicates('password')
    if (nameKeyword) {
      predicates.contains('name', nameKeyword)
    }
    if (orderColumn === 'updateTime') {
      predicates.orderByDesc('updateTime')
    }
    if (orderColumn === 'name') {
      predicates.orderByAsc('name')
    }
    const resultSet = await rdbStore.query(predicates)
    const idIndex = resultSet.getColumnIndex('id')
    const nameIndex = resultSet.getColumnIndex('name')
    const infoIndex = resultSet.getColumnIndex('info')
    const tagIndex = resultSet.getColumnIndex('tag')
    const updateTimeIndex = resultSet.getColumnIndex('updateTime')
    const cloudBackupTimeIndex = resultSet.getColumnIndex('cloudBackupTime')
    const array: Password[] = []
    while (resultSet.goToNextRow()) {
      let fit = true
      if (info.length > 0) {
        const passwordInfo = JSON.parse(resultSet.getValue(infoIndex) as string) as PasswordInfoItem[]
        fit = info.every(infoItem => passwordInfo.some(passwordInfoItem => passwordInfoItem.type === infoItem.type &&
          passwordInfoItem.value === infoItem.value))
      }
      if (tag.length > 0) {
        const passwordTag = JSON.parse(resultSet.getValue(tagIndex) as string) as string[]
        fit = tag.every(item => passwordTag.includes(item))
      }
      if (fit) {
        const tag = JSON.parse(resultSet.getValue(tagIndex) as string) as string[]
        const promises = tag.map(async (item): Promise<PasswordTagItem> => {
          return {
            value: item,
            color: await getTagColor(context, item)
          }
        })
        let cloudBackupTime: CloudBackupTimeItem[] = []
        try {
          cloudBackupTime = JSON.parse(resultSet.getValue(cloudBackupTimeIndex) as string) as CloudBackupTimeItem[]
        } catch {
        }
        const info: Password = {
          id: resultSet.getValue(idIndex) as number,
          name: resultSet.getValue(nameIndex) as string,
          info: JSON.parse(resultSet.getValue(infoIndex) as string) as PasswordInfoItem[],
          tag: await Promise.all(promises),
          updateTime: resultSet.getValue(updateTimeIndex) as number,
          cloudBackupTime: cloudBackupTime,
          isCloudBackup: false
        }
        const accountInfo = await getAccountInfo()
        const cloudBackupTimeItem = cloudBackupTime.find(item => item.uid === accountInfo.uid)
        if (cloudBackupTimeItem && cloudBackupTimeItem.time >= info.updateTime) {
          info.isCloudBackup = true
        }
        array.push(info)
      }
    }
    resultSet.close()
    return array
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return []
  }
}

export async function getPasswordMaxId(context: Context) {
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'password',
    securityLevel: relationalStore.SecurityLevel.S4,
    encrypt: true,
    allowRebuild: true
  })
  const predicates = new relationalStore.RdbPredicates('password')
  predicates.orderByDesc('id')
  const resultSet = await rdbStore.query(predicates)
  const idIndex = resultSet.getColumnIndex('id')
  let maxId = 0
  if (resultSet.goToNextRow()) {
    maxId = resultSet.getValue(idIndex) as number
  }
  resultSet.close()
  return maxId
}

export async function getInfoInfo(context: Context, id: number) {
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'info',
    securityLevel: relationalStore.SecurityLevel.S4,
    encrypt: true,
    allowRebuild: true
  })
  const predicates = new relationalStore.RdbPredicates('info')
  predicates.equalTo('id', id)
  const resultSet = await rdbStore.query(predicates)
  const idIndex = resultSet.getColumnIndex('id')
  const typeIndex = resultSet.getColumnIndex('type')
  const valueIndex = resultSet.getColumnIndex('value')
  const updateTimeIndex = resultSet.getColumnIndex('updateTime')
  const cloudBackupTimeIndex = resultSet.getColumnIndex('cloudBackupTime')
  if (resultSet.goToNextRow()) {
    let cloudBackupTime: CloudBackupTimeItem[] = []
    try {
      cloudBackupTime = JSON.parse(resultSet.getValue(cloudBackupTimeIndex) as string) as CloudBackupTimeItem[]
    } catch {
    }
    const info: Info = {
      id: resultSet.getValue(idIndex) as number,
      type: resultSet.getValue(typeIndex) as string,
      value: resultSet.getValue(valueIndex) as string,
      updateTime: resultSet.getValue(updateTimeIndex) as number,
      cloudBackupTime: cloudBackupTime,
      isCloudBackup: false
    }
    resultSet.close()
    const accountInfo = await getAccountInfo()
    const cloudBackupTimeItem = cloudBackupTime.find(item => item.uid === accountInfo.uid)
    if (cloudBackupTimeItem && cloudBackupTimeItem.time >= info.updateTime) {
      info.isCloudBackup = true
    }
    return info
  }
  resultSet.close()
  return 'fail'
}

export async function getInfoList(context: Context) {
  try {
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'info',
      securityLevel: relationalStore.SecurityLevel.S4,
      encrypt: true,
      allowRebuild: true
    })
    const predicates = new relationalStore.RdbPredicates('info')
    predicates.orderByDesc('updateTime')
    const resultSet = await rdbStore.query(predicates)
    const idIndex = resultSet.getColumnIndex('id')
    const typeIndex = resultSet.getColumnIndex('type')
    const valueIndex = resultSet.getColumnIndex('value')
    const updateTimeIndex = resultSet.getColumnIndex('updateTime')
    const cloudBackupTimeIndex = resultSet.getColumnIndex('cloudBackupTime')
    const array: Info[] = []
    while (resultSet.goToNextRow()) {
      let cloudBackupTime: CloudBackupTimeItem[] = []
      try {
        cloudBackupTime = JSON.parse(resultSet.getValue(cloudBackupTimeIndex) as string) as CloudBackupTimeItem[]
      } catch {
      }
      const info: Info = {
        id: resultSet.getValue(idIndex) as number,
        type: resultSet.getValue(typeIndex) as string,
        value: resultSet.getValue(valueIndex) as string,
        updateTime: resultSet.getValue(updateTimeIndex) as number,
        cloudBackupTime: cloudBackupTime,
        isCloudBackup: false
      }
      const accountInfo = await getAccountInfo()
      const cloudBackupTimeItem = cloudBackupTime.find(item => item.uid === accountInfo.uid)
      if (cloudBackupTimeItem && cloudBackupTimeItem.time >= info.updateTime) {
        info.isCloudBackup = true
      }
      array.push(info)
    }
    resultSet.close()
    return array
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return []
  }
}

export async function getInfoTypeList(context: Context) {
  try {
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'info',
      securityLevel: relationalStore.SecurityLevel.S4,
      encrypt: true,
      allowRebuild: true
    })
    const predicates = new relationalStore.RdbPredicates('info')
    predicates.orderByAsc('type')
    const resultSet = await rdbStore.query(predicates)
    const typeIndex = resultSet.getColumnIndex('type')
    const array: string[] = []
    while (resultSet.goToNextRow()) {
      const type = resultSet.getValue(typeIndex) as string
      if (!array.includes(type)) {
        array.push(type)
      }
    }
    resultSet.close()
    return array
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return []
  }
}

export async function getTypeInfoList(context: Context, type: string) {
  try {
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'info',
      securityLevel: relationalStore.SecurityLevel.S4,
      encrypt: true,
      allowRebuild: true
    })
    const predicates = new relationalStore.RdbPredicates('info')
    predicates.equalTo('type', type)
    predicates.orderByAsc('value')
    const resultSet = await rdbStore.query(predicates)
    const valueIndex = resultSet.getColumnIndex('value')
    const array: string[] = []
    while (resultSet.goToNextRow()) {
      array.push(resultSet.getValue(valueIndex) as string)
    }
    resultSet.close()
    return array
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return []
  }
}

async function getTagColor(context: Context, value: string) {
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'tag',
    securityLevel: relationalStore.SecurityLevel.S1,
    encrypt: true,
    allowRebuild: true
  })
  const predicates = new relationalStore.RdbPredicates('tag')
  predicates.equalTo('value', value)
  const resultSet = await rdbStore.query(predicates)
  const colorIndex = resultSet.getColumnIndex('color')
  if (resultSet.goToNextRow()) {
    const color = resultSet.getValue(colorIndex) as string
    resultSet.close()
    return color
  }
  resultSet.close()
  return ''
}

export async function getTagInfo(context: Context, id: number) {
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'tag',
    securityLevel: relationalStore.SecurityLevel.S1,
    encrypt: true,
    allowRebuild: true
  })
  const predicates = new relationalStore.RdbPredicates('tag')
  predicates.equalTo('id', id)
  const resultSet = await rdbStore.query(predicates)
  const idIndex = resultSet.getColumnIndex('id')
  const valueIndex = resultSet.getColumnIndex('value')
  const colorIndex = resultSet.getColumnIndex('color')
  const updateTimeIndex = resultSet.getColumnIndex('updateTime')
  const cloudBackupTimeIndex = resultSet.getColumnIndex('cloudBackupTime')
  if (resultSet.goToNextRow()) {
    let cloudBackupTime: CloudBackupTimeItem[] = []
    try {
      cloudBackupTime = JSON.parse(resultSet.getValue(cloudBackupTimeIndex) as string) as CloudBackupTimeItem[]
    } catch {
    }
    const info: Tag = {
      id: resultSet.getValue(idIndex) as number,
      value: resultSet.getValue(valueIndex) as string,
      color: resultSet.getValue(colorIndex) as string,
      updateTime: resultSet.getValue(updateTimeIndex) as number,
      cloudBackupTime: cloudBackupTime,
      isCloudBackup: false
    }
    resultSet.close()
    const accountInfo = await getAccountInfo()
    const cloudBackupTimeItem = cloudBackupTime.find(item => item.uid === accountInfo.uid)
    if (cloudBackupTimeItem && cloudBackupTimeItem.time >= info.updateTime) {
      info.isCloudBackup = true
    }
    return info
  }
  resultSet.close()
  return 'fail'
}

export async function getTagList(context: Context, orderColumn: string = 'updateTime') {
  try {
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'tag',
      securityLevel: relationalStore.SecurityLevel.S1,
      encrypt: true,
      allowRebuild: true
    })
    const predicates = new relationalStore.RdbPredicates('tag')
    if (orderColumn === 'updateTime') {
      predicates.orderByDesc('updateTime')
    }
    if (orderColumn === 'value') {
      predicates.orderByAsc('value')
    }
    const resultSet = await rdbStore.query(predicates)
    const idIndex = resultSet.getColumnIndex('id')
    const valueIndex = resultSet.getColumnIndex('value')
    const colorIndex = resultSet.getColumnIndex('color')
    const updateTimeIndex = resultSet.getColumnIndex('updateTime')
    const cloudBackupTimeIndex = resultSet.getColumnIndex('cloudBackupTime')
    const array: Tag[] = []
    while (resultSet.goToNextRow()) {
      let cloudBackupTime: CloudBackupTimeItem[] = []
      try {
        cloudBackupTime = JSON.parse(resultSet.getValue(cloudBackupTimeIndex) as string) as CloudBackupTimeItem[]
      } catch {
      }
      const info: Tag = {
        id: resultSet.getValue(idIndex) as number,
        value: resultSet.getValue(valueIndex) as string,
        color: resultSet.getValue(colorIndex) as string,
        updateTime: resultSet.getValue(updateTimeIndex) as number,
        cloudBackupTime: cloudBackupTime,
        isCloudBackup: false
      }
      const accountInfo = await getAccountInfo()
      const cloudBackupTimeItem = cloudBackupTime.find(item => item.uid === accountInfo.uid)
      if (cloudBackupTimeItem && cloudBackupTimeItem.time >= info.updateTime) {
        info.isCloudBackup = true
      }
      array.push(info)
    }
    resultSet.close()
    return array
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return []
  }
}