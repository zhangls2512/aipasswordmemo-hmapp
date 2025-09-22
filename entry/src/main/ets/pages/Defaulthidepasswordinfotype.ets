import { preferences } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'

@Builder
export function DefaulthidepasswordinfotypeBuilder() {
  Defaulthidepasswordinfotype()
}

@ComponentV2
struct Defaulthidepasswordinfotype {
  @Local defaultHidePasswordInfoTypeArray: string[] = []
  @Local type: string = ''
  context = this.getUIContext().getHostContext()
  commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'commonSetting'
  })

  build() {
    NavDestination() {
      List() {
        ListItem() {
          TextInput({
            placeholder: '请输入内容',
            text: this.type!!
          })
            .enableAutoSpacing(true)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Button('添加')
            .onClick(() => {
              if (!this.type) {
                promptAction.openToast({
                  message: '请输入内容'
                })
                return
              }
              if (this.type === '图标' || this.type === 'MFA') {
                promptAction.openToast({
                  message: '不支持添加此类型'
                })
                return
              }
              if (this.defaultHidePasswordInfoTypeArray.some(item => item === this.type)) {
                promptAction.openToast({
                  message: '已添加此类型'
                })
                return
              }
              this.defaultHidePasswordInfoTypeArray.push(this.type)
              this.type = ''
            })
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
        .width('100%')

        ForEach(this.defaultHidePasswordInfoTypeArray, (item: string, index) => {
          ListItem() {
            Column() {
              Row() {
                Text(item)
                  .enableAutoSpacing(true)
                  .width('87%')
                Blank()
                  .width('5%')
                Image($r('app.media.delete'))
                  .width('8%')
                  .onClick(() => {
                    this.defaultHidePasswordInfoTypeArray.splice(index, 1)
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
    .title('默认隐藏内容密码信息类型')
    .onAppear(() => {
      this.defaultHidePasswordInfoTypeArray =
        this.commonSettingDataPreferences.getSync('defaultHidePasswordInfoType', []) as string[]
    })
    .onDisAppear(() => {
      this.commonSettingDataPreferences.putSync('defaultHidePasswordInfoType', this.defaultHidePasswordInfoTypeArray)
    })
  }
}