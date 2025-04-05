import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'

@Builder
export function PermissionsettingBuilder() {
  Permissionsetting()
}

@ComponentV2
export struct Permissionsetting {
  context = getContext(this) as common.UIAbilityContext
  @Local writePasteBoard: boolean = false
  permissionSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'permissionSetting'
  })

  getSetting() {
    const writePasteBoard: preferences.ValueType =
      this.permissionSettingDataPreferences.getSync('writePasteBoard', false)
    this.writePasteBoard = writePasteBoard as boolean
  }

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Column() {
              Row() {
                Text('写入剪贴板')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: $$this.writePasteBoard
                })
                  .onChange((isOn: boolean) => {
                    this.permissionSettingDataPreferences.putSync('writePasteBoard', isOn)
                    this.permissionSettingDataPreferences.flushSync()
                  })
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))

            Text($r('app.string.WRITE_PASTEBOARD_reason'))
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                top: 6,
                left: $r('sys.float.ohos_id_corner_radius_default_m')
              })
          }
          .alignItems(HorizontalAlign.Start)
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
    .title('权限管理')
    .onReady(() => {
      this.getSetting()
    })
  }
}