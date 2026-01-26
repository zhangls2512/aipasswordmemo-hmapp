import { preferences } from '@kit.ArkData'
import { LengthMetrics, promptAction } from '@kit.ArkUI'
import { HdsNavDestination } from '@kit.UIDesignKit'

@Builder
export function OftenusedinfotypeBuilder() {
  Oftenusedinfotype()
}

@ComponentV2
struct Oftenusedinfotype {
  @Local oftenUsedInfoTypeArray: string[] = []
  @Local type: string = ''
  context = this.getUIContext().getHostContext()
  defaultInfoTypeArray =
    ['图标', '昵称', '用户名', '密码', 'MFA', '姓名', '手机号', '邮箱', '银行卡号', '身份证号', 'URL']
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
              if (this.type === '自定义') {
                await promptAction.openToast({
                  message: '不支持添加此类型'
                })
                return
              }
              if (this.oftenUsedInfoTypeArray.some(item => item === this.type)) {
                await promptAction.openToast({
                  message: '已添加此类型'
                })
                return
              }
              this.oftenUsedInfoTypeArray.push(this.type)
              this.type = ''
            })
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ForEach(this.oftenUsedInfoTypeArray, (item: string, index) => {
          ListItem() {
            Column() {
              Row() {
                Text(item)
                  .enableAutoSpacing(true)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                if (index !== 0) {
                  Image($r('app.media.up'))
                    .height(24)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                    .onClick(() => {
                      const temp = this.oftenUsedInfoTypeArray[index]
                      this.oftenUsedInfoTypeArray[index] = this.oftenUsedInfoTypeArray[index - 1]
                      this.oftenUsedInfoTypeArray[index - 1] = temp
                    })
                }
                if (index !== this.oftenUsedInfoTypeArray.length - 1) {
                  Image($r('app.media.down'))
                    .height(24)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                    .onClick(() => {
                      const temp = this.oftenUsedInfoTypeArray[index]
                      this.oftenUsedInfoTypeArray[index] = this.oftenUsedInfoTypeArray[index + 1]
                      this.oftenUsedInfoTypeArray[index + 1] = temp
                    })
                }
                Image($r('app.media.delete'))
                  .height(24)
                  .onClick(() => {
                    this.oftenUsedInfoTypeArray.splice(index, 1)
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
          Text('预置信息类型 (需要特殊处理、输入框类型适配或接入系统智能填充)')
            .fontWeight(FontWeight.Medium)
        }
        .margin({
          bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ForEach(this.defaultInfoTypeArray, (item: string) => {
          if (!this.oftenUsedInfoTypeArray.includes(item)) {
            ListItem() {
              Column() {
                Row() {
                  Text(item)
                    .layoutWeight(1)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                  Image($r('app.media.add'))
                    .height(24)
                    .onClick(async () => {
                      if (this.oftenUsedInfoTypeArray.some(typeItem => typeItem === item)) {
                        await promptAction.openToast({
                          message: '已添加此类型'
                        })
                        return
                      }
                      this.oftenUsedInfoTypeArray.push(item)
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
          }
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
          mainTitle: '常用信息类型'
        }
      },
      enableComponentSafeArea: true
    })
    .onAppear(() => {
      this.oftenUsedInfoTypeArray = this.commonSettingDataPreferences.getSync('oftenUsedInfoType', ['密码']) as string[]
    })
    .onDisAppear(() => {
      this.commonSettingDataPreferences.putSync('oftenUsedInfoType', this.oftenUsedInfoTypeArray)
    })
  }
}