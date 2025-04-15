import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { promptAction, window } from '@kit.ArkUI'
import { get, remove } from '../common/Accesstoken'
import { httpRequest } from '../common/Request'
import Login from './Login'
import Setting from './Setting'

@ComponentV2
export default struct Me {
  @Provider() isShowLoginSheet: boolean = false
  @Local isShowSettingSheet: boolean = false
  @Local loading: boolean = false
  @Local email: string = ''
  context = getContext(this) as common.UIAbilityContext

  async getEmail() {
    const accessToken = get()
    if (accessToken) {
      this.loading = true
      const res = await httpRequest('/account/getAccountInfo', {
        accessToken: accessToken
      })
      this.loading = false
      if (res !== 'fail') {
        this.email = JSON.parse(res).data.email as string
      }
    }
  }

  @Builder
  LoginSheetBuilder() {
    Login()
  }

  @Builder
  SettingSheetBuilder() {
    Setting()
  }

  build() {
    List() {
      ListItem() {
        Column() {
          Row() {
            Image($r('app.media.foreground'))
              .height(40)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .width(40)
            if (this.loading) {
              LoadingProgress()
                .height(40)
                .width(40)
            }
            if (!this.loading) {
              if (this.email === '') {
                Text('登录')
                  .fontSize($r('sys.float.ohos_id_text_size_dialog_tittle'))
                  .fontWeight('bold')
              }
              if (this.email !== '') {
                Text(this.email)
                  .fontSize($r('sys.float.ohos_id_text_size_dialog_tittle'))
                  .fontWeight('bold')
              }
            }
          }
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
          .padding($r('sys.float.ohos_id_corner_radius_default_m'))
          .stateStyles({
            normal: {
              .backgroundColor($r('sys.color.comp_background_primary'))
            },
            pressed: {
              .backgroundColor($r('sys.color.comp_background_secondary'))
            }
          })
          .width('100%')
          .onClick(async () => {
            if (this.email === '') {
              const lastWindow = await window.getLastWindow(this.context)
              await lastWindow.setWindowPrivacyMode(true)
              this.isShowLoginSheet = !this.isShowLoginSheet
            }
          })
          .bindSheet($$this.isShowLoginSheet, this.LoginSheetBuilder(), {
            preferType: SheetType.BOTTOM,
            onDisappear: (async () => {
              const lastWindow = await window.getLastWindow(this.context)
              await lastWindow.setWindowPrivacyMode(false)
              this.getEmail()
            })
          })
        }
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
        .padding($r('sys.float.ohos_id_corner_radius_mark'))
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      ListItem() {
        Column() {
          Row() {
            Image($r('app.media.setting'))
              .fillColor($r('sys.color.icon_primary'))
              .height(24)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .width(24)
            Text('设置')
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontWeight('medium')
            Blank()
            Image($r('app.media.right'))
              .fillColor($r('sys.color.icon_fourth'))
              .height(12)
              .width(12)
          }
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
          .padding($r('sys.float.ohos_id_corner_radius_default_m'))
          .stateStyles({
            normal: {
              .backgroundColor($r('sys.color.comp_background_primary'))
            },
            pressed: {
              .backgroundColor($r('sys.color.comp_background_secondary'))
            }
          })
          .width('100%')
          .onClick(() => {
            this.isShowSettingSheet = !this.isShowSettingSheet
          })
          .bindSheet($$this.isShowSettingSheet, this.SettingSheetBuilder(), {
            preferType: SheetType.BOTTOM
          })
        }
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
        .padding($r('sys.float.ohos_id_corner_radius_mark'))
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      if (this.email !== '') {
        ListItem() {
          Button('退出登录')
            .buttonStyle(ButtonStyleMode.NORMAL)
            .fontColor($r('sys.color.warning'))
            .onClick(async () => {
              const data = await promptAction.showDialog({
                title: '提示',
                message: '确定退出登录？',
                buttons: [
                  {
                    text: '取消',
                    color: $r('sys.color.font_primary')
                  },
                  {
                    text: '退出',
                    color: $r('sys.color.warning')
                  }
                ]
              })
              if (data.index === 1) {
                remove()
                const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
                  name: 'commonSetting'
                })
                commonSettingDataPreferences.deleteSync('loginEndDate')
                this.email = ''
                promptAction.showToast({
                  message: '退出成功'
                })
              }
            })
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })
        .width('100%')
      }
    }
    .backgroundColor($r('sys.color.background_secondary'))
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_max_padding_start'),
      right: $r('sys.float.ohos_id_max_padding_end')
    })
    .onAppear(() => {
      this.getEmail()
    })
  }
}