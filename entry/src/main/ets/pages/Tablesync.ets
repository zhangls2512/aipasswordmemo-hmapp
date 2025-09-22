import { common } from '@kit.AbilityKit'
import { preferences, relationalStore } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { distributedDeviceManager } from '@kit.DistributedServiceKit'
//import { HdsNavDestination } from '@kit.UIDesignKit'
import { checkPermission } from '../common/Permission'
import { syncTable } from '../common/Table'

interface Type {
  name: string,
  value: string
}

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
  @Local onTables: string[] = []
  @Local autoSyncTables: string[] = []
  @Local pauseAutoSyncWhenLowBatteryCapacityLevel: boolean = false
  @Local pauseAutoSyncWhenPowerSave: boolean = false
  @Local autoSyncDevices: Item[] = []
  @Local availableDeviceArray: Item[] = []
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
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
    this.onTables = this.dataSettingDataPreferences.getSync('onTables', []) as string[]
    this.autoSyncTables = this.dataSettingDataPreferences.getSync('autoSyncTables', []) as string[]
    this.autoSyncDevices = this.dataSettingDataPreferences.getSync('autoSyncDevices', []) as Item[]
    this.pauseAutoSyncWhenLowBatteryCapacityLevel =
      this.dataSettingDataPreferences.getSync('pauseAutoSyncWhenLowBatteryCapacityLevel', false) as boolean
    this.pauseAutoSyncWhenPowerSave =
      this.dataSettingDataPreferences.getSync('pauseAutoSyncWhenPowerSave', false) as boolean
  }

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Text('状态')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12
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
                  Blank()
                  Toggle({
                    type: ToggleType.Switch,
                    isOn: this.onTables.includes(item.value)
                  })
                    .enabled(!this.onTables.includes(item.value))
                    .onChange(async (isOn) => {
                      if (isOn) {
                        const res = await checkPermission('ohos.permission.DISTRIBUTED_DATASYNC')
                        if (!res) {
                          this.onTables = this.onTables.filter(itema => itema !== item.value)
                        }
                        if (res) {
                          let securityLevel = 4
                          if (item.value === 'tag') {
                            securityLevel = 1
                          }
                          const rdbStore = await relationalStore.getRdbStore(this.context, {
                            name: item.value,
                            securityLevel: securityLevel,
                            encrypt: true,
                            allowRebuild: true
                          })
                          await rdbStore.setDistributedTables([item.value])
                          const onTables = [...this.onTables, item.value]
                          this.dataSettingDataPreferences.putSync('onTables', onTables)
                          this.dataSettingDataPreferences.flushSync()
                        }
                        this.getSetting()
                      }
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
            Text('自动同步')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12
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
                  Blank()
                  Toggle({
                    type: ToggleType.Switch,
                    isOn: this.autoSyncTables.includes(item.value)
                  })
                    .onChange((isOn) => {
                      let autoSyncTables: string[] = []
                      if (!isOn) {
                        autoSyncTables = this.autoSyncTables.filter(itema => itema !== item.value)
                      }
                      if (isOn) {
                        autoSyncTables = [...this.autoSyncTables, item.value]
                      }
                      this.dataSettingDataPreferences.putSync('autoSyncTables', autoSyncTables)
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
          Text('自动同步 (推送) 到以下设备')
            .fontWeight(FontWeight.Medium)
        }
        .margin({
          bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ForEach(this.autoSyncDevices, (item: Item) => {
          ListItem() {
            Column() {
              Row() {
                Text('标识符')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.deviceId)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
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
                Text('名称')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.deviceName)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
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
                Text('类型')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.deviceType === 'phone' ? '手机' :
                  item.deviceType === 'tablet' ? '平板' :
                    item.deviceType === '2in1' ? '电脑' :
                      'undefined')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
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
                Text('网络标识')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.networkId)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
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
                Text('关闭自动同步')
                  .fontColor($r('sys.color.warning'))
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
                const autoSyncDevices = this.autoSyncDevices.filter(device => device.deviceId !== item.deviceId)
                this.dataSettingDataPreferences.putSync('autoSyncDevices', autoSyncDevices)
                this.dataSettingDataPreferences.flushSync()
                promptAction.openToast({
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
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
        })
        if (this.autoSyncDevices.length === 0) {
          ListItem() {
            Text('无数据')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .width('100%')
        }
        ListItem() {
          Column() {
            Text('暂停自动同步')
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
                  isOn: this.pauseAutoSyncWhenLowBatteryCapacityLevel!!
                })
                  .onChange((isOn) => {
                    this.dataSettingDataPreferences.putSync('pauseAutoSyncWhenLowBatteryCapacityLevel', isOn)
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
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.pauseAutoSyncWhenPowerSave!!
                })
                  .onChange((isOn) => {
                    this.dataSettingDataPreferences.putSync('pauseAutoSyncWhenPowerSave', isOn)
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
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Row() {
            Text('可信设备')
              .fontWeight(FontWeight.Medium)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
            Button('刷新')
              .onClick(() => {
                this.availableDeviceArray = distributedDeviceManager.createDeviceManager('com.zhangxm.aipasswordmemo')
                  .getAvailableDeviceListSync() as Item[]
                promptAction.openToast({
                  message: '刷新成功'
                })
              })
          }
        }
        .margin({
          bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ForEach(this.availableDeviceArray, (item: Item) => {
          ListItem() {
            Column() {
              Row() {
                Text('标识符')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.deviceId)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
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
                Text('名称')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.deviceName)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
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
                Text('类型')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.deviceType === 'phone' ? '手机' :
                  item.deviceType === 'tablet' ? '平板' :
                    item.deviceType === '2in1' ? '电脑' :
                      'undefined')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
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
                Text('网络标识')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.networkId)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius(12)
              .padding(12)
              .width('100%')

              if (!this.autoSyncDevices.find(device => device.deviceId === item.deviceId)) {
                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Text('开启自动同步')
                    .fontColor($r('sys.color.font_emphasize'))
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
                  const autoSyncDevices = [...this.autoSyncDevices, item]
                  this.dataSettingDataPreferences.putSync('autoSyncDevices', autoSyncDevices)
                  this.dataSettingDataPreferences.flushSync()
                  promptAction.openToast({
                    message: '已开启'
                  })
                  this.getSetting()
                })
              }
              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('推送')
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
                const promptAction = this.getUIContext().getPromptAction()
                const data = await promptAction.showActionMenu({
                  title: '选择数据类型',
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
                  syncTable('password', item.networkId, relationalStore.SyncMode.SYNC_MODE_PUSH)
                }
                if (data.index === 1) {
                  syncTable('info', item.networkId, relationalStore.SyncMode.SYNC_MODE_PUSH)
                }
                if (data.index === 2) {
                  syncTable('tag', item.networkId, relationalStore.SyncMode.SYNC_MODE_PUSH)
                }
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('拉取')
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
                const promptAction = this.getUIContext().getPromptAction()
                const data = await promptAction.showActionMenu({
                  title: '选择数据类型',
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
                  syncTable('password', item.networkId, relationalStore.SyncMode.SYNC_MODE_PULL)
                }
                if (data.index === 1) {
                  syncTable('info', item.networkId, relationalStore.SyncMode.SYNC_MODE_PULL)
                }
                if (data.index === 2) {
                  syncTable('tag', item.networkId, relationalStore.SyncMode.SYNC_MODE_PULL)
                }
              })
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
        })
        if (this.availableDeviceArray.length === 0) {
          ListItem() {
            Text('无数据')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
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
    /*.titleBar({
      content: {
        title: {
          mainTitle: ''
        }
      }
    })*/
    .title('设备间数据同步')
    .onAppear(async () => {
      this.getSetting()
      const res = await checkPermission('ohos.permission.DISTRIBUTED_DATASYNC')
      if (res) {
        this.availableDeviceArray = distributedDeviceManager.createDeviceManager('com.zhangxm.aipasswordmemo')
          .getAvailableDeviceListSync() as Item[]
      }
    })
  }
}