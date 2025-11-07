import { relationalStore } from '@kit.ArkData'
import { PasswordInfoItem } from './Dataget'

export interface ListItem {
  id: number,
  name: string
}

export interface RepeatItem {
  password: string,
  count: number,
  list: ListItem[]
}

export async function getPasswordStrengthList() {
  const context = getContext()
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'password',
    securityLevel: 4,
    encrypt: true,
    allowRebuild: true
  })
  const predicates = new relationalStore.RdbPredicates('password')
  const resultSet = await rdbStore.query(predicates)
  const idIndex = resultSet.getColumnIndex('id')
  const nameIndex = resultSet.getColumnIndex('name')
  const infoIndex = resultSet.getColumnIndex('info')
  const array: ListItem[][] = [[], [], []]
  while (resultSet.goToNextRow()) {
    const infoArray = JSON.parse(resultSet.getValue(infoIndex) as string) as PasswordInfoItem[]
    const passwordIndex = infoArray.findIndex(item => item.type === '密码')
    if (passwordIndex !== -1) {
      const password = infoArray[passwordIndex].value
      const length = password.length
      const hasDigit = /[0-9]/.test(password)
      const hasLower = /[a-z]/.test(password)
      const hasUpper = /[A-Z]/.test(password)
      const hasOther = /[^0-9a-zA-Z]/.test(password)
      const typeCount = [hasDigit, hasLower, hasUpper, hasOther].filter(Boolean).length
      if (length < 8 || typeCount === 1) {
        array[0].push({
          id: resultSet.getValue(idIndex) as number,
          name: resultSet.getValue(nameIndex) as string
        })
      }
      if ((length >= 8 && length < 12 && typeCount >= 2) || (length >= 12 && typeCount === 2)) {
        array[1].push({
          id: resultSet.getValue(idIndex) as number,
          name: resultSet.getValue(nameIndex) as string
        })
      }
      if (length >= 12 && typeCount >= 3) {
        array[2].push({
          id: resultSet.getValue(idIndex) as number,
          name: resultSet.getValue(nameIndex) as string
        })
      }
    }
  }
  resultSet.close()
  return array
}

export async function getRepeatPasswordList() {
  const context = getContext()
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'password',
    securityLevel: 4,
    encrypt: true,
    allowRebuild: true
  })
  const predicates = new relationalStore.RdbPredicates('password')
  const resultSet = await rdbStore.query(predicates)
  const idIndex = resultSet.getColumnIndex('id')
  const nameIndex = resultSet.getColumnIndex('name')
  const infoIndex = resultSet.getColumnIndex('info')
  const arrayMap = new Map<string, RepeatItem>()
  while (resultSet.goToNextRow()) {
    const infoArray = JSON.parse(resultSet.getValue(infoIndex) as string) as PasswordInfoItem[]
    const passwordInfo = infoArray.find(item => item.type === '密码')
    if (passwordInfo) {
      const password = passwordInfo.value
      const id = resultSet.getValue(idIndex) as number
      const name = resultSet.getValue(nameIndex) as string
      if (!arrayMap.has(password)) {
        arrayMap.set(password, {
          password,
          count: 1,
          list: [{
            id: id,
            name: name
          }]
        })
      }
      if (arrayMap.has(password)) {
        const item = arrayMap.get(password)!
        item.count++
        item.list.push({
          id: id,
          name: name
        })
      }
    }
  }
  resultSet.close()
  const array = Array.from(arrayMap.values()).filter(item => item.count !== 1).sort((a, b) => b.count - a.count)
  return array
}

export async function getOldPasswordList() {
  const context = getContext()
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'password',
    securityLevel: 4,
    encrypt: true,
    allowRebuild: true
  })
  const predicates = new relationalStore.RdbPredicates('password')
  const resultSet = await rdbStore.query(predicates)
  const idIndex = resultSet.getColumnIndex('id')
  const nameIndex = resultSet.getColumnIndex('name')
  const infoIndex = resultSet.getColumnIndex('info')
  const updateTimeIndex = resultSet.getColumnIndex('updateTime')
  const array: ListItem[] = []
  while (resultSet.goToNextRow()) {
    const infoArray = JSON.parse(resultSet.getValue(infoIndex) as string) as PasswordInfoItem[]
    const updateTime = resultSet.getValue(updateTimeIndex) as number
    if (infoArray.findIndex(item => item.type === '密码') !== -1 && updateTime < Date.now() - 31536000000) {
      array.push({
        id: resultSet.getValue(idIndex) as number,
        name: resultSet.getValue(nameIndex) as string
      })
    }
  }
  resultSet.close()
  return array
}