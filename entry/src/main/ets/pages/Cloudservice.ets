import { common } from '@kit.AbilityKit'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { get } from '../common/Accesstoken'
import getCloudServiceStatus from '../common/Cloudservice'
import request from '../common/Request'

@ComponentV2
export default struct Cloudservice {
  @Consumer() isShowCloudserviceSheet: boolean = false
  @Local cloudService: boolean = false
  @Local loading: boolean = false
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  accessToken: string = ''

  build() {
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
      if (!this.loading) {
        ListItem() {
          Column() {
            if (!this.cloudService) {
              Text('开通云服务后，可使用以下功能：')
                .fontWeight(FontWeight.Bold)
              Text('· 云备份')
                .fontWeight(FontWeight.Medium)
                .margin({
                  top: $r('sys.float.ohos_id_text_paragraph_margin_m')
                })
            }
            if (this.cloudService) {
              Text('取消开通云服务前，需：')
                .fontWeight(FontWeight.Bold)
              Text('· 清空云备份')
                .fontWeight(FontWeight.Medium)
                .margin({
                  top: $r('sys.float.ohos_id_text_paragraph_margin_m')
                })
              Text('· 无会员开通记录')
                .fontWeight(FontWeight.Medium)
                .margin({
                  top: $r('sys.float.ohos_id_text_paragraph_margin_s')
                })
            }
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Column() {
            if (!this.cloudService) {
              Button('开通')
                .enabled(this.accessToken !== '')
                .width('100%')
                .onClick(async () => {
                  const dialogControllerProgress = new CustomDialogController({
                    builder: LoadingDialog({
                      content: '开通中...'
                    })
                  })
                  dialogControllerProgress.open()
                  const res = await request(this.context, this.UIContext, '/account/openService', {
                    accessToken: this.accessToken,
                    service: 'password'
                  })
                  dialogControllerProgress.close()
                  if (res !== 'fail') {
                    promptAction.openToast({
                      message: '开通成功'
                    })
                    this.cloudService = true
                    this.context.eventHub.emit('refreshMe')
                    this.isShowCloudserviceSheet = false
                  }
                })
            }
            if (this.cloudService) {
              Button('取消开通')
                .enabled(this.accessToken !== '')
                .role(ButtonRole.ERROR)
                .width('100%')
                .onClick(async () => {
                  const dialogControllerProgress = new CustomDialogController({
                    builder: LoadingDialog({
                      content: '取消开通中...'
                    })
                  })
                  dialogControllerProgress.open()
                  const res = await request(this.context, this.UIContext, '/account/closeService', {
                    accessToken: this.accessToken,
                    service: 'password'
                  })
                  dialogControllerProgress.close()
                  if (res !== 'fail') {
                    promptAction.openToast({
                      message: '取消开通成功'
                    })
                    this.cloudService = false
                    this.context.eventHub.emit('refreshMe')
                    this.isShowCloudserviceSheet = false
                  }
                })
            }
          }
          .width('100%')
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })
      }
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_max_padding_start'),
      right: $r('sys.float.ohos_id_max_padding_end')
    })
    .onAppear(async () => {
      this.accessToken = await get()
      if (this.accessToken) {
        this.loading = true
        this.cloudService = await getCloudServiceStatus(this.context, this.UIContext)
        this.loading = false
      }
    })
  }
}