import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { emitter } from '@kit.BasicServicesKit'
import { get } from '../common/Accesstoken'
import request from '../common/Request'
import getCloudServiceStatus from '../common/Cloudservice'

@Builder
export function CloudserviceBuilder() {
  Cloudservice()
}

@ComponentV2
struct Cloudservice {
  @Local cloudService: boolean = false
  @Local loading: boolean = false
  pageInfos: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      List() {
        if (this.loading) {
          ListItem() {
            LoadingProgress()
              .width('50%')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_l')
          })
          .width('100%')
        }
        if (!this.loading) {
          ListItem() {
            Column() {
              if (!this.cloudService) {
                Text('开通云服务后，可使用以下功能：')
                  .fontWeight('bold')
                Text('· 云备份')
                  .fontWeight('medium')
                  .margin({
                    top: $r('sys.float.ohos_id_text_paragraph_margin_m')
                  })
              }
              if (this.cloudService) {
                Text('取消开通云服务前，需：')
                  .fontWeight('bold')
                Text('· 清空云备份')
                  .fontWeight('medium')
                  .margin({
                    top: $r('sys.float.ohos_id_text_paragraph_margin_m')
                  })
                Text('· 无会员开通记录')
                  .fontWeight('medium')
                  .margin({
                    top: $r('sys.float.ohos_id_text_paragraph_margin_s')
                  })
              }
            }
            .alignItems(HorizontalAlign.Start)
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_l')
          })

          ListItem() {
            Column() {
              if (!this.cloudService) {
                Button('开通')
                  .onClick(async () => {
                    const dialogControllerProgress: CustomDialogController = new CustomDialogController({
                      builder: LoadingDialog({
                        content: '开通中...'
                      })
                    })
                    dialogControllerProgress.open()
                    const res = await request('/account/openService', {
                      accessToken: get(),
                      service: 'password'
                    })
                    dialogControllerProgress.close()
                    if (res !== 'fail') {
                      promptAction.showToast({
                        message: '开通成功'
                      })
                      this.cloudService = true
                      this.pageInfos.pop()
                      emitter.emit('2')
                    }
                  })
              }
              if (this.cloudService) {
                Button('取消开通')
                  .role(ButtonRole.ERROR)
                  .onClick(async () => {
                    const dialogControllerProgress: CustomDialogController = new CustomDialogController({
                      builder: LoadingDialog({
                        content: '取消开通中...'
                      })
                    })
                    dialogControllerProgress.open()
                    const res = await request('/account/closeService', {
                      accessToken: get(),
                      service: 'password'
                    })
                    dialogControllerProgress.close()
                    if (res !== 'fail') {
                      promptAction.showToast({
                        message: '取消开通成功'
                      })
                      this.cloudService = false
                      this.pageInfos.pop()
                      emitter.emit('2')
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
      .backgroundColor($r('app.color.sheet_background'))
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title(this.cloudService ? '取消开通云服务' : '开通云服务')
    .onReady(async (context: NavDestinationContext) => {
      this.pageInfos = context.pathStack
      this.loading = true
      const cloudServiceStatus = await getCloudServiceStatus()
      this.loading = false
      this.cloudService = cloudServiceStatus
    })
  }
}