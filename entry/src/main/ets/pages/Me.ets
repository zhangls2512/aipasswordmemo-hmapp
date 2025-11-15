import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { display, window } from '@kit.ArkUI'
import { get, getAccountInfo, remove } from '../common/Accesstoken'
import getCloudServiceStatus from '../common/Cloudservice'
import openLink from '../common/Openlink'
import copy from '../common/Pasteboard'
import { getPreferType, getPreferTypeByDisplayId } from '../common/Prefertype'
import Cloudservice from './Cloudservice'
import Login from './Login'
import Passwordcheck from './Passwordcheck'
import Passwordgenerate from './Passwordgenerate'
import Setting from './Setting'
import Urlcheck from './Urlcheck'
import Vip from './Vip'

@ComponentV2
export default struct Me {
  @Provider() isShowLoginSheet: boolean = false
  @Provider() isShowCloudserviceSheet: boolean = false
  @Local preferType: number = 1
  @Local isShowVipSheet: boolean = false
  @Local isShowPasswordcheckSheet: boolean = false
  @Local isShowPasswordgenerateSheet: boolean = false
  @Local isShowUrlcheckSheet: boolean = false
  @Local isShowSettingSheet: boolean = false
  @Local uid: string = ''
  @Local email: string = ''
  @Local endDate: string = ''
  @Local cloudService: boolean = false
  @Local cloudServiceLoading: boolean = false
  @Local hoverId: number = -1
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'commonSetting'
  })

  async get() {
    const accountInfo = await getAccountInfo()
    this.uid = accountInfo.uid
    this.email = accountInfo.email
    this.endDate = String(new Date(accountInfo.endDate))
    const accessToken = await get()
    if (accessToken) {
      this.cloudServiceLoading = true
      this.cloudService = await getCloudServiceStatus(this.context, this.UIContext)
      this.cloudServiceLoading = false
    }
  }

  @Builder
  LoginSheetBuilder() {
    Login()
  }

  @Builder
  CloudserviceSheetBuilder() {
    Cloudservice()
  }

  @Builder
  VipSheetBuilder() {
    Vip()
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
            if (!this.uid) {
              Text('登录')
                .fontSize($r('sys.float.ohos_id_text_size_dialog_tittle'))
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)
            }
            if (this.uid) {
              if (!this.email) {
                Text('未绑定邮箱')
                  .fontSize($r('sys.float.ohos_id_text_size_dialog_tittle'))
                  .fontWeight(FontWeight.Bold)
                  .layoutWeight(1)
              }
              if (this.email) {
                Text(this.email)
                  .fontSize($r('sys.float.ohos_id_text_size_dialog_tittle'))
                  .fontWeight(FontWeight.Bold)
                  .layoutWeight(1)
              }
            }
          }
          .borderRadius(12)
          .padding(12)
          .stateStyles({
            normal: {
              .backgroundColor(this.hoverId === 0 ? $r('sys.color.interactive_hover') :
                $r('sys.color.comp_background_primary'))
            },
            pressed: {
              .backgroundColor($r('sys.color.comp_background_secondary'))
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
          .onClick(() => {
            if (!this.uid) {
              this.isShowLoginSheet = true
            }
          })
          .bindSheet(this.isShowLoginSheet!!, this.LoginSheetBuilder(), {
            height: SheetSize.FIT_CONTENT,
            preferType: this.preferType,
            title: {
              title: '登录'
            },
            onAppear: async () => {
              const disallowScreenshot =
                this.commonSettingDataPreferences.getSync('disallowScreenshot', true) as boolean
              if (disallowScreenshot) {
                const lastWindow = await window.getLastWindow(this.context)
                await lastWindow.setWindowPrivacyMode(true)
              }
            },
            onDisappear: async () => {
              const lastWindow = await window.getLastWindow(this.context)
              await lastWindow.setWindowPrivacyMode(false)
              this.get()
            }
          })

          if (this.uid) {
            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('UID')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(this.uid)
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .layoutWeight(1)
            }
            .borderRadius(12)
            .padding(12)
            .stateStyles({
              normal: {
                .backgroundColor(this.hoverId === 1 ? $r('sys.color.interactive_hover') :
                  $r('sys.color.comp_background_primary'))
              },
              pressed: {
                .backgroundColor($r('sys.color.comp_background_secondary'))
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
            .onClick(() => {
              copy(this.context, this.UIContext, this.uid)
            })

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('登录到期时间：' + this.endDate)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text('去修改')
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                })
              Image($r('app.media.right'))
                .fillColor($r('sys.color.icon_fourth'))
                .height(12)
                .width(12)
            }
            .borderRadius(12)
            .padding(12)
            .stateStyles({
              normal: {
                .backgroundColor(this.hoverId === 2 ? $r('sys.color.interactive_hover') :
                  $r('sys.color.comp_background_primary'))
              },
              pressed: {
                .backgroundColor($r('sys.color.comp_background_secondary'))
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
            .onClick(() => {
              openLink(this.context, 'https://www.zhangls2512.cn/product/account/info')
            })

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('云服务')
                .fontColor($r('sys.color.font_emphasize'))
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              if (!this.cloudServiceLoading) {
                if (!this.cloudService) {
                  Text('未开通')
                    .fontColor($r('sys.color.warning'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                    })
                }
                if (this.cloudService) {
                  Text('已开通')
                    .fontColor($r('sys.color.font_emphasize'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                    })
                }
              }
              if (this.cloudServiceLoading) {
                LoadingProgress()
                  .height(14)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                  })
                  .width(14)
              }
              Image($r('app.media.right'))
                .fillColor($r('sys.color.icon_fourth'))
                .height(12)
                .width(12)
            }
            .borderRadius(12)
            .padding(12)
            .stateStyles({
              normal: {
                .backgroundColor(this.hoverId === 3 ? $r('sys.color.interactive_hover') :
                  $r('sys.color.comp_background_primary'))
              },
              pressed: {
                .backgroundColor($r('sys.color.comp_background_secondary'))
              }
            })
            .width('100%')
            .onHover((isHover) => {
              if (!isHover) {
                this.hoverId = -1
              }
              if (isHover) {
                this.hoverId = 3
              }
            })
            .onClick(() => {
              this.isShowCloudserviceSheet = true
            })
            .bindSheet(this.isShowCloudserviceSheet!!, this.CloudserviceSheetBuilder(), {
              preferType: this.preferType,
              title: {
                title: '云服务'
              }
            })

            if (this.cloudService && !this.cloudServiceLoading) {
              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('会员中心')
                  .fontColor('#FFD700')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor(this.hoverId === 4 ? $r('sys.color.interactive_hover') :
                    $r('sys.color.comp_background_primary'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.comp_background_secondary'))
                }
              })
              .width('100%')
              .onHover((isHover) => {
                if (!isHover) {
                  this.hoverId = -1
                }
                if (isHover) {
                  this.hoverId = 4
                }
              })
              .onClick(() => {
                this.isShowVipSheet = true
              })
              .bindSheet(this.isShowVipSheet!!, this.VipSheetBuilder(), {
                preferType: this.preferType
              })
            }
          }
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
              left: 12,
              right: 12
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
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Image($r('app.media.right'))
                .fillColor($r('sys.color.icon_fourth'))
                .height(12)
                .width(12)
            }
            .borderRadius(12)
            .padding(12)
            .stateStyles({
              normal: {
                .backgroundColor(this.hoverId === 5 ? $r('sys.color.interactive_hover') :
                  $r('sys.color.comp_background_primary'))
              },
              pressed: {
                .backgroundColor($r('sys.color.comp_background_secondary'))
              }
            })
            .width('100%')
            .onHover((isHover) => {
              if (!isHover) {
                this.hoverId = -1
              }
              if (isHover) {
                this.hoverId = 5
              }
            })
            .onClick(() => {
              this.isShowPasswordcheckSheet = true
            })
            .bindSheet(this.isShowPasswordcheckSheet!!, this.PasswordcheckSheetBuilder(), {
              preferType: this.preferType,
              title: {
                title: '密码安全检查'
              },
              onAppear: async () => {
                const disallowScreenshot =
                  this.commonSettingDataPreferences.getSync('disallowScreenshot', true) as boolean
                if (disallowScreenshot) {
                  const lastWindow = await window.getLastWindow(this.context)
                  await lastWindow.setWindowPrivacyMode(true)
                }
              },
              onDisappear: async () => {
                const lastWindow = await window.getLastWindow(this.context)
                await lastWindow.setWindowPrivacyMode(false)
              }
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
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Image($r('app.media.right'))
                .fillColor($r('sys.color.icon_fourth'))
                .height(12)
                .width(12)
            }
            .borderRadius(12)
            .padding(12)
            .stateStyles({
              normal: {
                .backgroundColor(this.hoverId === 6 ? $r('sys.color.interactive_hover') :
                  $r('sys.color.comp_background_primary'))
              },
              pressed: {
                .backgroundColor($r('sys.color.comp_background_secondary'))
              }
            })
            .width('100%')
            .onHover((isHover) => {
              if (!isHover) {
                this.hoverId = -1
              }
              if (isHover) {
                this.hoverId = 6
              }
            })
            .onClick(() => {
              this.isShowPasswordgenerateSheet = true
            })
            .bindSheet(this.isShowPasswordgenerateSheet!!, this.PasswordgenerateSheetBuilder(), {
              preferType: this.preferType,
              title: {
                title: '密码随机生成'
              },
              onAppear: async () => {
                const disallowScreenshot =
                  this.commonSettingDataPreferences.getSync('disallowScreenshot', true) as boolean
                if (disallowScreenshot) {
                  const lastWindow = await window.getLastWindow(this.context)
                  await lastWindow.setWindowPrivacyMode(true)
                }
              },
              onDisappear: async () => {
                const lastWindow = await window.getLastWindow(this.context)
                await lastWindow.setWindowPrivacyMode(false)
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
          Text('更多工具')
            .fontColor($r('sys.color.font_secondary'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontWeight(FontWeight.Medium)
            .margin({
              bottom: 6,
              left: 12,
              right: 12
            })
          Column() {
            Row() {
              Image($r('app.media.dangerurl'))
                .height(24)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .width(24)
              Text('恶意URL检测')
                .enableAutoSpacing(true)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Image($r('app.media.right'))
                .fillColor($r('sys.color.icon_fourth'))
                .height(12)
                .width(12)
            }
            .borderRadius(12)
            .padding(12)
            .stateStyles({
              normal: {
                .backgroundColor(this.hoverId === 7 ? $r('sys.color.interactive_hover') :
                  $r('sys.color.comp_background_primary'))
              },
              pressed: {
                .backgroundColor($r('sys.color.comp_background_secondary'))
              }
            })
            .width('100%')
            .onHover((isHover) => {
              if (!isHover) {
                this.hoverId = -1
              }
              if (isHover) {
                this.hoverId = 7
              }
            })
            .onClick(() => {
              this.isShowUrlcheckSheet = true
            })
            .bindSheet(this.isShowUrlcheckSheet!!, this.UrlcheckSheetBuilder(), {
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
              .layoutWeight(1)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
            Image($r('app.media.right'))
              .fillColor($r('sys.color.icon_fourth'))
              .height(12)
              .width(12)
          }
          .borderRadius(12)
          .padding(12)
          .stateStyles({
            normal: {
              .backgroundColor(this.hoverId === 8 ? $r('sys.color.interactive_hover') :
                $r('sys.color.comp_background_primary'))
            },
            pressed: {
              .backgroundColor($r('sys.color.comp_background_secondary'))
            }
          })
          .width('100%')
          .onHover((isHover) => {
            if (!isHover) {
              this.hoverId = -1
            }
            if (isHover) {
              this.hoverId = 8
            }
          })
          .onClick(() => {
            this.isShowSettingSheet = true
          })
          .bindSheet(this.isShowSettingSheet!!, this.SettingSheetBuilder(), {
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

      if (this.uid) {
        ListItem() {
          Button('退出登录')
            .role(ButtonRole.ERROR)
            .width('100%')
            .onClick(async () => {
              const promptAction = this.getUIContext().getPromptAction()
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
                await remove()
                promptAction.openToast({
                  message: '退出成功'
                })
                this.uid = ''
                this.email = ''
                this.endDate = ''
                this.cloudService = false
              }
            })
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })
      }
    }
    .padding({
      left: $r('sys.float.ohos_id_max_padding_start'),
      right: $r('sys.float.ohos_id_max_padding_end'),
      top: this.preferType === 0 ? 0 : $r('sys.float.ohos_id_default_padding_top')
    })
    .onAppear(() => {
      this.preferType = getPreferType()
      display.on('change', (displayId) => {
        this.preferType = getPreferTypeByDisplayId(displayId)
      })
      this.context.eventHub.on('refreshMe', () => {
        this.get()
      })
      this.get()
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshMe')
      display.off('change')
    })
  }
}