import { promptAction } from '@kit.ArkUI'
import { get } from '../common/Accesstoken'
import { httpRequest } from '../common/Request'

@Builder
export function VipcodeBuilder() {
  Vipcode()
}

@ComponentV2
export struct Vipcode {
  @Local loading: boolean = false
  @Local vipcode: string = ''
  pageInfos: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            if (this.loading) {
              LoadingProgress()
                .width('50%')
            }
            if (!this.loading) {
              TextInput({
                placeholder: '请输入兑换码',
                text: $$this.vipcode
              })
                .maxLength(40)
                .showCounter(true)
              Button('提交')
                .enabled(this.vipcode ? true : false)
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
                .onClick(async () => {
                  this.loading = true
                  const res = await httpRequest('/product/useVipcode', {
                    accessToken: get(),
                    vipcode: this.vipcode
                  })
                  this.loading = false
                  if (res !== 'fail') {
                    promptAction.showToast({
                      message: '兑换成功'
                    })
                    this.pageInfos.pop()
                  }
                })
            }
          }
          .width('100%')
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
    .title('兑换会员')
    .onReady((context: NavDestinationContext) => {
      this.pageInfos = context.pathStack
    })
  }
}