import { promptAction } from '@kit.ArkUI'
import { httpRequest } from '../common/Request'

@Builder
export function FeedbackBuilder() {
  Feedback()
}

@ComponentV2
export struct Feedback {
  @Local loading: boolean = false
  @Local content: string = ''
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
              TextArea({
                placeholder: '请输入内容',
                text: $$this.content
              })
                .maxLength(500)
                .showCounter(true)
              Button('提交')
                .enabled(this.content ? true : false)
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
                .onClick(async () => {
                  this.loading = true
                  const res = await httpRequest('/debug/sendFeedbackEmail', {
                    key: 'RaGvhiCmYP8aPZ-QmmDgBQvwkfkp9TXEVCWEn8fPjshs9GyUCooG_kq7N8bHBRcT',
                    content: this.content
                  })
                  if (res !== 'fail') {
                    promptAction.showToast({
                      message: '提交成功'
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
    .title('意见反馈')
    .onReady((context: NavDestinationContext) => {
      this.pageInfos = context.pathStack
    })
  }
}