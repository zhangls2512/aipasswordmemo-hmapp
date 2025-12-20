import { common } from '@kit.AbilityKit'
import { preferences, relationalStore } from '@kit.ArkData'
import { promptAction, SegmentButtonV2Items, TabSegmentButtonV2 } from '@kit.ArkUI'
import { fileIo, picker } from '@kit.CoreFileKit'
import { getInfoList, getPasswordList, getTagList } from '../common/Dataget'
import { importInfo, importPassword, importTag } from '../common/Dataimport'
import { read, write } from '../common/File'
import { backupTable, recoveryTable } from '../common/Table'
import { InfoOutItem, PasswordOutItem, TagOutItem } from './DataInOut'

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
  @Local autoBackupTables: string[] = []
  @Local index: number = 0
  @Local value: string = '保留'
  @Local autoFileBackupTables: string[] = []
  @Local pauseAutoBackupWhenLowBatteryCapacityLevel: boolean = false
  @Local pauseAutoBackupWhenPowerSave: boolean = false
  @Local hoverId: number = -1
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  dataSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'dataSetting'
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

  getSetting() {
    this.isBackupTables = this.dataSettingDataPreferences.getSync('isBackupTables', []) as string[]
    this.autoBackupTables =
      this.dataSettingDataPreferences.getSync('autoBackupTables', ['password', 'info', 'tag']) as string[]
    this.autoFileBackupTables =
      this.dataSettingDataPreferences.getSync('autoFileBackupTables', ['password', 'info', 'tag']) as string[]
    this.pauseAutoBackupWhenLowBatteryCapacityLevel =
      this.dataSettingDataPreferences.getSync('pauseAutoBackupWhenLowBatteryCapacityLevel', false) as boolean
    this.pauseAutoBackupWhenPowerSave =
      this.dataSettingDataPreferences.getSync('pauseAutoBackupWhenPowerSave', false) as boolean
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          TabSegmentButtonV2({
            items: new SegmentButtonV2Items([
              { text: '数据库' },
              { text: '文件' },
              { text: '暂停自动备份' }
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
                          .onChange((isOn) => {
                            let autoBackupTables: string[] = []
                            if (!isOn) {
                              autoBackupTables = this.autoBackupTables.filter(inItem => inItem !== item.value)
                            }
                            if (isOn) {
                              autoBackupTables = [...this.autoBackupTables, item.value]
                            }
                            this.dataSettingDataPreferences.putSync('autoBackupTables', autoBackupTables)
                            this.dataSettingDataPreferences.flushSync()
                            this.getSetting()
                          })
                      }
                      .borderRadius(12)
                      .padding(12)
                      .width('100%')
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
                      await backupTable(this.context, 'password')
                      await promptAction.openToast({
                        message: '备份成功'
                      })
                      this.getSetting()
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
                      await backupTable(this.context, 'info')
                      await promptAction.openToast({
                        message: '备份成功'
                      })
                      this.getSetting()
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
                      await backupTable(this.context, 'tag')
                      await promptAction.openToast({
                        message: '备份成功'
                      })
                      this.getSetting()
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
                              item === 'tag' ? '标签' :
                                'undefined')
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
                          .onChange((isOn) => {
                            let autoFileBackupTables: string[] = []
                            if (!isOn) {
                              autoFileBackupTables = this.autoFileBackupTables.filter(inItem => inItem !== item.value)
                            }
                            if (isOn) {
                              autoFileBackupTables = [...this.autoFileBackupTables, item.value]
                            }
                            this.dataSettingDataPreferences.putSync('autoFileBackupTables', autoFileBackupTables)
                            this.dataSettingDataPreferences.flushSync()
                            this.getSetting()
                          })
                      }
                      .borderRadius(12)
                      .padding(12)
                      .width('100%')
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
                          info: item.info,
                          tag: item.tag.map(item => item.value),
                          updateTime: item.updateTime,
                          cloudBackupTime: cloudBackupTime
                        }
                      })
                      await write(this.context.filesDir + '/backup/password.txt', JSON.stringify(arrayOut))
                      await promptAction.openToast({
                        message: '备份成功'
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
                      await write(this.context.filesDir + '/backup/info.txt', JSON.stringify(arrayOut))
                      await promptAction.openToast({
                        message: '备份成功'
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
                      await write(this.context.filesDir + '/backup/tag.txt', JSON.stringify(arrayOut))
                      await promptAction.openToast({
                        message: '备份成功'
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
                        .backgroundColor(this.hoverId === 7 ? $r('sys.color.interactive_hover') :
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
                        this.hoverId = 7
                      }
                    })
                    .onClick(async () => {
                      const filePath = this.context.filesDir + '/backup/password.txt'
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
                      await importPassword(this.context, filestring, conflictResolution)
                      await promptAction.openToast({
                        message: '恢复成功'
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
                    .width('100%')
                    .onHover((isHover) => {
                      if (!isHover) {
                        this.hoverId = -1
                      }
                      if (isHover) {
                        this.hoverId = 8
                      }
                    })
                    .onClick(async () => {
                      const filePath = this.context.filesDir + '/backup/info.txt'
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
                      await importInfo(this.context, filestring, conflictResolution)
                      await promptAction.openToast({
                        message: '恢复成功'
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
                        .backgroundColor(this.hoverId === 9 ? $r('sys.color.interactive_hover') :
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
                        this.hoverId = 9
                      }
                    })
                    .onClick(async () => {
                      const filePath = this.context.filesDir + '/backup/tag.txt'
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
                      await importTag(this.context, filestring, conflictResolution)
                      await promptAction.openToast({
                        message: '恢复成功'
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
                        .backgroundColor(this.hoverId === 10 ? $r('sys.color.interactive_hover') :
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
                        this.hoverId = 10
                      }
                    })
                    .onClick(async () => {
                      const filePath = this.context.filesDir + '/backup/password.txt'
                      if (!fileIo.accessSync(filePath)) {
                        await promptAction.openToast({
                          message: '无备份文件，无需导出'
                        })
                        return
                      }
                      const documentSaveOptions = new picker.DocumentSaveOptions()
                      documentSaveOptions.newFileNames = ['password']
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
                        .backgroundColor(this.hoverId === 11 ? $r('sys.color.interactive_hover') :
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
                        this.hoverId = 11
                      }
                    })
                    .onClick(async () => {
                      const filePath = this.context.filesDir + '/backup/info.txt'
                      if (!fileIo.accessSync(filePath)) {
                        await promptAction.openToast({
                          message: '无备份文件，无需导出'
                        })
                        return
                      }
                      const documentSaveOptions = new picker.DocumentSaveOptions()
                      documentSaveOptions.newFileNames = ['info']
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
                        .backgroundColor(this.hoverId === 12 ? $r('sys.color.interactive_hover') :
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
                        this.hoverId = 12
                      }
                    })
                    .onClick(async () => {
                      const filePath = this.context.filesDir + '/backup/tag.txt'
                      if (!fileIo.accessSync(filePath)) {
                        await promptAction.openToast({
                          message: '无备份文件，无需导出'
                        })
                        return
                      }
                      const documentSaveOptions = new picker.DocumentSaveOptions()
                      documentSaveOptions.newFileNames = ['tag']
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
                        .backgroundColor(this.hoverId === 13 ? $r('sys.color.interactive_hover') :
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
                        this.hoverId = 13
                      }
                    })
                    .onClick(async () => {
                      const promptAction = this.UIContext.getPromptAction()
                      const filePath = this.context.filesDir + '/backup/password.txt'
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
                        .backgroundColor(this.hoverId === 14 ? $r('sys.color.interactive_hover') :
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
                        this.hoverId = 14
                      }
                    })
                    .onClick(async () => {
                      const promptAction = this.UIContext.getPromptAction()
                      const filePath = this.context.filesDir + '/backup/info.txt'
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
                        .backgroundColor(this.hoverId === 15 ? $r('sys.color.interactive_hover') :
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
                        this.hoverId = 15
                      }
                    })
                    .onClick(async () => {
                      const promptAction = this.UIContext.getPromptAction()
                      const filePath = this.context.filesDir + '/backup/tag.txt'
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
                      .onChange((isOn) => {
                        this.dataSettingDataPreferences.putSync('pauseAutoBackupWhenLowBatteryCapacityLevel', isOn)
                        this.dataSettingDataPreferences.flushSync()
                      })
                  }
                  .borderRadius(12)
                  .padding(12)
                  .width('100%')

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
                      .onChange((isOn) => {
                        this.dataSettingDataPreferences.putSync('pauseAutoBackupWhenPowerSave', isOn)
                        this.dataSettingDataPreferences.flushSync()
                      })
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
            }
          }
          .layoutWeight(1)
        }
      }
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
        right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title('数据备份与恢复')
    .onAppear(() => {
      this.getSetting()
    })
  }
}