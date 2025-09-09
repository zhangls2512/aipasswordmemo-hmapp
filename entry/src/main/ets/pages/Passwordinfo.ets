import { preferences } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { fileIo } from '@kit.CoreFileKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { getPasswordInfo, Password, PasswordInfoItem, PasswordTagItem } from '../common/Dataget'
import openLink from '../common/Openlink'
import copy from '../common/Pasteboard'
import getTotp from '../common/Totp'

@ComponentV2
export default struct Passwordinfo {
  @Consumer() isShowInfoSheet: boolean = false
  @Param passwordId: number = 0
  @Local passwordName: string = ''
  @Local passwordInfo: PasswordInfoItem[] = []
  @Local mfaValue: string = ''
  @Local mfaStep: number = 30
  @Local mfaSecondsRemaining: number = 0
  @Local mfaSecondsRemainingColor: Color = Color.Transparent
  @Local mfaSecondsRemainingStyle: string = ''
  @Local passwordTag: PasswordTagItem[] = []
  context = this.getUIContext().getHostContext()

  build() {
    List() {
      ListItem() {
        Text(this.passwordName)
          .fontWeight(FontWeight.Bold)
      }

      ListItem() {
        Text('信息')
          .fontWeight(FontWeight.Medium)
      }
      .margin({
        bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      ForEach(this.passwordInfo, (item: PasswordInfoItem) => {
        if (item.type !== '图标' && item.type !== 'MFA' && item.type !== 'URL') {
          ListItem() {
            Column() {
              Row() {
                Text(item.type)
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.value)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius(12)
              .padding(12)
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
        if (item.type === '图标') {
          ListItem() {
            Column() {
              Row() {
                Text(item.type)
                  .fontWeight(FontWeight.Medium)
                Blank()
                Image(item.value)
                  .width('10%')
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(async () => {
                const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(this.context)
                try {
                  const uris = await phAccessHelper.showAssetsCreationDialog([item.value], [{
                    fileNameExtension: 'png',
                    photoType: photoAccessHelper.PhotoType.IMAGE
                  }])
                  const srcFile = fileIo.openSync(item.value)
                  const destFile = fileIo.openSync(uris[0], fileIo.OpenMode.WRITE_ONLY)
                  fileIo.copyFileSync(srcFile.fd, destFile.fd);
                  fileIo.closeSync(srcFile)
                  fileIo.closeSync(destFile)
                  promptAction.openToast({
                    message: '保存成功'
                  })
                } catch (err) {
                  promptAction.openToast({
                    message: '发生错误，错误码：' + err.code
                  })
                }
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
                    .fontWeight(FontWeight.Medium)
                  Text(item.type)
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                }
                .alignItems(HorizontalAlign.Start)

                Blank()
                if (this.mfaSecondsRemainingStyle === 'progress') {
                  Progress({
                    value: this.mfaSecondsRemaining,
                    total: this.mfaStep,
                    type: ProgressType.Ring
                  })
                    .color(this.mfaSecondsRemainingColor)
                    .width(40)
                }
                if (this.mfaSecondsRemainingStyle === 'number') {
                  Text(String(this.mfaSecondsRemaining))
                    .fontColor(this.mfaSecondsRemainingColor)
                }
              }
              .borderRadius(12)
              .padding(12)
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
        if (item.type === 'URL') {
          ListItem() {
            Column() {
              Row() {
                Text(item.type)
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.value)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .bindMenu([
                {
                  value: '打开',
                  action: () => {
                    openLink(item.value)
                  }
                },
                {
                  value: '复制',
                  action: () => {
                    copy(item.value)
                  }
                }
              ], {
                hapticFeedbackMode: HapticFeedbackMode.AUTO
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
            .fontWeight(FontWeight.Medium)
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
                  .fontWeight(FontWeight.Medium)
              }
              .width('95%')
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
    .onAppear(async () => {
      const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
        name: 'commonSetting'
      })
      const mfaSecondsRemainingStyleIndex = commonSettingDataPreferences.getSync('mfaSecondsRemainingStyle', 0)
      if (mfaSecondsRemainingStyleIndex === 0) {
        this.mfaSecondsRemainingStyle = 'progress'
      }
      if (mfaSecondsRemainingStyleIndex === 1) {
        this.mfaSecondsRemainingStyle = 'number'
      }
      const passwordInfo = await getPasswordInfo(this.passwordId) as Password
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
          const mfaSecondsRemainingPercent = Number((this.mfaSecondsRemaining / this.mfaStep).toFixed(2))
          if (mfaSecondsRemainingPercent >= 0.5) {
            this.mfaSecondsRemainingColor = Color.Green
          }
          if (mfaSecondsRemainingPercent < 0.5 && mfaSecondsRemainingPercent >= 0.3) {
            this.mfaSecondsRemainingColor = Color.Yellow
          }
          if (mfaSecondsRemainingPercent < 0.3 && mfaSecondsRemainingPercent >= 0.1) {
            this.mfaSecondsRemainingColor = Color.Orange
          }
          if (mfaSecondsRemainingPercent <= 0.1) {
            this.mfaSecondsRemainingColor = Color.Red
          }
        }, 500)
      }
    })
  }
}