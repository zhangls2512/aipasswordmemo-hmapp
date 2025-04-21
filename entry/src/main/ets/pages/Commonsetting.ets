import { common, ConfigurationConstant } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'

@Builder
export function CommonsettingBuilder() {
  Commonsetting()
}

@ComponentV2
struct Commonsetting {
  @Local colorModeIndex: number = 0
  @Local colorModeValue: string = '跟随系统'
  @Local checkVersionUpdateIndex: number = 1
  @Local checkVersionUpdateValue: string = '仅 WLAN 下'
  @Local openLinkTypeIndex: number = 0
  @Local openLinkTypeValue: string = '系统默认'
  context = getContext(this) as common.UIAbilityContext
  commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'commonSetting'
  })

  getSetting() {
    const colorMode: preferences.ValueType =
      this.commonSettingDataPreferences.getSync('colorMode', 0)
    this.colorModeIndex = colorMode as number
    if (colorMode === 0) {
      this.colorModeValue = '跟随系统'
    }
    if (colorMode === 1) {
      this.colorModeValue = '浅色模式'
    }
    if (colorMode === 2) {
      this.colorModeValue = '深色模式'
    }
    const checkVersionUpdate: preferences.ValueType =
      this.commonSettingDataPreferences.getSync('checkVersionUpdate', 1)
    this.checkVersionUpdateIndex = checkVersionUpdate as number
    if (checkVersionUpdate === 0) {
      this.checkVersionUpdateValue = '从不'
    }
    if (checkVersionUpdate === 1) {
      this.checkVersionUpdateValue = '仅 WLAN 下'
    }
    if (checkVersionUpdate === 2) {
      this.checkVersionUpdateValue = '始终'
    }
    const openLinkType: preferences.ValueType =
      this.commonSettingDataPreferences.getSync('openLinkType', 0)
    this.openLinkTypeIndex = openLinkType as number
    if (openLinkType === 0) {
      this.openLinkTypeValue = '系统默认'
    }
    if (openLinkType === 1) {
      this.openLinkTypeValue = '自行选择'
    }
  }

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Row() {
              Text('深色模式')
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontWeight('medium')
              Blank()
              Select([
                { value: '跟随系统' },
                { value: '浅色模式' },
                { value: '深色模式' }
              ])
                .selected($$this.colorModeIndex)
                .value($$this.colorModeValue)
                .onSelect((index: number) => {
                  const applicationContext = this.context.getApplicationContext()
                  if (index === 0) {
                    applicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
                  }
                  if (index === 1) {
                    applicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT)
                  }
                  if (index === 2) {
                    applicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK)
                  }
                  this.commonSettingDataPreferences.putSync('colorMode', index)
                  this.commonSettingDataPreferences.flushSync()
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
              Text('启动时检测新版本')
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontWeight('medium')
              Blank()
              Select([
                { value: '从不' },
                { value: '仅 WLAN 下' },
                { value: '始终' }
              ])
                .selected($$this.checkVersionUpdateIndex)
                .value($$this.checkVersionUpdateValue)
                .onSelect((index: number) => {
                  this.commonSettingDataPreferences.putSync('checkVersionUpdate', index)
                  this.commonSettingDataPreferences.flushSync()
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
              Text('使用')
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontWeight('medium')
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Select([
                { value: '系统默认' },
                { value: '自行选择' }
              ])
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .selected($$this.openLinkTypeIndex)
                .value($$this.openLinkTypeValue)
                .onSelect((index: number) => {
                  this.commonSettingDataPreferences.putSync('openLinkType', index)
                  this.commonSettingDataPreferences.flushSync()
                })
              Text('浏览器打开链接')
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontWeight('medium')
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
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
      }
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title('通用')
    .onReady(() => {
      this.getSetting()
    })
  }
}