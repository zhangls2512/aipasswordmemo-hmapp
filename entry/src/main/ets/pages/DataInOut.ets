import { common } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { fileIo, picker } from '@kit.CoreFileKit'
import { importCsvPassword, parseCsvLine } from '../common/Csv'
import { getInfoList, getPasswordList, getPasswordMaxId, getTagList, PasswordInfoItem } from '../common/Dataget'
import { importInfo, importPassword, importTag } from '../common/Dataimport'
import { read } from '../common/File'
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

  escapeCsvField(value?: string) {
    const outValue = String(value)
    if (/[,"\n]/.test(outValue)) {
      return '"' + outValue.replace(/"/g, '""') + '"'
    }
    return outValue
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
                const filePath = uris[0]
                const filestring = read(filePath)
                let conflictResolution = 0
                if (this.index === 1) {
                  conflictResolution = 5
                }
                if (filePath.endsWith('.txt')) {
                  await importPassword(filestring, conflictResolution)
                  promptAction.openToast({
                    message: '导入成功'
                  })
                }
                if (filePath.endsWith('.csv')) {
                  importCsvPassword(filestring)
                }
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
                const filePath = uris[0]
                const filestring = read(filePath)
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
                const filePath = uris[0]
                const filestring = read(filePath)
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
              Span('中所述的标准格式。\n因密码“图标”类型信息存储方式特殊 (图标文件存储在应用沙箱文件目录而非数据库)，目前不支持导入。')
                .fontColor($r('sys.color.font_secondary'))
            }
            .enableAutoSpacing(true)
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
                const filePath = uris[0]
                const filestring = read(filePath)
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
                  const parsedFields = parseCsvLine(line)
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
                const array = await getPasswordList()
                const arrayOut = array.map((item): PasswordOutItem => {
                  let cloudBackupTime = JSON.stringify([])
                  if (typeof (item.cloudBackupTime) === 'string') {
                    cloudBackupTime = item.cloudBackupTime
                  }
                  return {
                    id: item.id,
                    name: item.name,
                    info: item.info.filter(itema => itema.type !== '图标'),
                    tag: item.tag.map(item => item.value),
                    updateTime: item.updateTime,
                    cloudBackupTime: cloudBackupTime
                  }
                })
                const documentSaveOptions = new picker.DocumentSaveOptions()
                documentSaveOptions.newFileNames = ['password']
                const promptAction = this.getUIContext().getPromptAction()
                const data = await promptAction.showActionMenu({
                  title: '选择格式',
                  buttons: [
                    {
                      text: 'txt (完整)',
                      color: $r('sys.color.font_primary')
                    },
                    {
                      text: 'csv (无修改时间、云备份时间)',
                      color: $r('sys.color.font_primary')
                    }
                  ]
                })
                if (data.index === 0) {
                  documentSaveOptions.fileSuffixChoices = ['.txt']
                  const documentViewPicker = new picker.DocumentViewPicker(this.context)
                  const uris = await documentViewPicker.save(documentSaveOptions)
                  const filePath = uris[0]
                  const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_WRITE)
                  fileIo.writeSync(file.fd, JSON.stringify(arrayOut))
                  fileIo.closeSync(file)
                }
                if (data.index === 1) {
                  let filestring = ''
                  if (arrayOut.length > 0) {
                    const allInfoTypesArray: string[] = []
                    arrayOut.forEach(item => {
                      item.info.forEach(itema => {
                        if (!allInfoTypesArray.includes(itema.type)) {
                          allInfoTypesArray.push(itema.type)
                        }
                      })
                    })
                    const collator = new Intl.Collator('zh', {
                      sensitivity: 'base',
                      numeric: true
                    })
                    allInfoTypesArray.sort(collator.compare)
                    const headers = ['名称'].concat(allInfoTypesArray)
                    const rows = arrayOut.map((item) => {
                      const values = [item.name]
                      for (const infotype of allInfoTypesArray) {
                        const value = item.info.findIndex(item => item.type === infotype) === -1 ? '' :
                          item.info.find(item => item.type === infotype)?.value
                        values.push(this.escapeCsvField(value))
                      }
                      return values.join(',')
                    })
                    filestring = [headers.join(','), ...rows].join('\n')
                  }
                  documentSaveOptions.fileSuffixChoices = ['.csv']
                  const documentViewPicker = new picker.DocumentViewPicker(this.context)
                  const uris = await documentViewPicker.save(documentSaveOptions)
                  const filePath = uris[0]
                  const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_WRITE)
                  fileIo.writeSync(file.fd, filestring)
                  fileIo.closeSync(file)
                }
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
                const filePath = uris[0]
                const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_WRITE)
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
                fileIo.writeSync(file.fd, JSON.stringify(arrayOut))
                fileIo.closeSync(file)
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
                const filePath = uris[0]
                const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_WRITE)
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
                fileIo.writeSync(file.fd, JSON.stringify(arrayOut))
                fileIo.closeSync(file)
                promptAction.openToast({
                  message: '导出成功'
                })
              })
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))

            Text('因密码“图标”类型信息存储方式特殊 (图标文件存储在应用沙箱文件目录而非数据库)，目前不支持导出。')
              .fontColor($r('sys.color.font_secondary'))
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