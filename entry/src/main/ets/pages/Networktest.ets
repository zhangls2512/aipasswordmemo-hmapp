import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { rcp } from '@kit.RemoteCommunicationKit'

interface Response {
  errCode: number,
  errMsg: string,
  requestIp: string,
  timeStamp: number
}

@Builder
export function NetworktestBuilder() {
  Networktest()
}

@ComponentV2
struct Networktest {
  @Local errCode: number = 0
  @Local errMsg: string = ''
  @Local requestIp: string = ''
  @Local timeStamp: number = 0
  @Local httpVersion: string = ''
  @Local nameLookupTimeMs: number = 0
  @Local connectTimeMs: number = 0
  @Local tlsHandshakeTimeMs: number = 0
  @Local preTransferTimeMs: number = 0
  @Local startTransferTimeMs: number = 0
  @Local totalTimeMs: number = 0
  @Local redirectTimeMs: number = 0

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Button('测试')
              .onClick(async () => {
                const dialogControllerProgress = new CustomDialogController({
                  builder: LoadingDialog({
                    content: '测试中...'
                  })
                })
                dialogControllerProgress.open()
                const session = rcp.createSession()
                try {
                  const response = await session.get('https://api.zhangls2512.cn/test')
                  session.close()
                  dialogControllerProgress.close()
                  if (response.statusCode === 200) {
                    let body = ''
                    if (response.toString()) {
                      body = response.toString() as string
                    }
                    const res = JSON.parse(body) as Response
                    this.errCode = res.errCode
                    this.errMsg = res.errMsg
                    this.requestIp = res.requestIp
                    this.timeStamp = res.timeStamp
                    this.httpVersion = String(response.httpVersion)
                    this.nameLookupTimeMs = Number(response.timeInfo?.nameLookupTimeMs)
                    this.connectTimeMs = Number(response.timeInfo?.connectTimeMs)
                    this.tlsHandshakeTimeMs = Number(response.timeInfo?.tlsHandshakeTimeMs)
                    this.preTransferTimeMs = Number(response.timeInfo?.preTransferTimeMs)
                    this.startTransferTimeMs = Number(response.timeInfo?.startTransferTimeMs)
                    this.totalTimeMs = Number(response.timeInfo?.totalTimeMs)
                    this.redirectTimeMs = Number(response.timeInfo?.redirectTimeMs)
                    promptAction.showToast({
                      message: '测试完成'
                    })
                  } else {
                    promptAction.showToast({
                      message: '请求失败，错误码：' + response.statusCode + '，错误信息：' + response.reasonPhrase
                    })
                  }
                } catch (err) {
                  session.close()
                  dialogControllerProgress.close()
                  promptAction.showToast({
                    message: '发生错误，错误码：' + err.code
                  })
                }
              })
            Column() {
              Row() {
                Text('错误码')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(this.errCode))
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('错误信息')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(this.errMsg)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('请求 IP')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(this.requestIp)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('请求时间戳')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(this.timeStamp))
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('HTTP 版本')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(this.httpVersion)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('DNS 解析所需的时间')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(this.httpVersion) + ' ms')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('建立连接时间')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(this.connectTimeMs) + ' ms')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('从开始到远程主机 (或代理) 的 TLS 握手完成的时间')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(this.tlsHandshakeTimeMs) + ' ms')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('传输开始前的时间')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(this.preTransferTimeMs) + ' ms')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('传输开始时间')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(this.startTransferTimeMs) + ' ms')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('请求总耗时')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(this.totalTimeMs) + ' ms')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('重定向所需的时间')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(this.redirectTimeMs) + ' ms')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_l')
            })
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
      }
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title('网络测试')
  }
}