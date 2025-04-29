import { common } from '@kit.AbilityKit'
import { relationalStore } from '@kit.ArkData'
import { Password, Info, Tag } from './Dataget'
import { autoBackupTable, autoSyncTable } from './Table'

export async function importPassword(data: string, conflict: relationalStore.ConflictResolution) {
  const array = JSON.parse(data.replace(/[\r\n\s\u0000]/g, '')) as Password[]
  const context = getContext() as common.UIAbilityContext
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'password',
    securityLevel: 4,
    encrypt: true,
    allowRebuild: true
  })
  array.forEach((item: Password) => {
    rdbStore.insertSync('password', {
      id: item.id,
      name: item.name,
      info: JSON.stringify(item.info),
      tag: JSON.stringify(item.tag),
      updateTime: item.updateTime,
      cloudBackupTime: item.cloudBackupTime
    }, conflict)
  })
  autoSyncTable('password')
  autoBackupTable('password')
}

export async function importInfo(data: string, conflict: relationalStore.ConflictResolution) {
  const array = JSON.parse(data.replace(/[\r\n\s\u0000]/g, '')) as Info[]
  const context = getContext() as common.UIAbilityContext
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'info',
    securityLevel: 4,
    encrypt: true,
    allowRebuild: true
  })
  array.forEach((item: Info) => {
    rdbStore.insertSync('info', {
      id: item.id,
      type: item.type,
      value: item.value,
      updateTime: item.updateTime,
      cloudBackupTime: item.cloudBackupTime
    }, conflict)
  })
  autoSyncTable('info')
  autoBackupTable('info')
}

export async function importTag(data: string, conflict: relationalStore.ConflictResolution) {
  const array = JSON.parse(data.replace(/[\r\n\s\u0000]/g, '')) as Tag[]
  const context = getContext() as common.UIAbilityContext
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'tag',
    securityLevel: 1,
    encrypt: true,
    allowRebuild: true
  })
  array.forEach((item: Tag) => {
    rdbStore.insertSync('tag', {
      id: item.id,
      value: item.value,
      color: item.color,
      updateTime: item.updateTime,
      cloudBackupTime: item.cloudBackupTime
    }, conflict)
  })
  autoSyncTable('tag')
  autoBackupTable('tag')
}