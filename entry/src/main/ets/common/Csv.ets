import { relationalStore } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { getPasswordMaxId, PasswordInfoItem } from './Dataget'
import { importPassword, PasswordItem } from './Dataimport'
import { getFlushPreference } from './Preference'

export function parseCsvLine(line: string) {
  const result: string[] = []
  let inQuotes = false
  let currentField = ''
  for (let i = 0; i < line.length; i++) {
    const char = line[i]
    if (char === '"') {
      if (inQuotes && line[i + 1] === '"') {
        currentField += '"'
        i++
      } else {
        inQuotes = !inQuotes
      }
    } else if (char === ',' && !inQuotes) {
      result.push(currentField)
      currentField = ''
    } else {
      currentField += char
    }
  }
  result.push(currentField)
  return result
}

export async function importCsvPassword(context: Context, content: string) {
  if (!content) {
    await promptAction.openToast({
      message: '导入失败，原因：文件为空'
    })
    return
  }
  const lines = content.split('\n').filter(line => line.trim() !== '')
  const result: PasswordItem[] = []
  const maxId = await getPasswordMaxId(context)
  let idCounter = maxId + 1
  const firstLine = parseCsvLine(lines[0])
  const nameIndex = firstLine.indexOf('名称')
  if (nameIndex !== -1) {
    const infoColumnsIndex: number[] = []
    firstLine.forEach((item, index) => {
      if (index !== nameIndex) {
        infoColumnsIndex.push(index)
      }
    })
    const storeValueHistoryPasswordInfoTypeArray =
      getFlushPreference(context, 'commonSetting', 'storeValueHistoryPasswordInfoType', ['密码']) as string[]
    lines.forEach((item, index) => {
      if (index !== 0) {
        const parsedLine = parseCsvLine(item)
        const name = parsedLine[nameIndex]
        const info: PasswordInfoItem[] = []
        const updateTime = Date.now()
        infoColumnsIndex.forEach(item => {
          if (firstLine[item] && parsedLine[item] && firstLine[item] !== 'MFA') {
            const type = firstLine[item]
            const value = parsedLine[item]
            if (!storeValueHistoryPasswordInfoTypeArray.includes(type)) {
              info.push({
                type: type,
                value: value,
                history: []
              })
            }
            if (storeValueHistoryPasswordInfoTypeArray.includes(type)) {
              info.push({
                type: type,
                value: value,
                history: [
                  {
                    value: value,
                    updateTime: updateTime
                  }
                ]
              })
            }
          }
        })
        if (name && info.length > 0) {
          result.push({
            id: idCounter++,
            name: name,
            info: info,
            tag: [],
            updateTime: updateTime,
            cloudBackupTime: []
          })
        }
      }
    })
    await importPassword(context, JSON.stringify(result), relationalStore.ConflictResolution.ON_CONFLICT_IGNORE)
    await promptAction.openToast({
      message: '导入成功'
    })
  }
  if (nameIndex === -1) {
    await promptAction.openToast({
      message: '导入失败，原因：无名称列'
    })
  }
}