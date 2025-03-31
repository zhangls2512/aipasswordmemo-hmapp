import { common } from '@kit.AbilityKit'
import { AppStorageV2 } from '@kit.ArkUI'
import { notificationManager } from '@kit.NotificationKit'
import { TitleBar } from './Me'

@Builder
export function NoticeBuilder() {
  Notice()
}

@ComponentV2
export struct Notice {
  @Local titlebar: TitleBar = AppStorageV2.connect(TitleBar, () => new TitleBar())!
  context = getContext(this) as common.UIAbilityContext

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Row() {
              Text('通知管理')
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
                .backgroundColor($r('sys.color.comp_background_list_card'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .width('100%')
            .onClick(() => {
              notificationManager.openNotificationSettings(this.context)
            })
          }
          .backgroundColor($r('sys.color.comp_background_list_card'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })
      }
      .padding({
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title('消息通知')
    .onWillAppear(() => {
      this.titlebar.hide = true
    })
    .onWillDisappear(() => {
      this.titlebar.hide = false
    })
  }
}