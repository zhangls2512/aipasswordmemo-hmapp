import { common } from '@kit.AbilityKit'
import { loginComponentManager, LoginWithHuaweiIDButton } from '@kit.AccountKit'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { get, getAccountInfo, remove, set } from '../common/Accesstoken'
import request from '../common/Request'

@Builder
export function EmailBuilder() {
  Email()
}

@ComponentV2
struct Email {
  @Local email: string = ''
  @Local emailcode: string = ''
  @Local buttonText: string = '获取验证码'
  @Local buttonEnabled: boolean = true
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()
  controller: loginComponentManager.LoginWithHuaweiIDButtonController =
    new loginComponentManager.LoginWithHuaweiIDButtonController()
      .onClickLoginWithHuaweiIDButton(async (err, response) => {
        if (!this.email) {
          promptAction.openToast({
            message: '请输入邮箱'
          })
          return
        }
        if (this.emailcode.length !== 8) {
          promptAction.openToast({
            message: '请输入正确的邮箱验证码'
          })
          return
        }
        if (response) {
          const dialogControllerProgress = new CustomDialogController({
            builder: LoadingDialog({
              content: '绑定中...'
            })
          })
          dialogControllerProgress.open()
          const res = await request('/account/updateEmail', {
            verifyType: 'huaweiaipasswordmemoapp',
            verifyCode: response.authorizationCode,
            newEmail: this.email,
            newEmailCode: this.emailcode
          })
          dialogControllerProgress.close()
          if (res !== 'fail') {
            promptAction.openToast({
              message: '绑定成功'
            })
            const accessToken = await get()
            const accountInfo = await getAccountInfo()
            await remove()
            await set(accessToken, {
              uid: accountInfo.uid,
              email: this.email,
              endDate: accountInfo.endDate
            })
            this.pageInfos.pop()
            this.context.eventHub.emit('refreshSetting')
            this.context.eventHub.emit('refreshMe')
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
        ListItem() {
          Column() {
            Row() {
              Text('邮箱')
                .fontWeight(FontWeight.Medium)
                .width('20%')
              TextInput({
                text: this.email!!,
                placeholder: '请输入邮箱'
              })
                .contentType(ContentType.EMAIL_ADDRESS)
                .enableAutoSpacing(true)
                .type(InputType.Email)
                .width('75%')
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })

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
                if (!this.email) {
                  promptAction.openToast({
                    message: '请输入邮箱'
                  })
                  return
                }
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
              .height(40)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })
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
    .title('绑定邮箱')
    .onReady((context) => {
      this.pageInfos = context.pathStack
    })
  }
}