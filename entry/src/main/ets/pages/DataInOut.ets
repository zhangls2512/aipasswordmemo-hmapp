import { common } from '@kit.AbilityKit'
import { relationalStore } from '@kit.ArkData'
import { LengthMetrics, promptAction } from '@kit.ArkUI'
import { zlib } from '@kit.BasicServicesKit'
import { fileIo, picker } from '@kit.CoreFileKit'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { importCsvPassword, parseCsvLine } from '../common/Csv'
import { getInfoList, getPasswordList, getPasswordMaxId, getTagList, PasswordInfoItem } from '../common/Dataget'
import { importInfo, importPassword, importTag } from '../common/Dataimport'
import { readUri, writeUri } from '../common/File'
import openLink from '../common/Openlink'

export interface PasswordOutItem {
  id: number,
  name: string,
  info: PasswordInfoItem[],
  tag: string[],
  updateTime: number,
  cloudBackupTime: string
}

export interface InfoOutItem {
  id: number,
  type: string,
  value: string,
  updateTime: number,
  cloudBackupTime: string
}

export interface TagOutItem {
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
    HdsNavDestination() {
      List() {
        ListItem()
          .margin({
            top: 64
          })
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
            Text('导入 (支持加密备份文件)')
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
              .onHover(isHover => {
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
                  let conflictResolution = relationalStore.ConflictResolution.ON_CONFLICT_IGNORE
                  if (this.index === 1) {
                    conflictResolution = relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
                  }
                  if (filePath.endsWith('.txt')) {
                    const res = await importPassword(this.context, filestring, conflictResolution)
                    if (res === 'success') {
                      await promptAction.openToast({
                        message: '导入成功'
                      })
                    }
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
                Text('密码图标')
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
              .onHover(isHover => {
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
                documentSelectOptions.fileSuffixFilters = ['.zip']
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.select(documentSelectOptions)
                if (uris.length === 1) {
                  const passwordIconDir = this.context.filesDir + '/media/passwordicon/'
                  if (!fileIo.accessSync(passwordIconDir)) {
                    await fileIo.mkdir(passwordIconDir, true)
                  }
                  const filePath = this.context.tempDir + '/passwordicon.zip'
                  const srcFile = fileIo.openSync(uris[0])
                  const destFile = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
                  await fileIo.copyFile(srcFile.fd, destFile.fd)
                  fileIo.closeSync(srcFile)
                  fileIo.closeSync(destFile)
                  await zlib.decompressFile(filePath, passwordIconDir)
                  await fileIo.unlink(filePath)
                  const promptAction = this.UIContext.getPromptAction()
                  const data = await promptAction.showDialog({
                    title: '提示',
                    message: '导入成功，需重启应用生效，是否重启？',
                    buttons: [
                      {
                        text: '取消',
                        color: $r('sys.color.font_primary')
                      },
                      {
                        text: '重启',
                        color: $r('sys.color.font_emphasize')
                      }
                    ]
                  })
                  if (data.index === 1) {
                    const applicationContext = this.context.getApplicationContext()
                    applicationContext.restartApp({
                      bundleName: 'com.zhangxm.aipasswordmemo',
                      abilityName: 'EntryAbility'
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
                  .backgroundColor(this.hoverId === 2 ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .onHover(isHover => {
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
                  let conflictResolution = relationalStore.ConflictResolution.ON_CONFLICT_IGNORE
                  if (this.index === 1) {
                    conflictResolution = relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
                  }
                  const res = await importInfo(this.context, filestring, conflictResolution)
                  if (res === 'success') {
                    await promptAction.openToast({
                      message: '导入成功'
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
                  .backgroundColor(this.hoverId === 3 ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .onHover(isHover => {
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
                documentSelectOptions.fileSuffixFilters = ['.txt']
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.select(documentSelectOptions)
                if (uris.length === 1) {
                  const filePath = uris[0]
                  const filestring = await readUri(filePath)
                  let conflictResolution = relationalStore.ConflictResolution.ON_CONFLICT_IGNORE
                  if (this.index === 1) {
                    conflictResolution = relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
                  }
                  const res = await importTag(this.context, filestring, conflictResolution)
                  if (res === 'success') {
                    await promptAction.openToast({
                      message: '导入成功'
                    })
                  }
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
              Span('中所述的标准格式。')
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
                  .backgroundColor(this.hoverId === 4 ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .onHover(isHover => {
                if (!isHover) {
                  this.hoverId = -1
                }
                if (isHover) {
                  this.hoverId = 4
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
            Text('导出 (未加密，请务必安全存储，保障数据安全。如需加密，请前往“我的”>“设置”>“数据”>“备份与恢复”>“文件”，开启“加密”，手动备份成功后导出)')
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
                  .backgroundColor(this.hoverId === 5 ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .onHover(isHover => {
                if (!isHover) {
                  this.hoverId = -1
                }
                if (isHover) {
                  this.hoverId = 5
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
                    info: item.info,
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
                      text: 'csv (仅包含名称、信息)',
                      color: $r('sys.color.font_primary')
                    }
                  ]
                })
                if (data.index === 0) {
                  documentSaveOptions.fileSuffixChoices = ['.txt']
                  const documentViewPicker = new picker.DocumentViewPicker(this.context)
                  const uris = await documentViewPicker.save(documentSaveOptions)
                  if (uris.length === 1) {
                    const filePath = uris[0]
                    await writeUri(filePath, JSON.stringify(arrayOut))
                    await promptAction.openToast({
                      message: '导出成功'
                    })
                  }
                }
                if (data.index === 1) {
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
                    const headers = ['名称'].concat(allInfoTypesArray)
                    const rows = arrayOut.map(item => {
                      const values = [item.name]
                      for (let i = 0; i < allInfoTypesArray.length; i++) {
                        let value = ''
                        const infoValue = item.info.find(item => item.type === allInfoTypesArray[i])
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
                  if (uris.length === 1) {
                    const filePath = uris[0]
                    await writeUri(filePath, filestring)
                    await promptAction.openToast({
                      message: '导出成功'
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
                Text('密码图标')
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
              .onHover(isHover => {
                if (!isHover) {
                  this.hoverId = -1
                }
                if (isHover) {
                  this.hoverId = 6
                }
              })
              .onClick(async () => {
                const passwordIconDir = this.context.filesDir + '/media/passwordicon/'
                if (!fileIo.accessSync(passwordIconDir)) {
                  await promptAction.openToast({
                    message: '无密码图标，无需导出'
                  })
                  return
                }
                const passwordIconFileNameArray = await fileIo.listFile(passwordIconDir)
                const passwordIconFilePathArray = passwordIconFileNameArray.map(item => passwordIconDir + item)
                if (passwordIconFilePathArray.length === 0) {
                  await promptAction.openToast({
                    message: '无密码图标，无需导出'
                  })
                  return
                }
                const documentSaveOptions = new picker.DocumentSaveOptions()
                documentSaveOptions.newFileNames = ['passwordicon']
                documentSaveOptions.fileSuffixChoices = ['.zip']
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.save(documentSaveOptions)
                if (uris.length === 1) {
                  const filePath = this.context.tempDir + '/passwordicon.zip'
                  await zlib.compressFiles(passwordIconFilePathArray, filePath, {})
                  const srcFile = fileIo.openSync(filePath)
                  const destFile = fileIo.openSync(uris[0], fileIo.OpenMode.WRITE_ONLY)
                  await fileIo.copyFile(srcFile.fd, destFile.fd)
                  fileIo.closeSync(srcFile)
                  fileIo.closeSync(destFile)
                  await fileIo.unlink(filePath)
                  await promptAction.openToast({
                    message: '导出成功'
                  })
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
                  .backgroundColor(this.hoverId === 7 ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .onHover(isHover => {
                if (!isHover) {
                  this.hoverId = -1
                }
                if (isHover) {
                  this.hoverId = 7
                }
              })
              .onClick(async () => {
                const documentSaveOptions = new picker.DocumentSaveOptions()
                documentSaveOptions.newFileNames = ['info']
                documentSaveOptions.fileSuffixChoices = ['.txt']
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.save(documentSaveOptions)
                if (uris.length === 1) {
                  const filePath = uris[0]
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
                  await writeUri(filePath, JSON.stringify(arrayOut))
                  await promptAction.openToast({
                    message: '导出成功'
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
                  .backgroundColor(this.hoverId === 8 ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .onHover(isHover => {
                if (!isHover) {
                  this.hoverId = -1
                }
                if (isHover) {
                  this.hoverId = 8
                }
              })
              .onClick(async () => {
                const documentSaveOptions = new picker.DocumentSaveOptions()
                documentSaveOptions.newFileNames = ['tag']
                documentSaveOptions.fileSuffixChoices = ['.txt']
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.save(documentSaveOptions)
                if (uris.length === 1) {
                  const filePath = uris[0]
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
                  await writeUri(filePath, JSON.stringify(arrayOut))
                  await promptAction.openToast({
                    message: '导出成功'
                  })
                }
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

        ListItem()
          .margin({
            bottom: 28
          })
      }
      .padding({
        left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
        right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .recoverable(true)
    .titleBar({
      padding: {
        end: LengthMetrics.vp(60)
      },
      style: {
        scrollEffectOpts: {
          scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR
        },
        originalStyle: {
          contentStyle: {
            titleStyle: {
              mainTitleColor: $r('sys.color.font_primary')
            },
            backIconStyle: {
              iconColor: $r('sys.color.icon_primary')
            }
          }
        },
        thermoCtrl: true,
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.ADAPTIVE,
          materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
        }
      },
      content: {
        title: {
          mainTitle: '数据导入与导出'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onReady(context => {
      this.pageInfos = context.pathStack
    })
  }
}