import { promptAction } from '@kit.ArkUI'
import { netQuality } from '@kit.NetworkBoostKit'

@Builder
export function ReportQoeBuilder() {
  ReportQoe()
}

@ComponentV2
struct ReportQoe {
  pageInfos: NavPathStack = new NavPathStack()
  serviceType: netQuality.ServiceType = 'default'
  qoeType: netQuality.QoeType = 'good'

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Column() {
              Row() {
                Text('业务类型')
                  .fontWeight('medium')
                Blank()
                Select([
                  { value: '默认' },
                  { value: '后台' },
                  { value: '下载' },
                  { value: '上传' }
                ])
                  .selected(0)
                  .value('默认')
                  .onSelect((index: number) => {
                    if (index === 0) {
                      this.serviceType = 'default'
                    }
                    if (index === 1) {
                      this.serviceType = 'background'
                    }
                    if (index === 2) {
                      this.serviceType = 'download'
                    }
                    if (index === 3) {
                      this.serviceType = 'upload'
                    }
                  })
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
                Text('体验类型')
                  .fontWeight('medium')
                Blank()
                Select([
                  { value: '良好' },
                  { value: '未知原因' },
                  { value: '服务器异常' },
                  { value: '无数据' },
                  { value: '丢包' },
                  { value: '乱序' },
                  { value: '高抖动' },
                  { value: '高时延' }
                ])
                  .selected(0)
                  .value('良好')
                  .onSelect((index: number) => {
                    if (index === 0) {
                      this.qoeType = 'good'
                    }
                    if (index === 1) {
                      this.qoeType = 'unknown'
                    }
                    if (index === 2) {
                      this.qoeType = 'serverErr'
                    }
                    if (index === 3) {
                      this.qoeType = 'noData'
                    }
                    if (index === 4) {
                      this.qoeType = 'packetLost'
                    }
                    if (index === 5) {
                      this.qoeType = 'packetOutOfOrder'
                    }
                    if (index === 6) {
                      this.qoeType = 'highJitter'
                    }
                    if (index === 7) {
                      this.qoeType = 'highLatency'
                    }
                  })
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))

            Button('反馈')
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })
              .onClick(() => {
                netQuality.reportQoe({
                  serviceType: this.serviceType,
                  qoeType: this.qoeType
                })
                promptAction.showToast({
                  message: '反馈成功'
                })
                this.pageInfos.pop()
              })
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
    .title('反馈网络传输体验')
    .onReady((context: NavDestinationContext) => {
      this.pageInfos = context.pathStack
    })
  }
}