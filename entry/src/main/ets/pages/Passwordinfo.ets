import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { uri } from '@kit.ArkTS'
import { LengthMetrics, promptAction } from '@kit.ArkUI'
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
  @Local hidePasswordInfoType: string[] = []
  @Local passwordInfoValueDataDetector: boolean = false
  @Local mfaValue: string = ''
  @Local mfaStep: number = 30
  @Local mfaSecondsRemaining: number = 0
  @Local mfaOtpauthUri: string = ''
  @Local mfaSecondsRemainingColor: Color = Color.Transparent
  @Local mfaSecondsRemainingStyle: string = ''
  @Local passwordTag: PasswordTagItem[] = []
  @Local hoverId: number = -1
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext

  build() {
    List() {
      ListItem() {
        Text(this.passwordName)
          .enableAutoSpacing(true)
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
                  .enableAutoSpacing(true)
                  .fontWeight(FontWeight.Medium)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                if (!this.hidePasswordInfoType.includes(item.type)) {
                  Text(item.value)
                    .copyOption(CopyOptions.LocalDevice)
                    .enableAutoSpacing(true)
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .enableDataDetector(this.passwordInfoValueDataDetector)
                    .layoutWeight(1)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                    .textAlign(TextAlign.End)
                    .onClick(async () => {
                      await copy(this.context, this.UIContext, item.value)
                    })
                  Image($r('app.media.hide'))
                    .fillColor($r('sys.color.icon_secondary'))
                    .width('8%')
                    .onClick(() => {
                      this.hidePasswordInfoType.push(item.type)
                    })
                }
                if (this.hidePasswordInfoType.includes(item.type)) {
                  Text('***')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .layoutWeight(1)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                    .textAlign(TextAlign.End)
                    .onClick(async () => {
                      await copy(this.context, this.UIContext, item.value)
                    })
                  Image($r('app.media.show'))
                    .fillColor($r('sys.color.icon_secondary'))
                    .width('8%')
                    .onClick(() => {
                      this.hidePasswordInfoType.splice(this.hidePasswordInfoType.indexOf(item.type), 1)
                    })
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
        }
        if (item.type === '图标') {
          ListItem() {
            Column() {
              Row() {
                Text(item.type)
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Image(item.value)
                  .copyOption(CopyOptions.LocalDevice)
                  .width('10%')
                  .onError(async (err) => {
                    await promptAction.openToast({
                      message: '发生错误，错误信息：' + err.message
                    })
                  })
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor(this.hoverId === 0 ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onHover((isHover) => {
                if (!isHover) {
                  this.hoverId = -1
                }
                if (isHover) {
                  this.hoverId = 0
                }
              })
              .onClick(async () => {
                const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(this.context)
                try {
                  const uris = await phAccessHelper.showAssetsCreationDialog([item.value], [{
                    fileNameExtension: 'png',
                    photoType: photoAccessHelper.PhotoType.IMAGE
                  }])
                  const srcFile = fileIo.openSync(item.value)
                  const destFile = fileIo.openSync(uris[0], fileIo.OpenMode.WRITE_ONLY)
                  await fileIo.copyFile(srcFile.fd, destFile.fd)
                  fileIo.closeSync(srcFile)
                  fileIo.closeSync(destFile)
                  await promptAction.openToast({
                    message: '保存成功'
                  })
                } catch (err) {
                  if (err.code !== 13900020) {
                    await promptAction.openToast({
                      message: '发生错误，错误码：' + err.code
                    })
                  }
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
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })

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
                  .backgroundColor(this.hoverId === 1 ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onHover((isHover) => {
                if (!isHover) {
                  this.hoverId = -1
                }
                if (isHover) {
                  this.hoverId = 1
                }
              })
              .onClick(async () => {
                await copy(this.context, this.UIContext, this.mfaValue)
              })
              .gesture(
                LongPressGesture()
                  .onAction(async () => {
                    await copy(this.context, this.UIContext, this.mfaOtpauthUri)
                  })
              )
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
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(item.value)
                  .enableAutoSpacing(true)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor(this.hoverId === 2 ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onHover((isHover) => {
                if (!isHover) {
                  this.hoverId = -1
                }
                if (isHover) {
                  this.hoverId = 2
                }
              })
              .bindMenu([
                {
                  value: '打开',
                  action: async () => {
                    await openLink(this.context, item.value)
                  }
                },
                {
                  value: '复制',
                  action: async () => {
                    await copy(this.context, this.UIContext, item.value)
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
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })
      }
      ListItem() {
        Flex({
          wrap: FlexWrap.Wrap,
          space: {
            main: LengthMetrics.vp(8),
            cross: LengthMetrics.vp(8)
          }
        }) {
          ForEach(this.passwordTag, (item: PasswordTagItem) => {
            Text(item.value)
              .enableAutoSpacing(true)
              .fontColor(item.color)
              .fontWeight(FontWeight.Medium)
          })
        }
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
    .onAppear(async () => {
      const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
        name: 'commonSetting'
      })
      this.hidePasswordInfoType = commonSettingDataPreferences.getSync('defaultHidePasswordInfoType', []) as string[]
      this.passwordInfoValueDataDetector =
        commonSettingDataPreferences.getSync('passwordInfoValueDataDetector', true) as boolean
      const mfaSecondsRemainingStyleIndex = commonSettingDataPreferences.getSync('mfaSecondsRemainingStyle', 0)
      if (mfaSecondsRemainingStyleIndex === 0) {
        this.mfaSecondsRemainingStyle = 'progress'
      }
      if (mfaSecondsRemainingStyleIndex === 1) {
        this.mfaSecondsRemainingStyle = 'number'
      }
      const passwordInfo = await getPasswordInfo(this.context, this.passwordId) as Password
      this.passwordName = passwordInfo.name
      this.passwordInfo = passwordInfo.info
      this.passwordTag = passwordInfo.tag
      const mfaInfo = this.passwordInfo.find(item => item.type === 'MFA')
      if (mfaInfo) {
        setInterval(() => {
          const mfaInfoArray = mfaInfo.value.split('\0')
          let mfaOthauthUri = new uri.URI('otpauth://totp/' + passwordInfo.name)
          mfaOthauthUri = mfaOthauthUri.addQueryValue('secret', mfaInfoArray[0])
          mfaOthauthUri = mfaOthauthUri.addQueryValue('period', mfaInfoArray[1])
          mfaOthauthUri = mfaOthauthUri.addQueryValue('digits', mfaInfoArray[2])
          this.mfaOtpauthUri = mfaOthauthUri.toString()
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