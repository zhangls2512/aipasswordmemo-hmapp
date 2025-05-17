import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { get } from '../common/Accesstoken'
import request from '../common/Request'

@Builder
export function VipcodeBuilder() {
  Vipcode()
}

@ComponentV2
struct Vipcode {
  @Local vipcode: string = ''
  context = getContext(this)
  pageInfos = new NavPathStack()
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '验证中...'
    })
  })

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            TextInput({
              placeholder: '请输入兑换码',
              text: $$this.vipcode
            })
              .maxLength(32)
            Button('兑换')
              .enabled(this.vipcode.length === 32 ? true : false)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })
              .onClick(async () => {
                this.dialogControllerProgress.open()
                const res = await request('/product/useVipcode', {
                  accessToken: get(),
                  vipcode: this.vipcode
                })
                this.dialogControllerProgress.close()
                if (res !== 'fail') {
                  promptAction.showToast({
                    message: '兑换成功'
                  })
                  this.pageInfos.pop()
                  this.context.eventHub.emit('refreshVip')
                }
              })
          }
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Column() {
            Text('如何获取兑换码？')
              .fontWeight(FontWeight.Bold)
            Text('· 提供有效反馈')
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_m')
              })
            Text('· 关注官方活动')
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_s')
              })
            Text('· 加入官方团队')
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_s')
              })
          }
          .alignItems(HorizontalAlign.Start)
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