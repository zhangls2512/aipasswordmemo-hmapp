import { common } from '@kit.AbilityKit'
import { relationalStore } from '@kit.ArkData'

export interface PasswordInfoItem {
  type: string,
  value: string
}

export interface Password {
  id: number,
  name: string,
  info: PasswordInfoItem[],
  tag: string[],
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

export async function getPasswordInfo(id: number): Promise<Password | string> {
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
  if (resultSet.goToNextRow()) {
    const info: Password = {
      id: resultSet.getValue(resultSet.getColumnIndex('id')) as number,
      name: resultSet.getValue(resultSet.getColumnIndex('name')) as string,
      info: JSON.parse(resultSet.getValue(resultSet.getColumnIndex('info')) as string) as PasswordInfoItem[],
      tag: JSON.parse(resultSet.getValue(resultSet.getColumnIndex('tag')) as string) as string[],
      updateTime: resultSet.getValue(resultSet.getColumnIndex('updateTime')) as number,
      cloudBackupTime: resultSet.getValue(resultSet.getColumnIndex('cloudBackupTime')) as number
    }
    resultSet.close()
    return info
  } else {
    resultSet.close()
    return 'fail'
  }
}

export async function getPasswordList(): Promise<Password[]> {
  const context = getContext() as common.UIAbilityContext
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'password',
    securityLevel: 4,
    encrypt: true,
    allowRebuild: true
  })
  const predicates = new relationalStore.RdbPredicates('password')
  predicates.orderByDesc('updateTime')
  const resultSet = await rdbStore.query(predicates)
  const array: Password[] = []
  while (resultSet.goToNextRow()) {
    array.push({
      id: resultSet.getValue(resultSet.getColumnIndex('id')) as number,
      name: resultSet.getValue(resultSet.getColumnIndex('name')) as string,
      info: JSON.parse(resultSet.getValue(resultSet.getColumnIndex('info')) as string) as PasswordInfoItem[],
      tag: JSON.parse(resultSet.getValue(resultSet.getColumnIndex('tag')) as string) as string[],
      updateTime: resultSet.getValue(resultSet.getColumnIndex('updateTime')) as number,
      cloudBackupTime: resultSet.getValue(resultSet.getColumnIndex('cloudBackupTime')) as number
    })
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
  if (resultSet.goToNextRow()) {
    const info: Info = {
      id: resultSet.getValue(resultSet.getColumnIndex('id')) as number,
      type: resultSet.getValue(resultSet.getColumnIndex('type')) as string,
      value: resultSet.getValue(resultSet.getColumnIndex('value')) as string,
      updateTime: resultSet.getValue(resultSet.getColumnIndex('updateTime')) as number,
      cloudBackupTime: resultSet.getValue(resultSet.getColumnIndex('cloudBackupTime')) as number
    }
    resultSet.close()
    return info
  } else {
    resultSet.close()
    return 'fail'
  }
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
  const array: Info[] = []
  while (resultSet.goToNextRow()) {
    array.push({
      id: resultSet.getValue(resultSet.getColumnIndex('id')) as number,
      type: resultSet.getValue(resultSet.getColumnIndex('type')) as string,
      value: resultSet.getValue(resultSet.getColumnIndex('value')) as string,
      updateTime: resultSet.getValue(resultSet.getColumnIndex('updateTime')) as number,
      cloudBackupTime: resultSet.getValue(resultSet.getColumnIndex('cloudBackupTime')) as number
    })
  }
  resultSet.close()
  return array
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
  if (resultSet.goToNextRow()) {
    const info: Tag = {
      id: resultSet.getValue(resultSet.getColumnIndex('id')) as number,
      value: resultSet.getValue(resultSet.getColumnIndex('value')) as string,
      color: resultSet.getValue(resultSet.getColumnIndex('color')) as string,
      updateTime: resultSet.getValue(resultSet.getColumnIndex('updateTime')) as number,
      cloudBackupTime: resultSet.getValue(resultSet.getColumnIndex('cloudBackupTime')) as number
    }
    resultSet.close()
    return info
  } else {
    resultSet.close()
    return 'fail'
  }
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
  const array: Tag[] = []
  while (resultSet.goToNextRow()) {
    array.push({
      id: resultSet.getValue(resultSet.getColumnIndex('id')) as number,
      value: resultSet.getValue(resultSet.getColumnIndex('value')) as string,
      color: resultSet.getValue(resultSet.getColumnIndex('color')) as string,
      updateTime: resultSet.getValue(resultSet.getColumnIndex('updateTime')) as number,
      cloudBackupTime: resultSet.getValue(resultSet.getColumnIndex('cloudBackupTime')) as number
    })
  }
  resultSet.close()
  return array
}