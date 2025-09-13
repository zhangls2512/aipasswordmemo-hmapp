import { get, getAccountInfo } from '../common/Accesstoken'
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

export async function importCloudBackupPassword() {
  const accessToken = await get()
  const accountInfo = await getAccountInfo()
  if (accessToken && getKey()) {
    const countres = await request('/password/getBackupCount', {
      accessToken: accessToken
    })
    if (countres !== 'fail') {
      const total = JSON.parse(countres).count.password as number
      for (let i = 0; i < total; i += 50) {
        const listres = await request('/password/getBackupList', {
          accessToken: accessToken,
          type: 'password',
          skip: i,
          count: 50
        })
        if (listres !== 'fail') {
          const listarray = JSON.parse(listres).data as Item[]
          const array: PasswordInItem[] = []
          const promises = listarray.map(async (item) => {
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
              array.push({
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
          await importPassword(JSON.stringify(array), 0)
        }
      }
    }
  }
}

export async function importCloudBackupInfo() {
  const accessToken = await get()
  const accountInfo = await getAccountInfo()
  if (accessToken && getKey()) {
    const countres = await request('/password/getBackupCount', {
      accessToken: accessToken
    })
    if (countres !== 'fail') {
      const total = JSON.parse(countres).count.info as number
      for (let i = 0; i < total; i += 50) {
        const listres = await request('/password/getBackupList', {
          accessToken: accessToken,
          type: 'info',
          skip: i,
          count: 50
        })
        if (listres !== 'fail') {
          const listarray = JSON.parse(listres).data as Item[]
          const array: InfoInItem[] = []
          const promises = listarray.map(async (item) => {
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
              array.push({
                id: item.id,
                type: itemobject.type,
                value: itemobject.value,
                updateTime: itemobject.updateTime,
                cloudBackupTime: cloudBackupTime
              })
            }
          })
          await Promise.all(promises)
          await importInfo(JSON.stringify(array), 0)
        }
      }
    }
  }
}

export async function importCloudBackupTag() {
  const accessToken = await get()
  const accountInfo = await getAccountInfo()
  if (accessToken && getKey()) {
    const countres = await request('/password/getBackupCount', {
      accessToken: accessToken
    })
    if (countres !== 'fail') {
      const total = JSON.parse(countres).count.tag as number
      for (let i = 0; i < total; i += 50) {
        const listres = await request('/password/getBackupList', {
          accessToken: accessToken,
          type: 'tag',
          skip: i,
          count: 50
        })
        if (listres !== 'fail') {
          const listarray = JSON.parse(listres).data as Item[]
          const array: TagInItem[] = []
          const promises = listarray.map(async (item) => {
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
              array.push({
                id: item.id,
                value: itemobject.value,
                color: itemobject.color,
                updateTime: itemobject.updateTime,
                cloudBackupTime: cloudBackupTime
              })
            }
          })
          await Promise.all(promises)
          await importTag(JSON.stringify(array), 0)
        }
      }
    }
  }
}