import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'

@Builder
export function AutocloudbackupsettingBuilder() {
  Autocloudbackupsetting()
}

@ComponentV2
struct Autocloudbackupsetting {
  @Local password: boolean = false
  @Local info: boolean = false
  @Local tag: boolean = false
  context = getContext(this) as common.UIAbilityContext
  cloudbackupSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'cloudbackupSetting'
  })
  autoOn: string[] = []

  getSetting() {
    const autoOn: preferences.ValueType =
      this.cloudbackupSettingDataPreferences.getSync('autoOn', [])
    this.autoOn = autoOn as string[]
    this.password = this.autoOn.includes('password')
    this.info = this.autoOn.includes('info')
    this.tag = this.autoOn.includes('tag')
  }

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Row() {
              Text('密码')
                .fontWeight('medium')
              Blank()
              Toggle({
                type: ToggleType.Switch,
                isOn: this.password
              })
                .onChange((isOn: boolean) => {
                  let autoOn: string[] = []
                  if (!isOn) {
                    autoOn = this.autoOn.filter(item => item !== 'password')
                  }
                  if (isOn) {
                    autoOn = [...this.autoOn, 'password']
                  }
                  this.cloudbackupSettingDataPreferences.putSync('autoOn', autoOn)
                  this.cloudbackupSettingDataPreferences.flushSync()
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
                isOn: this.info
              })
                .onChange((isOn: boolean) => {
                  let autoOn: string[] = []
                  if (!isOn) {
                    autoOn = this.autoOn.filter(item => item !== 'info')
                  }
                  if (isOn) {
                    autoOn = [...this.autoOn, 'info']
                  }
                  this.cloudbackupSettingDataPreferences.putSync('autoOn', autoOn)
                  this.cloudbackupSettingDataPreferences.flushSync()
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
                isOn: this.tag
              })
                .onChange((isOn: boolean) => {
                  let autoOn: string[] = []
                  if (!isOn) {
                    autoOn = this.autoOn.filter(item => item !== 'tag')
                  }
                  if (isOn) {
                    autoOn = [...this.autoOn, 'tag']
                  }
                  this.cloudbackupSettingDataPreferences.putSync('autoOn', autoOn)
                  this.cloudbackupSettingDataPreferences.flushSync()
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
    .onReady(() => {
      this.getSetting()
    })
  }
}