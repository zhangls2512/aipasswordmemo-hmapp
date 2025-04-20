import { common } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { BusinessError } from '@kit.BasicServicesKit'
import { iap } from '@kit.IAPKit'
import { get } from '../common/Accesstoken'
import request from '../common/Request'

@Builder
export function VipBuilder() {
  Vip()
}

@ComponentV2
export struct Vip {
  @Local vipEndDate: string = '未开通会员'
  @Local vipEndDateLoading: boolean = false
  @Local color: string = ''
  context = getContext(this) as common.UIAbilityContext
  pageInfos: NavPathStack = new NavPathStack()

  async getVipEndDate() {
    this.vipEndDateLoading = true
    const userres = await request('/product/getUserInfo', {
      accessToken: get(),
      product: 'password'
    })
    this.vipEndDateLoading = false
    if (userres !== 'fail') {
      const vipenddate = JSON.parse(userres).data.vipEndDate as number
      if (vipenddate === 0) {
        this.vipEndDate = '终身会员'
        this.color = '#FFD700'
      }
      if (vipenddate > 0 && vipenddate >= Date.now()) {
        this.vipEndDate = '会员有效期至 ' + String(new Date(vipenddate))
        this.color = '#FFD700'
      }
    } else {
      this.vipEndDateLoading = false
    }
  }

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            if (!this.vipEndDateLoading) {
              Text(this.vipEndDate)
                .fontColor(this.color)
                .fontSize($r('sys.float.ohos_id_text_size_dialog_tittle'))
                .fontWeight('bold')
            }
            if (this.vipEndDateLoading) {
              LoadingProgress()
                .height(20)
                .width(20)
            }
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('会员可享以下特权：')
              .fontWeight('bold')
            Text('· 云备份不限个数')
              .fontWeight('medium')
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_m')
              })
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Row() {
              Text('订阅管理')
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontWeight('medium')
              Blank()
              Image($r('app.media.right'))
                .fillColor($r('sys.color.icon_fourth'))
                .height(12)
                .width(12)
            }
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
            .padding($r('sys.float.ohos_id_corner_radius_default_m'))
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .width('100%')
            .onClick(() => {
              const uiWindowParameter: iap.UIWindowParameter = {
                windowScreenMode: iap.WindowScreenMode.DIALOG_BOX
              }
              try {
                iap.showManagedSubscriptions(this.context, uiWindowParameter)
              } catch (err) {
                promptAction.showToast({
                  message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
                  (err as BusinessError).message
                })
              }
            })

            Divider()
              .padding({
                left: $r('sys.float.ohos_id_corner_radius_default_m'),
                right: $r('sys.float.ohos_id_corner_radius_default_m')
              })
            Row() {
              Text('兑换码')
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontWeight('medium')
              Blank()
              Image($r('app.media.right'))
                .fillColor($r('sys.color.icon_fourth'))
                .height(12)
                .width(12)
            }
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
            .padding($r('sys.float.ohos_id_corner_radius_default_m'))
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .width('100%')
            .onClick(() => {
              this.pageInfos.pushPath({
                name: 'Vipcode'
              })
            })

            Divider()
              .padding({
                left: $r('sys.float.ohos_id_corner_radius_default_m'),
                right: $r('sys.float.ohos_id_corner_radius_default_m')
              })
            Row() {
              Text('开通记录')
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontWeight('medium')
              Blank()
              Image($r('app.media.right'))
                .fillColor($r('sys.color.icon_fourth'))
                .height(12)
                .width(12)
            }
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
            .padding($r('sys.float.ohos_id_corner_radius_default_m'))
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .width('100%')
            .onClick(() => {
              this.pageInfos.pushPath({
                name: 'Viplog'
              })
            })
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
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
    .title('会员中心')
    .onReady(async (context: NavDestinationContext) => {
      this.pageInfos = context.pathStack
      this.getVipEndDate()
    })
  }
}