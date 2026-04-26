import { common } from '@kit.AbilityKit'
import { relationalStore } from '@kit.ArkData'
import { util } from '@kit.ArkTS'
import { LengthMetrics, LoadingDialog, promptAction, SegmentButtonV2Items, TabSegmentButtonV2 } from '@kit.ArkUI'
import { appAccount } from '@kit.BasicServicesKit'
import { fileIo, picker } from '@kit.CoreFileKit'
import { rcp } from '@kit.RemoteCommunicationKit'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { importInfo, importPassword, importTag } from '../common/Dataimport'
import { read } from '../common/File'
import { checkPermission } from '../common/Permission'
import { getFlushPreference, setFlushPreference } from '../common/Preference'
import { backupTable, fileBackupTable, recoveryTable, webdavBackupTable } from '../common/Table'
import { getWebdavServerInfo } from '../common/Webdavserver'

interface Type {
  name: string,
  value: string
}

@Builder
export function DataBackupRecoveryBuilder() {
  DataBackupRecovery()
}

@ComponentV2
struct DataBackupRecovery {
  @Local selectedIndex: number = 0
  @Local isBackupTables: string[] = []
  @Local accountDataSyncEnabled: boolean = false
  @Local hoverId: number | string = -1
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()
  autoBackupTables: string[] = []
  index = 0
  value = '保留'
  encryptFileBackup = true
  autoFileBackupTables: string[] = []
  accountDataSync = false
  encryptWebdavBackup = true
  autoWebdavBackupTables: string[] = []
  pauseAutoBackupWhenLowBatteryCapacityLevel = false
  pauseAutoBackupWhenPowerSave = false
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '请求中...'
    })
  })
  typeArray: Type[] = [
    {
      name: '密码',
      value: 'password'
    },
    {
      name: '常用信息',
      value: 'info'
    },
    {
      name: '标签',
      value: 'tag'
    }
  ]

  async getSetting() {
    const isBackupTables: string[] = []
    this.typeArray.forEach(item => {
      if (fileIo.accessSync(this.context.databaseDir + '/rdb/' + item.value + 'backup.db')) {
        isBackupTables.push(item.value)
      }
    })
    this.isBackupTables = isBackupTables
    this.autoBackupTables =
      getFlushPreference(this.context, 'dataSetting', 'autoBackupTables', ['password', 'info', 'tag']) as string[]
    this.encryptFileBackup = getFlushPreference(this.context, 'dataSetting', 'encryptFileBackup', true) as boolean
    this.autoFileBackupTables =
      getFlushPreference(this.context, 'dataSetting', 'autoFileBackupTables', ['password', 'info', 'tag']) as string[]
    this.encryptWebdavBackup = getFlushPreference(this.context, 'dataSetting', 'encryptWebdavBackup', true) as boolean
    this.autoWebdavBackupTables =
      getFlushPreference(this.context, 'dataSetting', 'autoWebdavBackupTables', ['password', 'info', 'tag']) as string[]
    this.pauseAutoBackupWhenLowBatteryCapacityLevel =
      getFlushPreference(this.context, 'dataSetting', 'pauseAutoBackupWhenLowBatteryCapacityLevel', false) as boolean
    this.pauseAutoBackupWhenPowerSave =
      getFlushPreference(this.context, 'dataSetting', 'pauseAutoBackupWhenPowerSave', false) as boolean
    const webdavServerInfo = await getWebdavServerInfo()
    if (!webdavServerInfo.path) {
      this.accountDataSyncEnabled = false
    }
    if (webdavServerInfo.path) {
      const res = await checkPermission(this.context, this.UIContext, 'ohos.permission.DISTRIBUTED_DATASYNC')
      this.accountDataSyncEnabled = res
      if (res) {
        const appAccountManager = appAccount.createAppAccountManager()
        this.accountDataSync = await appAccountManager.checkDataSyncEnabled('webdavserver')
      }
    }
  }

  async getWebdavBackup(table: string) {
    const webdavServerInfo = await getWebdavServerInfo()
    const session = rcp.createSession({
      requestConfiguration: {
        security: {
          tlsRange: {
            min: 'TlsV1.2'
          }
        }
      },
      headers: {
        Authorization: 'Basic ' +
          new util.Base64Helper().encodeToStringSync(new util.TextEncoder().encodeInto(webdavServerInfo.username + ':' +
            webdavServerInfo.password))
      }
    })
    try {
      const response = await session.get(webdavServerInfo.path + '/' + table + '.txt')
      session.close()
      if (response.statusCode >= 200 && response.statusCode < 300) {
        const body = String(response)
        if (!body) {
          await promptAction.openToast({
            message: '备份文件内容为空，无法恢复'
          })
          return 'fail'
        }
        return body
      }
      const statusCodeMap: Record<number, string> = {
        401: '账号密码错误',
        404: '无备份文件',
        405: '目录不存在或无权限'
      }
      const reason = statusCodeMap[response.statusCode]
      if (reason) {
        await promptAction.openToast({
          message: '恢复失败，原因：' + reason
        })
        return 'fail'
      }
      await promptAction.openToast({
        message: '请求失败，错误码：' + response.statusCode
      })
      return 'fail'
    } catch (err) {
      session.close()
      await promptAction.openToast({
        message: '发生错误，错误码：' + err.code
      })
      return 'fail'
    }
  }

  async deleteWebdavBackup(table: string) {
    const webdavServerInfo = await getWebdavServerInfo()
    const session = rcp.createSession({
      requestConfiguration: {
        security: {
          tlsRange: {
            min: 'TlsV1.2'
          }
        }
      },
      headers: {
        Authorization: 'Basic ' +
          new util.Base64Helper().encodeToStringSync(new util.TextEncoder().encodeInto(webdavServerInfo.username + ':' +
            webdavServerInfo.password))
      }
    })
    try {
      const response = await session.delete(webdavServerInfo.path + '/' + table + '.txt')
      session.close()
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return 'success'
      }
      const statusCodeMap: Record<number, string> = {
        401: '账号密码错误',
        404: '无备份文件',
        405: '目录不存在或无权限'
      }
      const reason = statusCodeMap[response.statusCode]
      if (reason) {
        await promptAction.openToast({
          message: '删除失败，原因：' + reason
        })
        return 'fail'
      }
      await promptAction.openToast({
        message: '请求失败，错误码：' + response.statusCode
      })
      return 'fail'
    } catch (err) {
      session.close()
      await promptAction.openToast({
        message: '发生错误，错误码：' + err.code
      })
      return 'fail'
    }
  }

  build() {
    HdsNavDestination() {
      Scroll() {
        Column() {
          TabSegmentButtonV2({
            items: new SegmentButtonV2Items([
              { text: '数据库' },
              { text: '文件' },
              { text: 'WebDAV' },
              { text: '暂停' }
            ]),
            selectedIndex: this.selectedIndex!!
          })
            .margin({
              bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
          List() {
            if (this.selectedIndex === 0) {
              ListItem() {
                Column() {
                  Text('自动备份')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .fontWeight(FontWeight.Medium)
                    .margin({
                      bottom: 6,
                      left: 12,
                      right: 12
                    })
                  Column() {
                    ForEach(this.typeArray, (item: Type, index) => {
                      if (index !== 0) {
                        Divider()
                          .padding({
                            left: 12,
                            right: 12
                          })
                      }
                      Row() {
                        Text(item.name)
                          .fontWeight(FontWeight.Medium)
                          .layoutWeight(1)
                          .margin({
                            right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                          })
                        Toggle({
                          type: ToggleType.Switch,
                          isOn: this.autoBackupTables.includes(item.value)
                        })
                          .onChange(isOn => {
                            if (!isOn) {
                              this.autoBackupTables = this.autoBackupTables.filter(inItem => inItem !== item.value)
                            }
                            if (isOn) {
                              this.autoBackupTables = Array.from(new Set([...this.autoBackupTables, item.value]))
                            }
                            setFlushPreference(this.context, 'dataSetting', 'autoBackupTables', this.autoBackupTables)
                          })
                      }
                      .borderRadius(12)
                      .padding(12)
                    })
                  }
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                  .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                  .padding($r('sys.float.ohos_id_corner_radius_mark'))
                }
                .alignItems(HorizontalAlign.Start)
              }
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })

              ListItem() {
                Column() {
                  Text('手动备份')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .fontWeight(FontWeight.Medium)
                    .margin({
                      bottom: 6,
                      left: 12,
                      right: 12
                    })
                  Column() {
                    ForEach(this.typeArray, (item: Type, index) => {
                      if (index !== 0) {
                        Divider()
                          .padding({
                            left: 12,
                            right: 12
                          })
                      }
                      Row() {
                        Text(item.name)
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
                          .backgroundColor(this.hoverId === '0,' + index ? $r('sys.color.interactive_hover') :
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
                          this.hoverId = '0,' + index
                        }
                      })
                      .onClick(async () => {
                        await backupTable(this.context, item.value)
                        await promptAction.openToast({
                          message: '备份成功'
                        })
                        await this.getSetting()
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

              if (this.isBackupTables.length > 0) {
                ListItem() {
                  Column() {
                    Text('恢复')
                      .fontColor($r('sys.color.font_secondary'))
                      .fontSize($r('sys.float.ohos_id_text_size_body2'))
                      .fontWeight(FontWeight.Medium)
                      .margin({
                        bottom: 6,
                        left: 12,
                        right: 12
                      })
                    Column() {
                      ForEach(this.isBackupTables, (item: string, index) => {
                        if (index !== 0) {
                          Divider()
                            .padding({
                              left: 12,
                              right: 12
                            })
                        }
                        Row() {
                          Text(item === 'password' ? '密码' :
                            item === 'info' ? '常用信息' :
                              item === 'tag' ? '标签' : 'undefined')
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
                            .backgroundColor(this.hoverId === '1,' + index ? $r('sys.color.interactive_hover') :
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
                            this.hoverId = '1,' + index
                          }
                        })
                        .onClick(async () => {
                          await recoveryTable(this.context, item)
                          await promptAction.openToast({
                            message: '恢复成功'
                          })
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
            }
            if (this.selectedIndex === 1) {
              ListItem() {
                Column() {
                  Row() {
                    Column() {
                      Text('加密')
                        .fontWeight(FontWeight.Medium)
                      Text('在“我的”>“设置”>“密钥”导入密钥后生效')
                        .fontColor($r('sys.color.font_secondary'))
                        .fontSize($r('sys.float.ohos_id_text_size_body2'))
                        .margin({
                          top: $r('sys.float.ohos_id_text_margin_vertical')
                        })
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })

                    Toggle({
                      type: ToggleType.Switch,
                      isOn: this.encryptFileBackup!!
                    })
                      .onChange(isOn => {
                        setFlushPreference(this.context, 'dataSetting', 'encryptFileBackup', isOn)
                      })
                  }
                  .borderRadius(12)
                  .padding(12)

                  Divider()
                    .padding({
                      left: 12,
                      right: 12
                    })
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
                  Text('自动备份')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .fontWeight(FontWeight.Medium)
                    .margin({
                      bottom: 6,
                      left: 12,
                      right: 12
                    })
                  Column() {
                    ForEach(this.typeArray, (item: Type, index) => {
                      if (index !== 0) {
                        Divider()
                          .padding({
                            left: 12,
                            right: 12
                          })
                      }
                      Row() {
                        Text(item.name)
                          .fontWeight(FontWeight.Medium)
                          .layoutWeight(1)
                          .margin({
                            right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                          })
                        Toggle({
                          type: ToggleType.Switch,
                          isOn: this.autoFileBackupTables.includes(item.value)
                        })
                          .onChange(isOn => {
                            if (!isOn) {
                              this.autoFileBackupTables =
                                this.autoFileBackupTables.filter(inItem => inItem !== item.value)
                            }
                            if (isOn) {
                              this.autoFileBackupTables =
                                Array.from(new Set([...this.autoFileBackupTables, item.value]))
                            }
                            setFlushPreference(this.context, 'dataSetting', 'autoFileBackupTables',
                              this.autoFileBackupTables)
                          })
                      }
                      .borderRadius(12)
                      .padding(12)
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

              ListItem() {
                Column() {
                  Text('手动备份')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .fontWeight(FontWeight.Medium)
                    .margin({
                      bottom: 6,
                      left: 12,
                      right: 12
                    })
                  Column() {
                    ForEach(this.typeArray, (item: Type, index) => {
                      if (index !== 0) {
                        Divider()
                          .padding({
                            left: 12,
                            right: 12
                          })
                      }
                      Row() {
                        Text(item.name)
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
                          .backgroundColor(this.hoverId === '2,' + index ? $r('sys.color.interactive_hover') :
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
                          this.hoverId = '2,' + index
                        }
                      })
                      .onClick(async () => {
                        await fileBackupTable(this.context, item.value)
                        await promptAction.openToast({
                          message: '备份成功'
                        })
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

              ListItem() {
                Column() {
                  Text('恢复')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .fontWeight(FontWeight.Medium)
                    .margin({
                      bottom: 6,
                      left: 12,
                      right: 12
                    })
                  Column() {
                    ForEach(this.typeArray, (item: Type, index) => {
                      if (index !== 0) {
                        Divider()
                          .padding({
                            left: 12,
                            right: 12
                          })
                      }
                      Row() {
                        Text(item.name)
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
                          .backgroundColor(this.hoverId === '3,' + index ? $r('sys.color.interactive_hover') :
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
                          this.hoverId = '3,' + index
                        }
                      })
                      .onClick(async () => {
                        const filePath = this.context.filesDir + '/backup/' + item.value + '.txt'
                        if (!fileIo.accessSync(filePath)) {
                          await promptAction.openToast({
                            message: '无备份文件，无法恢复'
                          })
                          return
                        }
                        const filestring = await read(filePath)
                        let conflictResolution = relationalStore.ConflictResolution.ON_CONFLICT_IGNORE
                        if (this.index === 1) {
                          conflictResolution = relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
                        }
                        let res = ''
                        if (item.name === '密码') {
                          res = await importPassword(this.context, filestring, conflictResolution)
                        }
                        if (item.name === '常用信息') {
                          res = await importInfo(this.context, filestring, conflictResolution)
                        }
                        if (item.name === '标签') {
                          res = await importTag(this.context, filestring, conflictResolution)
                        }
                        if (res === 'success') {
                          await promptAction.openToast({
                            message: '恢复成功'
                          })
                        }
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

              ListItem() {
                Column() {
                  Text('导出备份')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .fontWeight(FontWeight.Medium)
                    .margin({
                      bottom: 6,
                      left: 12,
                      right: 12
                    })
                  Column() {
                    ForEach(this.typeArray, (item: Type, index) => {
                      if (index !== 0) {
                        Divider()
                          .padding({
                            left: 12,
                            right: 12
                          })
                      }
                      Row() {
                        Text(item.name)
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
                          .backgroundColor(this.hoverId === '4,' + index ? $r('sys.color.interactive_hover') :
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
                          this.hoverId = '4,' + index
                        }
                      })
                      .onClick(async () => {
                        const filePath = this.context.filesDir + '/backup/' + item.value + '.txt'
                        if (!fileIo.accessSync(filePath)) {
                          await promptAction.openToast({
                            message: '无备份文件，无需导出'
                          })
                          return
                        }
                        const documentSaveOptions = new picker.DocumentSaveOptions()
                        documentSaveOptions.newFileNames = [item.value]
                        documentSaveOptions.fileSuffixChoices = ['.txt']
                        const documentViewPicker = new picker.DocumentViewPicker(this.context)
                        const uris = await documentViewPicker.save(documentSaveOptions)
                        if (uris.length === 1) {
                          const srcFile = fileIo.openSync(filePath)
                          const destFile = fileIo.openSync(uris[0], fileIo.OpenMode.WRITE_ONLY)
                          await fileIo.copyFile(srcFile.fd, destFile.fd)
                          fileIo.closeSync(srcFile)
                          fileIo.closeSync(destFile)
                          await promptAction.openToast({
                            message: '导出成功'
                          })
                        }
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

              ListItem() {
                Column() {
                  Text('删除备份')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .fontWeight(FontWeight.Medium)
                    .margin({
                      bottom: 6,
                      left: 12,
                      right: 12
                    })
                  Column() {
                    ForEach(this.typeArray, (item: Type, index) => {
                      if (index !== 0) {
                        Divider()
                          .padding({
                            left: 12,
                            right: 12
                          })
                      }
                      Row() {
                        Text(item.name)
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
                          .backgroundColor(this.hoverId === '5,' + index ? $r('sys.color.interactive_hover') :
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
                          this.hoverId = '5,' + index
                        }
                      })
                      .onClick(async () => {
                        const promptAction = this.UIContext.getPromptAction()
                        const filePath = this.context.filesDir + '/backup/' + item.value + '.txt'
                        if (!fileIo.accessSync(filePath)) {
                          await promptAction.openToast({
                            message: '无备份文件，无需删除'
                          })
                          return
                        }
                        const data = await promptAction.showDialog({
                          title: '提示',
                          message: '删除成功后无法恢复，确定删除？',
                          buttons: [
                            {
                              text: '取消',
                              color: $r('sys.color.font_primary')
                            },
                            {
                              text: '确定',
                              color: $r('sys.color.warning')
                            }
                          ]
                        })
                        if (data.index === 1) {
                          await fileIo.unlink(filePath)
                          await promptAction.openToast({
                            message: '删除成功'
                          })
                        }
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
            if (this.selectedIndex === 2) {
              ListItem() {
                Column() {
                  Row() {
                    Text('WebDAV服务器')
                      .enableAutoSpacing(true)
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
                  .onClick(() => {
                    this.pageInfos.pushPath({
                      name: 'Webdavserver'
                    })
                  })

                  if (this.accountDataSyncEnabled) {
                    Divider()
                      .padding({
                        left: 12,
                        right: 12
                      })
                    Row() {
                      Text('设备间同步')
                        .fontWeight(FontWeight.Medium)
                        .layoutWeight(1)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                      Toggle({
                        type: ToggleType.Switch,
                        isOn: this.accountDataSync!!
                      })
                        .onChange(async (isOn) => {
                          try {
                            const appAccountManager = appAccount.createAppAccountManager()
                            await appAccountManager.setDataSyncEnabled('webdavserver', isOn)
                          } catch (err) {
                            this.accountDataSync = false
                            await promptAction.openToast({
                              message: '发生错误，错误码：' + err.code
                            })
                          }
                        })
                    }
                    .borderRadius(12)
                    .padding(12)
                  }
                  Divider()
                    .padding({
                      left: 12,
                      right: 12
                    })
                  Row() {
                    Column() {
                      Text('加密')
                        .fontWeight(FontWeight.Medium)
                      Text('在“我的”>“设置”>“密钥”导入密钥后生效')
                        .fontColor($r('sys.color.font_secondary'))
                        .fontSize($r('sys.float.ohos_id_text_size_body2'))
                        .margin({
                          top: $r('sys.float.ohos_id_text_margin_vertical')
                        })
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })

                    Toggle({
                      type: ToggleType.Switch,
                      isOn: this.encryptWebdavBackup!!
                    })
                      .onChange(isOn => {
                        setFlushPreference(this.context, 'dataSetting', 'encryptWebdavBackup', isOn)
                      })
                  }
                  .borderRadius(12)
                  .padding(12)

                  Divider()
                    .padding({
                      left: 12,
                      right: 12
                    })
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
                  Text('自动备份')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .fontWeight(FontWeight.Medium)
                    .margin({
                      bottom: 6,
                      left: 12,
                      right: 12
                    })
                  Column() {
                    ForEach(this.typeArray, (item: Type, index) => {
                      if (index !== 0) {
                        Divider()
                          .padding({
                            left: 12,
                            right: 12
                          })
                      }
                      Row() {
                        Text(item.name)
                          .fontWeight(FontWeight.Medium)
                          .layoutWeight(1)
                          .margin({
                            right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                          })
                        Toggle({
                          type: ToggleType.Switch,
                          isOn: this.autoWebdavBackupTables.includes(item.value)
                        })
                          .onChange(isOn => {
                            if (!isOn) {
                              this.autoWebdavBackupTables =
                                this.autoWebdavBackupTables.filter(inItem => inItem !== item.value)
                            }
                            if (isOn) {
                              this.autoWebdavBackupTables =
                                Array.from(new Set([...this.autoWebdavBackupTables, item.value]))
                            }
                            setFlushPreference(this.context, 'dataSetting', 'autoWebdavBackupTables',
                              this.autoWebdavBackupTables)
                          })
                      }
                      .borderRadius(12)
                      .padding(12)
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

              ListItem() {
                Column() {
                  Text('手动备份')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .fontWeight(FontWeight.Medium)
                    .margin({
                      bottom: 6,
                      left: 12,
                      right: 12
                    })
                  Column() {
                    ForEach(this.typeArray, (item: Type, index) => {
                      if (index !== 0) {
                        Divider()
                          .padding({
                            left: 12,
                            right: 12
                          })
                      }
                      Row() {
                        Text(item.name)
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
                          .backgroundColor(this.hoverId === '6,' + index ? $r('sys.color.interactive_hover') :
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
                          this.hoverId = '6,' + index
                        }
                      })
                      .onClick(async () => {
                        const webdavServerInfo = await getWebdavServerInfo()
                        if (!webdavServerInfo.path) {
                          await promptAction.openToast({
                            message: '未配置 WebDAV 服务器，无法备份'
                          })
                          return
                        }
                        this.dialogControllerProgress.open()
                        const res = await webdavBackupTable(this.context, item.value)
                        this.dialogControllerProgress.close()
                        if (res !== 'fail') {
                          await promptAction.openToast({
                            message: '备份成功'
                          })
                        }
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

              ListItem() {
                Column() {
                  Text('恢复')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .fontWeight(FontWeight.Medium)
                    .margin({
                      bottom: 6,
                      left: 12,
                      right: 12
                    })
                  Column() {
                    ForEach(this.typeArray, (item: Type, index) => {
                      if (index !== 0) {
                        Divider()
                          .padding({
                            left: 12,
                            right: 12
                          })
                      }
                      Row() {
                        Text(item.name)
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
                          .backgroundColor(this.hoverId === '7,' + index ? $r('sys.color.interactive_hover') :
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
                          this.hoverId = '7,' + index
                        }
                      })
                      .onClick(async () => {
                        const webdavServerInfo = await getWebdavServerInfo()
                        if (!webdavServerInfo.path) {
                          await promptAction.openToast({
                            message: '未配置 WebDAV 服务器，无法恢复'
                          })
                          return
                        }
                        this.dialogControllerProgress.open()
                        const filestring = await this.getWebdavBackup(item.value)
                        this.dialogControllerProgress.close()
                        if (filestring !== 'fail') {
                          let conflictResolution = relationalStore.ConflictResolution.ON_CONFLICT_IGNORE
                          if (this.index === 1) {
                            conflictResolution = relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
                          }
                          let res = ''
                          if (item.name === '密码') {
                            res = await importPassword(this.context, filestring, conflictResolution)
                          }
                          if (item.name === '常用信息') {
                            res = await importInfo(this.context, filestring, conflictResolution)
                          }
                          if (item.name === '标签') {
                            res = await importTag(this.context, filestring, conflictResolution)
                          }
                          if (res === 'success') {
                            await promptAction.openToast({
                              message: '恢复成功'
                            })
                          }
                        }
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

              ListItem() {
                Column() {
                  Text('删除备份')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .fontWeight(FontWeight.Medium)
                    .margin({
                      bottom: 6,
                      left: 12,
                      right: 12
                    })
                  Column() {
                    ForEach(this.typeArray, (item: Type, index) => {
                      if (index !== 0) {
                        Divider()
                          .padding({
                            left: 12,
                            right: 12
                          })
                      }
                      Row() {
                        Text(item.name)
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
                          .backgroundColor(this.hoverId === '8,' + index ? $r('sys.color.interactive_hover') :
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
                          this.hoverId = '8,' + index
                        }
                      })
                      .onClick(async () => {
                        const promptAction = this.UIContext.getPromptAction()
                        const webdavServerInfo = await getWebdavServerInfo()
                        if (!webdavServerInfo.path) {
                          await promptAction.openToast({
                            message: '未配置 WebDAV 服务器，无法删除'
                          })
                          return
                        }
                        const data = await promptAction.showDialog({
                          title: '提示',
                          message: '删除成功后无法恢复，确定删除？',
                          buttons: [
                            {
                              text: '取消',
                              color: $r('sys.color.font_primary')
                            },
                            {
                              text: '确定',
                              color: $r('sys.color.warning')
                            }
                          ]
                        })
                        if (data.index === 1) {
                          this.dialogControllerProgress.open()
                          const res = await this.deleteWebdavBackup(item.value)
                          this.dialogControllerProgress.close()
                          if (res !== 'fail') {
                            await promptAction.openToast({
                              message: '删除成功'
                            })
                          }
                        }
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
            if (this.selectedIndex === 3) {
              ListItem() {
                Column() {
                  Text('暂停自动备份')
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
                      Text('电池电量低')
                        .fontWeight(FontWeight.Medium)
                        .layoutWeight(1)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                      Toggle({
                        type: ToggleType.Switch,
                        isOn: this.pauseAutoBackupWhenLowBatteryCapacityLevel!!
                      })
                        .onChange(isOn => {
                          setFlushPreference(this.context, 'dataSetting', 'pauseAutoBackupWhenLowBatteryCapacityLevel',
                            isOn)
                        })
                    }
                    .borderRadius(12)
                    .padding(12)

                    Divider()
                      .padding({
                        left: 12,
                        right: 12
                      })
                    Row() {
                      Text('系统开启 (超级) 省电模式')
                        .fontWeight(FontWeight.Medium)
                        .layoutWeight(1)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                      Toggle({
                        type: ToggleType.Switch,
                        isOn: this.pauseAutoBackupWhenPowerSave!!
                      })
                        .onChange(isOn => {
                          setFlushPreference(this.context, 'dataSetting', 'pauseAutoBackupWhenPowerSave', isOn)
                        })
                    }
                    .borderRadius(12)
                    .padding(12)
                  }
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                  .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                  .padding($r('sys.float.ohos_id_corner_radius_mark'))
                }
                .alignItems(HorizontalAlign.Start)
              }
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
            }
            ListItem()
              .margin({
                bottom: 28
              })
          }
          .layoutWeight(1)
        }
        .margin({
          top: 64
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
          mainTitle: '数据备份与恢复'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onReady(async (context) => {
      this.pageInfos = context.pathStack
      this.context.eventHub.on('refreshDataBackupRecovery', async () => {
        await this.getSetting()
      })
      await this.getSetting()
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshDataBackupRecovery')
    })
  }
}