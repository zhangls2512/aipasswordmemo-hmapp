import { preferences } from '@kit.ArkData'
import { promptAction, window } from '@kit.ArkUI'
import { deviceInfo } from '@kit.BasicServicesKit'
import { get, remove } from '../common/Accesstoken'
import request from '../common/Request'
import Login from './Login'
import Passwordcheck from './Passwordcheck'
import Passwordgenerate from './Passwordgenerate'
import Setting from './Setting'
import Urlcheck from './Urlcheck'

@ComponentV2
export default struct Me {
  @Provider() isShowLoginSheet: boolean = false
  @Local isShowPasswordcheckSheet: boolean = false
  @Local isShowPasswordgenerateSheet: boolean = false
  @Local isShowUrlcheckSheet: boolean = false
  @Local isShowSettingSheet: boolean = false
  @Local loading: boolean = false
  @Local email: string = ''
  context = getContext(this)
  preferType = 1

  async getEmail() {
    const accessToken = get()
    if (accessToken) {
      this.loading = true
      const res = await request('/account/getAccountInfo', {
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
  PasswordcheckSheetBuilder() {
    Passwordcheck()
  }

  @Builder
  PasswordgenerateSheetBuilder() {
    Passwordgenerate()
  }

  @Builder
  UrlcheckSheetBuilder() {
    Urlcheck()
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
              if (!this.email) {
                Text('登录')
                  .fontSize($r('sys.float.ohos_id_text_size_dialog_tittle'))
                  .fontWeight(FontWeight.Bold)
              }
              if (this.email) {
                Text(this.email)
                  .fontSize($r('sys.float.ohos_id_text_size_dialog_tittle'))
                  .fontWeight(FontWeight.Bold)
              }
            }
          }
          .borderRadius(12)
          .padding(12)
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
            if (!this.email && !this.loading) {
              this.isShowLoginSheet = !this.isShowLoginSheet
            }
          })
          .bindSheet($$this.isShowLoginSheet, this.LoginSheetBuilder(), {
            height: SheetSize.FIT_CONTENT,
            preferType: this.preferType,
            title: {
              title: '登录'
            },
            onAppear: (async () => {
              const lastWindow = await window.getLastWindow(this.context)
              await lastWindow.setWindowPrivacyMode(true)
            }),
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

      ListItem() {
        Column() {
          Text('密码工具')
            .fontColor($r('sys.color.font_secondary'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontWeight(FontWeight.Medium)
            .margin({
              bottom: 6,
              left: 12
            })
          Column() {
            Row() {
              Image($r('app.media.check'))
                .height(24)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .width(24)
              Text('安全检查')
                .fontWeight(FontWeight.Medium)
              Blank()
              Image($r('app.media.right'))
                .fillColor($r('sys.color.icon_fourth'))
                .height(12)
                .width(12)
            }
            .borderRadius(12)
            .padding(12)
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
              this.isShowPasswordcheckSheet = !this.isShowPasswordcheckSheet
            })
            .bindSheet($$this.isShowPasswordcheckSheet, this.PasswordcheckSheetBuilder(), {
              preferType: this.preferType,
              title: {
                title: '密码安全检查'
              },
              onAppear: (async () => {
                const lastWindow = await window.getLastWindow(this.context)
                await lastWindow.setWindowPrivacyMode(true)
              }),
              onDisappear: (async () => {
                const lastWindow = await window.getLastWindow(this.context)
                await lastWindow.setWindowPrivacyMode(false)
              })
            })

            Divider()
              .padding({
                left: 44,
                right: 12
              })
            Row() {
              Image($r('app.media.more'))
                .fillColor($r('sys.color.icon_primary'))
                .height(24)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .width(24)
              Text('随机生成')
                .fontWeight(FontWeight.Medium)
              Blank()
              Image($r('app.media.right'))
                .fillColor($r('sys.color.icon_fourth'))
                .height(12)
                .width(12)
            }
            .borderRadius(12)
            .padding(12)
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
              this.isShowPasswordgenerateSheet = !this.isShowPasswordgenerateSheet
            })
            .bindSheet($$this.isShowPasswordgenerateSheet, this.PasswordgenerateSheetBuilder(), {
              preferType: this.preferType,
              title: {
                title: '密码随机生成'
              },
              onAppear: (async () => {
                const lastWindow = await window.getLastWindow(this.context)
                await lastWindow.setWindowPrivacyMode(true)
              }),
              onDisappear: (async () => {
                const lastWindow = await window.getLastWindow(this.context)
                await lastWindow.setWindowPrivacyMode(false)
              })
            })
          }
          .backgroundColor($r('sys.color.comp_background_primary'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .alignItems(HorizontalAlign.Start)
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      ListItem() {
        Column() {
          Text('更多工具')
            .fontColor($r('sys.color.font_secondary'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontWeight(FontWeight.Medium)
            .margin({
              bottom: 6,
              left: 12
            })
          Column() {
            Row() {
              Image($r('app.media.dangerurl'))
                .height(24)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .width(24)
              Text('恶意 URL 检测')
                .fontWeight(FontWeight.Medium)
              Blank()
              Image($r('app.media.right'))
                .fillColor($r('sys.color.icon_fourth'))
                .height(12)
                .width(12)
            }
            .borderRadius(12)
            .padding(12)
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
              this.isShowUrlcheckSheet = !this.isShowUrlcheckSheet
            })
            .bindSheet($$this.isShowUrlcheckSheet, this.UrlcheckSheetBuilder(), {
              preferType: this.preferType,
              title: {
                title: '恶意 URL 检测'
              }
            })
          }
          .backgroundColor($r('sys.color.comp_background_primary'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .alignItems(HorizontalAlign.Start)
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
              .fontWeight(FontWeight.Medium)
            Blank()
            Image($r('app.media.right'))
              .fillColor($r('sys.color.icon_fourth'))
              .height(12)
              .width(12)
          }
          .borderRadius(12)
          .padding(12)
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
            preferType: this.preferType
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
                await preferences.deletePreferences(this.context, {
                  name: 'login'
                })
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
      if (deviceInfo.deviceType === 'phone') {
        this.preferType = 0
      }
      this.context.eventHub.on('refreshMe', () => {
        this.getEmail()
      })
      this.getEmail()
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshMe')
    })
  }
}