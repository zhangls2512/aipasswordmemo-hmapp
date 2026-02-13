import { preferences } from '@kit.ArkData'
import { LengthMetrics } from '@kit.ArkUI'
import { HdsNavDestination } from '@kit.UIDesignKit'

interface Type {
  name: string,
  value: string
}

@Builder
export function AutocloudbackupsettingBuilder() {
  Autocloudbackupsetting()
}

@ComponentV2
struct Autocloudbackupsetting {
  context = this.getUIContext().getHostContext()
  autoOn: string[] = []
  cloudbackupSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'cloudbackupSetting'
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
    this.autoOn = this.cloudbackupSettingDataPreferences.getSync('autoOn', []) as string[]
  }

  build() {
    HdsNavDestination() {
      List() {
        ListItem() {
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
                  isOn: this.autoOn.includes(item.value)
                })
                  .onChange((isOn) => {
                    if (!isOn) {
                      this.autoOn = this.autoOn.filter(inItem => inItem !== item.value)
                    }
                    if (isOn) {
                      this.autoOn = Array.from(new Set([...this.autoOn, item.value]))
                    }
                    this.cloudbackupSettingDataPreferences.putSync('autoOn', this.autoOn)
                    this.cloudbackupSettingDataPreferences.flushSync()
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
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
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
      content: {
        title: {
          mainTitle: '云备份自动开启设置'
        }
      },
      enableComponentSafeArea: true
    })
    .onAppear(() => {
      this.getSetting()
    })
  }
}