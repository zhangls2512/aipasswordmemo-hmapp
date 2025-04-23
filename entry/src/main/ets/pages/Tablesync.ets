import { common } from '@kit.AbilityKit'
import { preferences, relationalStore } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { BusinessError } from '@kit.BasicServicesKit'
import { distributedDeviceManager } from '@kit.DistributedServiceKit'
import { checkPermission } from '../common/Permission'

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
  @Local password: boolean = false
  @Local info: boolean = false
  @Local tag: boolean = false
  context = getContext(this) as common.UIAbilityContext
  datasyncSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'datasyncSetting'
  })
  onTables: string[] = []
  availableDeviceArray: Item[] = []

  getSetting() {
    const onTables: preferences.ValueType =
      this.datasyncSettingDataPreferences.getSync('onTables', [])
    this.onTables = onTables as string[]
    this.password = this.onTables.includes('password')
    this.info = this.onTables.includes('info')
    this.tag = this.onTables.includes('tag')
  }

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Row() {
              Text('密码')
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontWeight('medium')
              Blank()
              Toggle({
                type: ToggleType.Switch,
                isOn: $$this.password
              })
                .enabled(!this.password)
                .onChange(async (isOn: boolean) => {
                  if (isOn) {
                    const res = await checkPermission('ohos.permission.DISTRIBUTED_DATASYNC')
                    if (!res) {
                      this.password = false
                    }
                    if (res) {
                      const rdbStore = await relationalStore.getRdbStore(this.context, {
                        name: 'password',
                        securityLevel: 4,
                        encrypt: true,
                        allowRebuild: true
                      })
                      try {
                        await rdbStore.setDistributedTables(['password'])
                        const onTables = [...this.onTables, 'password']
                        this.datasyncSettingDataPreferences.putSync('onTables', onTables)
                        this.datasyncSettingDataPreferences.flushSync()
                        this.getSetting()
                      } catch (err) {
                        this.password = false
                        promptAction.showToast({
                          message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
                          (err as BusinessError).message
                        })
                      }
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
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontWeight('medium')
              Blank()
              Toggle({
                type: ToggleType.Switch,
                isOn: $$this.info
              })
                .enabled(!this.info)
                .onChange(async (isOn: boolean) => {
                  if (isOn) {
                    const res = await checkPermission('ohos.permission.DISTRIBUTED_DATASYNC')
                    if (!res) {
                      this.info = false
                    }
                    if (res) {
                      const rdbStore = await relationalStore.getRdbStore(this.context, {
                        name: 'info',
                        securityLevel: 4,
                        encrypt: true,
                        allowRebuild: true
                      })
                      try {
                        await rdbStore.setDistributedTables(['info'])
                        const onTables = [...this.onTables, 'info']
                        this.datasyncSettingDataPreferences.putSync('onTables', onTables)
                        this.datasyncSettingDataPreferences.flushSync()
                        this.getSetting()
                      } catch (err) {
                        this.info = false
                        promptAction.showToast({
                          message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
                          (err as BusinessError).message
                        })
                      }
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
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontWeight('medium')
              Blank()
              Toggle({
                type: ToggleType.Switch,
                isOn: $$this.tag
              })
                .enabled(!this.tag)
                .onChange(async (isOn: boolean) => {
                  if (isOn) {
                    const res = await checkPermission('ohos.permission.DISTRIBUTED_DATASYNC')
                    if (!res) {
                      this.tag = false
                    }
                    if (res) {
                      const rdbStore = await relationalStore.getRdbStore(this.context, {
                        name: 'tag',
                        securityLevel: 1,
                        encrypt: true,
                        allowRebuild: true
                      })
                      try {
                        await rdbStore.setDistributedTables(['tag'])
                        const onTables = [...this.onTables, 'tag']
                        this.datasyncSettingDataPreferences.putSync('onTables', onTables)
                        this.datasyncSettingDataPreferences.flushSync()
                        this.getSetting()
                      } catch (err) {
                        this.tag = false
                        promptAction.showToast({
                          message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
                          (err as BusinessError).message
                        })
                      }
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
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Text('可信设备')
            .fontSize($r('sys.float.ohos_id_text_size_dialog_tittle'))
            .fontWeight('bold')
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ForEach(this.availableDeviceArray, (item: Item) => {
          ListItem() {
            Column() {
              Row() {
                Text('标识符')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
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
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
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
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
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
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
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
                Text('推送')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
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
                  title: '选择数据表',
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
                  const rdbStore = await relationalStore.getRdbStore(this.context, {
                    name: 'password',
                    securityLevel: 4,
                    encrypt: true,
                    allowRebuild: true
                  })
                  const predicates = new relationalStore.RdbPredicates('password')
                  predicates.inDevices([item.deviceId])
                  try {
                    const res = await rdbStore.sync(relationalStore.SyncMode.SYNC_MODE_PUSH, predicates)
                    if (res[0][1] === 0) {
                      promptAction.showToast({
                        message: '同步成功'
                      })
                    } else {
                      promptAction.showToast({
                        message: '同步失败'
                      })
                    }
                  } catch (err) {
                    this.tag = false
                    promptAction.showToast({
                      message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
                      (err as BusinessError).message
                    })
                  }
                }
                if (data.index === 1) {
                  const rdbStore = await relationalStore.getRdbStore(this.context, {
                    name: 'info',
                    securityLevel: 4,
                    encrypt: true,
                    allowRebuild: true
                  })
                  const predicates = new relationalStore.RdbPredicates('info')
                  predicates.inDevices([item.deviceId])
                  try {
                    const res = await rdbStore.sync(relationalStore.SyncMode.SYNC_MODE_PUSH, predicates)
                    if (res[0][1] === 0) {
                      promptAction.showToast({
                        message: '同步成功'
                      })
                    } else {
                      promptAction.showToast({
                        message: '同步失败'
                      })
                    }
                  } catch (err) {
                    this.tag = false
                    promptAction.showToast({
                      message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
                      (err as BusinessError).message
                    })
                  }
                }
                if (data.index === 2) {
                  const rdbStore = await relationalStore.getRdbStore(this.context, {
                    name: 'tag',
                    securityLevel: 1,
                    encrypt: true,
                    allowRebuild: true
                  })
                  const predicates = new relationalStore.RdbPredicates('tag')
                  predicates.inDevices([item.deviceId])
                  try {
                    const res = await rdbStore.sync(relationalStore.SyncMode.SYNC_MODE_PUSH, predicates)
                    if (res[0][1] === 0) {
                      promptAction.showToast({
                        message: '同步成功'
                      })
                    } else {
                      promptAction.showToast({
                        message: '同步失败'
                      })
                    }
                  } catch (err) {
                    this.tag = false
                    promptAction.showToast({
                      message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
                      (err as BusinessError).message
                    })
                  }
                }
              })

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('拉取')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
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
                  title: '选择数据表',
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
                  const rdbStore = await relationalStore.getRdbStore(this.context, {
                    name: 'password',
                    securityLevel: 4,
                    encrypt: true,
                    allowRebuild: true
                  })
                  const predicates = new relationalStore.RdbPredicates('password')
                  predicates.inDevices([item.deviceId])
                  try {
                    const res = await rdbStore.sync(relationalStore.SyncMode.SYNC_MODE_PULL, predicates)
                    if (res[0][1] === 0) {
                      promptAction.showToast({
                        message: '同步成功'
                      })
                    } else {
                      promptAction.showToast({
                        message: '同步失败'
                      })
                    }
                  } catch (err) {
                    this.tag = false
                    promptAction.showToast({
                      message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
                      (err as BusinessError).message
                    })
                  }
                }
                if (data.index === 1) {
                  const rdbStore = await relationalStore.getRdbStore(this.context, {
                    name: 'info',
                    securityLevel: 4,
                    encrypt: true,
                    allowRebuild: true
                  })
                  const predicates = new relationalStore.RdbPredicates('info')
                  predicates.inDevices([item.deviceId])
                  try {
                    const res = await rdbStore.sync(relationalStore.SyncMode.SYNC_MODE_PULL, predicates)
                    if (res[0][1] === 0) {
                      promptAction.showToast({
                        message: '同步成功'
                      })
                    } else {
                      promptAction.showToast({
                        message: '同步失败'
                      })
                    }
                  } catch (err) {
                    this.tag = false
                    promptAction.showToast({
                      message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
                      (err as BusinessError).message
                    })
                  }
                }
                if (data.index === 2) {
                  const rdbStore = await relationalStore.getRdbStore(this.context, {
                    name: 'tag',
                    securityLevel: 1,
                    encrypt: true,
                    allowRebuild: true
                  })
                  const predicates = new relationalStore.RdbPredicates('tag')
                  predicates.inDevices([item.deviceId])
                  try {
                    const res = await rdbStore.sync(relationalStore.SyncMode.SYNC_MODE_PULL, predicates)
                    if (res[0][1] === 0) {
                      promptAction.showToast({
                        message: '同步成功'
                      })
                    } else {
                      promptAction.showToast({
                        message: '同步失败'
                      })
                    }
                  } catch (err) {
                    this.tag = false
                    promptAction.showToast({
                      message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
                      (err as BusinessError).message
                    })
                  }
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