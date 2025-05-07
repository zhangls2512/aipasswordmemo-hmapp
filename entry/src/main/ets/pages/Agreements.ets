import { privacyManager } from '@kit.AppGalleryKit'
import { promptAction } from '@kit.ArkUI'
import openLink from '../common/Openlink'

@Builder
export function AgreementsBuilder() {
  Agreements()
}

@ComponentV2
struct Agreements {
  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Row() {
              Text('用户服务条款与条件')
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
            .onClick(() => {
              try {
                const appPrivacyLink = privacyManager.getAppPrivacyMgmtInfo().privacyInfo.find(item => item.type === 2)
                openLink(appPrivacyLink?.url as string)
              } catch (err) {
                promptAction.showToast({
                  message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
                })
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
      }
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title('服务协议与规则')
  }
}