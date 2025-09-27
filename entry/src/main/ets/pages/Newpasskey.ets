import { common } from '@kit.AbilityKit'
import { util } from '@kit.ArkTS'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { fido2 } from '@kit.OnlineAuthenticationKit'
import { getAccountInfo } from '../common/Accesstoken'
import request from '../common/Request'

@Builder
export function NewpasskeyBuilder() {
  Newpasskey()
}

@ComponentV2
struct Newpasskey {
  @Local email: string = ''
  @Local rawId: string = ''
  @Local publicKey: string = ''
  @Local type: string = 'mfa'
  @Local mfa: string = ''
  @Local emailcode: string = ''
  @Local buttonText: string = '获取验证码'
  @Local buttonEnabled: boolean = true
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()

  build() {
    NavDestination() {
      List() {
        if (this.email && this.rawId && this.publicKey) {
          ListItem() {
            Column() {
              Row() {
                Text('方式')
                  .fontWeight(FontWeight.Medium)
                  .width('20%')
                Row() {
                  Radio({
                    value: 'mfa',
                    group: 'type'
                  })
                    .checked(this.type === 'mfa' ? true : false)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                    .onChange((isChecked) => {
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
                    .onChange((isChecked) => {
                      if (isChecked) {
                        this.type = 'emailcode'
                      }
                    })
                  Text('邮箱验证码')
                }
                .width('75%')
              }

              if (this.type === 'mfa') {
                Row() {
                  Text('MFA')
                    .fontWeight(FontWeight.Medium)
                    .width('20%')
                  TextInput({
                    text: this.mfa!!,
                    placeholder: '请输入 MFA'
                  })
                    .enableAutoSpacing(true)
                    .maxLength(6)
                    .type(InputType.ONE_TIME_CODE)
                    .width('75%')
                }
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
              }
              if (this.type === 'emailcode') {
                Row() {
                  Text('验证码')
                    .fontWeight(FontWeight.Medium)
                    .width('20%')
                  TextInput({
                    text: this.emailcode!!,
                    placeholder: '请输入邮箱验证码'
                  })
                    .enableAutoSpacing(true)
                    .maxLength(8)
                    .type(InputType.ONE_TIME_CODE)
                    .width('75%')
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
              Button('新增')
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_l')
                })
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
                      content: '新增中...'
                    })
                  })
                  dialogControllerProgress.open()
                  const res = await request('/account/bindExternalAccount', {
                    email: this.email,
                    verifyType: this.type,
                    verifyCode: code,
                    platform: 'passkey',
                    rawId: this.rawId,
                    publicKey: this.publicKey
                  })
                  dialogControllerProgress.close()
                  if (res !== 'fail') {
                    promptAction.openToast({
                      message: '新增成功'
                    })
                    this.pageInfos.pop()
                  }
                })
            }
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .width('100%')
        }
      }
      .backgroundColor($r('app.color.sheet_background'))
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title('新增通行密钥')
    .onReady(async (context) => {
      this.pageInfos = context.pathStack
      const accountInfo = await getAccountInfo()
      this.email = accountInfo.email
      if (this.email) {
        try {
          const res = await fido2.register(this.context, {
            publicKey: {
              rp: {
                name: 'xm2512'
              },
              user: {
                id: new util.TextEncoder().encodeInto(accountInfo.uid),
                name: accountInfo.email,
                displayName: accountInfo.email
              },
              challenge: new util.TextEncoder().encodeInto(String(Date.now()).slice(0, -5) + '00000'),
              pubKeyCredParams: [{
                type: fido2.PublicKeyCredentialType.PUBLIC_KEY,
                alg: -7
              }]
            }
          })
          this.rawId = new util.Base64Helper().encodeToStringSync(res.rawId, util.Type.BASIC_URL_SAFE)
          this.publicKey = new util.Base64Helper().encodeToStringSync(res.response.publicKey, util.Type.BASIC_URL_SAFE)
        } catch (err) {
          promptAction.openToast({
            message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
          })
        }
      }
    })
  }
}