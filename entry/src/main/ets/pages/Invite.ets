import { common } from '@kit.AbilityKit'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { get } from '../common/Accesstoken'
import getDeviceToken from '../common/Devicetoken'
import copy from '../common/Pasteboard'
import request from '../common/Request'

@Builder
export function InviteBuilder() {
  Invite()
}

@ComponentV2
struct Invite {
  @Local deviceToken: string = ''
  @Local invitationcode: string = ''
  @Local inviteusercount: number = -1
  @Local loading: boolean = false
  @Local inputInvitationcode: string = ''
  @Local accessToken: string = ''
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            if (!this.loading && this.invitationcode && this.inviteusercount !== -1) {
              Text('本账号邀请码')
                .fontWeight(FontWeight.Bold)
              Text(this.invitationcode)
                .fontColor($r('sys.color.font_emphasize'))
                .fontWeight(FontWeight.Medium)
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
                .onClick(() => {
                  copy(this.invitationcode)
                })
              Text('已邀请新用户数：' + String(this.inviteusercount))
                .fontWeight(FontWeight.Bold)
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
            }
            if (this.loading) {
              LoadingProgress()
                .height(20)
                .width(20)
            }
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Column() {
            TextArea({
              placeholder: '请输入邀请码',
              text: this.inputInvitationcode!!
            })
              .enableAutoSpacing(true)
              .maxLength(62)
              .showCounter(true)
            Button('提交')
              .enabled(this.accessToken !== '' && this.deviceToken !== '' && this.inputInvitationcode.length === 62)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })
              .onClick(async () => {
                const dialogControllerProgress = new CustomDialogController({
                  builder: LoadingDialog({
                    content: '验证中...'
                  })
                })
                dialogControllerProgress.open()
                const res = await request('/product/useInvitationcode', {
                  accessToken: this.accessToken,
                  deviceToken: this.deviceToken,
                  product: 'password',
                  invitationcode: this.inputInvitationcode
                })
                dialogControllerProgress.close()
                if (res !== 'fail') {
                  promptAction.openToast({
                    message: '验证通过，已获得 30 天会员'
                  })
                  this.pageInfos.pop()
                  this.context.eventHub.emit('refreshVip')
                }
              })
          }
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('活动说明')
              .fontWeight(FontWeight.Bold)
            Text('1. 其他账号每使用本账号邀请码一次，本账号获得7天会员，其他账号获得30天会员。')
              .fontWeight(FontWeight.Medium)
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_m')
              })
            Text('2. 每个账号、设备仅能使用一次邀请码。')
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_s')
              })
            Text('3. 本账号邀请码可以被不限制数量的其他账号、设备使用，但不可被本账号使用。')
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_s')
              })
            Text('4. 本账号当前邀请码在取消开通云服务后会失效，重新开通无法恢复 (会生成新的邀请码)。')
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_s')
              })
          }
          .alignItems(HorizontalAlign.Start)
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
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title('邀请新用户，免费得会员')
    .onReady(async (context) => {
      this.pageInfos = context.pathStack
      this.accessToken = await get()
      if (this.accessToken) {
        this.loading = true
        this.deviceToken = await getDeviceToken()
        const userres = await request('/product/getUserInfo', {
          accessToken: this.accessToken,
          product: 'password'
        })
        if (userres !== 'fail') {
          this.invitationcode = JSON.parse(userres).data.invitationCode as string
        }
        const countres = await request('/product/getInviteUserCount', {
          accessToken: this.accessToken,
          product: 'password'
        })
        this.loading = false
        if (countres !== 'fail') {
          this.inviteusercount = JSON.parse(countres).count as number
        }
      }
    })
  }
}