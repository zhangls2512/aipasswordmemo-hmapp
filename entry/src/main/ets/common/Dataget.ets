import { common } from '@kit.AbilityKit'
import { relationalStore } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { BusinessError } from '@kit.BasicServicesKit'

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

export async function getPasswordList(): Promise<Password[] | boolean> {
  const context = getContext() as common.UIAbilityContext
  try {
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
        id: resultSet.getValue(resultSet.getColumnIndex('rowId')) as number,
        name: resultSet.getValue(resultSet.getColumnIndex('name')) as string,
        info: JSON.parse(resultSet.getValue(resultSet.getColumnIndex('info')) as string) as PasswordInfoItem[],
        tag: JSON.parse(resultSet.getValue(resultSet.getColumnIndex('tag')) as string) as string[],
        updateTime: resultSet.getValue(resultSet.getColumnIndex('updateTime')) as number,
        cloudBackupTime: resultSet.getValue(resultSet.getColumnIndex('cloudBackupTime')) as number
      })
    }
    resultSet.close()
    return array
  } catch (err) {
    promptAction.showToast({
      message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
      (err as BusinessError).message
    })
    return false
  }
}

export async function getInfoList(): Promise<Info[] | boolean> {
  const context = getContext() as common.UIAbilityContext
  try {
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
        id: resultSet.getValue(resultSet.getColumnIndex('rowId')) as number,
        type: resultSet.getValue(resultSet.getColumnIndex('type')) as string,
        value: resultSet.getValue(resultSet.getColumnIndex('value')) as string,
        updateTime: resultSet.getValue(resultSet.getColumnIndex('updateTime')) as number,
        cloudBackupTime: resultSet.getValue(resultSet.getColumnIndex('cloudBackupTime')) as number
      })
    }
    resultSet.close()
    return array
  } catch (err) {
    promptAction.showToast({
      message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
      (err as BusinessError).message
    })
    return false
  }
}

export async function getTagList(): Promise<Tag[] | boolean> {
  const context = getContext() as common.UIAbilityContext
  try {
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'tag',
      securityLevel: 1,
      encrypt: true,
      allowRebuild: true
    })
    const predicates = new relationalStore.RdbPredicates('tag')
    predicates.orderByDesc('updateTime')
    const resultSet = await rdbStore.query(predicates)
    const array: Tag[] = []
    while (resultSet.goToNextRow()) {
      array.push({
        id: resultSet.getValue(resultSet.getColumnIndex('rowId')) as number,
        value: resultSet.getValue(resultSet.getColumnIndex('value')) as string,
        color: resultSet.getValue(resultSet.getColumnIndex('color')) as string,
        updateTime: resultSet.getValue(resultSet.getColumnIndex('updateTime')) as number,
        cloudBackupTime: resultSet.getValue(resultSet.getColumnIndex('cloudBackupTime')) as number
      })
    }
    resultSet.close()
    return array
  } catch (err) {
    promptAction.showToast({
      message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
      (err as BusinessError).message
    })
    return false
  }
}