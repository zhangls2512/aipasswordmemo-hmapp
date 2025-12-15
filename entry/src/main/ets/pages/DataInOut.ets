import { common } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { fileIo, picker } from '@kit.CoreFileKit'
import { importCsvPassword, parseCsvLine } from '../common/Csv'
import { getInfoList, getPasswordList, getPasswordMaxId, getTagList, PasswordInfoItem } from '../common/Dataget'
import { importInfo, importPassword, importTag } from '../common/Dataimport'
import { readUri } from '../common/File'
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
  @Local hoverId: number = -1
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
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
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
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
                left: 12,
                right: 12
              })
            Column() {
              Row() {
                Text('密码')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor(this.hoverId === 0 ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onHover((isHover) => {
                if (!isHover) {
                  this.hoverId = -1
                }
                if (isHover) {
                  this.hoverId = 0
                }
              })
              .onClick(async () => {
                const documentSelectOptions = new picker.DocumentSelectOptions()
                documentSelectOptions.maxSelectNumber = 1
                documentSelectOptions.fileSuffixFilters = ['.txt', '.csv']
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.select(documentSelectOptions)
                if (uris.length === 1) {
                  const filePath = uris[0]
                  const filestring = await readUri(filePath)
                  let conflictResolution = 0
                  if (this.index === 1) {
                    conflictResolution = 5
                  }
                  if (filePath.endsWith('.txt')) {
                    await importPassword(this.context, filestring, conflictResolution)
                    await promptAction.openToast({
                      message: '导入成功'
                    })
                  }
                  if (filePath.endsWith('.csv')) {
                    await importCsvPassword(this.context, filestring)
                  }
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
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor(this.hoverId === 1 ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onHover((isHover) => {
                if (!isHover) {
                  this.hoverId = -1
                }
                if (isHover) {
                  this.hoverId = 1
                }
              })
              .onClick(async () => {
                const documentSelectOptions = new picker.DocumentSelectOptions()
                documentSelectOptions.maxSelectNumber = 1
                documentSelectOptions.fileSuffixFilters = ['.txt']
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.select(documentSelectOptions)
                if (uris.length === 1) {
                  const filePath = uris[0]
                  const filestring = await readUri(filePath)
                  let conflictResolution = 0
                  if (this.index === 1) {
                    conflictResolution = 5
                  }
                  await importInfo(this.context, filestring, conflictResolution)
                  await promptAction.openToast({
                    message: '导入成功'
                  })
                }
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('标签')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor(this.hoverId === 2 ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onHover((isHover) => {
                if (!isHover) {
                  this.hoverId = -1
                }
                if (isHover) {
                  this.hoverId = 2
                }
              })
              .onClick(async () => {
                const documentSelectOptions = new picker.DocumentSelectOptions()
                documentSelectOptions.maxSelectNumber = 1
                documentSelectOptions.fileSuffixFilters = ['.txt']
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.select(documentSelectOptions)
                if (uris.length === 1) {
                  const filePath = uris[0]
                  const filestring = await readUri(filePath)
                  let conflictResolution = 0
                  if (this.index === 1) {
                    conflictResolution = 5
                  }
                  await importTag(this.context, filestring, conflictResolution)
                  await promptAction.openToast({
                    message: '导入成功'
                  })
                }
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
                .onClick(async () => {
                  await openLink(this.context, 'https://docs.qq.com/doc/p/a12dc0f6d9e9ab998d81ddd1ddc95b5445518209')
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
                left: 12,
                right: 12
              })
            Column() {
              Row() {
                Text('Edge、Chrome')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor(this.hoverId === 3 ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onHover((isHover) => {
                if (!isHover) {
                  this.hoverId = -1
                }
                if (isHover) {
                  this.hoverId = 3
                }
              })
              .onClick(async () => {
                const documentSelectOptions = new picker.DocumentSelectOptions()
                documentSelectOptions.maxSelectNumber = 1
                documentSelectOptions.fileSuffixFilters = ['.csv']
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.select(documentSelectOptions)
                if (uris.length === 1) {
                  const filePath = uris[0]
                  const filestring = await readUri(filePath)
                  let conflictResolution = 0
                  if (this.index === 1) {
                    conflictResolution = 5
                  }
                  const lines = filestring.split('\n').filter(line => line.trim() !== '')
                  const result: PasswordOutItem[] = []
                  const maxId = await getPasswordMaxId(this.context)
                  let idCounter = maxId + 1
                  lines.forEach(item => {
                    const parsedFields = parseCsvLine(item)
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
                  })
                  await importPassword(this.context, JSON.stringify(result), conflictResolution)
                  await promptAction.openToast({
                    message: '导入成功'
                  })
                }
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
                left: 12,
                right: 12
              })
            Column() {
              Row() {
                Text('密码')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor(this.hoverId === 4 ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onHover((isHover) => {
                if (!isHover) {
                  this.hoverId = -1
                }
                if (isHover) {
                  this.hoverId = 4
                }
              })
              .onClick(async () => {
                const array = await getPasswordList(this.context)
                const arrayOut = array.map((item): PasswordOutItem => {
                  let cloudBackupTime = JSON.stringify([])
                  if (typeof (item.cloudBackupTime) === 'string') {
                    cloudBackupTime = item.cloudBackupTime
                  }
                  return {
                    id: item.id,
                    name: item.name,
                    info: item.info.filter(infoItem => infoItem.type !== '图标'),
                    tag: item.tag.map(item => item.value),
                    updateTime: item.updateTime,
                    cloudBackupTime: cloudBackupTime
                  }
                })
                const documentSaveOptions = new picker.DocumentSaveOptions()
                documentSaveOptions.newFileNames = ['password']
                const promptAction = this.UIContext.getPromptAction()
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
                  try {
                    documentSaveOptions.fileSuffixChoices = ['.txt']
                    const documentViewPicker = new picker.DocumentViewPicker(this.context)
                    const uris = await documentViewPicker.save(documentSaveOptions)
                    const filePath = uris[0]
                    const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE)
                    await fileIo.write(file.fd, JSON.stringify(arrayOut))
                    fileIo.closeSync(file)
                    await promptAction.openToast({
                      message: '导出成功'
                    })
                  } catch (err) {
                    if (err.code !== 13900020) {
                      await promptAction.openToast({
                        message: '发生错误，错误码：' + err.code
                      })
                    }
                  }
                }
                if (data.index === 1) {
                  try {
                    let filestring = ''
                    if (arrayOut.length > 0) {
                      const allInfoTypesArray: string[] = []
                      arrayOut.forEach(item => {
                        item.info.forEach(infoItem => {
                          if (!allInfoTypesArray.includes(infoItem.type)) {
                            allInfoTypesArray.push(infoItem.type)
                          }
                        })
                      })
                      const collator = new Intl.Collator('zh', {
                        sensitivity: 'base',
                        numeric: true
                      })
                      allInfoTypesArray.sort(collator.compare)
                      const headers = ['名称'].concat(allInfoTypesArray)
                      const rows = arrayOut.map(item => {
                        const values = [item.name]
                        for (const infotype of allInfoTypesArray) {
                          let value = ''
                          const infoValue = item.info.find(item => item.type === infotype)
                          if (infoValue) {
                            value = infoValue.value
                          }
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
                    const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE)
                    await fileIo.write(file.fd, filestring)
                    fileIo.closeSync(file)
                    await promptAction.openToast({
                      message: '导出成功'
                    })
                  } catch (err) {
                    if (err.code !== 13900020) {
                      await promptAction.openToast({
                        message: '发生错误，错误码：' + err.code
                      })
                    }
                  }
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
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor(this.hoverId === 5 ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onHover((isHover) => {
                if (!isHover) {
                  this.hoverId = -1
                }
                if (isHover) {
                  this.hoverId = 5
                }
              })
              .onClick(async () => {
                try {
                  const documentSaveOptions = new picker.DocumentSaveOptions()
                  documentSaveOptions.newFileNames = ['info']
                  documentSaveOptions.fileSuffixChoices = ['.txt']
                  const documentViewPicker = new picker.DocumentViewPicker(this.context)
                  const uris = await documentViewPicker.save(documentSaveOptions)
                  const filePath = uris[0]
                  const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE)
                  const array = await getInfoList(this.context)
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
                  await fileIo.write(file.fd, JSON.stringify(arrayOut))
                  fileIo.closeSync(file)
                  await promptAction.openToast({
                    message: '导出成功'
                  })
                } catch (err) {
                  if (err.code !== 13900020) {
                    await promptAction.openToast({
                      message: '发生错误，错误码：' + err.code
                    })
                  }
                }
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('标签')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor(this.hoverId === 6 ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onHover((isHover) => {
                if (!isHover) {
                  this.hoverId = -1
                }
                if (isHover) {
                  this.hoverId = 6
                }
              })
              .onClick(async () => {
                try {
                  const documentSaveOptions = new picker.DocumentSaveOptions()
                  documentSaveOptions.newFileNames = ['tag']
                  documentSaveOptions.fileSuffixChoices = ['.txt']
                  const documentViewPicker = new picker.DocumentViewPicker(this.context)
                  const uris = await documentViewPicker.save(documentSaveOptions)
                  const filePath = uris[0]
                  const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE)
                  const array = await getTagList(this.context)
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
                  await fileIo.write(file.fd, JSON.stringify(arrayOut))
                  fileIo.closeSync(file)
                  await promptAction.openToast({
                    message: '导出成功'
                  })
                } catch (err) {
                  if (err.code !== 13900020) {
                    await promptAction.openToast({
                      message: '发生错误，错误码：' + err.code
                    })
                  }
                }
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
        left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
        right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title('数据导入与导出')
    .onReady((context) => {
      this.pageInfos = context.pathStack
    })
  }
}