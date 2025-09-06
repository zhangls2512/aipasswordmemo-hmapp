import { common } from '@kit.AbilityKit'
import { util } from '@kit.ArkTS'
import { promptAction } from '@kit.ArkUI'
import { fileIo as fs, picker } from '@kit.CoreFileKit'
import { getInfoList, getPasswordList, getPasswordMaxId, getTagList, PasswordInfoItem } from '../common/Dataget'
import { importInfo, importPassword, importTag } from '../common/Dataimport'
import openLink from '../common/Openlink'

export interface PasswordOutItem {
  id: number,
  name: string,
  info: PasswordInfoItem[],
  tag: string[],
  updateTime: number,
  cloudBackupTime: string
}

interface InfoOutItem {
  id: number,
  type: string,
  value: string,
  updateTime: number,
  cloudBackupTime: string
}

interface TagOutItem {
  id: number,
  value: string,
  color: string,
  updateTime: number,
  cloudBackupTime: string
}

@Builder
export function DataInOutBuilder() {
  DataInOut()
}

@ComponentV2
struct DataInOut {
  @Local index: number = 0
  @Local value: string = '保留'
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()

  parseCsvLine(line: string) {
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

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Row() {
              Text('冲突解决模式')
                .fontWeight(FontWeight.Medium)
              Blank()
              Select([
                { value: '保留' },
                { value: '覆盖' }
              ])
                .selected(this.index!!)
                .value(this.value!!)
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Column() {
            Text('导入')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              Row() {
                Text('密码')
                  .fontWeight(FontWeight.Medium)
                Blank()
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(async () => {
                const documentSelectOptions = new picker.DocumentSelectOptions()
                documentSelectOptions.maxSelectNumber = 1
                documentSelectOptions.fileSuffixFilters = ['.txt', '.csv']
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.select(documentSelectOptions)
                const file = fs.openSync(uris[0])
                const name = file.name
                const size = fs.statSync(file.fd).size
                const filebuffer = new ArrayBuffer(size)
                fs.readSync(file.fd, filebuffer)
                const decoder = util.TextDecoder.create()
                const filestring = decoder.decodeToString(new Uint8Array(filebuffer))
                fs.closeSync(file)
                let conflictResolution = 0
                if (this.index === 1) {
                  conflictResolution = 5
                }
                if (name.endsWith('.txt')) {
                  await importPassword(filestring, conflictResolution)
                }
                if (name.endsWith('.csv')) {
                  const lines = filestring.split('\n').filter(line => line.trim() !== '')
                  const result: PasswordOutItem[] = []
                  const maxId = await getPasswordMaxId()
                  let idCounter = maxId + 1
                  const firstLine = this.parseCsvLine(lines[0])
                  const columnCount = firstLine.length
                  const nameIndex = firstLine.findIndex(item => item === '名称')
                  if (nameIndex === -1) {
                    promptAction.openToast({
                      message: '导入失败，原因：无名称列'
                    })
                    return
                  }
                  const infoColumnsIndex: number[] = []
                  for (let i = 0; i < columnCount; i++) {
                    if (i !== nameIndex) {
                      infoColumnsIndex.push(i)
                    }
                  }
                  for (let i = 1; i < lines.length; i++) {
                    const line = lines[i]
                    const parsedLine = this.parseCsvLine(line)
                    const name = parsedLine[nameIndex]
                    const info: PasswordInfoItem[] = []
                    infoColumnsIndex.forEach(item => {
                      if (firstLine[item] && parsedLine[item] && firstLine[item] !== '图标' &&
                        firstLine[item] !== 'MFA') {
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
                  await importPassword(JSON.stringify(result), conflictResolution)
                }
                promptAction.openToast({
                  message: '导入成功'
                })
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('常用信息')
                  .fontWeight(FontWeight.Medium)
                Blank()
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(async () => {
                const documentSelectOptions = new picker.DocumentSelectOptions()
                documentSelectOptions.maxSelectNumber = 1
                documentSelectOptions.fileSuffixFilters = ['.txt']
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.select(documentSelectOptions)
                const file = fs.openSync(uris[0])
                const size = fs.statSync(file.fd).size
                const filebuffer = new ArrayBuffer(size)
                fs.readSync(file.fd, filebuffer)
                const decoder = util.TextDecoder.create()
                const filestring = decoder.decodeToString(new Uint8Array(filebuffer))
                fs.closeSync(file)
                let conflictResolution = 0
                if (this.index === 1) {
                  conflictResolution = 5
                }
                await importInfo(filestring, conflictResolution)
                promptAction.openToast({
                  message: '导入成功'
                })
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('标签')
                  .fontWeight(FontWeight.Medium)
                Blank()
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(async () => {
                const documentSelectOptions = new picker.DocumentSelectOptions()
                documentSelectOptions.maxSelectNumber = 1
                documentSelectOptions.fileSuffixFilters = ['.txt']
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.select(documentSelectOptions)
                const file = fs.openSync(uris[0])
                const size = fs.statSync(file.fd).size
                const filebuffer = new ArrayBuffer(size)
                fs.readSync(file.fd, filebuffer)
                const decoder = util.TextDecoder.create()
                const filestring = decoder.decodeToString(new Uint8Array(filebuffer))
                fs.closeSync(file)
                let conflictResolution = 0
                if (this.index === 1) {
                  conflictResolution = 5
                }
                await importTag(filestring, conflictResolution)
                promptAction.openToast({
                  message: '导入成功'
                })
              })
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))

            Text() {
              Span('导入密码须知：txt文件需为从本页面下方导出的、csv文件需为')
                .fontColor($r('sys.color.font_secondary'))
              Span('此文档')
                .fontColor($r('sys.color.font_emphasize'))
                .fontWeight(FontWeight.Medium)
                .onClick(() => {
                  openLink('https://docs.qq.com/doc/p/a12dc0f6d9e9ab998d81ddd1ddc95b5445518209')
                })
              Span('中所述的标准格式')
                .fontColor($r('sys.color.font_secondary'))
            }
            .fontSize($r('sys.float.ohos_id_text_size_body3'))
            .enableAutoSpacing(true)
            .margin({
              top: 6,
              left: 12,
              right: 12
            })
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('导入第三方密码')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              Row() {
                Text('Edge、Chrome')
                  .fontWeight(FontWeight.Medium)
                Blank()
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(async () => {
                const documentSelectOptions = new picker.DocumentSelectOptions()
                documentSelectOptions.maxSelectNumber = 1
                documentSelectOptions.fileSuffixFilters = ['.csv']
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.select(documentSelectOptions)
                const file = fs.openSync(uris[0])
                const size = fs.statSync(file.fd).size
                const filebuffer = new ArrayBuffer(size)
                fs.readSync(file.fd, filebuffer)
                const decoder = util.TextDecoder.create()
                const filestring = decoder.decodeToString(new Uint8Array(filebuffer))
                fs.closeSync(file)
                let conflictResolution = 0
                if (this.index === 1) {
                  conflictResolution = 5
                }
                const lines = filestring.split('\n').filter(line => line.trim() !== '')
                const result: PasswordOutItem[] = []
                const maxId = await getPasswordMaxId()
                let idCounter = maxId + 1
                for (let i = 1; i < lines.length; i++) {
                  const line = lines[i]
                  const parsedFields = this.parseCsvLine(line)
                  const name = parsedFields[0]
                  const url = parsedFields[1]
                  const username = parsedFields[2]
                  const password = parsedFields[3]
                  const info: PasswordInfoItem[] = []
                  if (username) {
                    info.push({ type: '用户名', value: username })
                  }
                  if (password) {
                    info.push({ type: '密码', value: password })
                  }
                  if (url) {
                    info.push({ type: 'URL', value: url })
                  }
                  result.push({
                    id: idCounter++,
                    name,
                    info,
                    tag: [],
                    updateTime: Date.now(),
                    cloudBackupTime: JSON.stringify([])
                  })
                }
                await importPassword(JSON.stringify(result), conflictResolution)
                promptAction.openToast({
                  message: '导入成功'
                })
              })
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))

            Text() {
              Span('联系')
                .fontColor($r('sys.color.font_secondary'))
              Span('客服')
                .fontColor($r('sys.color.font_emphasize'))
                .fontWeight(FontWeight.Medium)
                .onClick(() => {
                  this.pageInfos.pushPath({
                    name: 'About'
                  })
                })
              Span('申请适配更多第三方')
                .fontColor($r('sys.color.font_secondary'))
            }
            .fontSize($r('sys.float.ohos_id_text_size_body3'))
            .margin({
              top: 6,
              left: 12,
              right: 12
            })
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('导出')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              Row() {
                Text('密码')
                  .fontWeight(FontWeight.Medium)
                Blank()
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(async () => {
                const documentSaveOptions = new picker.DocumentSaveOptions()
                documentSaveOptions.newFileNames = ['password']
                documentSaveOptions.fileSuffixChoices = ['.txt']
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.save(documentSaveOptions)
                const file = fs.openSync(uris[0], fs.OpenMode.READ_WRITE)
                const array = await getPasswordList()
                const arrayOut = array.map((item): PasswordOutItem => {
                  let cloudBackupTime = JSON.stringify([])
                  if (typeof (item.cloudBackupTime) === 'string') {
                    cloudBackupTime = item.cloudBackupTime
                  }
                  return {
                    id: item.id,
                    name: item.name,
                    info: item.info,
                    tag: item.tag.map(item => item.value),
                    updateTime: item.updateTime,
                    cloudBackupTime: cloudBackupTime
                  }
                })
                fs.writeSync(file.fd, JSON.stringify(arrayOut))
                fs.closeSync(file)
                promptAction.openToast({
                  message: '导出成功'
                })
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('常用信息')
                  .fontWeight(FontWeight.Medium)
                Blank()
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(async () => {
                const documentSaveOptions = new picker.DocumentSaveOptions()
                documentSaveOptions.newFileNames = ['info']
                documentSaveOptions.fileSuffixChoices = ['.txt']
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.save(documentSaveOptions)
                const file = fs.openSync(uris[0], fs.OpenMode.READ_WRITE)
                const array = await getInfoList()
                const arrayOut = array.map((item): InfoOutItem => {
                  let cloudBackupTime = JSON.stringify([])
                  if (typeof (item.cloudBackupTime) === 'string') {
                    cloudBackupTime = item.cloudBackupTime
                  }
                  return {
                    id: item.id,
                    type: item.type,
                    value: item.value,
                    updateTime: item.updateTime,
                    cloudBackupTime: cloudBackupTime
                  }
                })
                fs.writeSync(file.fd, JSON.stringify(arrayOut))
                fs.closeSync(file)
                promptAction.openToast({
                  message: '导出成功'
                })
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('标签')
                  .fontWeight(FontWeight.Medium)
                Blank()
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(async () => {
                const documentSaveOptions = new picker.DocumentSaveOptions()
                documentSaveOptions.newFileNames = ['tag']
                documentSaveOptions.fileSuffixChoices = ['.txt']
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.save(documentSaveOptions)
                const file = fs.openSync(uris[0], fs.OpenMode.READ_WRITE)
                const array = await getTagList()
                const arrayOut = array.map((item): TagOutItem => {
                  let cloudBackupTime = JSON.stringify([])
                  if (typeof (item.cloudBackupTime) === 'string') {
                    cloudBackupTime = item.cloudBackupTime
                  }
                  return {
                    id: item.id,
                    value: item.value,
                    color: item.color,
                    updateTime: item.updateTime,
                    cloudBackupTime: cloudBackupTime
                  }
                })
                fs.writeSync(file.fd, JSON.stringify(arrayOut))
                fs.closeSync(file)
                promptAction.openToast({
                  message: '导出成功'
                })
              })
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })
      }
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title('数据导入与导出')
    .onReady((context) => {
      this.pageInfos = context.pathStack
    })
  }
}