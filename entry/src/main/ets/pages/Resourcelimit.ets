import { promptAction } from '@kit.ArkUI'
import { hidebug } from '@kit.PerformanceAnalysisKit'

//import { HdsNavDestination } from '@kit.UIDesignKit'

@Builder
export function ResourcelimitBuilder() {
  Resourcelimit()
}

@ComponentV2
struct Resourcelimit {
  pageInfos = new NavPathStack()
  @Local valueText: string = ''
  @Local enableDebugLog: boolean = false
  type: string = 'pss_memory'
  value: number = 0

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Column() {
              Row() {
                Text('类型')
                  .fontWeight(FontWeight.Medium)
                Blank()
                Select([
                  { value: 'native 内存' },
                  { value: 'js 堆内存' },
                  { value: '文件描述符' },
                  { value: '线程' }
                ])
                  .selected(0)
                  .value('native 内存')
                  .onSelect((index) => {
                    if (index === 0) {
                      this.type = 'pss_memory'
                    }
                    if (index === 1) {
                      this.type = 'js_heap'
                    }
                    if (index === 2) {
                      this.type = 'fd'
                    }
                    if (index === 3) {
                      this.type = 'thread'
                    }
                  })
              }
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('最大值')
                  .fontWeight('medium')
                Blank()
                TextInput({
                  text: this.valueText!!
                })
                  .enableAutoSpacing(true)
                  .maxLength(7)
                  .type(InputType.Number)
                  .width('50%')
                  .onSubmit((enterKey, event) => {
                    this.value = Number(event.text)
                  })
              }
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('外部调试日志')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.enableDebugLog!!
                })
              }
              .borderRadius(12)
              .padding(12)
              .width('100%')
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))

            Button('保存')
              .enabled(this.valueText !== '')
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })
              .onClick(() => {
                try {
                  hidebug.setAppResourceLimit(this.type, this.value, this.enableDebugLog)
                  promptAction.openToast({
                    message: '保存成功'
                  })
                  this.pageInfos.pop()
                } catch (err) {
                  promptAction.openToast({
                    message: '发生错误，错误码：' + err.code
                  })
                }
              })
          }
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Column() {
            Text('提示：')
              .fontWeight(FontWeight.Bold)
            Text('1. 当设置的开发者选项开关打开并重启设备后，此功能有效。')
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_m')
              })
            Text('2. native内存范围：[1024,4194304]。')
              .enableAutoSpacing(true)
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_s')
              })
            Text('3. js堆内存范围：[85,95]。')
              .enableAutoSpacing(true)
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_s')
              })
            Text('4. 文件描述符范围：[10,10000]。')
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_s')
              })
            Text('5. 线程范围：[1,1000]。')
              .fontWeight(FontWeight.Medium)
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
    /*.titleBar({
      content: {
        title: {
          mainTitle: ''
        }
      }
    })*/
    .title('应用资源限制设置')
    .onReady((context) => {
      this.pageInfos = context.pathStack
    })
  }
}