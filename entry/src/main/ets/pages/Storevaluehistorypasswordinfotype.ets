import { preferences } from '@kit.ArkData'
import { LengthMetrics, promptAction } from '@kit.ArkUI'
import { HdsNavDestination } from '@kit.UIDesignKit'

@Builder
export function StorevaluehistorypasswordinfotypeBuilder() {
  Storevaluehistorypasswordinfotype()
}

@ComponentV2
struct Storevaluehistorypasswordinfotype {
  @Local storeValueHistoryPasswordInfoTypeArray: string[] = []
  @Local type: string = ''
  context = this.getUIContext().getHostContext()
  commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'commonSetting'
  })

  build() {
    HdsNavDestination() {
      List() {
        ListItem() {
          TextInput({
            placeholder: '请输入内容',
            text: this.type!!
          })
            .defaultFocus(this.storeValueHistoryPasswordInfoTypeArray.length === 0 ? true : false)
            .enableAutoSpacing(true)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Button('添加')
            .width('100%')
            .onClick(async () => {
              if (!this.type) {
                await promptAction.openToast({
                  message: '请输入内容'
                })
                return
              }
              if (this.type === '图标' || this.type === 'MFA') {
                await promptAction.openToast({
                  message: '不支持添加此类型'
                })
                return
              }
              if (this.storeValueHistoryPasswordInfoTypeArray.some(item => item === this.type)) {
                await promptAction.openToast({
                  message: '已添加此类型'
                })
                return
              }
              this.storeValueHistoryPasswordInfoTypeArray.push(this.type)
              this.type = ''
            })
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ForEach(this.storeValueHistoryPasswordInfoTypeArray, (item: string, index) => {
          ListItem() {
            Column() {
              Row() {
                Text(item)
                  .enableAutoSpacing(true)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Image($r('app.media.delete'))
                  .height(24)
                  .onClick(() => {
                    this.storeValueHistoryPasswordInfoTypeArray.splice(index, 1)
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
      content: {
        title: {
          mainTitle: '记录内容历史记录密码信息类型'
        }
      },
      enableComponentSafeArea: true
    })
    .onAppear(() => {
      this.storeValueHistoryPasswordInfoTypeArray =
        this.commonSettingDataPreferences.getSync('storeValueHistoryPasswordInfoType', ['密码']) as string[]
    })
    .onDisAppear(() => {
      this.commonSettingDataPreferences.putSync('storeValueHistoryPasswordInfoType',
        this.storeValueHistoryPasswordInfoTypeArray)
    })
  }
}