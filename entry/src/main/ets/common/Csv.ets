import { promptAction } from '@kit.ArkUI'
import { getPasswordMaxId, PasswordInfoItem } from '../common/Dataget'
import { importPassword } from '../common/Dataimport'
import { PasswordOutItem } from '../pages/DataInOut'

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

export async function importCsvPassword(content: string) {
  const lines = content.split('\n').filter(line => line.trim() !== '')
  const result: PasswordOutItem[] = []
  const maxId = await getPasswordMaxId()
  let idCounter = maxId + 1
  const firstLine = parseCsvLine(lines[0])
  const columnCount = firstLine.length
  const nameIndex = firstLine.findIndex(item => item === '名称')
  if (nameIndex !== -1) {
    const infoColumnsIndex: number[] = []
    for (let i = 0; i < columnCount; i++) {
      if (i !== nameIndex) {
        infoColumnsIndex.push(i)
      }
    }
    for (let i = 1; i < lines.length; i++) {
      const line = lines[i]
      const parsedLine = parseCsvLine(line)
      const name = parsedLine[nameIndex]
      const info: PasswordInfoItem[] = []
      infoColumnsIndex.forEach(item => {
        if (firstLine[item] && parsedLine[item] && firstLine[item] !== '图标' && firstLine[item] !== 'MFA') {
          info.push({ type: firstLine[item], value: parsedLine[item] })
        }
      })
      if (name && info.length > 0) {
        result.push({
          id: idCounter++,
          name: name,
          info,
          tag: [],
          updateTime: Date.now(),
          cloudBackupTime: JSON.stringify([])
        })
      }
    }
    await importPassword(JSON.stringify(result), 0)
    promptAction.openToast({
      message: '导入成功'
    })
  }
  if (nameIndex === -1) {
    promptAction.openToast({
      message: '导入失败，原因：无名称列'
    })
  }
}