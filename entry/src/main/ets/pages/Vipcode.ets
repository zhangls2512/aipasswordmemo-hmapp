import { common } from '@kit.AbilityKit'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
//import { HdsNavDestination } from '@kit.UIDesignKit'
import { get } from '../common/Accesstoken'
import request from '../common/Request'

@Builder
export function VipcodeBuilder() {
  Vipcode()
}

@ComponentV2
struct Vipcode {
  @Local vipCode: string = ''
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            TextArea({
              placeholder: '请输入兑换码',
              text: this.vipCode!!
            })
              .enableAutoSpacing(true)
              .maxLength(32)
              .showCounter(true)
            Button('兑换')
              .enabled(this.vipCode.length === 32 ? true : false)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })
              .onClick(async () => {
                const accessToken = await get()
                if (accessToken) {
                  const dialogControllerProgress = new CustomDialogController({
                    builder: LoadingDialog({
                      content: '验证中...'
                    })
                  })
                  dialogControllerProgress.open()
                  const res = await request('/product/useVipcode', {
                    accessToken: accessToken,
                    vipcode: this.vipCode
                  })
                  dialogControllerProgress.close()
                  if (res !== 'fail') {
                    promptAction.openToast({
                      message: '兑换成功'
                    })
                    this.pageInfos.pop()
                    this.context.eventHub.emit('refreshVip')
                  }
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
            Text('· 应用市场评论')
              .fontColor($r('sys.color.font_emphasize'))
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_m')
              })
              .onClick(() => {
                this.context.openLink('https://appgallery.huawei.com/app/detail?id=com.zhangxm.aipasswordmemo&action=write-review')
              })
            Text('· 提供有效反馈')
              .fontColor($r('sys.color.font_emphasize'))
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_s')
              })
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'Feedback'
                })
              })
            Text('· 关注官方活动')
              .fontColor($r('sys.color.font_emphasize'))
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_s')
              })
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'About'
                })
              })
            Text('· 加入官方团队')
              .fontColor($r('sys.color.font_emphasize'))
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_s')
              })
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'About'
                })
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
    /*.titleBar({
      content: {
        title: {
          mainTitle: ''
        }
      }
    })*/
    .title('兑换会员')
    .onReady((context) => {
      this.pageInfos = context.pathStack
    })
  }
}