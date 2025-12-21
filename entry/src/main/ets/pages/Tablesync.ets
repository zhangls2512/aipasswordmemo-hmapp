import { common } from '@kit.AbilityKit'
import { preferences, relationalStore, uniformTypeDescriptor } from '@kit.ArkData'
import { LoadingDialog, promptAction, SegmentButtonV2Items, TabSegmentButtonV2 } from '@kit.ArkUI'
import { deviceInfo, zlib } from '@kit.BasicServicesKit'
import { fileIo, fileUri } from '@kit.CoreFileKit'
import { distributedDeviceManager } from '@kit.DistributedServiceKit'
import { harmonyShare, systemShare } from '@kit.ShareKit'
import { getInfoList, getPasswordList, getTagList } from '../common/Dataget'
import { write } from '../common/File'
import { checkPermission } from '../common/Permission'
import { getSizeString } from '../common/Stringformat'
import { syncTable } from '../common/Table'
import { InfoOutItem, PasswordOutItem, TagOutItem } from './DataInOut'

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
  @Local selectedIndex: number = 0
  @Local onTables: string[] = []
  @Local autoSyncTables: string[] = []
  @Local pauseAutoSyncWhenLowBatteryCapacityLevel: boolean = false
  @Local pauseAutoSyncWhenPowerSave: boolean = false
  @Local autoSyncDevices: Item[] = []
  @Local availableDeviceArray: Item[] = []
  @Local hoverId: number | string = -1
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  dataSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'dataSetting'
  })
  pushDialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '推送中...'
    })
  })
  pullDialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '拉取中...'
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
      Scroll() {
        Column() {
          if (deviceInfo.deviceType !== 'tablet') {
            TabSegmentButtonV2({
              items: new SegmentButtonV2Items([
                { text: '可信' },
                { text: '邻近' }
              ]),
              selectedIndex: this.selectedIndex!!
            })
              .margin({
                bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
          }
          List() {
            if (this.selectedIndex === 0) {
              ListItem() {
                Column() {
                  Text('状态')
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
                          isOn: this.onTables.includes(item.value)
                        })
                          .enabled(!this.onTables.includes(item.value))
                          .onChange(async (isOn) => {
                            if (isOn) {
                              const res =
                                await checkPermission(this.context, this.UIContext,
                                  'ohos.permission.DISTRIBUTED_DATASYNC')
                              if (!res) {
                                this.onTables = this.onTables.filter(inItem => inItem !== item.value)
                              }
                              if (res) {
                                let securityLevel = relationalStore.SecurityLevel.S4
                                if (item.value === 'tag') {
                                  securityLevel = relationalStore.SecurityLevel.S1
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
                          isOn: this.autoSyncTables.includes(item.value)
                        })
                          .onChange((isOn) => {
                            let autoSyncTables: string[] = []
                            if (!isOn) {
                              autoSyncTables = this.autoSyncTables.filter(inItem => inItem !== item.value)
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

              ForEach(this.autoSyncDevices, (item: Item, index) => {
                ListItem() {
                  Column() {
                    Row() {
                      Text('标识符')
                        .fontWeight(FontWeight.Medium)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                      Text(item.deviceId)
                        .fontColor($r('sys.color.font_secondary'))
                        .fontSize($r('sys.float.ohos_id_text_size_body2'))
                        .layoutWeight(1)
                        .textAlign(TextAlign.End)
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
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                      Text(item.deviceName)
                        .fontColor($r('sys.color.font_secondary'))
                        .fontSize($r('sys.float.ohos_id_text_size_body2'))
                        .layoutWeight(1)
                        .textAlign(TextAlign.End)
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
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                      Text(item.deviceType === 'PHONE' ? '手机' :
                        item.deviceType === 'TABLET' ? '平板' :
                          item.deviceType === '2IN1' ? '电脑' :
                            'undefined')
                        .fontColor($r('sys.color.font_secondary'))
                        .fontSize($r('sys.float.ohos_id_text_size_body2'))
                        .layoutWeight(1)
                        .textAlign(TextAlign.End)
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
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                      Text(item.networkId)
                        .fontColor($r('sys.color.font_secondary'))
                        .fontSize($r('sys.float.ohos_id_text_size_body2'))
                        .layoutWeight(1)
                        .textAlign(TextAlign.End)
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
                    .width('100%')
                    .onHover((isHover) => {
                      if (!isHover) {
                        this.hoverId = -1
                      }
                      if (isHover) {
                        this.hoverId = '0,' + index
                      }
                    })
                    .onClick(async () => {
                      const autoSyncDevices = this.autoSyncDevices.filter(device => device.deviceId !== item.deviceId)
                      this.dataSettingDataPreferences.putSync('autoSyncDevices', autoSyncDevices)
                      this.dataSettingDataPreferences.flushSync()
                      await promptAction.openToast({
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
                        .layoutWeight(1)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
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
                    .onClick(async () => {
                      this.availableDeviceArray =
                        distributedDeviceManager.createDeviceManager('com.zhangxm.aipasswordmemo')
                          .getAvailableDeviceListSync() as Item[]
                      await promptAction.openToast({
                        message: '刷新成功'
                      })
                    })
                }
              }
              .margin({
                bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })

              ForEach(this.availableDeviceArray, (item: Item, index) => {
                ListItem() {
                  Column() {
                    Row() {
                      Text('标识符')
                        .fontWeight(FontWeight.Medium)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                      Text(item.deviceId)
                        .fontColor($r('sys.color.font_secondary'))
                        .fontSize($r('sys.float.ohos_id_text_size_body2'))
                        .layoutWeight(1)
                        .textAlign(TextAlign.End)
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
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                      Text(item.deviceName)
                        .fontColor($r('sys.color.font_secondary'))
                        .fontSize($r('sys.float.ohos_id_text_size_body2'))
                        .layoutWeight(1)
                        .textAlign(TextAlign.End)
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
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                      Text(item.deviceType === 'PHONE' ? '手机' :
                        item.deviceType === 'TABLET' ? '平板' :
                          item.deviceType === '2IN1' ? '电脑' :
                            'undefined')
                        .fontColor($r('sys.color.font_secondary'))
                        .fontSize($r('sys.float.ohos_id_text_size_body2'))
                        .layoutWeight(1)
                        .textAlign(TextAlign.End)
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
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                      Text(item.networkId)
                        .fontColor($r('sys.color.font_secondary'))
                        .fontSize($r('sys.float.ohos_id_text_size_body2'))
                        .layoutWeight(1)
                        .textAlign(TextAlign.End)
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
                      .width('100%')
                      .onHover((isHover) => {
                        if (!isHover) {
                          this.hoverId = -1
                        }
                        if (isHover) {
                          this.hoverId = '1,' + index
                        }
                      })
                      .onClick(async () => {
                        const autoSyncDevices = [...this.autoSyncDevices, item]
                        this.dataSettingDataPreferences.putSync('autoSyncDevices', autoSyncDevices)
                        this.dataSettingDataPreferences.flushSync()
                        await promptAction.openToast({
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
                    .width('100%')
                    .onHover((isHover) => {
                      if (!isHover) {
                        this.hoverId = -1
                      }
                      if (isHover) {
                        this.hoverId = '2,' + index
                      }
                    })
                    .onClick(async () => {
                      const promptAction = this.UIContext.getPromptAction()
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
                        this.pushDialogControllerProgress.open()
                        await syncTable(this.context, 'password', item.networkId,
                          relationalStore.SyncMode.SYNC_MODE_PUSH)
                        this.pushDialogControllerProgress.close()
                      }
                      if (data.index === 1) {
                        this.pushDialogControllerProgress.open()
                        await syncTable(this.context, 'info', item.networkId, relationalStore.SyncMode.SYNC_MODE_PUSH)
                        this.pushDialogControllerProgress.close()
                      }
                      if (data.index === 2) {
                        this.pushDialogControllerProgress.open()
                        await syncTable(this.context, 'tag', item.networkId, relationalStore.SyncMode.SYNC_MODE_PUSH)
                        this.pushDialogControllerProgress.close()
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
                    .width('100%')
                    .onHover((isHover) => {
                      if (!isHover) {
                        this.hoverId = -1
                      }
                      if (isHover) {
                        this.hoverId = '3,' + index
                      }
                    })
                    .onClick(async () => {
                      const promptAction = this.UIContext.getPromptAction()
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
                        this.pullDialogControllerProgress.open()
                        await syncTable(this.context, 'password', item.networkId,
                          relationalStore.SyncMode.SYNC_MODE_PULL)
                        this.pullDialogControllerProgress.close()
                      }
                      if (data.index === 1) {
                        this.pullDialogControllerProgress.open()
                        await syncTable(this.context, 'info', item.networkId, relationalStore.SyncMode.SYNC_MODE_PULL)
                        this.pullDialogControllerProgress.close()
                      }
                      if (data.index === 2) {
                        this.pullDialogControllerProgress.open()
                        await syncTable(this.context, 'tag', item.networkId, relationalStore.SyncMode.SYNC_MODE_PULL)
                        this.pullDialogControllerProgress.close()
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
            if (this.selectedIndex === 1) {
              ListItem() {
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
                    const filePath = this.context.tempDir + '/password.txt'
                    await write(filePath, JSON.stringify(arrayOut))
                    const file = fileIo.openSync(filePath)
                    const shareData = new systemShare.SharedData({
                      utd: uniformTypeDescriptor.UniformDataType.PLAIN_TEXT,
                      title: 'password.txt',
                      description: getSizeString(fileIo.statSync(file.fd).size),
                      uri: fileUri.getUriFromPath(filePath)
                    })
                    harmonyShare.on('knockShare', async (sharableTarget) => {
                      await sharableTarget.share(shareData)
                    })
                    harmonyShare.on('gesturesShare', async (sharableTarget) => {
                      await sharableTarget.share(shareData)
                    })
                    const promptAction = this.UIContext.getPromptAction()
                    await promptAction.showDialog({
                      title: '提示',
                      message: '碰一碰/隔空传送邻近设备即可同步，关闭此弹窗后停止同步',
                      buttons: [
                        {
                          text: '关闭',
                          color: $r('sys.color.warning')
                        }
                      ],
                      onDidDisappear: async () => {
                        fileIo.closeSync(file)
                        await fileIo.unlink(filePath)
                        harmonyShare.off('knockShare')
                        harmonyShare.off('gesturesShare')
                      }
                    })
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
                    const promptAction = this.UIContext.getPromptAction()
                    const passwordIconDir = this.context.filesDir + '/media/passwordicon/'
                    if (!fileIo.accessSync(passwordIconDir)) {
                      await promptAction.openToast({
                        message: '无密码图标，无需同步'
                      })
                      return
                    }
                    const passwordIconFileNameArray = await fileIo.listFile(passwordIconDir)
                    const passwordIconFilePathArray = passwordIconFileNameArray.map(item => passwordIconDir + item)
                    if (passwordIconFilePathArray.length === 0) {
                      await promptAction.openToast({
                        message: '无密码图标，无需同步'
                      })
                      return
                    }
                    const filePath = this.context.tempDir + '/passwordicon.zip'
                    await zlib.compressFiles(passwordIconFilePathArray, filePath, {})
                    const file = fileIo.openSync(filePath)
                    const shareData = new systemShare.SharedData({
                      utd: uniformTypeDescriptor.UniformDataType.ZIP_ARCHIVE,
                      title: 'passwordicon.zip',
                      description: getSizeString(fileIo.statSync(file.fd).size),
                      uri: fileUri.getUriFromPath(filePath)
                    })
                    harmonyShare.on('knockShare', async (sharableTarget) => {
                      await sharableTarget.share(shareData)
                    })
                    harmonyShare.on('gesturesShare', async (sharableTarget) => {
                      await sharableTarget.share(shareData)
                    })
                    await promptAction.showDialog({
                      title: '提示',
                      message: '碰一碰/隔空传送邻近设备即可同步，关闭此弹窗后停止同步',
                      buttons: [
                        {
                          text: '关闭',
                          color: $r('sys.color.warning')
                        }
                      ],
                      onDidDisappear: async () => {
                        fileIo.closeSync(file)
                        await fileIo.unlink(filePath)
                        harmonyShare.off('knockShare')
                        harmonyShare.off('gesturesShare')
                      }
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
                    const filePath = this.context.tempDir + '/info.txt'
                    await write(filePath, JSON.stringify(arrayOut))
                    const file = fileIo.openSync(filePath)
                    const shareData = new systemShare.SharedData({
                      utd: uniformTypeDescriptor.UniformDataType.PLAIN_TEXT,
                      title: 'info.txt',
                      description: getSizeString(fileIo.statSync(file.fd).size),
                      uri: fileUri.getUriFromPath(filePath)
                    })
                    harmonyShare.on('knockShare', async (sharableTarget) => {
                      await sharableTarget.share(shareData)
                    })
                    harmonyShare.on('gesturesShare', async (sharableTarget) => {
                      await sharableTarget.share(shareData)
                    })
                    const promptAction = this.UIContext.getPromptAction()
                    await promptAction.showDialog({
                      title: '提示',
                      message: '碰一碰/隔空传送邻近设备即可同步，关闭此弹窗后停止同步',
                      buttons: [
                        {
                          text: '关闭',
                          color: $r('sys.color.warning')
                        }
                      ],
                      onDidDisappear: async () => {
                        fileIo.closeSync(file)
                        await fileIo.unlink(filePath)
                        harmonyShare.off('knockShare')
                        harmonyShare.off('gesturesShare')
                      }
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
                    const filePath = this.context.tempDir + '/tag.txt'
                    await write(filePath, JSON.stringify(arrayOut))
                    const file = fileIo.openSync(filePath)
                    const shareData = new systemShare.SharedData({
                      utd: uniformTypeDescriptor.UniformDataType.PLAIN_TEXT,
                      title: 'tag.txt',
                      description: getSizeString(fileIo.statSync(file.fd).size),
                      uri: fileUri.getUriFromPath(filePath)
                    })
                    harmonyShare.on('knockShare', async (sharableTarget) => {
                      await sharableTarget.share(shareData)
                    })
                    harmonyShare.on('gesturesShare', async (sharableTarget) => {
                      await sharableTarget.share(shareData)
                    })
                    const promptAction = this.UIContext.getPromptAction()
                    await promptAction.showDialog({
                      title: '提示',
                      message: '碰一碰/隔空传送邻近设备即可同步，关闭此弹窗后停止同步',
                      buttons: [
                        {
                          text: '关闭',
                          color: $r('sys.color.warning')
                        }
                      ],
                      onDidDisappear: async () => {
                        fileIo.closeSync(file)
                        await fileIo.unlink(filePath)
                        harmonyShare.off('knockShare')
                        harmonyShare.off('gesturesShare')
                      }
                    })
                  })
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
    .title('设备间数据同步')
    .onAppear(async () => {
      this.getSetting()
      const res = await checkPermission(this.context, this.UIContext, 'ohos.permission.DISTRIBUTED_DATASYNC')
      if (res) {
        this.availableDeviceArray = distributedDeviceManager.createDeviceManager('com.zhangxm.aipasswordmemo')
          .getAvailableDeviceListSync() as Item[]
      }
    })
  }
}