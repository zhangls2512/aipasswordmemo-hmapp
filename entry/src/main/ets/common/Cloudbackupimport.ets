import { relationalStore } from '@kit.ArkData'
import { getAccountAccessToken } from './Account'
import { decrypt, getKeyAlg } from './Crypto'
import { CloudBackupTimeItem, PasswordInfoItem } from './Dataget'
import { importInfo, importPassword, importTag, InfoInItem, PasswordInItem, TagInItem } from './Dataimport'
import request from './Request'

interface Item {
  id: number,
  content: string,
  iv: string
}

interface PasswordCloudBackup {
  name: string,
  info: PasswordInfoItem[],
  tag: string[],
  updateTime: number,
  cloudBackupTime: CloudBackupTimeItem[]
}

interface InfoCloudBackup {
  type: string,
  value: string,
  updateTime: number,
  cloudBackupTime: CloudBackupTimeItem[]
}

interface TagCloudBackup {
  value: string,
  color: string,
  updateTime: number,
  cloudBackupTime: CloudBackupTimeItem[]
}

export async function importCloudBackupPassword(context: Context, conflict: relationalStore.ConflictResolution) {
  const accessToken = await getAccountAccessToken()
  if (accessToken && getKeyAlg()) {
    const countResponse = await request(context, '/password/getBackupCount', {
      accessToken: accessToken
    })
    if (countResponse !== 'fail') {
      const total = JSON.parse(countResponse).count.password as number
      for (let i = 0; i < total; i += 50) {
        const listResponse = await request(context, '/password/getBackupList', {
          accessToken: accessToken,
          type: 'password',
          skip: i,
          limit: 50
        })
        if (listResponse !== 'fail') {
          const array = JSON.parse(listResponse).data as Item[]
          const passwordArray: PasswordInItem[] = []
          const promises = array.map(async (item) => {
            const itemstring = await decrypt({
              content: item.content,
              iv: item.iv
            })
            if (itemstring !== 'fail') {
              const itemobject = JSON.parse(itemstring) as PasswordCloudBackup
              passwordArray.push({
                id: item.id,
                name: itemobject.name,
                info: Array.isArray(itemobject.info) ? itemobject.info : [],
                tag: Array.isArray(itemobject.tag) ? itemobject.tag : [],
                updateTime: itemobject.updateTime,
                cloudBackupTime: Array.isArray(itemobject.cloudBackupTime) ? itemobject.cloudBackupTime : []
              })
            }
          })
          await Promise.all(promises)
          await importPassword(context, JSON.stringify(passwordArray), conflict)
        }
      }
      return 'success'
    }
  }
  return 'fail'
}

export async function importCloudBackupInfo(context: Context, conflict: relationalStore.ConflictResolution) {
  const accessToken = await getAccountAccessToken()
  if (accessToken && getKeyAlg()) {
    const countResponse = await request(context, '/password/getBackupCount', {
      accessToken: accessToken
    })
    if (countResponse !== 'fail') {
      const total = JSON.parse(countResponse).count.info as number
      for (let i = 0; i < total; i += 50) {
        const listResponse = await request(context, '/password/getBackupList', {
          accessToken: accessToken,
          type: 'info',
          skip: i,
          limit: 50
        })
        if (listResponse !== 'fail') {
          const array = JSON.parse(listResponse).data as Item[]
          const infoArray: InfoInItem[] = []
          const promises = array.map(async (item) => {
            const itemstring = await decrypt({
              content: item.content,
              iv: item.iv
            })
            if (itemstring !== 'fail') {
              const itemobject = JSON.parse(itemstring) as InfoCloudBackup
              infoArray.push({
                id: item.id,
                type: itemobject.type,
                value: itemobject.value,
                updateTime: itemobject.updateTime,
                cloudBackupTime: Array.isArray(itemobject.cloudBackupTime) ? itemobject.cloudBackupTime : []
              })
            }
          })
          await Promise.all(promises)
          await importInfo(context, JSON.stringify(infoArray), conflict)
        }
      }
      return 'success'
    }
  }
  return 'fail'
}

export async function importCloudBackupTag(context: Context, conflict: relationalStore.ConflictResolution) {
  const accessToken = await getAccountAccessToken()
  if (accessToken && getKeyAlg()) {
    const countResponse = await request(context, '/password/getBackupCount', {
      accessToken: accessToken
    })
    if (countResponse !== 'fail') {
      const total = JSON.parse(countResponse).count.tag as number
      for (let i = 0; i < total; i += 50) {
        const listResponse = await request(context, '/password/getBackupList', {
          accessToken: accessToken,
          type: 'tag',
          skip: i,
          limit: 50
        })
        if (listResponse !== 'fail') {
          const array = JSON.parse(listResponse).data as Item[]
          const tagArray: TagInItem[] = []
          const promises = array.map(async (item) => {
            const itemstring = await decrypt({
              content: item.content,
              iv: item.iv
            })
            if (itemstring !== 'fail') {
              const itemobject = JSON.parse(itemstring) as TagCloudBackup
              tagArray.push({
                id: item.id,
                value: itemobject.value,
                color: itemobject.color,
                updateTime: itemobject.updateTime,
                cloudBackupTime: Array.isArray(itemobject.cloudBackupTime) ? itemobject.cloudBackupTime : []
              })
            }
          })
          await Promise.all(promises)
          await importTag(context, JSON.stringify(tagArray), conflict)
        }
      }
      return 'success'
    }
  }
  return 'fail'
}