import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'

@Builder
export function ClearsettingsBuilder() {
  Clearsettings()
}

@ComponentV2
struct Clearsettings {
  @Local all: boolean = false
  @Local cloudbackup: boolean = false
  @Local data: boolean = false
  @Local common: boolean = false
  @Local permission: boolean = false
  @Local types: string[] = []
  context = getContext(this) as common.UIAbilityContext
  pageInfos: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Column() {
              Row() {
                CheckboxGroup({
                  group: 'type'
                })
                  .checkboxShape(CheckBoxShape.ROUNDED_SQUARE)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .selectAll($$this.all)
                  .onChange((itemName: CheckboxGroupResult) => {
                    this.types = itemName.name
                  })
                Text('全部')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('bold')
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
                Checkbox({
                  name: 'cloudbackup',
                  group: 'type'
                })
                  .shape(CheckBoxShape.ROUNDED_SQUARE)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .select($$this.cloudbackup)
                Column() {
                  Text('云备份')
                    .fontSize($r('sys.float.ohos_id_text_size_body1'))
                    .fontWeight('medium')
                  Text('自动同步')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                    .width('90%')
                }
                .alignItems(HorizontalAlign.Start)
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
                Checkbox({
                  name: 'data',
                  group: 'type'
                })
                  .shape(CheckBoxShape.ROUNDED_SQUARE)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .select($$this.data)
                Column() {
                  Text('数据')
                    .fontSize($r('sys.float.ohos_id_text_size_body1'))
                    .fontWeight('medium')
                  Text('设备间自动同步、自动备份等')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                    .width('90%')
                }
                .alignItems(HorizontalAlign.Start)
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
                Checkbox({
                  name: 'common',
                  group: 'type'
                })
                  .shape(CheckBoxShape.ROUNDED_SQUARE)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .select($$this.common)
                Column() {
                  Text('通用')
                    .fontSize($r('sys.float.ohos_id_text_size_body1'))
                    .fontWeight('medium')
                  Text('应用服务模式、深色模式、启动时检查更新、链接打开方式')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                    .width('90%')
                }
                .alignItems(HorizontalAlign.Start)
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
                Checkbox({
                  name: 'permission',
                  group: 'type'
                })
                  .shape(CheckBoxShape.ROUNDED_SQUARE)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .select($$this.permission)
                Column() {
                  Text('权限')
                    .fontSize($r('sys.float.ohos_id_text_size_body1'))
                    .fontWeight('medium')
                  Text('写入剪贴板')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                    .width('90%')
                }
                .alignItems(HorizontalAlign.Start)
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))

            Button('清除')
              .enabled(this.types.length > 0)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })
              .role(ButtonRole.ERROR)
              .onClick(async () => {
                const data = await promptAction.showDialog({
                  title: '提示',
                  message: '清除成功后将恢复所选设置为默认，无法恢复。确定清除？',
                  buttons: [
                    {
                      text: '取消',
                      color: $r('sys.color.font_primary')
                    },
                    {
                      text: '清除',
                      color: $r('sys.color.warning')
                    }
                  ]
                })
                if (data.index === 1) {
                  this.types.forEach((item) => {
                    const dataPreferences = preferences.getPreferencesSync(this.context, {
                      name: item + 'Setting'
                    })
                    if (item === 'data') {
                      const keys = [
                        'autoSyncTables',
                        'autoSyncDevices',
                        'autoBackupTables',
                        'pauseAutoSyncWhenLowBatteryCapacityLevel',
                        'pauseAutoSyncWhenPowerSave',
                        'pauseAutoBackupWhenLowBatteryCapacityLevel',
                        'pauseAutoBackupWhenPowerSave'
                      ]
                      keys.forEach((item) => {
                        dataPreferences.deleteSync(item)
                      })
                    } else {
                      dataPreferences.clearSync()
                    }
                    dataPreferences.flushSync()
                  })
                  promptAction.showToast({
                    message: '清除成功'
                  })
                  this.pageInfos.pop()
                }
              })
          }
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })
      }
      .backgroundColor($r('app.color.sheet_background'))
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title('清除设置数据')
    .onReady((context: NavDestinationContext) => {
      this.pageInfos = context.pathStack
    })
  }
}