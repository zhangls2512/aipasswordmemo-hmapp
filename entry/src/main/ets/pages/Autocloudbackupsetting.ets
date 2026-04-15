import { common } from '@kit.AbilityKit'
import { LengthMetrics } from '@kit.ArkUI'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { getFlushPreference, setFlushPreference } from '../common/Preference'

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
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  autoOn: string[] = []
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

  build() {
    HdsNavDestination() {
      List() {
        ListItem()
          .margin({
            top: 64
          })
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
                    setFlushPreference(this.context, 'cloudbackupSetting', 'autoOn', this.autoOn)
                  })
              }
              .borderRadius(12)
              .padding(12)
            })
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
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
          mainTitle: '云备份自动开启设置'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onAppear(() => {
      this.autoOn = getFlushPreference(this.context, 'cloudbackupSetting', 'autoOn', []) as string[]
    })
  }
}