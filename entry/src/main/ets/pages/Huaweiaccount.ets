import { common } from '@kit.AbilityKit'
import { loginComponentManager, LoginWithHuaweiIDButton } from '@kit.AccountKit'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { get, getAccountInfo } from '../common/Accesstoken'
import request from '../common/Request'

export interface Account {
  platform: string,
  openid: string
}

@Builder
export function HuaweiaccountBuilder() {
  Huaweiaccount()
}

@ComponentV2
struct Huaweiaccount {
  @Local email: string = ''
  @Local loading: boolean = false
  @Local isBind: boolean = false
  @Local type: string = 'mfa'
  @Local mfa: string = ''
  @Local emailcode: string = ''
  @Local agree: boolean = false
  @Local buttonText: string = '获取验证码'
  @Local buttonEnabled: boolean = true
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()
  controller: loginComponentManager.LoginWithHuaweiIDButtonController =
    new loginComponentManager.LoginWithHuaweiIDButtonController()
      .onClickLoginWithHuaweiIDButton(async (err, response) => {
        if (this.type === 'mfa' && this.mfa.length !== 6) {
          promptAction.openToast({
            message: '请输入正确的 MFA'
          })
          return
        }
        if (this.type === 'emailcode' && this.emailcode.length !== 8) {
          promptAction.openToast({
            message: '请输入正确的邮箱验证码'
          })
          return
        }
        let code = ''
        if (this.type === 'mfa') {
          code = this.mfa
        }
        if (this.type === 'emailcode') {
          code = this.emailcode
        }
        if (response) {
          const dialogControllerProgress = new CustomDialogController({
            builder: LoadingDialog({
              content: '绑定中...'
            })
          })
          dialogControllerProgress.open()
          const res = await request('/account/bindExternalAccount', {
            verifyType: this.type,
            verifyCode: code,
            email: this.email,
            platform: 'huaweiaipasswordmemoapp',
            code: response.authorizationCode
          })
          dialogControllerProgress.close()
          if (res !== 'fail') {
            promptAction.openToast({
              message: '绑定成功'
            })
            this.pageInfos.pop()
            this.context.eventHub.emit('refreshSetting')
          }
        }
        if (err) {
          promptAction.openToast({
            message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
          })
        }
      })

  build() {
    NavDestination() {
      List() {
        if (this.loading) {
          ListItem() {
            LoadingProgress()
              .width('50%')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .width('100%')
        }
        if (this.email && !this.loading) {
          ListItem() {
            Column() {
              Row() {
                Text('方式')
                  .fontWeight(FontWeight.Medium)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Column() {
                  Row() {
                    Radio({
                      value: 'mfa',
                      group: 'type'
                    })
                      .checked(this.type === 'mfa' ? true : false)
                      .onChange((isChecked) => {
                        if (isChecked) {
                          this.type = 'mfa'
                        }
                      })
                    Text('MFA')
                  }

                  Row() {
                    Radio({
                      value: 'emailcode',
                      group: 'type'
                    })
                      .checked(this.type === 'emailcode' ? true : false)
                      .onChange((isChecked) => {
                        if (isChecked) {
                          this.type = 'emailcode'
                        }
                      })
                    Text('邮箱验证码')
                  }
                  .margin({
                    top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                  })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }

              if (this.type === 'mfa') {
                Row() {
                  Text('MFA')
                    .fontWeight(FontWeight.Medium)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                  TextInput({
                    placeholder: '请输入MFA',
                    text: this.mfa!!
                  })
                    .enableAutoSpacing(true)
                    .layoutWeight(1)
                    .maxLength(6)
                    .type(InputType.ONE_TIME_CODE)
                }
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
              }
              if (this.type === 'emailcode') {
                Row() {
                  Text('验证码')
                    .fontWeight(FontWeight.Medium)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                  TextInput({
                    placeholder: '请输入邮箱验证码',
                    text: this.emailcode!!
                  })
                    .enableAutoSpacing(true)
                    .layoutWeight(1)
                    .maxLength(8)
                    .type(InputType.ONE_TIME_CODE)
                }
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })

                Button(this.buttonText)
                  .buttonStyle(ButtonStyleMode.NORMAL)
                  .enabled(this.buttonEnabled)
                  .margin({
                    top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                  })
                  .width('100%')
                  .onClick(async () => {
                    const dialogControllerProgress = new CustomDialogController({
                      builder: LoadingDialog({
                        content: '发送中...'
                      })
                    })
                    dialogControllerProgress.open()
                    const res = await request('/account/sendEmailCode', {
                      email: this.email
                    })
                    dialogControllerProgress.close()
                    if (res !== 'fail') {
                      promptAction.openToast({
                        message: '验证码已成功发送到邮箱：' + this.email
                      })
                      this.buttonEnabled = false
                      let countdown = 60
                      const interval = setInterval(() => {
                        countdown--
                        if (countdown > 0) {
                          this.buttonText = '重新发送 (' + countdown + ')'
                        } else {
                          clearInterval(interval)
                          this.buttonEnabled = true
                          this.buttonText = '获取验证码'
                        }
                      }, 1000)
                    }
                  })
              }
              if (!this.isBind) {
                LoginWithHuaweiIDButton({
                  params: {
                    style: loginComponentManager.Style.BUTTON_RED,
                    extraStyle: {
                      buttonStyle: new loginComponentManager.ButtonStyle().loadingStyle({
                        show: true
                      })
                    }
                  },
                  controller: this.controller
                })
                  .enabled(this.agree)
                  .height(40)
                  .margin({
                    top: $r('sys.float.ohos_id_elements_margin_vertical_l')
                  })
              }
              if (this.isBind) {
                Button('解绑')
                  .margin({
                    top: $r('sys.float.ohos_id_elements_margin_vertical_l')
                  })
                  .role(ButtonRole.ERROR)
                  .width('100%')
                  .onClick(async () => {
                    if (this.type === 'mfa' && this.mfa.length !== 6) {
                      promptAction.openToast({
                        message: '请输入正确的 MFA'
                      })
                      return
                    }
                    if (this.type === 'emailcode' && this.emailcode.length !== 8) {
                      promptAction.openToast({
                        message: '请输入正确的邮箱验证码'
                      })
                      return
                    }
                    let code = ''
                    if (this.type === 'mfa') {
                      code = this.mfa
                    }
                    if (this.type === 'emailcode') {
                      code = this.emailcode
                    }
                    const dialogControllerProgress = new CustomDialogController({
                      builder: LoadingDialog({
                        content: '解绑中...'
                      })
                    })
                    dialogControllerProgress.open()
                    const res = await request('/account/unbindExternalAccount', {
                      verifyType: this.type,
                      verifyCode: code,
                      email: this.email,
                      platform: 'huawei'
                    })
                    dialogControllerProgress.close()
                    if (res !== 'fail') {
                      promptAction.openToast({
                        message: '解绑成功'
                      })
                      this.pageInfos.pop()
                      this.context.eventHub.emit('refreshSetting')
                    }
                  })
              }
              if (!this.isBind) {
                Row() {
                  Toggle({
                    type: ToggleType.Checkbox,
                    isOn: this.agree!!
                  })
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                    .onChange((isOn) => {
                      this.controller.setEnabled(isOn)
                    })
                  Text() {
                    Span('已阅读并同意')
                    Span('《华为账号用户认证协议》')
                      .fontColor($r('sys.color.font_emphasize'))
                      .onClick(() => {
                        this.pageInfos.pushPath({
                          name: 'Webview',
                          param: 'https://privacy.consumer.huawei.com/legal/id/authentication-terms.htm?code=CN&language=zh-CN'
                        })
                      })
                    Span('《关于华为账号与隐私的声明》')
                      .fontColor($r('sys.color.font_emphasize'))
                      .onClick(() => {
                        this.pageInfos.pushPath({
                          name: 'Webview',
                          param: 'https://legal.cloud.huawei.com/terms/scope/huawei/id-hmos/privacy-statement.htm?code=CN&language=zh-CN'
                        })
                      })
                    Span('。')
                  }
                  .fontSize($r('sys.float.ohos_id_text_size_body3'))
                  .layoutWeight(1)
                }
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_l')
                })
              }
            }
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .width('100%')
        }
      }
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title(this.isBind ? '解绑华为账号' : '绑定华为账号')
    .onReady(async (context) => {
      this.pageInfos = context.pathStack
      this.controller.setEnabled(false)
      const accountInfo = await getAccountInfo()
      this.email = accountInfo.email
      const accessToken = await get()
      if (accessToken) {
        this.loading = true
        const res = await request('/account/getExternalAccount', {
          accessToken: accessToken
        })
        this.loading = false
        if (res !== 'fail') {
          const account = JSON.parse(res).data as Account[]
          if (account.some(item => item.platform === 'huawei')) {
            this.isBind = true
          }
        }
      }
    })
  }
}