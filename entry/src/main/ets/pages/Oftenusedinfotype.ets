import { common } from '@kit.AbilityKit'
import { LengthMetrics, promptAction } from '@kit.ArkUI'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { getFlushPreference, setFlushPreference } from '../common/Preference'

@Builder
export function OftenusedinfotypeBuilder() {
  Oftenusedinfotype()
}

@ComponentV2
struct Oftenusedinfotype {
  @Local oftenUsedInfoTypeArray: string[] = []
  @Local type: string = ''
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  defaultInfoTypeArray =
    ['图标', '昵称', '用户名', '密码', 'MFA', '姓名', '手机号', '邮箱', '银行卡号', '身份证号', 'URL']

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
                if (this.type === '自定义') {
                  await promptAction.openToast({
                    message: '不支持添加此类型'
                  })
                  return
                }
                if (this.oftenUsedInfoTypeArray.some(item => item === this.type)) {
                  await promptAction.openToast({
                    message: '已添加此类型'
                  })
                  return
                }
                this.oftenUsedInfoTypeArray.push(this.type)
                this.type = ''
              })
          }
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ForEach(this.oftenUsedInfoTypeArray, (item: string, index) => {
          ListItem() {
            Column() {
              Row() {
                Text(item)
                  .enableAutoSpacing(true)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                if (index !== 0) {
                  Image($r('app.media.up'))
                    .height(24)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                    .onClick(() => {
                      const temp = this.oftenUsedInfoTypeArray[index]
                      this.oftenUsedInfoTypeArray[index] = this.oftenUsedInfoTypeArray[index - 1]
                      this.oftenUsedInfoTypeArray[index - 1] = temp
                    })
                }
                if (index !== this.oftenUsedInfoTypeArray.length - 1) {
                  Image($r('app.media.down'))
                    .height(24)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                    .onClick(() => {
                      const temp = this.oftenUsedInfoTypeArray[index]
                      this.oftenUsedInfoTypeArray[index] = this.oftenUsedInfoTypeArray[index + 1]
                      this.oftenUsedInfoTypeArray[index + 1] = temp
                    })
                }
                Image($r('app.media.delete'))
                  .height(24)
                  .onClick(() => {
                    this.oftenUsedInfoTypeArray.splice(index, 1)
                  })
              }
              .borderRadius(12)
              .padding(12)
              .width('100%')
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
        })
        ListItem() {
          Text('预置信息类型 (需要特殊处理、输入框类型适配或接入系统智能填充)')
            .fontWeight(FontWeight.Medium)
        }
        .margin({
          bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ForEach(this.defaultInfoTypeArray, (item: string) => {
          if (!this.oftenUsedInfoTypeArray.includes(item)) {
            ListItem() {
              Column() {
                Row() {
                  Text(item)
                    .layoutWeight(1)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                  Image($r('app.media.add'))
                    .height(24)
                    .onClick(async () => {
                      if (this.oftenUsedInfoTypeArray.some(typeItem => typeItem === item)) {
                        await promptAction.openToast({
                          message: '已添加此类型'
                        })
                        return
                      }
                      this.oftenUsedInfoTypeArray.push(item)
                    })
                }
                .borderRadius(12)
                .padding(12)
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
          mainTitle: '常用信息类型'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onAppear(() => {
      this.oftenUsedInfoTypeArray =
        getFlushPreference(this.context, 'commonSetting', 'oftenUsedInfoType', ['密码']) as string[]
    })
    .onDisAppear(() => {
      setFlushPreference(this.context, 'commonSetting', 'oftenUsedInfoType', this.oftenUsedInfoTypeArray)
    })
  }
}