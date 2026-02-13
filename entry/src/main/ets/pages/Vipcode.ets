import { common } from '@kit.AbilityKit'
import { LengthMetrics, LoadingDialog, promptAction } from '@kit.ArkUI'
import { hdsMaterial, HdsNavDestination } from '@kit.UIDesignKit'
import { getAccountAccessToken } from '../common/Accesstoken'
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
    HdsNavDestination() {
      List() {
        ListItem() {
          Column() {
            TextArea({
              placeholder: '请输入兑换码',
              text: this.vipCode!!
            })
              .defaultFocus(true)
              .enableAutoSpacing(true)
              .maxLength(32)
              .showCounter(true)
            Button('兑换')
              .enabled(this.vipCode.length === 32 ? true : false)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .width('100%')
              .onClick(async () => {
                const accessToken = await getAccountAccessToken()
                if (accessToken) {
                  const dialogControllerProgress = new CustomDialogController({
                    builder: LoadingDialog({
                      content: '验证中...'
                    })
                  })
                  dialogControllerProgress.open()
                  const res = await request(this.context, '/product/useVipcode', {
                    accessToken: accessToken,
                    vipcode: this.vipCode
                  })
                  dialogControllerProgress.close()
                  if (res !== 'fail') {
                    await promptAction.openToast({
                      message: '兑换成功'
                    })
                    this.pageInfos.pop()
                    this.context.eventHub.emit('refreshVip')
                  }
                }
              })
            Text('如何获取兑换码？')
              .fontWeight(FontWeight.Bold)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })
            Text('· 应用市场评论')
              .fontColor($r('sys.color.font_emphasize'))
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_m')
              })
              .onClick(async () => {
                await this.context.openLink('https://appgallery.huawei.com/app/detail?id=com.zhangxm.aipasswordmemo&action=write-review')
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
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
      }
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
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
        thermoCtrl: true,
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.ADAPTIVE,
          materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
        }
      },
      content: {
        title: {
          mainTitle: '兑换会员'
        }
      },
      enableComponentSafeArea: true
    })
    .onReady((context) => {
      this.pageInfos = context.pathStack
    })
  }
}