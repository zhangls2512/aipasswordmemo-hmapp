import { promptAction } from '@kit.ArkUI'
import { fileIo } from '@kit.CoreFileKit'

@Builder
export function DeletefileBuilder() {
  Deletefile()
}

@ComponentV2
struct Deletefile {
  @Local fileUri: string = ''

  build() {
    NavDestination() {
      List() {
        ListItem() {
          TextInput({
            placeholder: '请输入文件 URI',
            text: $$this.fileUri
          })
            .defaultFocus(true)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Column() {
            Button('删除')
              .enabled(this.fileUri !== '')
              .role(ButtonRole.ERROR)
              .onClick(() => {
                try {
                  fileIo.unlinkSync(this.fileUri.replace('file://com.zhangxm.aipasswordmemo', ''))
                  promptAction.showToast({
                    message: '删除成功'
                  })
                  this.fileUri = ''
                } catch (err) {
                  promptAction.showToast({
                    message: '发生错误，错误码：' + err.code
                  })
                }
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
    .title('沙箱文件删除工具')
  }
}