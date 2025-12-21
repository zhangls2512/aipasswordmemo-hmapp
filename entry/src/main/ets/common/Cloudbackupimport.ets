import { relationalStore } from '@kit.ArkData'
import { getAccountAccessToken, getAccountInfo } from '../common/Accesstoken'
import { decrypt, getKey } from '../common/Crypto'
import { PasswordInfoItem } from '../common/Dataget'
import { importInfo, importPassword, importTag, InfoInItem, PasswordInItem, TagInItem } from '../common/Dataimport'
import request from '../common/Request'

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
  cloudBackupTime: string | number
}

interface InfoCloudBackup {
  type: string,
  value: string,
  updateTime: number,
  cloudBackupTime: string | number
}

interface TagCloudBackup {
  value: string,
  color: string,
  updateTime: number,
  cloudBackupTime: string | number
}

export async function importCloudBackupPassword(context: Context) {
  const accessToken = await getAccountAccessToken()
  if (accessToken && getKey()) {
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
          const accountInfo = await getAccountInfo()
          const promises = array.map(async (item) => {
            const itemstring = await decrypt({
              content: item.content,
              iv: item.iv
            })
            if (itemstring !== 'fail') {
              const itemobject = JSON.parse(itemstring) as PasswordCloudBackup
              let cloudBackupTime = itemobject.cloudBackupTime
              if (typeof (cloudBackupTime) === 'number') {
                cloudBackupTime = JSON.stringify([{
                  uid: accountInfo.uid,
                  time: itemobject.cloudBackupTime
                }])
              }
              passwordArray.push({
                id: item.id,
                name: itemobject.name,
                info: itemobject.info,
                tag: itemobject.tag,
                updateTime: itemobject.updateTime,
                cloudBackupTime: cloudBackupTime
              })
            }
          })
          await Promise.all(promises)
          await importPassword(context, JSON.stringify(passwordArray),
            relationalStore.ConflictResolution.ON_CONFLICT_IGNORE)
        }
      }
      return 'success'
    }
  }
  return 'fail'
}

export async function importCloudBackupInfo(context: Context) {
  const accessToken = await getAccountAccessToken()
  if (accessToken && getKey()) {
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
          const accountInfo = await getAccountInfo()
          const promises = array.map(async (item) => {
            const itemstring = await decrypt({
              content: item.content,
              iv: item.iv
            })
            if (itemstring !== 'fail') {
              const itemobject = JSON.parse(itemstring) as InfoCloudBackup
              let cloudBackupTime = itemobject.cloudBackupTime
              if (typeof (cloudBackupTime) === 'number') {
                cloudBackupTime = JSON.stringify([{
                  uid: accountInfo.uid,
                  time: itemobject.cloudBackupTime
                }])
              }
              infoArray.push({
                id: item.id,
                type: itemobject.type,
                value: itemobject.value,
                updateTime: itemobject.updateTime,
                cloudBackupTime: cloudBackupTime
              })
            }
          })
          await Promise.all(promises)
          await importInfo(context, JSON.stringify(infoArray), relationalStore.ConflictResolution.ON_CONFLICT_IGNORE)
        }
      }
      return 'success'
    }
  }
  return 'fail'
}

export async function importCloudBackupTag(context: Context) {
  const accessToken = await getAccountAccessToken()
  if (accessToken && getKey()) {
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
          const accountInfo = await getAccountInfo()
          const promises = array.map(async (item) => {
            const itemstring = await decrypt({
              content: item.content,
              iv: item.iv
            })
            if (itemstring !== 'fail') {
              const itemobject = JSON.parse(itemstring) as TagCloudBackup
              let cloudBackupTime = itemobject.cloudBackupTime
              if (typeof (cloudBackupTime) === 'number') {
                cloudBackupTime = JSON.stringify([{
                  uid: accountInfo.uid,
                  time: itemobject.cloudBackupTime
                }])
              }
              tagArray.push({
                id: item.id,
                value: itemobject.value,
                color: itemobject.color,
                updateTime: itemobject.updateTime,
                cloudBackupTime: cloudBackupTime
              })
            }
          })
          await Promise.all(promises)
          await importTag(context, JSON.stringify(tagArray), relationalStore.ConflictResolution.ON_CONFLICT_IGNORE)
        }
      }
      return 'success'
    }
  }
  return 'fail'
}