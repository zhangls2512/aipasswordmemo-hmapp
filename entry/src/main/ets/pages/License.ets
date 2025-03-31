import { common } from '@kit.AbilityKit'

@Builder
export function LicenseBuilder() {
  License()
}

@ComponentV2
export struct License {
  context = getContext(this) as common.UIAbilityContext

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Row() {
              Text('ICP备案')
                .width('20%')
              Blank()
                .width('5%')
              Text('黑ICP备2024023054号-9A')
                .fontColor($r('sys.color.font_emphasize'))
                .width('75%')
                .onClick(() => {
                  this.context.openLink('https://beian.miit.gov.cn/#/Integrated/recordQuery', {
                    parameters: {
                      'ohos.ability.params.showDefaultPicker': true
                    }
                  })
                })
            }

            Row() {
              Text('产品备案')
                .width('20%')
              Blank()
                .width('5%')
              Text('轩铭2512品备12号-HA')
                .fontColor($r('sys.color.font_emphasize'))
                .width('75%')
                .onClick(() => {
                  this.context.openLink('https://www.zhangls2512.cn/product/baxk/jqcx?baxknumber=轩铭2512品备12号-HA', {
                    parameters: {
                      'ohos.ability.params.showDefaultPicker': true
                    }
                  })
                })
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
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
    .title('资质证照')
  }
}