import { promptAction } from '@kit.ArkUI'
import { iap } from '@kit.IAPKit'
import { get } from '../common/Accesstoken'
import request from '../common/Request'

interface Item {
  duration: number,
  type: string,
  info: string,
  date: number
}

@Builder
export function ViplogBuilder() {
  Viplog()
}

@ComponentV2
struct Viplog {
  @Local viplogArray: Item[] = []
  @Local loading: boolean = false
  @Local accessToken: string = ''
  empty: boolean | undefined = undefined

  build() {
    NavDestination() {
      List() {
        if (this.viplogArray.length === 0 && !this.loading) {
          ListItem() {
            Text('无数据')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .width('100%')
        }
        ForEach(this.viplogArray, (item: Item) => {
          ListItem() {
            Column() {
              Row() {
                Text('时长')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.duration === 0 ? '终身' : String(item.duration) + ' 天')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('类型')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.type === 'pay' ? '付费' :
                  item.type === 'vipcode' ? '兑换码' :
                    item.type === 'invitationcode' ? '邀请码' :
                      item.type === 'invitenewuser' ? '邀请新用户' :
                        'undefined')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('详情')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.info)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('时间')
                  .fontWeight(FontWeight.Medium)
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(new Date(item.date)))
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius(12)
              .padding(12)
              .width('100%')

              if (item.type === 'pay') {
                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Text('申请退款')
                    .fontWeight(FontWeight.Medium)
                  Blank()
                  Image($r('app.media.right'))
                    .fillColor($r('sys.color.icon_fourth'))
                    .height(12)
                    .width(12)
                }
                .borderRadius(12)
                .padding(12)
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
                  const context = getContext()
                  try {
                    iap.createRefundRequest(context, item.info)
                  } catch (err) {
                    promptAction.showToast({
                      message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
                    })
                  }
                })
              }
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
        })
        if (this.loading) {
          ListItem() {
            LoadingProgress()
              .width('20%')
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
      .onReachEnd(async () => {
        if (this.accessToken && this.empty === false) {
          this.loading = true
          const res = await request('/product/getViplogList', {
            accessToken: this.accessToken,
            product: 'password',
            skip: this.viplogArray.length
          })
          this.loading = false
          if (res !== 'fail') {
            const array = JSON.parse(res).data as Item[]
            if (array.length === 0) {
              this.empty = true
            }
            this.viplogArray = this.viplogArray.concat(array)
          }
        }
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title('会员开通记录')
    .onReady(async () => {
      this.accessToken = await get()
      if (this.accessToken) {
        this.loading = true
        const res = await request('/product/getViplogList', {
          accessToken: this.accessToken,
          product: 'password'
        })
        this.loading = false
        if (res !== 'fail') {
          const viplogs = JSON.parse(res).data as Item[]
          this.viplogArray = viplogs
          this.empty = false
        }
      }
    })
  }
}