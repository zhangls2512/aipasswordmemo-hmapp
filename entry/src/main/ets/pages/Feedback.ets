import { LoadingDialog, promptAction } from '@kit.ArkUI'
import request from '../common/Request'

@Builder
export function FeedbackBuilder() {
  Feedback()
}

@ComponentV2
export struct Feedback {
  @Local content: string = ''
  pageInfos: NavPathStack = new NavPathStack()
  dialogControllerProgress: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: '提交中...'
    })
  })

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            TextArea({
              placeholder: '请输入内容',
              text: $$this.content
            })
              .maxLength(500)
              .showCounter(true)
            Button('提交')
              .enabled(this.content ? true : false)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })
              .onClick(async () => {
                this.dialogControllerProgress.open()
                const res = await request('/debug/sendFeedbackEmail', {
                  key: 'RaGvhiCmYP8aPZ-QmmDgBQvwkfkp9TXEVCWEn8fPjshs9GyUCooG_kq7N8bHBRcT',
                  product: '密码智能备忘录',
                  content: this.content
                })
                this.dialogControllerProgress.close()
                if (res !== 'fail') {
                  promptAction.showToast({
                    message: '提交成功'
                  })
                  this.pageInfos.pop()
                }
              })
          }
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