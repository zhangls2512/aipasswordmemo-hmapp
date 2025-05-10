import { common } from '@kit.AbilityKit'
import { window } from '@kit.ArkUI'
import { setCustomKey } from '../common/Crypto'

@Builder
export function ImportkeyBuilder() {
  Importkey()
}

@ComponentV2
struct Importkey {
  @Local keyValue: string = ''
  context = getContext(this) as common.UIAbilityContext
  pageInfos: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            TextArea({
              placeholder: '请输入 Base64 编码、长度 44 的 AES256 密钥',
              text: $$this.keyValue
            })
              .maxLength(44)
              .showCounter(true)
            Button('导入')
              .enabled(this.keyValue.length === 44 ? true : false)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })
              .onClick(async () => {
                await setCustomKey(this.keyValue)
                this.pageInfos.pop()
                this.context.eventHub.emit('refreshKey')
              })
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