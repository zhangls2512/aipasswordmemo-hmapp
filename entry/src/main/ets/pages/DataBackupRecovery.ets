import { preferences } from '@kit.ArkData'
import { backupTable, recoveryTable } from '../common/Table'

@Builder
export function DataBackupRecoveryBuilder() {
  DataBackupRecovery()
}

@ComponentV2
struct DataBackupRecovery {
  @Local isBackupPassword: boolean = false
  @Local isBackupInfo: boolean = false
  @Local isBackupTag: boolean = false
  @Local autoBackupPassword: boolean = false
  @Local autoBackupInfo: boolean = false
  @Local autoBackupTag: boolean = false
  @Local pauseAutoBackupWhenLowBatteryCapacityLevel: boolean = false
  @Local pauseAutoBackupWhenPowerSave: boolean = false
  @Local isBackupTables: string[] = []
  context = getContext(this)
  dataSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'dataSetting'
  })
  autoBackupTables: string[] = []

  getSetting() {
    const isBackupTables = this.dataSettingDataPreferences.getSync('isBackupTables', [])
    this.isBackupTables = isBackupTables as string[]
    this.isBackupPassword = this.isBackupTables.includes('password')
    this.isBackupInfo = this.isBackupTables.includes('info')
    this.isBackupTag = this.isBackupTables.includes('tag')
    const autoBackupTables = this.dataSettingDataPreferences.getSync('autoBackupTables', [])
    this.autoBackupTables = autoBackupTables as string[]
    this.autoBackupPassword = this.autoBackupTables.includes('password')
    this.autoBackupInfo = this.autoBackupTables.includes('info')
    this.autoBackupTag = this.autoBackupTables.includes('tag')
    const pauseAutoBackupWhenLowBatteryCapacityLevel =
      this.dataSettingDataPreferences.getSync('pauseAutoBackupWhenLowBatteryCapacityLevel', false)
    this.pauseAutoBackupWhenLowBatteryCapacityLevel = pauseAutoBackupWhenLowBatteryCapacityLevel as boolean
    const pauseAutoBackupWhenPowerSave = this.dataSettingDataPreferences.getSync('pauseAutoBackupWhenPowerSave', false)
    this.pauseAutoBackupWhenPowerSave = pauseAutoBackupWhenPowerSave as boolean
  }

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Text('自动备份')
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
                Toggle({
                  type: ToggleType.Switch,
                  isOn: $$this.autoBackupPassword
                })
                  .onChange((isOn: boolean) => {
                    let autoBackupTables: string[] = []
                    if (!isOn) {
                      autoBackupTables = this.autoBackupTables.filter(item => item !== 'password')
                    }
                    if (isOn) {
                      autoBackupTables = [...this.autoBackupTables, 'password']
                    }
                    this.dataSettingDataPreferences.putSync('autoBackupTables', autoBackupTables)
                    this.dataSettingDataPreferences.flushSync()
                    this.getSetting()
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
                Text('常用信息')
                  .fontWeight(FontWeight.Medium)
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: $$this.autoBackupInfo
                })
                  .onChange((isOn: boolean) => {
                    let autoBackupTables: string[] = []
                    if (!isOn) {
                      autoBackupTables = this.autoBackupTables.filter(item => item !== 'info')
                    }
                    if (isOn) {
                      autoBackupTables = [...this.autoBackupTables, 'info']
                    }
                    this.dataSettingDataPreferences.putSync('autoBackupTables', autoBackupTables)
                    this.dataSettingDataPreferences.flushSync()
                    this.getSetting()
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
                Text('标签')
                  .fontWeight(FontWeight.Medium)
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: $$this.autoBackupTag
                })
                  .onChange((isOn: boolean) => {
                    let autoBackupTables: string[] = []
                    if (!isOn) {
                      autoBackupTables = this.autoBackupTables.filter(item => item !== 'tag')
                    }
                    if (isOn) {
                      autoBackupTables = [...this.autoBackupTables, 'tag']
                    }
                    this.dataSettingDataPreferences.putSync('autoBackupTables', autoBackupTables)
                    this.dataSettingDataPreferences.flushSync()
                    this.getSetting()
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
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Column() {
            Text('暂停自动备份')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              Row() {
                Text('电池电量低')
                  .fontWeight(FontWeight.Medium)
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: $$this.pauseAutoBackupWhenLowBatteryCapacityLevel
                })
                  .onChange((isOn: boolean) => {
                    this.dataSettingDataPreferences.putSync('pauseAutoBackupWhenLowBatteryCapacityLevel', isOn)
                    this.dataSettingDataPreferences.flushSync()
                    this.getSetting()
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
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: $$this.pauseAutoBackupWhenPowerSave
                })
                  .onChange((isOn: boolean) => {
                    this.dataSettingDataPreferences.putSync('pauseAutoBackupWhenPowerSave', isOn)
                    this.dataSettingDataPreferences.flushSync()
                    this.getSetting()
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
                await backupTable('password')
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
                await backupTable('info')
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
                await backupTable('tag')
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
                  left: 12
                })
              Column() {
                ForEach(this.isBackupTables, (item: string, index: number) => {
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
                  .onClick(() => {
                    recoveryTable(item)
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
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title('数据备份与恢复')
    .onReady(() => {
      this.getSetting()
    })
  }
}