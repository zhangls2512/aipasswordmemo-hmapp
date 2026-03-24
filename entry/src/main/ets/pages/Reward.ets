import { common } from '@kit.AbilityKit'
import { LengthMetrics } from '@kit.ArkUI'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import openLink from '../common/Openlink'

@Builder
export function RewardBuilder() {
  Reward()
}

@ComponentV2
struct Reward {
  context = this.getUIContext().getHostContext() as common.UIAbilityContext

  build() {
    HdsNavDestination() {
      List() {
        ListItem()
          .margin({
            top: 64
          })
        ListItem() {
          Column() {
            Text('《App Linking解锁酷炫链接新玩法》优秀参与奖')
              .enableAutoSpacing(true)
              .fontColor($r('sys.color.font_emphasize'))
              .onClick(async () => {
                await openLink(this.context, 'https://developer.huawei.com/consumer/cn/blog/topic/03194438986554058')
              })
            Text('《HarmonyOS Codelabs校园挑战汇（第三期）》成长奖')
              .enableAutoSpacing(true)
              .fontColor($r('sys.color.font_emphasize'))
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .onClick(async () => {
                await openLink(this.context, 'https://developer.huawei.com/consumer/cn/forum/topic/0203198763060850022')
              })
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem()
          .margin({
            bottom: 28
          })
      }
      .padding({
        left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
        right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .recoverable(true)
    .titleBar({
      padding: {
        end: LengthMetrics.vp(60)
      },
      style: {
        scrollEffectOpts: {
          scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR
        },
        originalStyle: {
          contentStyle: {
            titleStyle: {
              mainTitleColor: $r('sys.color.font_primary')
            },
            backIconStyle: {
              backgroundColor: $r('sys.color.comp_background_color_floating_smooth'),
              iconColor: $r('sys.color.icon_primary')
            }
          }
        },
        scrollEffectStyle: {
          contentStyle: {
            backIconStyle: {
              backgroundColor: $r('sys.color.comp_background_color_floating_smooth'),
              iconColor: $r('sys.color.icon_primary')
            }
          }
        },
        thermoCtrl: true,
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.ADAPTIVE,
          materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
        }
      },
      content: {
        title: {
          mainTitle: '获得奖项'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
  }
}