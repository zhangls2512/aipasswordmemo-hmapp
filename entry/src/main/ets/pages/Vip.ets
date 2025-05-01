import { common } from '@kit.AbilityKit'
import { iap } from '@kit.IAPKit'
import { get } from '../common/Accesstoken'
import request from '../common/Request'

@Builder
export function VipBuilder() {
  Vip()
}

@ComponentV2
struct Vip {
  @Local vipStatus: string = '未开通'
  @Local vipStatusLoading: boolean = false
  @Local vipStatusColor: string = 'red'
  @Local vipEndDate: string = ''
  context = getContext(this) as common.UIAbilityContext
  pageInfos: NavPathStack = new NavPathStack()

  async getVipStatus() {
    this.vipStatusLoading = true
    const userres = await request('/product/getUserInfo', {
      accessToken: get(),
      product: 'password'
    })
    this.vipStatusLoading = false
    if (userres !== 'fail') {
      const vipenddate = JSON.parse(userres).data.vipEndDate as number
      if (vipenddate === 0) {
        this.vipStatus = '已开通'
        this.vipStatusColor = '#FFD700'
        this.vipEndDate = '终身'
      }
      if (vipenddate > 0) {
        this.vipEndDate = String(new Date(vipenddate))
        if (vipenddate >= Date.now()) {
          this.vipStatus = '已开通 '
          this.vipStatusColor = '#FFD700'
        }
        if (vipenddate < Date.now()) {
          this.vipStatus = '已过期'
        }
      }
    }
  }

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            if (!this.vipStatusLoading) {
              Text(this.vipStatus)
                .fontColor(this.vipStatusColor)
                .fontSize($r('sys.float.ohos_id_text_size_dialog_tittle'))
                .fontWeight('bold')
              if (this.vipEndDate) {
                Text('到期时间：' + this.vipEndDate)
                  .fontWeight('medium')
                  .margin({
                    top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                  })
              }
            }
            if (this.vipStatusLoading) {
              LoadingProgress()
                .height(20)
                .width(20)
            }
            Text() {
              Span('会员')
                .fontColor('#FFD700')
              Span('可享以下特权：')
            }
            .fontWeight('bold')
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_l')
            })

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
              iap.showManagedSubscriptions(this.context, uiWindowParameter)
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
    .onReady((context: NavDestinationContext) => {
      this.pageInfos = context.pathStack
      this.getVipStatus()
    })
  }
}