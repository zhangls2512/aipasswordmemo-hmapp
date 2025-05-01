import { loginComponentManager, LoginWithHuaweiIDButton } from '@kit.AccountKit'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { BusinessError } from '@kit.BasicServicesKit'
import { get } from '../common/Accesstoken'
import openLink from '../common/Openlink'
import request from '../common/Request'

interface Account {
  platform: string,
  openid: string
}

@Builder
export function HuaweiaccountBuilder() {
  Huaweiaccount()
}

@ComponentV2
struct Huaweiaccount {
  @Local loading: boolean = false
  @Local isBind: boolean = false
  @Local type: string = 'mfa'
  @Local email: string = ''
  @Local mfa: string = ''
  @Local emailcode: string = ''
  @Local agree: boolean = false
  @Local buttonText: string = '获取验证码'
  @Local buttonEnabled: boolean = true
  pageInfos: NavPathStack = new NavPathStack()
  controller: loginComponentManager.LoginWithHuaweiIDButtonController =
    new loginComponentManager.LoginWithHuaweiIDButtonController()
      .onClickLoginWithHuaweiIDButton(async (err: BusinessError,
        response: loginComponentManager.HuaweiIDCredential) => {
        if (this.type === 'mfa' && this.mfa.length !== 6) {
          promptAction.showToast({
            message: '请输入正确的 MFA'
          })
          return
        }
        if (this.type === 'emailcode' && this.emailcode.length !== 8) {
          promptAction.showToast({
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
          const dialogControllerProgress: CustomDialogController = new CustomDialogController({
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
            promptAction.showToast({
              message: '绑定成功'
            })
            this.pageInfos.pop()
          }
        }
        if (err) {
          promptAction.showToast({
            message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
          })
        }
      })

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            if (this.email && !this.loading) {
              Column() {
                Row() {
                  Text('方式')
                    .fontWeight('medium')
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                    .width('15%')
                  Row() {
                    Radio({
                      value: 'mfa',
                      group: 'type'
                    })
                      .checked(this.type === 'mfa' ? true : false)
                      .margin({
                        right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                      })
                      .onChange((isChecked: boolean) => {
                        if (isChecked) {
                          this.type = 'mfa'
                        }
                      })
                    Text('MFA')
                      .margin({
                        right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                      })
                    Radio({
                      value: 'emailcode',
                      group: 'type'
                    })
                      .checked(this.type === 'emailcode' ? true : false)
                      .margin({
                        right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                      })
                      .onChange((isChecked: boolean) => {
                        if (isChecked) {
                          this.type = 'emailcode'
                        }
                      })
                    Text('邮箱验证码')
                  }
                  .width('80%')
                }

                if (this.type === 'mfa') {
                  Row() {
                    Text('MFA')
                      .fontWeight('medium')
                      .margin({
                        right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                      })
                      .width('15%')
                    TextInput({
                      text: $$this.mfa,
                      placeholder: '请输入 MFA'
                    })
                      .maxLength(6)
                      .type(InputType.Number)
                      .width('80%')
                  }
                  .margin({
                    top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                  })
                }
                if (this.type === 'emailcode') {
                  Row() {
                    Text('验证码')
                      .fontWeight('medium')
                      .margin({
                        right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                      })
                      .width('15%')
                    TextInput({
                      text: $$this.emailcode,
                      placeholder: '请输入邮箱验证码'
                    })
                      .maxLength(8)
                      .type(InputType.Number)
                      .width('80%')
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
                      const dialogControllerProgress: CustomDialogController = new CustomDialogController({
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
                        promptAction.showToast({
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
                    .margin({
                      top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                    })
                    .height(40)
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
                        promptAction.showToast({
                          message: '请输入正确的 MFA'
                        })
                        return
                      }
                      if (this.type === 'emailcode' && this.emailcode.length !== 8) {
                        promptAction.showToast({
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
                      const dialogControllerProgress: CustomDialogController = new CustomDialogController({
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
                        promptAction.showToast({
                          message: '解绑成功'
                        })
                        this.pageInfos.pop()
                      }
                    })
                }
                if (!this.isBind) {
                  Blank()
                  Row() {
                    Column() {
                      Toggle({
                        type: ToggleType.Checkbox,
                        isOn: $$this.agree
                      })
                        .onChange((isOn: boolean) => {
                          this.controller.setEnabled(isOn)
                        })
                    }
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                    .width('10%')

                    Text() {
                      Span('已阅读并同意')
                      Span('《关于华为账号与隐私的声明》')
                        .fontColor($r('sys.color.font_emphasize'))
                        .onClick(() => {
                          openLink('https://legal.cloud.huawei.com/terms/scope/huawei/id-hmos/privacy-statement.htm?code=CN&language=zh-CN')
                        })
                      Span('。')
                    }
                    .fontSize($r('sys.float.ohos_id_text_size_body3'))
                    .width('85%')
                  }
                  .margin({
                    top: $r('sys.float.ohos_id_elements_margin_vertical_l')
                  })
                }
              }
            }
            if (this.loading) {
              LoadingProgress()
                .width('50%')
            }
          }
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })
        .width('100%')
      }
      .backgroundColor($r('app.color.sheet_background'))
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title(this.isBind ? '解绑华为账号' : '绑定华为账号')
    .onReady(async (context: NavDestinationContext) => {
      this.pageInfos = context.pathStack
      this.controller.setEnabled(false)
      const accessToken = get()
      if (accessToken) {
        this.loading = true
        const infores = await request('/account/getAccountInfo', {
          accessToken: accessToken
        })
        if (infores !== 'fail') {
          this.email = JSON.parse(infores).data.email as string
          const accountres = await request('/account/getExternalAccount', {
            accessToken: accessToken
          })
          this.loading = false
          if (accountres !== 'fail') {
            const account = JSON.parse(accountres).data as Account[]
            if (account.some(item => item.platform === 'huawei')) {
              this.isBind = true
            } else {
              this.isBind = false
            }
          }
        } else {
          this.loading = false
        }
      }
    })
  }
}