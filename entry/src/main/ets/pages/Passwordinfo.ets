import { getPasswordInfo, PasswordInfoItem, PasswordOut, PasswordTagItem } from '../common/Dataget'
import { copy } from '../common/Pasteboard'
import { getTotp } from '../common/Totp'

@ComponentV2
export default struct Passwordinfo {
  @Consumer() isShowInfoSheet: boolean = false
  @Param passwordId: number = 0
  @Local passwordName: string = ''
  @Local passwordInfo: PasswordInfoItem[] = []
  @Local mfaValue: string = ''
  @Local mfaStep: number = 30
  @Local mfaSecondsRemaining: number = 0
  @Local passwordTag: PasswordTagItem[] = []

  build() {
    List() {
      ListItem() {
        Text(this.passwordName)
          .fontWeight('bold')
      }

      ListItem() {
        Text('信息')
          .fontWeight('medium')
      }
      .margin({
        bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      ForEach(this.passwordInfo, (item: PasswordInfoItem) => {
        if (item.type !== 'MFA') {
          ListItem() {
            Column() {
              Row() {
                Text(item.type)
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.value)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .stateStyles({
                normal: {
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(() => {
                copy(item.value)
              })
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
        }
        if (item.type === 'MFA') {
          ListItem() {
            Column() {
              Row() {
                Column() {
                  Text(this.mfaValue)
                    .fontWeight('medium')
                  Text(item.type)
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                }
                .alignItems(HorizontalAlign.Start)

                Blank()
                Progress({
                  value: this.mfaSecondsRemaining,
                  total: this.mfaStep,
                  type: ProgressType.Ring
                })
                  .width(40)
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .stateStyles({
                normal: {
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(() => {
                copy(this.mfaValue)
              })
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
      if (this.passwordTag.length > 0) {
        ListItem() {
          Text('标签')
            .fontWeight('medium')
        }
        .margin({
          bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })
      }

      ForEach(this.passwordTag, (item: PasswordTagItem) => {
        ListItem() {
          Column() {
            Row() {
              Row() {
                Circle({
                  height: 16,
                  width: 16
                })
                  .fill(item.color)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(item.value)
                  .fontWeight('medium')
              }
              .width('95%')
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
    .onAppear(async () => {
      const passwordInfo = await getPasswordInfo(this.passwordId) as PasswordOut
      this.passwordName = passwordInfo.name
      this.passwordInfo = passwordInfo.info
      this.passwordTag = passwordInfo.tag
      const mfaInfo = this.passwordInfo.find(item => item.type === 'MFA')
      if (mfaInfo) {
        setInterval(() => {
          const mfaInfoArray = mfaInfo.value.split('\0')
          this.mfaStep = Number(mfaInfoArray[1])
          const res = getTotp(mfaInfoArray[0], Number(mfaInfoArray[1]), Number(mfaInfoArray[2]))
          this.mfaValue = res.value
          this.mfaSecondsRemaining = res.secondsRemaining
        }, 500)
      }
    })
  }
}