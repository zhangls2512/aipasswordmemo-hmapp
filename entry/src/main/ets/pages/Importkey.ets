import { common } from '@kit.AbilityKit'
import { promptAction, window } from '@kit.ArkUI'
import { setCustomKey } from '../common/Crypto'

@Builder
export function ImportkeyBuilder() {
  Importkey()
}

@ComponentV2
struct Importkey {
  @Local keycontent: string = ''
  @Local iv: string = ''
  context = getContext(this) as common.UIAbilityContext
  pageInfos: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            TextInput({
              placeholder: '请输入密钥',
              text: $$this.keycontent
            })
              .maxLength(44)
            TextInput({
              placeholder: '请输入初始向量',
              text: $$this.iv
            })
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .maxLength(24)
            Button('导入')
              .enabled(this.keycontent.length === 44 && this.iv.length === 24 ? true : false)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })
              .onClick(async () => {
                const res = await setCustomKey({
                  key: this.keycontent,
                  iv: this.iv
                })
                if (res !== 'fail') {
                  promptAction.showToast({
                    message: '导入成功'
                  })
                  this.pageInfos.pop()
                } else {
                  promptAction.showToast({
                    message: '导入失败'
                  })
                }
              })
          }
          .width('100%')
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('格式要求')
              .fontWeight('bold')
            Text('· 密钥：Base64 编码的 AES256 密钥（长度 44）')
              .fontWeight('medium')
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_m')
              })
            Text('· 初始向量：Base64 编码的初始向量（长度 24）')
              .fontWeight('medium')
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
    .title('导入自定义密钥')
    .onReady((context: NavDestinationContext) => {
      this.pageInfos = context.pathStack
    })
    .onShown(async () => {
      const lastWindow = await window.getLastWindow(this.context)
      await lastWindow.setWindowPrivacyMode(true)
    })
    .onHidden(async () => {
      const lastWindow = await window.getLastWindow(this.context)
      await lastWindow.setWindowPrivacyMode(false)
    })
  }
}