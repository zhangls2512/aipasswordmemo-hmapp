import { common } from '@kit.AbilityKit'
import { LengthMetrics, promptAction } from '@kit.ArkUI'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { getFlushPreference, setFlushPreference } from '../common/Preference'

@Builder
export function StorevaluehistorypasswordinfotypeBuilder() {
  Storevaluehistorypasswordinfotype()
}

@ComponentV2
struct Storevaluehistorypasswordinfotype {
  @Local storeValueHistoryPasswordInfoTypeArray: string[] = []
  @Local type: string = ''
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
            TextInput({
              placeholder: '请输入内容',
              text: this.type!!
            })
              .defaultFocus(this.storeValueHistoryPasswordInfoTypeArray.length === 0 ? true : false)
              .enableAutoSpacing(true)
            Button('添加')
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .width('100%')
              .onClick(async () => {
                if (!this.type) {
                  await promptAction.openToast({
                    message: '请输入内容'
                  })
                  return
                }
                if (this.type === '图标' || this.type === 'MFA') {
                  await promptAction.openToast({
                    message: '不支持添加此类型'
                  })
                  return
                }
                if (this.storeValueHistoryPasswordInfoTypeArray.some(item => item === this.type)) {
                  await promptAction.openToast({
                    message: '已添加此类型'
                  })
                  return
                }
                this.storeValueHistoryPasswordInfoTypeArray.push(this.type)
                this.type = ''
              })
          }
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ForEach(this.storeValueHistoryPasswordInfoTypeArray, (item: string, index) => {
          ListItem() {
            Column() {
              Row() {
                Text(item)
                  .enableAutoSpacing(true)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Image($r('app.media.delete'))
                  .height(24)
                  .onClick(() => {
                    this.storeValueHistoryPasswordInfoTypeArray.splice(index, 1)
                  })
              }
              .borderRadius(12)
              .padding(12)
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
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
          mainTitle: '记录内容历史记录密码信息类型'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onAppear(() => {
      this.storeValueHistoryPasswordInfoTypeArray =
        getFlushPreference(this.context, 'commonSetting', 'storeValueHistoryPasswordInfoType', ['密码']) as string[]
    })
    .onDisAppear(() => {
      setFlushPreference(this.context, 'commonSetting', 'storeValueHistoryPasswordInfoType',
        this.storeValueHistoryPasswordInfoTypeArray)
    })
  }
}