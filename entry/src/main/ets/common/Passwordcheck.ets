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

export async function getRepeatPasswordList(): Promise<RepeatItem[]> {
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
      if (arrayMap.has(password)) {
        const item = arrayMap.get(password)!
        item.count++
        item.list.push({
          id: id,
          name: name
        })
      } else {
        arrayMap.set(password, {
          password,
          count: 1,
          list: [{
            id: id,
            name: name
          }]
        })
      }
    }
  }
  resultSet.close()
  const array = Array.from(arrayMap.values()).filter(item => item.count !== 1).sort((a, b) => b.count - a.count)
  return array
}