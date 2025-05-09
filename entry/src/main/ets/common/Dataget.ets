import { common } from '@kit.AbilityKit'
import { relationalStore } from '@kit.ArkData'

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
  tag: string[],
  updateTime: number,
  cloudBackupTime: number
}

export interface PasswordOut {
  id: number,
  name: string,
  info: PasswordInfoItem[],
  tag: PasswordTagItem[],
  updateTime: number,
  cloudBackupTime: number
}

export interface Info {
  id: number,
  type: string,
  value: string,
  updateTime: number,
  cloudBackupTime: number
}

export interface Tag {
  id: number,
  value: string,
  color: string,
  updateTime: number,
  cloudBackupTime: number
}

export async function getPasswordInfo(id: number): Promise<PasswordOut | string> {
  const context = getContext() as common.UIAbilityContext
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
    const info: Password = {
      id: resultSet.getValue(idIndex) as number,
      name: resultSet.getValue(nameIndex) as string,
      info: JSON.parse(resultSet.getValue(infoIndex) as string) as PasswordInfoItem[],
      tag: JSON.parse(resultSet.getValue(tagIndex) as string) as string[],
      updateTime: resultSet.getValue(updateTimeIndex) as number,
      cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex) as number
    }
    resultSet.close()
    const promises = info.tag.map(async (item): Promise<PasswordTagItem> => {
      return {
        value: item,
        color: await getTagColor(item)
      }
    })
    const infoout: PasswordOut = {
      id: info.id,
      name: info.name,
      info: info.info,
      tag: await Promise.all(promises),
      updateTime: info.updateTime,
      cloudBackupTime: info.cloudBackupTime
    }
    return infoout
  }
  resultSet.close()
  return 'fail'
}

export async function getPasswordList(orderColumn?: string): Promise<PasswordOut[]> {
  const context = getContext() as common.UIAbilityContext
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
  const array: PasswordOut[] = []
  while (resultSet.goToNextRow()) {
    const tags = JSON.parse(resultSet.getValue(tagIndex) as string) as string[]
    const promises = tags.map(async (item): Promise<PasswordTagItem> => {
      return {
        value: item,
        color: await getTagColor(item)
      }
    })
    array.push({
      id: resultSet.getValue(idIndex) as number,
      name: resultSet.getValue(nameIndex) as string,
      info: JSON.parse(resultSet.getValue(infoIndex) as string) as PasswordInfoItem[],
      tag: await Promise.all(promises),
      updateTime: resultSet.getValue(updateTimeIndex) as number,
      cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex) as number
    })
  }
  resultSet.close()
  return array
}

export async function getFilterPasswordList(nameKeyword: string, info: PasswordInfoItem[], tag: string[],
  orderColumn?: string): Promise<PasswordOut[]> {
  const context = getContext() as common.UIAbilityContext
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
  const array: PasswordOut[] = []
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
      const tags = JSON.parse(resultSet.getValue(tagIndex) as string) as string[]
      const promises = tags.map(async (item): Promise<PasswordTagItem> => {
        return {
          value: item,
          color: await getTagColor(item)
        }
      })
      array.push({
        id: resultSet.getValue(idIndex) as number,
        name: resultSet.getValue(nameIndex) as string,
        info: JSON.parse(resultSet.getValue(infoIndex) as string) as PasswordInfoItem[],
        tag: await Promise.all(promises),
        updateTime: resultSet.getValue(updateTimeIndex) as number,
        cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex) as number
      })
    }
  }
  resultSet.close()
  return array
}

export async function getInfoInfo(id: number): Promise<Info | string> {
  const context = getContext() as common.UIAbilityContext
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
      cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex) as number
    }
    resultSet.close()
    return info
  }
  resultSet.close()
  return 'fail'
}

export async function getInfoList(): Promise<Info[]> {
  const context = getContext() as common.UIAbilityContext
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
    array.push({
      id: resultSet.getValue(idIndex) as number,
      type: resultSet.getValue(typeIndex) as string,
      value: resultSet.getValue(valueIndex) as string,
      updateTime: resultSet.getValue(updateTimeIndex) as number,
      cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex) as number
    })
  }
  resultSet.close()
  return array
}

export async function getTypeInfoList(type: string): Promise<string[]> {
  const context = getContext() as common.UIAbilityContext
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
}

async function getTagColor(value: string): Promise<string> {
  const context = getContext() as common.UIAbilityContext
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
  const context = getContext() as common.UIAbilityContext
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
      cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex) as number
    }
    resultSet.close()
    return info
  }
  resultSet.close()
  return 'fail'
}

export async function getTagList(orderColumn?: string): Promise<Tag[]> {
  const context = getContext() as common.UIAbilityContext
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
    array.push({
      id: resultSet.getValue(idIndex) as number,
      value: resultSet.getValue(valueIndex) as string,
      color: resultSet.getValue(colorIndex) as string,
      updateTime: resultSet.getValue(updateTimeIndex) as number,
      cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex) as number
    })
  }
  resultSet.close()
  return array
}