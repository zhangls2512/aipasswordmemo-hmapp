import { common } from '@kit.AbilityKit'
import openLink from '../common/Openlink'

@Builder
export function RewardBuilder() {
  Reward()
}

@ComponentV2
struct Reward {
  context = this.getUIContext().getHostContext() as common.UIAbilityContext

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Text('《App Linking解锁酷炫链接新玩法》优秀参与奖')
            .enableAutoSpacing(true)
            .fontColor($r('sys.color.font_emphasize'))
            .onClick(async () => {
              await openLink(this.context, 'https://developer.huawei.com/consumer/cn/blog/topic/03194438986554058')
            })
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Text('《HarmonyOS Codelabs校园挑战汇（第三期）》成长奖')
            .enableAutoSpacing(true)
            .fontColor($r('sys.color.font_emphasize'))
            .onClick(async () => {
              await openLink(this.context, 'https://developer.huawei.com/consumer/cn/forum/topic/0203198763060850022')
            })
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
    .title('获得奖项')
  }
}