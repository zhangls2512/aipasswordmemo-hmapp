import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { safetyDetect } from '@kit.DeviceSecurityKit'

@ComponentV2
export default struct Urlcheck {
  @Local url: string = ''
  @Local urlArray: Array<string> = []
  @Local resultArray: safetyDetect.UrlCheckResult[] = []

  build() {
    List() {
      ListItem() {
        TextInput({
          placeholder: '请输入 URL',
          text: $$this.url
        })
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_m')
      })

      ListItem() {
        Column() {
          Button('添加')
            .onClick(() => {
              if (this.urlArray.length >= 10) {
                promptAction.showToast({
                  message: '数量达到上限'
                })
                return
              }
              if (!this.url) {
                promptAction.showToast({
                  message: '请输入 URL'
                })
                return
              }
              if (this.urlArray.includes(this.url)) {
                promptAction.showToast({
                  message: '已添加此 URL'
                })
                return
              }
              this.urlArray.push(this.url)
              this.url = ''
            })
        }
        .width('100%')
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_m')
      })

      ForEach(this.urlArray, (item: string, index) => {
        ListItem() {
          Column() {
            Row() {
              Text(item)
                .width('75%')
              Blank()
                .width('5%')
              Button('删除')
                .role(ButtonRole.ERROR)
                .width('20%')
                .onClick(() => {
                  this.urlArray.splice(index, 1)
                })
            }
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
            .padding($r('sys.float.ohos_id_corner_radius_default_m'))
            .width('100%')
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
      })
      ListItem() {
        Column() {
          Button('检测')
            .onClick(async () => {
              if (this.urlArray.length === 0) {
                promptAction.showToast({
                  message: '请添加 URL'
                })
                return
              }
              const dialogControllerProgress = new CustomDialogController({
                builder: LoadingDialog({
                  content: '检测中...'
                })
              })
              dialogControllerProgress.open()
              try {
                const res = await safetyDetect.checkUrlThreat({
                  urls: [...this.urlArray]
                })
                dialogControllerProgress.close()
                this.resultArray = res.results
              } catch (err) {
                dialogControllerProgress.close()
                promptAction.showToast({
                  message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
                })
              }
            })
        }
        .width('100%')
      }
      .margin({
        bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      ForEach(this.resultArray, (item: safetyDetect.UrlCheckResult) => {
        ListItem() {
          Column() {
            Row() {
              Text(item.url)
                .width('80%')
              Blank()
                .width('5%')
              if (item.threat === safetyDetect.UrlThreatType.NORMAL) {
                Text('安全')
                  .fontColor(Color.Green)
                  .textAlign(TextAlign.End)
                  .width('15%')
              }
              if (item.threat === safetyDetect.UrlThreatType.MALWARE) {
                Text('恶意')
                  .fontColor(Color.Red)
                  .textAlign(TextAlign.End)
                  .width('15%')
              }
              if (item.threat === safetyDetect.UrlThreatType.PHISHING) {
                Text('钓鱼')
                  .fontColor(Color.Orange)
                  .textAlign(TextAlign.End)
                  .width('15%')
              }
              if (item.threat === safetyDetect.UrlThreatType.OTHERS) {
                Text('其他')
                  .fontColor(Color.Gray)
                  .textAlign(TextAlign.End)
                  .width('15%')
              }
            }
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
            .padding($r('sys.float.ohos_id_corner_radius_default_m'))
            .width('100%')
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
      })
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_max_padding_start'),
      right: $r('sys.float.ohos_id_max_padding_end')
    })
  }
}