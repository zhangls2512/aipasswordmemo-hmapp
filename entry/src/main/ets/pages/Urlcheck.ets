import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { safetyDetect } from '@kit.DeviceSecurityKit'

@ComponentV2
export default struct Urlcheck {
  @Local url: string = ''
  @Local urlArray: string[] = []
  @Local resultArray: safetyDetect.UrlCheckResult[] = []

  build() {
    List() {
      ListItem() {
        TextInput({
          placeholder: '请输入URL',
          text: this.url!!
        })
          .defaultFocus(true)
          .enableAutoSpacing(true)
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_m')
      })

      ListItem() {
        Button('添加')
          .width('100%')
          .onClick(async () => {
            if (this.urlArray.length >= 10) {
              await promptAction.openToast({
                message: '数量达到上限'
              })
              return
            }
            if (!this.url) {
              await promptAction.openToast({
                message: '请输入 URL'
              })
              return
            }
            if (this.urlArray.includes(this.url)) {
              await promptAction.openToast({
                message: '已添加此 URL'
              })
              return
            }
            this.urlArray.push(this.url)
            this.url = ''
          })
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_m')
      })

      ForEach(this.urlArray, (item: string, index) => {
        ListItem() {
          Column() {
            Row() {
              Text(item)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Image($r('app.media.delete'))
                .height(24)
                .onClick(() => {
                  this.urlArray.splice(index, 1)
                })
            }
            .borderRadius(12)
            .padding(12)
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
        Button('检测')
          .width('100%')
          .onClick(async () => {
            if (this.urlArray.length === 0) {
              await promptAction.openToast({
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
              await promptAction.openToast({
                message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
              })
            }
          })
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
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              if (item.threat === safetyDetect.UrlThreatType.NORMAL) {
                Text('安全')
                  .fontColor(Color.Green)
                  .textAlign(TextAlign.End)
              }
              if (item.threat === safetyDetect.UrlThreatType.MALWARE) {
                Text('恶意')
                  .fontColor(Color.Red)
                  .textAlign(TextAlign.End)
              }
              if (item.threat === safetyDetect.UrlThreatType.PHISHING) {
                Text('钓鱼')
                  .fontColor(Color.Orange)
                  .textAlign(TextAlign.End)
              }
              if (item.threat === safetyDetect.UrlThreatType.OTHERS) {
                Text('其他')
                  .fontColor(Color.Grey)
                  .textAlign(TextAlign.End)
              }
            }
            .borderRadius(12)
            .padding(12)
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
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
    })
  }
}