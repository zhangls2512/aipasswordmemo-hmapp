import { common } from '@kit.AbilityKit'
import { cloudData, preferences, relationalStore, uniformTypeDescriptor } from '@kit.ArkData'
import { LengthMetrics, LoadingDialog, promptAction, SegmentButtonV2Items, TabSegmentButtonV2 } from '@kit.ArkUI'
import { deviceInfo, zlib } from '@kit.BasicServicesKit'
import { fileIo, fileUri } from '@kit.CoreFileKit'
import { distributedDeviceManager } from '@kit.DistributedServiceKit'
import { harmonyShare, systemShare } from '@kit.ShareKit'
import { hdsMaterial, HdsNavDestination } from '@kit.UIDesignKit'
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
  @Local huaweiCloudSyncOnTables: string[] = []
  @Local autoSyncDevices: Item[] = []
  @Local availableDeviceArray: Item[] = []
  @Local passwordHuaweiCloudSyncProgressDetails: relationalStore.ProgressDetails | undefined = undefined
  @Local infoHuaweiCloudSyncProgressDetails: relationalStore.ProgressDetails | undefined = undefined
  @Local tagHuaweiCloudSyncProgressDetails: relationalStore.ProgressDetails | undefined = undefined
  @Local hoverId: number | string = -1
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  index = 0
  value = '始终'
  autoSyncTables: string[] = []
  autoHuaweiCloudSyncTables: string[] = []
  pauseAutoSyncWhenLowBatteryCapacityLevel = false
  pauseAutoSyncWhenPowerSave = false
  dataSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'dataSetting'
  })
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '进行中...'
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
    const index = this.dataSettingDataPreferences.getSync('huaweiCloudSyncNetworkStrategy', 0)
    this.index = index as number
    if (index === 0) {
      this.value = '始终'
    }
    if (index === 1) {
      this.value = '仅 WLAN 下'
    }
    this.huaweiCloudSyncOnTables = this.dataSettingDataPreferences.getSync('huaweiCloudSyncOnTables', []) as string[]
    this.autoHuaweiCloudSyncTables =
      this.dataSettingDataPreferences.getSync('autoHuaweiCloudSyncTables', []) as string[]
    this.pauseAutoSyncWhenLowBatteryCapacityLevel =
      this.dataSettingDataPreferences.getSync('pauseAutoSyncWhenLowBatteryCapacityLevel', false) as boolean
    this.pauseAutoSyncWhenPowerSave =
      this.dataSettingDataPreferences.getSync('pauseAutoSyncWhenPowerSave', false) as boolean
  }

  build() {
    HdsNavDestination() {
      Scroll() {
        Column() {
          if (deviceInfo.deviceType !== 'tablet') {
            TabSegmentButtonV2({
              items: new SegmentButtonV2Items([
                { text: '可信' },
                { text: '云空间' },
                { text: '暂停' },
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
                              const res = await checkPermission(this.context, this.UIContext,
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
                                await rdbStore.setDistributedTables([item.value],
                                  relationalStore.DistributedType.DISTRIBUTED_DEVICE, {
                                    autoSync: false
                                  })
                                this.onTables = Array.from(new Set([...this.onTables, item.value]))
                                this.dataSettingDataPreferences.putSync('onTables', this.onTables)
                                this.dataSettingDataPreferences.flushSync()
                              }
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
                          .enabled(this.onTables.includes(item.value))
                          .onChange((isOn) => {
                            if (!isOn) {
                              this.autoSyncTables = this.autoSyncTables.filter(inItem => inItem !== item.value)
                            }
                            if (isOn) {
                              this.autoSyncTables = Array.from(new Set([...this.autoSyncTables, item.value]))
                            }
                            this.dataSettingDataPreferences.putSync('autoSyncTables', this.autoSyncTables)
                            this.dataSettingDataPreferences.flushSync()
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
                          item.deviceType === '2IN1' ? '电脑' : 'undefined')
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
                        this.autoSyncDevices = Array.from(new Set([...this.autoSyncDevices, item]))
                        this.dataSettingDataPreferences.putSync('autoSyncDevices', this.autoSyncDevices)
                        this.dataSettingDataPreferences.flushSync()
                        await promptAction.openToast({
                          message: '已开启'
                        })
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
                        if (!this.onTables.includes('password')) {
                          await promptAction.openToast({
                            message: '请先开启上方状态开关'
                          })
                          return
                        }
                        this.dialogControllerProgress.open()
                        await syncTable(this.context, 'password', item.networkId,
                          relationalStore.SyncMode.SYNC_MODE_PUSH)
                        this.dialogControllerProgress.close()
                      }
                      if (data.index === 1) {
                        if (!this.onTables.includes('info')) {
                          await promptAction.openToast({
                            message: '请先开启上方状态开关'
                          })
                          return
                        }
                        this.dialogControllerProgress.open()
                        await syncTable(this.context, 'info', item.networkId, relationalStore.SyncMode.SYNC_MODE_PUSH)
                        this.dialogControllerProgress.close()
                      }
                      if (data.index === 2) {
                        if (!this.onTables.includes('tag')) {
                          await promptAction.openToast({
                            message: '请先开启上方状态开关'
                          })
                          return
                        }
                        this.dialogControllerProgress.open()
                        await syncTable(this.context, 'tag', item.networkId, relationalStore.SyncMode.SYNC_MODE_PUSH)
                        this.dialogControllerProgress.close()
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
                        if (!this.onTables.includes('password')) {
                          await promptAction.openToast({
                            message: '请先开启上方状态开关'
                          })
                          return
                        }
                        this.dialogControllerProgress.open()
                        await syncTable(this.context, 'password', item.networkId,
                          relationalStore.SyncMode.SYNC_MODE_PULL)
                        this.dialogControllerProgress.close()
                      }
                      if (data.index === 1) {
                        if (!this.onTables.includes('info')) {
                          await promptAction.openToast({
                            message: '请先开启上方状态开关'
                          })
                          return
                        }
                        this.dialogControllerProgress.open()
                        await syncTable(this.context, 'info', item.networkId, relationalStore.SyncMode.SYNC_MODE_PULL)
                        this.dialogControllerProgress.close()
                      }
                      if (data.index === 2) {
                        if (!this.onTables.includes('tag')) {
                          await promptAction.openToast({
                            message: '请先开启上方状态开关'
                          })
                          return
                        }
                        this.dialogControllerProgress.open()
                        await syncTable(this.context, 'tag', item.networkId, relationalStore.SyncMode.SYNC_MODE_PULL)
                        this.dialogControllerProgress.close()
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
                    Text('同步时机')
                      .fontWeight(FontWeight.Medium)
                      .layoutWeight(1)
                      .margin({
                        right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                      })
                    Select([
                      { value: '始终' },
                      { value: '仅 WLAN 下' }
                    ])
                      .selected(this.index!!)
                      .value(this.value!!)
                      .onSelect(async (index) => {
                        if (index === 0) {
                          await cloudData.setCloudStrategy(cloudData.StrategyType.NETWORK,
                            [cloudData.NetWorkStrategy.WIFI, cloudData.NetWorkStrategy.CELLULAR])
                        }
                        if (index === 1) {
                          await cloudData.setCloudStrategy(cloudData.StrategyType.NETWORK,
                            [cloudData.NetWorkStrategy.WIFI])
                        }
                        this.dataSettingDataPreferences.putSync('huaweiCloudSyncNetworkStrategy', index)
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
                          isOn: this.huaweiCloudSyncOnTables.includes(item.value)
                        })
                          .enabled(!this.huaweiCloudSyncOnTables.includes(item.value))
                          .onChange(async (isOn) => {
                            if (isOn) {
                              const rdbStore = await relationalStore.getRdbStore(this.context, {
                                name: 'huaweicloudsync',
                                securityLevel: relationalStore.SecurityLevel.S3,
                                encrypt: true,
                                allowRebuild: true
                              })
                              await rdbStore.setDistributedTables([item.value],
                                relationalStore.DistributedType.DISTRIBUTED_CLOUD, {
                                  autoSync: false
                                })
                              this.huaweiCloudSyncOnTables =
                                Array.from(new Set([...this.huaweiCloudSyncOnTables, item.value]))
                              this.dataSettingDataPreferences.putSync('huaweiCloudSyncOnTables',
                                this.huaweiCloudSyncOnTables)
                              this.dataSettingDataPreferences.flushSync()
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

                  Text() {
                    Span('使用前请')
                      .fontColor($r('sys.color.font_secondary'))
                    Span('点此')
                      .fontColor($r('sys.color.font_emphasize'))
                      .fontWeight(FontWeight.Medium)
                      .onClick(async () => {
                        await this.context.openLink('hicloud://cloudDrive/getInfo?path=MainActivity')
                      })
                    Span('前往系统云空间设置页面开启本应用的云空间同步功能。')
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
                  Text('自动同步 (从修改时间较近的一端同步到修改时间较远的一端)')
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
                          isOn: this.autoHuaweiCloudSyncTables.includes(item.value)
                        })
                          .enabled(this.huaweiCloudSyncOnTables.includes(item.value))
                          .onChange((isOn) => {
                            if (!isOn) {
                              this.autoHuaweiCloudSyncTables =
                                this.autoHuaweiCloudSyncTables.filter(inItem => inItem !== item.value)
                            }
                            if (isOn) {
                              this.autoHuaweiCloudSyncTables =
                                Array.from(new Set([...this.autoHuaweiCloudSyncTables, item.value]))
                            }
                            this.dataSettingDataPreferences.putSync('autoHuaweiCloudSyncTables',
                              this.autoHuaweiCloudSyncTables)
                            this.dataSettingDataPreferences.flushSync()
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
                  Text('手动同步')
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
                      Column() {
                        Text('密码')
                          .fontWeight(FontWeight.Medium)
                        if (this.passwordHuaweiCloudSyncProgressDetails) {
                          Text() {
                            Span(this.passwordHuaweiCloudSyncProgressDetails.schedule ===
                            relationalStore.Progress.SYNC_BEGIN ? '同步开始\n' :
                              this.passwordHuaweiCloudSyncProgressDetails.schedule ===
                              relationalStore.Progress.SYNC_IN_PROGRESS ? '同步中\n' :
                                this.passwordHuaweiCloudSyncProgressDetails.schedule ===
                                relationalStore.Progress.SYNC_FINISH ? '同步完成\n' : 'undefined\n')
                              .fontColor(this.passwordHuaweiCloudSyncProgressDetails.schedule ===
                              relationalStore.Progress.SYNC_BEGIN ? $r('sys.color.font_secondary') :
                                this.passwordHuaweiCloudSyncProgressDetails.schedule ===
                                relationalStore.Progress.SYNC_IN_PROGRESS ? Color.Orange : Color.Green)
                            Span(this.passwordHuaweiCloudSyncProgressDetails.code ===
                            relationalStore.ProgressCode.SUCCESS ? '同步成功' :
                              this.passwordHuaweiCloudSyncProgressDetails.code ===
                              relationalStore.ProgressCode.UNKNOWN_ERROR ? '同步过程遇到未知错误' :
                                this.passwordHuaweiCloudSyncProgressDetails.code ===
                                relationalStore.ProgressCode.NETWORK_ERROR ? '同步过程遇到网络错误' :
                                  this.passwordHuaweiCloudSyncProgressDetails.code ===
                                  relationalStore.ProgressCode.CLOUD_DISABLED ? '云端不可用' :
                                    this.passwordHuaweiCloudSyncProgressDetails.code ===
                                    relationalStore.ProgressCode.LOCKED_BY_OTHERS ?
                                      '有其他设备正在同步，本设备当前无法进行同步' :
                                      this.passwordHuaweiCloudSyncProgressDetails.code ===
                                      relationalStore.ProgressCode.RECORD_LIMIT_EXCEEDED ?
                                        '本次同步条目或大小超出最大值' :
                                        this.passwordHuaweiCloudSyncProgressDetails.code ===
                                        relationalStore.ProgressCode.NO_SPACE_FOR_ASSET ?
                                          '云空间剩余空间小于待同步大小' :
                                          this.passwordHuaweiCloudSyncProgressDetails.code ===
                                          relationalStore.ProgressCode.BLOCKED_BY_NETWORK_STRATEGY ?
                                            '同步被网络策略限制' : 'undefined')
                              .fontColor(this.passwordHuaweiCloudSyncProgressDetails.code ===
                              relationalStore.ProgressCode.SUCCESS ? Color.Green : Color.Red)
                            if (this.passwordHuaweiCloudSyncProgressDetails.details['password']) {
                              Span('\n上传：')
                              Span(String(this.passwordHuaweiCloudSyncProgressDetails.details['password'].upload.total))
                              Span('/')
                                .fontColor($r('sys.color.font_secondary'))
                              Span(String(this.passwordHuaweiCloudSyncProgressDetails.details['password'].upload.remained))
                                .fontColor(Color.Orange)
                              Span('/')
                                .fontColor($r('sys.color.font_secondary'))
                              Span(String(this.passwordHuaweiCloudSyncProgressDetails.details['password'].upload.successful))
                                .fontColor(Color.Green)
                              Span('/')
                                .fontColor($r('sys.color.font_secondary'))
                              Span(String(this.passwordHuaweiCloudSyncProgressDetails.details['password'].upload.failed))
                                .fontColor(Color.Red)
                              Span('\n下载：')
                              Span(String(this.passwordHuaweiCloudSyncProgressDetails.details['password'].download.total))
                              Span('/')
                                .fontColor($r('sys.color.font_secondary'))
                              Span(String(this.passwordHuaweiCloudSyncProgressDetails.details['password'].download.remained))
                                .fontColor(Color.Orange)
                              Span('/')
                                .fontColor($r('sys.color.font_secondary'))
                              Span(String(this.passwordHuaweiCloudSyncProgressDetails.details['password'].download.successful))
                                .fontColor(Color.Green)
                              Span('/')
                                .fontColor($r('sys.color.font_secondary'))
                              Span(String(this.passwordHuaweiCloudSyncProgressDetails.details['password'].download.failed))
                                .fontColor(Color.Red)
                            }
                          }
                          .fontSize($r('sys.float.ohos_id_text_size_body2'))
                          .margin({
                            top: $r('sys.float.ohos_id_text_margin_vertical')
                          })
                        }
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)
                      .margin({
                        right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                      })

                      Image($r('app.media.up'))
                        .height(24)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                        .onClick(async () => {
                          if (!this.huaweiCloudSyncOnTables.includes('password')) {
                            await promptAction.openToast({
                              message: '请先开启上方状态开关'
                            })
                            return
                          }
                          const huaweiCloudSyncRdbStore = await relationalStore.getRdbStore(this.context, {
                            name: 'huaweicloudsync',
                            securityLevel: relationalStore.SecurityLevel.S3,
                            encrypt: true,
                            allowRebuild: true
                          })
                          await huaweiCloudSyncRdbStore.cloudSync(relationalStore.SyncMode.SYNC_MODE_NATIVE_FIRST,
                            ['password'], (progressDetails) => {
                              this.passwordHuaweiCloudSyncProgressDetails = progressDetails
                            })
                        })
                      Image($r('app.media.down'))
                        .height(24)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                        .onClick(async () => {
                          if (!this.huaweiCloudSyncOnTables.includes('password')) {
                            await promptAction.openToast({
                              message: '请先开启上方状态开关'
                            })
                            return
                          }
                          const huaweiCloudSyncRdbStore = await relationalStore.getRdbStore(this.context, {
                            name: 'huaweicloudsync',
                            securityLevel: relationalStore.SecurityLevel.S3,
                            encrypt: true,
                            allowRebuild: true
                          })
                          await huaweiCloudSyncRdbStore.cloudSync(relationalStore.SyncMode.SYNC_MODE_CLOUD_FIRST,
                            ['password'], (progressDetails) => {
                              this.passwordHuaweiCloudSyncProgressDetails = progressDetails
                            })
                        })
                      Image($r('app.media.time'))
                        .height(24)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                        .onClick(async () => {
                          if (!this.huaweiCloudSyncOnTables.includes('password')) {
                            await promptAction.openToast({
                              message: '请先开启上方状态开关'
                            })
                            return
                          }
                          const huaweiCloudSyncRdbStore = await relationalStore.getRdbStore(this.context, {
                            name: 'huaweicloudsync',
                            securityLevel: relationalStore.SecurityLevel.S3,
                            encrypt: true,
                            allowRebuild: true
                          })
                          await huaweiCloudSyncRdbStore.cloudSync(relationalStore.SyncMode.SYNC_MODE_TIME_FIRST,
                            ['password'], (progressDetails) => {
                              this.passwordHuaweiCloudSyncProgressDetails = progressDetails
                            })
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
                      Column() {
                        Text('常用信息')
                          .fontWeight(FontWeight.Medium)
                        if (this.infoHuaweiCloudSyncProgressDetails) {
                          Text() {
                            Span(this.infoHuaweiCloudSyncProgressDetails.schedule ===
                            relationalStore.Progress.SYNC_BEGIN ? '同步开始\n' :
                              this.infoHuaweiCloudSyncProgressDetails.schedule ===
                              relationalStore.Progress.SYNC_IN_PROGRESS ? '同步中\n' :
                                this.infoHuaweiCloudSyncProgressDetails.schedule ===
                                relationalStore.Progress.SYNC_FINISH ? '同步完成\n' : 'undefined\n')
                              .fontColor(this.infoHuaweiCloudSyncProgressDetails.schedule ===
                              relationalStore.Progress.SYNC_BEGIN ? $r('sys.color.font_secondary') :
                                this.infoHuaweiCloudSyncProgressDetails.schedule ===
                                relationalStore.Progress.SYNC_IN_PROGRESS ? Color.Orange : Color.Green)
                            Span(this.infoHuaweiCloudSyncProgressDetails.code ===
                            relationalStore.ProgressCode.SUCCESS ? '同步成功' :
                              this.infoHuaweiCloudSyncProgressDetails.code ===
                              relationalStore.ProgressCode.UNKNOWN_ERROR ? '同步过程遇到未知错误' :
                                this.infoHuaweiCloudSyncProgressDetails.code ===
                                relationalStore.ProgressCode.NETWORK_ERROR ? '同步过程遇到网络错误' :
                                  this.infoHuaweiCloudSyncProgressDetails.code ===
                                  relationalStore.ProgressCode.CLOUD_DISABLED ? '云端不可用' :
                                    this.infoHuaweiCloudSyncProgressDetails.code ===
                                    relationalStore.ProgressCode.LOCKED_BY_OTHERS ?
                                      '有其他设备正在同步，本设备当前无法进行同步' :
                                      this.infoHuaweiCloudSyncProgressDetails.code ===
                                      relationalStore.ProgressCode.RECORD_LIMIT_EXCEEDED ?
                                        '本次同步条目或大小超出最大值' :
                                        this.infoHuaweiCloudSyncProgressDetails.code ===
                                        relationalStore.ProgressCode.NO_SPACE_FOR_ASSET ?
                                          '云空间剩余空间小于待同步大小' :
                                          this.infoHuaweiCloudSyncProgressDetails.code ===
                                          relationalStore.ProgressCode.BLOCKED_BY_NETWORK_STRATEGY ?
                                            '同步被网络策略限制' : 'undefined')
                              .fontColor(this.infoHuaweiCloudSyncProgressDetails.code ===
                              relationalStore.ProgressCode.SUCCESS ? Color.Green : Color.Red)
                            if (this.infoHuaweiCloudSyncProgressDetails.details['info']) {
                              Span('\n上传：')
                              Span(String(this.infoHuaweiCloudSyncProgressDetails.details['info'].upload.total))
                              Span('/')
                                .fontColor($r('sys.color.font_secondary'))
                              Span(String(this.infoHuaweiCloudSyncProgressDetails.details['info'].upload.remained))
                                .fontColor(Color.Orange)
                              Span('/')
                                .fontColor($r('sys.color.font_secondary'))
                              Span(String(this.infoHuaweiCloudSyncProgressDetails.details['info'].upload.successful))
                                .fontColor(Color.Green)
                              Span('/')
                                .fontColor($r('sys.color.font_secondary'))
                              Span(String(this.infoHuaweiCloudSyncProgressDetails.details['info'].upload.failed))
                                .fontColor(Color.Red)
                              Span('\n下载：')
                              Span(String(this.infoHuaweiCloudSyncProgressDetails.details['info'].download.total))
                              Span('/')
                                .fontColor($r('sys.color.font_secondary'))
                              Span(String(this.infoHuaweiCloudSyncProgressDetails.details['info'].download.remained))
                                .fontColor(Color.Orange)
                              Span('/')
                                .fontColor($r('sys.color.font_secondary'))
                              Span(String(this.infoHuaweiCloudSyncProgressDetails.details['info'].download.successful))
                                .fontColor(Color.Green)
                              Span('/')
                                .fontColor($r('sys.color.font_secondary'))
                              Span(String(this.infoHuaweiCloudSyncProgressDetails.details['info'].download.failed))
                                .fontColor(Color.Red)
                            }
                          }
                          .fontSize($r('sys.float.ohos_id_text_size_body2'))
                          .margin({
                            top: $r('sys.float.ohos_id_text_margin_vertical')
                          })
                        }
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)
                      .margin({
                        right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                      })

                      Image($r('app.media.up'))
                        .height(24)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                        .onClick(async () => {
                          if (!this.huaweiCloudSyncOnTables.includes('info')) {
                            await promptAction.openToast({
                              message: '请先开启上方状态开关'
                            })
                            return
                          }
                          const huaweiCloudSyncRdbStore = await relationalStore.getRdbStore(this.context, {
                            name: 'huaweicloudsync',
                            securityLevel: relationalStore.SecurityLevel.S3,
                            encrypt: true,
                            allowRebuild: true
                          })
                          await huaweiCloudSyncRdbStore.cloudSync(relationalStore.SyncMode.SYNC_MODE_NATIVE_FIRST,
                            ['info'], (progressDetails) => {
                              this.infoHuaweiCloudSyncProgressDetails = progressDetails
                            })
                        })
                      Image($r('app.media.down'))
                        .height(24)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                        .onClick(async () => {
                          if (!this.huaweiCloudSyncOnTables.includes('info')) {
                            await promptAction.openToast({
                              message: '请先开启上方状态开关'
                            })
                            return
                          }
                          const huaweiCloudSyncRdbStore = await relationalStore.getRdbStore(this.context, {
                            name: 'huaweicloudsync',
                            securityLevel: relationalStore.SecurityLevel.S3,
                            encrypt: true,
                            allowRebuild: true
                          })
                          await huaweiCloudSyncRdbStore.cloudSync(relationalStore.SyncMode.SYNC_MODE_CLOUD_FIRST,
                            ['info'], (progressDetails) => {
                              this.infoHuaweiCloudSyncProgressDetails = progressDetails
                            })
                        })
                      Image($r('app.media.time'))
                        .height(24)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                        .onClick(async () => {
                          if (!this.huaweiCloudSyncOnTables.includes('info')) {
                            await promptAction.openToast({
                              message: '请先开启上方状态开关'
                            })
                            return
                          }
                          const huaweiCloudSyncRdbStore = await relationalStore.getRdbStore(this.context, {
                            name: 'huaweicloudsync',
                            securityLevel: relationalStore.SecurityLevel.S3,
                            encrypt: true,
                            allowRebuild: true
                          })
                          await huaweiCloudSyncRdbStore.cloudSync(relationalStore.SyncMode.SYNC_MODE_TIME_FIRST,
                            ['info'], (progressDetails) => {
                              this.infoHuaweiCloudSyncProgressDetails = progressDetails
                            })
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
                      Column() {
                        Text('标签')
                          .fontWeight(FontWeight.Medium)
                        if (this.tagHuaweiCloudSyncProgressDetails) {
                          Text() {
                            Span(this.tagHuaweiCloudSyncProgressDetails.schedule ===
                            relationalStore.Progress.SYNC_BEGIN ? '同步开始\n' :
                              this.tagHuaweiCloudSyncProgressDetails.schedule ===
                              relationalStore.Progress.SYNC_IN_PROGRESS ? '同步中\n' :
                                this.tagHuaweiCloudSyncProgressDetails.schedule ===
                                relationalStore.Progress.SYNC_FINISH ? '同步完成\n' : 'undefined\n')
                              .fontColor(this.tagHuaweiCloudSyncProgressDetails.schedule ===
                              relationalStore.Progress.SYNC_BEGIN ? $r('sys.color.font_secondary') :
                                this.tagHuaweiCloudSyncProgressDetails.schedule ===
                                relationalStore.Progress.SYNC_IN_PROGRESS ? Color.Orange : Color.Green)
                            Span(this.tagHuaweiCloudSyncProgressDetails.code ===
                            relationalStore.ProgressCode.SUCCESS ? '同步成功' :
                              this.tagHuaweiCloudSyncProgressDetails.code ===
                              relationalStore.ProgressCode.UNKNOWN_ERROR ? '同步过程遇到未知错误' :
                                this.tagHuaweiCloudSyncProgressDetails.code ===
                                relationalStore.ProgressCode.NETWORK_ERROR ? '同步过程遇到网络错误' :
                                  this.tagHuaweiCloudSyncProgressDetails.code ===
                                  relationalStore.ProgressCode.CLOUD_DISABLED ? '云端不可用' :
                                    this.tagHuaweiCloudSyncProgressDetails.code ===
                                    relationalStore.ProgressCode.LOCKED_BY_OTHERS ?
                                      '有其他设备正在同步，本设备当前无法进行同步' :
                                      this.tagHuaweiCloudSyncProgressDetails.code ===
                                      relationalStore.ProgressCode.RECORD_LIMIT_EXCEEDED ?
                                        '本次同步条目或大小超出最大值' :
                                        this.tagHuaweiCloudSyncProgressDetails.code ===
                                        relationalStore.ProgressCode.NO_SPACE_FOR_ASSET ?
                                          '云空间剩余空间小于待同步大小' :
                                          this.tagHuaweiCloudSyncProgressDetails.code ===
                                          relationalStore.ProgressCode.BLOCKED_BY_NETWORK_STRATEGY ?
                                            '同步被网络策略限制' : 'undefined')
                              .fontColor(this.tagHuaweiCloudSyncProgressDetails.code ===
                              relationalStore.ProgressCode.SUCCESS ? Color.Green : Color.Red)
                            if (this.tagHuaweiCloudSyncProgressDetails.details['tag']) {
                              Span('\n上传：')
                              Span(String(this.tagHuaweiCloudSyncProgressDetails.details['tag'].upload.total))
                              Span('/')
                                .fontColor($r('sys.color.font_secondary'))
                              Span(String(this.tagHuaweiCloudSyncProgressDetails.details['tag'].upload.remained))
                                .fontColor(Color.Orange)
                              Span('/')
                                .fontColor($r('sys.color.font_secondary'))
                              Span(String(this.tagHuaweiCloudSyncProgressDetails.details['tag'].upload.successful))
                                .fontColor(Color.Green)
                              Span('/')
                                .fontColor($r('sys.color.font_secondary'))
                              Span(String(this.tagHuaweiCloudSyncProgressDetails.details['tag'].upload.failed))
                                .fontColor(Color.Red)
                              Span('\n下载：')
                              Span(String(this.tagHuaweiCloudSyncProgressDetails.details['tag'].download.total))
                              Span('/')
                                .fontColor($r('sys.color.font_secondary'))
                              Span(String(this.tagHuaweiCloudSyncProgressDetails.details['tag'].download.remained))
                                .fontColor(Color.Orange)
                              Span('/')
                                .fontColor($r('sys.color.font_secondary'))
                              Span(String(this.tagHuaweiCloudSyncProgressDetails.details['tag'].download.successful))
                                .fontColor(Color.Green)
                              Span('/')
                                .fontColor($r('sys.color.font_secondary'))
                              Span(String(this.tagHuaweiCloudSyncProgressDetails.details['tag'].download.failed))
                                .fontColor(Color.Red)
                            }
                          }
                          .fontSize($r('sys.float.ohos_id_text_size_body2'))
                          .margin({
                            top: $r('sys.float.ohos_id_text_margin_vertical')
                          })
                        }
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)
                      .margin({
                        right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                      })

                      Image($r('app.media.up'))
                        .height(24)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                        .onClick(async () => {
                          if (!this.huaweiCloudSyncOnTables.includes('tag')) {
                            await promptAction.openToast({
                              message: '请先开启上方状态开关'
                            })
                            return
                          }
                          const huaweiCloudSyncRdbStore = await relationalStore.getRdbStore(this.context, {
                            name: 'huaweicloudsync',
                            securityLevel: relationalStore.SecurityLevel.S3,
                            encrypt: true,
                            allowRebuild: true
                          })
                          await huaweiCloudSyncRdbStore.cloudSync(relationalStore.SyncMode.SYNC_MODE_NATIVE_FIRST,
                            ['tag'], (progressDetails) => {
                              this.tagHuaweiCloudSyncProgressDetails = progressDetails
                            })
                        })
                      Image($r('app.media.down'))
                        .height(24)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                        .onClick(async () => {
                          if (!this.huaweiCloudSyncOnTables.includes('tag')) {
                            await promptAction.openToast({
                              message: '请先开启上方状态开关'
                            })
                            return
                          }
                          const huaweiCloudSyncRdbStore = await relationalStore.getRdbStore(this.context, {
                            name: 'huaweicloudsync',
                            securityLevel: relationalStore.SecurityLevel.S3,
                            encrypt: true,
                            allowRebuild: true
                          })
                          await huaweiCloudSyncRdbStore.cloudSync(relationalStore.SyncMode.SYNC_MODE_CLOUD_FIRST,
                            ['tag'], (progressDetails) => {
                              this.tagHuaweiCloudSyncProgressDetails = progressDetails
                            })
                        })
                      Image($r('app.media.time'))
                        .height(24)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                        .onClick(async () => {
                          if (!this.huaweiCloudSyncOnTables.includes('tag')) {
                            await promptAction.openToast({
                              message: '请先开启上方状态开关'
                            })
                            return
                          }
                          const huaweiCloudSyncRdbStore = await relationalStore.getRdbStore(this.context, {
                            name: 'huaweicloudsync',
                            securityLevel: relationalStore.SecurityLevel.S3,
                            encrypt: true,
                            allowRebuild: true
                          })
                          await huaweiCloudSyncRdbStore.cloudSync(relationalStore.SyncMode.SYNC_MODE_TIME_FIRST,
                            ['tag'], (progressDetails) => {
                              this.tagHuaweiCloudSyncProgressDetails = progressDetails
                            })
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
                  Row() {
                    Text('迁移本地表数据到云空间同步表')
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
                    const rdbStore = await relationalStore.getRdbStore(this.context, {
                      name: 'huaweicloudsync',
                      securityLevel: relationalStore.SecurityLevel.S3,
                      encrypt: true,
                      allowRebuild: true
                    })
                    const passwordRdbStore = await relationalStore.getRdbStore(this.context, {
                      name: 'password',
                      securityLevel: relationalStore.SecurityLevel.S4,
                      encrypt: true,
                      allowRebuild: true
                    })
                    const predicatesPassword = new relationalStore.RdbPredicates('password')
                    const resultSetPassword = await passwordRdbStore.query(predicatesPassword)
                    const idIndexPassword = resultSetPassword.getColumnIndex('id')
                    const nameIndexPassword = resultSetPassword.getColumnIndex('name')
                    const infoIndexPassword = resultSetPassword.getColumnIndex('info')
                    const tagIndexPassword = resultSetPassword.getColumnIndex('tag')
                    const updateTimeIndexPassword = resultSetPassword.getColumnIndex('updateTime')
                    const cloudBackupTimeIndexPassword = resultSetPassword.getColumnIndex('cloudBackupTime')
                    while (resultSetPassword.goToNextRow()) {
                      rdbStore.insertSync('password', {
                        id: String(resultSetPassword.getValue(idIndexPassword)),
                        name: resultSetPassword.getValue(nameIndexPassword) as string,
                        info: resultSetPassword.getValue(infoIndexPassword) as string,
                        tag: resultSetPassword.getValue(tagIndexPassword) as string,
                        updateTime: resultSetPassword.getValue(updateTimeIndexPassword) as number,
                        cloudBackupTime: resultSetPassword.getValue(cloudBackupTimeIndexPassword) as string | number
                      }, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
                    }
                    resultSetPassword.close()
                    const infoRdbStore = await relationalStore.getRdbStore(this.context, {
                      name: 'info',
                      securityLevel: relationalStore.SecurityLevel.S4,
                      encrypt: true,
                      allowRebuild: true
                    })
                    const predicatesInfo = new relationalStore.RdbPredicates('info')
                    const resultSetInfo = await infoRdbStore.query(predicatesInfo)
                    const idIndexInfo = resultSetInfo.getColumnIndex('id')
                    const typeIndexInfo = resultSetInfo.getColumnIndex('type')
                    const valueIndexInfo = resultSetInfo.getColumnIndex('value')
                    const updateTimeIndexInfo = resultSetInfo.getColumnIndex('updateTime')
                    const cloudBackupTimeIndexInfo = resultSetInfo.getColumnIndex('cloudBackupTime')
                    while (resultSetInfo.goToNextRow()) {
                      rdbStore.insertSync('info', {
                        id: String(resultSetInfo.getValue(idIndexInfo)),
                        type: resultSetInfo.getValue(typeIndexInfo) as string,
                        value: resultSetInfo.getValue(valueIndexInfo) as string,
                        updateTime: resultSetInfo.getValue(updateTimeIndexInfo) as number,
                        cloudBackupTime: resultSetInfo.getValue(cloudBackupTimeIndexInfo) as string | number
                      }, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
                    }
                    resultSetInfo.close()
                    const tagRdbStore = await relationalStore.getRdbStore(this.context, {
                      name: 'tag',
                      securityLevel: relationalStore.SecurityLevel.S1,
                      encrypt: true,
                      allowRebuild: true
                    })
                    const predicatesTag = new relationalStore.RdbPredicates('tag')
                    const resultSetTag = await tagRdbStore.query(predicatesTag)
                    const idIndexTag = resultSetTag.getColumnIndex('id')
                    const valueIndexTag = resultSetTag.getColumnIndex('value')
                    const colorIndexTag = resultSetTag.getColumnIndex('color')
                    const updateTimeIndexTag = resultSetTag.getColumnIndex('updateTime')
                    const cloudBackupTimeIndexTag = resultSetTag.getColumnIndex('cloudBackupTime')
                    while (resultSetTag.goToNextRow()) {
                      rdbStore.insertSync('tag', {
                        id: String(resultSetTag.getValue(idIndexTag)),
                        value: resultSetTag.getValue(valueIndexTag) as string,
                        color: resultSetTag.getValue(colorIndexTag) as string,
                        updateTime: resultSetTag.getValue(updateTimeIndexTag) as number,
                        cloudBackupTime: resultSetTag.getValue(cloudBackupTimeIndexTag) as string | number
                      }, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
                    }
                    resultSetTag.close()
                    await promptAction.openToast({
                      message: '迁移成功'
                    })
                  })
                }
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                .padding($r('sys.float.ohos_id_corner_radius_mark'))
              }
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })
            }
            if (this.selectedIndex === 2) {
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
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
            }
            if (this.selectedIndex === 3) {
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
                    const shareData = new systemShare.SharedData({
                      utd: uniformTypeDescriptor.UniformDataType.PLAIN_TEXT,
                      title: 'password.txt',
                      description: getSizeString(fileIo.statSync(filePath).size),
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
                    const shareData = new systemShare.SharedData({
                      utd: uniformTypeDescriptor.UniformDataType.ZIP_ARCHIVE,
                      title: 'passwordicon.zip',
                      description: getSizeString(fileIo.statSync(filePath).size),
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
                    const shareData = new systemShare.SharedData({
                      utd: uniformTypeDescriptor.UniformDataType.PLAIN_TEXT,
                      title: 'info.txt',
                      description: getSizeString(fileIo.statSync(filePath).size),
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
                    const shareData = new systemShare.SharedData({
                      utd: uniformTypeDescriptor.UniformDataType.PLAIN_TEXT,
                      title: 'tag.txt',
                      description: getSizeString(fileIo.statSync(filePath).size),
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
    .titleBar({
      padding: {
        end: LengthMetrics.vp(60)
      },
      style: {
        thermoCtrl: true,
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.ADAPTIVE,
          materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
        }
      },
      content: {
        title: {
          mainTitle: '设备间数据同步'
        }
      },
      enableComponentSafeArea: true
    })
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