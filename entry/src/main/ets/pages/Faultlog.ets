import { FaultLogger } from '@kit.PerformanceAnalysisKit'

@Builder
export function FaultlogBuilder() {
  Faultlog()
}

@ComponentV2
struct Faultlog {
  @Local faultLogArray: FaultLogger.FaultLogInfo[] = []

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Select([
            { value: '全部' },
            { value: 'C++ 程序' },
            { value: 'JS 程序' },
            { value: '应用程序卡死' }
          ])
            .margin({
              bottom: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
            .selected(0)
            .value('全部')
            .onSelect(async (index: number) => {
              if (index === 0) {
                this.faultLogArray = await FaultLogger.query(FaultLogger.FaultType.NO_SPECIFIC)
              }
              if (index === 1) {
                this.faultLogArray = await FaultLogger.query(FaultLogger.FaultType.CPP_CRASH)
              }
              if (index === 2) {
                this.faultLogArray = await FaultLogger.query(FaultLogger.FaultType.JS_CRASH)
              }
              if (index === 3) {
                this.faultLogArray = await FaultLogger.query(FaultLogger.FaultType.APP_FREEZE)
              }
            })
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ForEach(this.faultLogArray, (item: FaultLogger.FaultLogInfo) => {
          ListItem() {
            Column() {
              Row() {
                Text('进程 ID')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(item.pid))
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
                Text('用户 ID')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(item.uid))
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
                Text('类型')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.type === 0 ? '不区分' :
                  item.type === 2 ? 'C++ 程序' :
                    item.type === 3 ? 'JS 程序' :
                      item.type === 4 ? '应用程序卡死' :
                        'unknown'
                )
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
                Text('日志生成时的毫秒级时间戳')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(item.timestamp))
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
                Text('原因')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.reason)
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
                Text('模块')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.module)
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
                Text('概要')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.summary)
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
                Text('日志全文')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.fullLog)
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
    .backgroundColor($r('app.color.sheet_background'))
    .title('故障日志')
    .onReady(async () => {
      this.faultLogArray = await FaultLogger.query(FaultLogger.FaultType.NO_SPECIFIC)
    })
  }
}