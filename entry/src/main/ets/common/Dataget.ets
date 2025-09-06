import { relationalStore } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { getAccountInfo } from './Accesstoken'

export interface CloudBackupTimeItem {
  uid: string,
  time: number
}

export interface PasswordInfoItem {
  type: string,
  value: string
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
  cloudBackupTime: string | number,
  isCloudBackup: boolean
}

export interface Info {
  id: number,
  type: string,
  value: string,
  updateTime: number,
  cloudBackupTime: string | number,
  isCloudBackup: boolean
}

export interface Tag {
  id: number,
  value: string,
  color: string,
  updateTime: number,
  cloudBackupTime: string | number,
  isCloudBackup: boolean
}

export async function getPasswordInfo(id: number): Promise<Password | string> {
  const context = getContext()
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'password',
    securityLevel: 4,
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
        color: await getTagColor(item)
      }
    })
    const info: Password = {
      id: resultSet.getValue(idIndex) as number,
      name: resultSet.getValue(nameIndex) as string,
      info: JSON.parse(resultSet.getValue(infoIndex) as string) as PasswordInfoItem[],
      tag: await Promise.all(promises),
      updateTime: resultSet.getValue(updateTimeIndex) as number,
      cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex) as string | number,
      isCloudBackup: false
    }
    resultSet.close()
    if (typeof (info.cloudBackupTime) === 'number' && info.cloudBackupTime >= info.updateTime) {
      info.isCloudBackup = true
    }
    if (typeof (info.cloudBackupTime) === 'string') {
      const cloudBackupTime = JSON.parse(info.cloudBackupTime) as CloudBackupTimeItem[]
      const accountInfo = await getAccountInfo()
      const cloudBackupTimeIndex = cloudBackupTime.findIndex(item => item.uid === accountInfo.uid)
      if (cloudBackupTimeIndex !== -1) {
        if (cloudBackupTime[cloudBackupTimeIndex].time >= info.updateTime) {
          info.isCloudBackup = true
        }
      }
    }
    return info
  }
  resultSet.close()
  return 'fail'
}

export async function getPasswordList(orderColumn: string = 'updateTime'): Promise<Password[]> {
  try {
    const context = getContext()
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'password',
      securityLevel: 4,
      encrypt: true,
      allowRebuild: true
    })
    const predicates = new relationalStore.RdbPredicates('password')
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
      const tag = JSON.parse(resultSet.getValue(tagIndex) as string) as string[]
      const promises = tag.map(async (item): Promise<PasswordTagItem> => {
        return {
          value: item,
          color: await getTagColor(item)
        }
      })
      const info: Password = {
        id: resultSet.getValue(idIndex) as number,
        name: resultSet.getValue(nameIndex) as string,
        info: JSON.parse(resultSet.getValue(infoIndex) as string) as PasswordInfoItem[],
        tag: await Promise.all(promises),
        updateTime: resultSet.getValue(updateTimeIndex) as number,
        cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex) as string | number,
        isCloudBackup: false
      }
      if (typeof (info.cloudBackupTime) === 'number' && info.cloudBackupTime >= info.updateTime) {
        info.isCloudBackup = true
      }
      if (typeof (info.cloudBackupTime) === 'string') {
        const cloudBackupTime = JSON.parse(info.cloudBackupTime) as CloudBackupTimeItem[]
        const accountInfo = await getAccountInfo()
        const cloudBackupTimeIndex = cloudBackupTime.findIndex(item => item.uid === accountInfo.uid)
        if (cloudBackupTimeIndex !== -1) {
          if (cloudBackupTime[cloudBackupTimeIndex].time >= info.updateTime) {
            info.isCloudBackup = true
          }
        }
      }
      array.push(info)
    }
    resultSet.close()
    return array
  } catch {
    promptAction.openToast({
      message: '发生错误'
    })
    return []
  }
}

export async function getFilterPasswordList(nameKeyword: string, info: PasswordInfoItem[], tag: string[],
  orderColumn: string = 'updateTime'): Promise<Password[]> {
  try {
    const context = getContext()
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'password',
      securityLevel: 4,
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
            color: await getTagColor(item)
          }
        })
        const info: Password = {
          id: resultSet.getValue(idIndex) as number,
          name: resultSet.getValue(nameIndex) as string,
          info: JSON.parse(resultSet.getValue(infoIndex) as string) as PasswordInfoItem[],
          tag: await Promise.all(promises),
          updateTime: resultSet.getValue(updateTimeIndex) as number,
          cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex) as string | number,
          isCloudBackup: false
        }
        if (typeof (info.cloudBackupTime) === 'number' && info.cloudBackupTime >= info.updateTime) {
          info.isCloudBackup = true
        }
        if (typeof (info.cloudBackupTime) === 'string') {
          const cloudBackupTime = JSON.parse(info.cloudBackupTime) as CloudBackupTimeItem[]
          const accountInfo = await getAccountInfo()
          const cloudBackupTimeIndex = cloudBackupTime.findIndex(item => item.uid === accountInfo.uid)
          if (cloudBackupTimeIndex !== -1) {
            if (cloudBackupTime[cloudBackupTimeIndex].time >= info.updateTime) {
              info.isCloudBackup = true
            }
          }
        }
        array.push(info)
      }
    }
    resultSet.close()
    return array
  } catch {
    promptAction.openToast({
      message: '发生错误'
    })
    return []
  }
}

export async function getPasswordMaxId(): Promise<number> {
  const context = getContext()
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'password',
    securityLevel: 4,
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

export async function getInfoInfo(id: number): Promise<Info | string> {
  const context = getContext()
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'info',
    securityLevel: 4,
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
    const info: Info = {
      id: resultSet.getValue(idIndex) as number,
      type: resultSet.getValue(typeIndex) as string,
      value: resultSet.getValue(valueIndex) as string,
      updateTime: resultSet.getValue(updateTimeIndex) as number,
      cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex) as string | number,
      isCloudBackup: false
    }
    resultSet.close()
    if (typeof (info.cloudBackupTime) === 'number' && info.cloudBackupTime >= info.updateTime) {
      info.isCloudBackup = true
    }
    if (typeof (info.cloudBackupTime) === 'string') {
      const cloudBackupTime = JSON.parse(info.cloudBackupTime) as CloudBackupTimeItem[]
      const accountInfo = await getAccountInfo()
      const cloudBackupTimeIndex = cloudBackupTime.findIndex(item => item.uid === accountInfo.uid)
      if (cloudBackupTimeIndex !== -1) {
        if (cloudBackupTime[cloudBackupTimeIndex].time >= info.updateTime) {
          info.isCloudBackup = true
        }
      }
    }
    return info
  }
  resultSet.close()
  return 'fail'
}

export async function getInfoList(): Promise<Info[]> {
  try {
    const context = getContext()
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'info',
      securityLevel: 4,
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
      const info: Info = {
        id: resultSet.getValue(idIndex) as number,
        type: resultSet.getValue(typeIndex) as string,
        value: resultSet.getValue(valueIndex) as string,
        updateTime: resultSet.getValue(updateTimeIndex) as number,
        cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex) as string | number,
        isCloudBackup: false
      }
      if (typeof (info.cloudBackupTime) === 'number' && info.cloudBackupTime >= info.updateTime) {
        info.isCloudBackup = true
      }
      if (typeof (info.cloudBackupTime) === 'string') {
        const cloudBackupTime = JSON.parse(info.cloudBackupTime) as CloudBackupTimeItem[]
        const accountInfo = await getAccountInfo()
        const cloudBackupTimeIndex = cloudBackupTime.findIndex(item => item.uid === accountInfo.uid)
        if (cloudBackupTimeIndex !== -1) {
          if (cloudBackupTime[cloudBackupTimeIndex].time >= info.updateTime) {
            info.isCloudBackup = true
          }
        }
      }
      array.push(info)
    }
    resultSet.close()
    return array
  } catch {
    promptAction.openToast({
      message: '发生错误'
    })
    return []
  }
}

export async function getTypeInfoList(type: string): Promise<string[]> {
  try {
    const context = getContext()
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'info',
      securityLevel: 4,
      encrypt: true,
      allowRebuild: true
    })
    const predicates = new relationalStore.RdbPredicates('info')
    predicates.equalTo('type', type)
    const resultSet = await rdbStore.query(predicates)
    const valueIndex = resultSet.getColumnIndex('value')
    const array: string[] = []
    while (resultSet.goToNextRow()) {
      array.push(resultSet.getValue(valueIndex) as string)
    }
    resultSet.close()
    return array
  } catch {
    promptAction.openToast({
      message: '发生错误'
    })
    return []
  }
}

async function getTagColor(value: string): Promise<string> {
  const context = getContext()
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'tag',
    securityLevel: 1,
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
  return 'rgba(0,0,0,0)'
}

export async function getTagInfo(id: number): Promise<Tag | string> {
  const context = getContext()
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'tag',
    securityLevel: 1,
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
    const info: Tag = {
      id: resultSet.getValue(idIndex) as number,
      value: resultSet.getValue(valueIndex) as string,
      color: resultSet.getValue(colorIndex) as string,
      updateTime: resultSet.getValue(updateTimeIndex) as number,
      cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex) as string | number,
      isCloudBackup: false
    }
    resultSet.close()
    if (typeof (info.cloudBackupTime) === 'number' && info.cloudBackupTime >= info.updateTime) {
      info.isCloudBackup = true
    }
    if (typeof (info.cloudBackupTime) === 'string') {
      const cloudBackupTime = JSON.parse(info.cloudBackupTime) as CloudBackupTimeItem[]
      const accountInfo = await getAccountInfo()
      const cloudBackupTimeIndex = cloudBackupTime.findIndex(item => item.uid === accountInfo.uid)
      if (cloudBackupTimeIndex !== -1) {
        if (cloudBackupTime[cloudBackupTimeIndex].time >= info.updateTime) {
          info.isCloudBackup = true
        }
      }
    }
    return info
  }
  resultSet.close()
  return 'fail'
}

export async function getTagList(orderColumn: string = 'updateTime'): Promise<Tag[]> {
  try {
    const context = getContext()
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'tag',
      securityLevel: 1,
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
      const info: Tag = {
        id: resultSet.getValue(idIndex) as number,
        value: resultSet.getValue(valueIndex) as string,
        color: resultSet.getValue(colorIndex) as string,
        updateTime: resultSet.getValue(updateTimeIndex) as number,
        cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex) as string | number,
        isCloudBackup: false
      }
      if (typeof (info.cloudBackupTime) === 'number' && info.cloudBackupTime >= info.updateTime) {
        info.isCloudBackup = true
      }
      if (typeof (info.cloudBackupTime) === 'string') {
        const cloudBackupTime = JSON.parse(info.cloudBackupTime) as CloudBackupTimeItem[]
        const accountInfo = await getAccountInfo()
        const cloudBackupTimeIndex = cloudBackupTime.findIndex(item => item.uid === accountInfo.uid)
        if (cloudBackupTimeIndex !== -1) {
          if (cloudBackupTime[cloudBackupTimeIndex].time >= info.updateTime) {
            info.isCloudBackup = true
          }
        }
      }
      array.push(info)
    }
    resultSet.close()
    return array
  } catch {
    promptAction.openToast({
      message: '发生错误'
    })
    return []
  }
}