import { preferences } from '@kit.ArkData'

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
  @Local autoOn: string[] = []
  context = this.getUIContext().getHostContext()
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
    NavDestination() {
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
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.autoOn.includes(item.value)
                })
                  .onChange((isOn) => {
                    let autoOn: string[] = []
                    if (!isOn) {
                      autoOn = this.autoOn.filter(itema => itema !== item.value)
                    }
                    if (isOn) {
                      autoOn = [...this.autoOn, item.value]
                    }
                    this.cloudbackupSettingDataPreferences.putSync('autoOn', autoOn)
                    this.cloudbackupSettingDataPreferences.flushSync()
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
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
      }
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title('云备份自动开启设置')
    .onAppear(() => {
      this.getSetting()
    })
  }
}