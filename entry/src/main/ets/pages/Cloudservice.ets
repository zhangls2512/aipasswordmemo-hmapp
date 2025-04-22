import { AppStorageV2, LoadingDialog, promptAction } from '@kit.ArkUI'
import { get } from '../common/Accesstoken'
import request from '../common/Request'
import { CloudService } from './Setting'

@Builder
export function CloudserviceBuilder() {
  Cloudservice()
}

@ComponentV2
struct Cloudservice {
  @Local CloudService: CloudService = AppStorageV2.connect(CloudService, () => new CloudService())!
  @Local loading: boolean = false
  pageInfos: NavPathStack = new NavPathStack()
  dialogControllerProgress: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: '请稍候...'
    })
  })

  build() {
    NavDestination() {
      List() {
        if (!this.loading) {
          ListItem() {
            Column() {
              if (!this.CloudService.status) {
                Text('开通云服务后，可使用以下功能：')
                  .fontWeight('bold')
                Text('· 数据云备份')
                  .fontWeight('medium')
                  .margin({
                    top: $r('sys.float.ohos_id_text_paragraph_margin_m')
                  })
              }
              if (this.CloudService.status) {
                Text('取消开通云服务前，需：')
                  .fontWeight('bold')
                Text('· 清空云备份数据')
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
              if (!this.CloudService.status) {
                Button('开通')
                  .buttonStyle(ButtonStyleMode.EMPHASIZED)
                  .onClick(async () => {
                    this.dialogControllerProgress.open()
                    const res = await request('/account/openService', {
                      accessToken: get(),
                      service: 'password'
                    })
                    this.dialogControllerProgress.close()
                    if (res !== 'fail') {
                      promptAction.showToast({
                        message: '开通成功'
                      })
                      this.CloudService.status = true
                      this.pageInfos.pop()
                    }
                  })
              }
              if (this.CloudService.status) {
                Button('取消开通')
                  .role(ButtonRole.ERROR)
                  .onClick(async () => {
                    this.dialogControllerProgress.open()
                    const res = await request('/account/closeService', {
                      accessToken: get(),
                      service: 'password'
                    })
                    this.dialogControllerProgress.close()
                    if (res !== 'fail') {
                      promptAction.showToast({
                        message: '取消开通成功'
                      })
                      this.CloudService.status = false
                      this.pageInfos.pop()
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
      }
      .backgroundColor($r('app.color.sheet_background'))
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title(this.CloudService.status ? '取消开通云服务' : '开通云服务')
    .onReady(async (context: NavDestinationContext) => {
      this.pageInfos = context.pathStack
      this.loading = true
      const infores = await request('/account/getAccountInfo', {
        accessToken: get()
      })
      this.loading = false
      if (infores !== 'fail') {
        const service = JSON.parse(infores).data.service as string[]
        this.CloudService.status = service.includes('password')
      } else {
        this.loading = false
      }
    })
  }
}