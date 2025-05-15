import { common } from '@kit.AbilityKit'
import { preferences, relationalStore } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { distributedDeviceManager } from '@kit.DistributedServiceKit'
import { checkPermission } from '../common/Permission'
import { syncTable } from '../common/Table'

interface Item {
  deviceId: string,
  deviceName: string,
  deviceType: string,
  networkId: string
}

@Builder
export function TablesyncBuilder() {
  Tablesync()
}

@ComponentV2
struct Tablesync {
  @Local onPassword: boolean = false
  @Local onInfo: boolean = false
  @Local onTag: boolean = false
  @Local autoSyncPassword: boolean = false
  @Local autoSyncInfo: boolean = false
  @Local autoSyncTag: boolean = false
  @Local pauseAutoSyncWhenLowBatteryCapacityLevel: boolean = false
  @Local pauseAutoSyncWhenPowerSave: boolean = false
  @Local autoSyncDevices: Item[] = []
  @Local availableDeviceArray: Item[] = []
  context = getContext(this) as common.UIAbilityContext
  dataSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'dataSetting'
  })
  onTables: string[] = []
  autoSyncTables: string[] = []

  getSetting() {
    const onTables: preferences.ValueType =
      this.dataSettingDataPreferences.getSync('onTables', [])
    this.onTables = onTables as string[]
    this.onPassword = this.onTables.includes('password')
    this.onInfo = this.onTables.includes('info')
    this.onTag = this.onTables.includes('tag')
    const autoSyncTables: preferences.ValueType =
      this.dataSettingDataPreferences.getSync('autoSyncTables', [])
    this.autoSyncTables = autoSyncTables as string[]
    this.autoSyncPassword = this.autoSyncTables.includes('password')
    this.autoSyncInfo = this.autoSyncTables.includes('info')
    this.autoSyncTag = this.autoSyncTables.includes('tag')
    const autoSyncDevices: preferences.ValueType =
      this.dataSettingDataPreferences.getSync('autoSyncDevices', [])
    this.autoSyncDevices = autoSyncDevices as Item[]
    const pauseAutoSyncWhenLowBatteryCapacityLevel: preferences.ValueType =
      this.dataSettingDataPreferences.getSync('pauseAutoSyncWhenLowBatteryCapacityLevel', false)
    this.pauseAutoSyncWhenLowBatteryCapacityLevel = pauseAutoSyncWhenLowBatteryCapacityLevel as boolean
    const pauseAutoSyncWhenPowerSave: preferences.ValueType =
      this.dataSettingDataPreferences.getSync('pauseAutoSyncWhenPowerSave', false)
    this.pauseAutoSyncWhenPowerSave = pauseAutoSyncWhenPowerSave as boolean
  }

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Text('状态')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: $r('sys.float.ohos_id_corner_radius_default_m')
              })
            Column() {
              Row() {
                Text('密码')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: $$this.onPassword
                })
                  .enabled(!this.onPassword)
                  .onChange(async (isOn: boolean) => {
                    if (isOn) {
                      const res = await checkPermission('ohos.permission.DISTRIBUTED_DATASYNC')
                      if (!res) {
                        this.onPassword = false
                      }
                      if (res) {
                        const rdbStore = await relationalStore.getRdbStore(this.context, {
                          name: 'password',
                          securityLevel: 4,
                          encrypt: true,
                          allowRebuild: true
                        })
                        await rdbStore.setDistributedTables(['password'])
                        const onTables = [...this.onTables, 'password']
                        this.dataSettingDataPreferences.putSync('onTables', onTables)
                        this.dataSettingDataPreferences.flushSync()
                        this.getSetting()
                      }
                    }
                  })
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('常用信息')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: $$this.onInfo
                })
                  .enabled(!this.onInfo)
                  .onChange(async (isOn: boolean) => {
                    if (isOn) {
                      const res = await checkPermission('ohos.permission.DISTRIBUTED_DATASYNC')
                      if (!res) {
                        this.onInfo = false
                      }
                      if (res) {
                        const rdbStore = await relationalStore.getRdbStore(this.context, {
                          name: 'info',
                          securityLevel: 4,
                          encrypt: true,
                          allowRebuild: true
                        })
                        await rdbStore.setDistributedTables(['info'])
                        const onTables = [...this.onTables, 'info']
                        this.dataSettingDataPreferences.putSync('onTables', onTables)
                        this.dataSettingDataPreferences.flushSync()
                        this.getSetting()
                      }
                    }
                  })
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('标签')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: $$this.onTag
                })
                  .enabled(!this.onTag)
                  .onChange(async (isOn: boolean) => {
                    if (isOn) {
                      const res = await checkPermission('ohos.permission.DISTRIBUTED_DATASYNC')
                      if (!res) {
                        this.onTag = false
                      }
                      if (res) {
                        const rdbStore = await relationalStore.getRdbStore(this.context, {
                          name: 'tag',
                          securityLevel: 1,
                          encrypt: true,
                          allowRebuild: true
                        })
                        await rdbStore.setDistributedTables(['tag'])
                        const onTables = [...this.onTables, 'tag']
                        this.dataSettingDataPreferences.putSync('onTables', onTables)
                        this.dataSettingDataPreferences.flushSync()
                        this.getSetting()
                      }
                    }
                  })
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
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
            Text('自动同步')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: $r('sys.float.ohos_id_corner_radius_default_m')
              })
            Column() {
              Row() {
                Text('密码')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: $$this.autoSyncPassword
                })
                  .enabled(this.onPassword)
                  .onChange((isOn: boolean) => {
                    let autoSyncTables: string[] = []
                    if (!isOn) {
                      autoSyncTables = this.autoSyncTables.filter(item => item !== 'password')
                    }
                    if (isOn) {
                      autoSyncTables = [...this.autoSyncTables, 'password']
                    }
                    this.dataSettingDataPreferences.putSync('autoSyncTables', autoSyncTables)
                    this.dataSettingDataPreferences.flushSync()
                    this.getSetting()
                  })
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('常用信息')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: $$this.autoSyncInfo
                })
                  .enabled(this.onInfo)
                  .onChange((isOn: boolean) => {
                    let autoSyncTables: string[] = []
                    if (!isOn) {
                      autoSyncTables = this.autoSyncTables.filter(item => item !== 'info')
                    }
                    if (isOn) {
                      autoSyncTables = [...this.autoSyncTables, 'info']
                    }
                    this.dataSettingDataPreferences.putSync('autoSyncTables', autoSyncTables)
                    this.dataSettingDataPreferences.flushSync()
                    this.getSetting()
                  })
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('标签')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: $$this.autoSyncTag
                })
                  .enabled(this.onTag)
                  .onChange((isOn: boolean) => {
                    let autoSyncTables: string[] = []
                    if (!isOn) {
                      autoSyncTables = this.autoSyncTables.filter(item => item !== 'tag')
                    }
                    if (isOn) {
                      autoSyncTables = [...this.autoSyncTables, 'tag']
                    }
                    this.dataSettingDataPreferences.putSync('autoSyncTables', autoSyncTables)
                    this.dataSettingDataPreferences.flushSync()
                    this.getSetting()
                  })
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
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
          Text('自动同步 (推送) 到以下设备')
            .fontWeight('medium')
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ForEach(this.autoSyncDevices, (item: Item) => {
          ListItem() {
            Column() {
              Row() {
                Text('标识符')
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.deviceId)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('名称')
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.deviceName)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('类型')
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.deviceType)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('网络标识')
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.networkId)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('关闭自动同步')
                  .fontColor($r('sys.color.warning'))
                  .fontWeight('medium')
                Blank()
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
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
                const autoSyncDevices = this.autoSyncDevices.filter(device => device.deviceId !== item.deviceId)
                this.dataSettingDataPreferences.putSync('autoSyncDevices', autoSyncDevices)
                this.dataSettingDataPreferences.flushSync()
                promptAction.showToast({
                  message: '已关闭'
                })
                this.getSetting()
              })
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_l')
          })
        })
        if (this.autoSyncDevices.length === 0) {
          ListItem() {
            Text('无数据')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_l')
          })
          .width('100%')
        }
        ListItem() {
          Column() {
            Text('暂停自动同步')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: $r('sys.float.ohos_id_corner_radius_default_m')
              })
            Column() {
              Row() {
                Text('电池电量低')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: $$this.pauseAutoSyncWhenLowBatteryCapacityLevel
                })
                  .onChange((isOn: boolean) => {
                    this.dataSettingDataPreferences.putSync('pauseAutoSyncWhenLowBatteryCapacityLevel', isOn)
                    this.dataSettingDataPreferences.flushSync()
                    this.getSetting()
                  })
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('系统开启 (超级) 省电模式')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: $$this.pauseAutoSyncWhenPowerSave
                })
                  .onChange((isOn: boolean) => {
                    this.dataSettingDataPreferences.putSync('pauseAutoSyncWhenPowerSave', isOn)
                    this.dataSettingDataPreferences.flushSync()
                    this.getSetting()
                  })
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
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
          Text('可信设备')
            .fontWeight('medium')
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ForEach(this.availableDeviceArray, (item: Item) => {
          ListItem() {
            Column() {
              Row() {
                Text('标识符')
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.deviceId)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('名称')
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.deviceName)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('类型')
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.deviceType)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('网络标识')
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.networkId)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              if (!this.autoSyncDevices.find(device => device.deviceId = item.deviceId)) {
                Divider()
                  .padding({
                    left: $r('sys.float.ohos_id_corner_radius_default_m'),
                    right: $r('sys.float.ohos_id_corner_radius_default_m')
                  })
                Row() {
                  Text('开启自动同步')
                    .fontColor($r('sys.color.font_emphasize'))
                    .fontWeight('medium')
                  Blank()
                  Image($r('app.media.right'))
                    .fillColor($r('sys.color.icon_fourth'))
                    .height(12)
                    .width(12)
                }
                .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
                .padding($r('sys.float.ohos_id_corner_radius_default_m'))
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
                  const autoSyncDevices = [...this.autoSyncDevices, item]
                  this.dataSettingDataPreferences.putSync('autoSyncDevices', autoSyncDevices)
                  this.dataSettingDataPreferences.flushSync()
                  promptAction.showToast({
                    message: '已开启'
                  })
                  this.getSetting()
                })
              }
              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('推送')
                  .fontWeight('medium')
                Blank()
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
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
                const data = await promptAction.showActionMenu({
                  title: '选择数据项',
                  buttons: [
                    {
                      text: '密码',
                      color: $r('sys.color.font_primary')
                    },
                    {
                      text: '常用信息',
                      color: $r('sys.color.font_primary')
                    },
                    {
                      text: '标签',
                      color: $r('sys.color.font_primary')
                    }
                  ]
                })
                if (data.index === 0) {
                  syncTable('password', item.deviceId, relationalStore.SyncMode.SYNC_MODE_PUSH)
                }
                if (data.index === 1) {
                  syncTable('info', item.deviceId, relationalStore.SyncMode.SYNC_MODE_PUSH)
                }
                if (data.index === 2) {
                  syncTable('tag', item.deviceId, relationalStore.SyncMode.SYNC_MODE_PUSH)
                }
              })

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('拉取')
                  .fontWeight('medium')
                Blank()
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
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
                const data = await promptAction.showActionMenu({
                  title: '选择数据项',
                  buttons: [
                    {
                      text: '密码',
                      color: $r('sys.color.font_primary')
                    },
                    {
                      text: '常用信息',
                      color: $r('sys.color.font_primary')
                    },
                    {
                      text: '标签',
                      color: $r('sys.color.font_primary')
                    }
                  ]
                })
                if (data.index === 0) {
                  syncTable('password', item.deviceId, relationalStore.SyncMode.SYNC_MODE_PULL)
                }
                if (data.index === 1) {
                  syncTable('info', item.deviceId, relationalStore.SyncMode.SYNC_MODE_PULL)
                }
                if (data.index === 2) {
                  syncTable('tag', item.deviceId, relationalStore.SyncMode.SYNC_MODE_PULL)
                }
              })
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_l')
          })
        })
        if (this.availableDeviceArray.length === 0) {
          ListItem() {
            Text('无数据')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_l')
          })
          .width('100%')
        }
      }
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title('设备间数据同步')
    .onReady(async () => {
      this.getSetting()
      const res = await checkPermission('ohos.permission.DISTRIBUTED_DATASYNC')
      if (res) {
        this.availableDeviceArray = distributedDeviceManager.createDeviceManager('com.zhangxm.aipasswordmemo')
          .getAvailableDeviceListSync() as Item[]
      }
    })
  }
}