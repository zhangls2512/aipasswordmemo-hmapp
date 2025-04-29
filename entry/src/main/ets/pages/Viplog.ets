import { get } from '../common/Accesstoken'
import request from '../common/Request'

interface Item {
  date: number,
  duration: number,
  info: string,
  type: string
}

@Builder
export function ViplogBuilder() {
  Viplog()
}

@ComponentV2
struct Viplog {
  @Local viplogArray: Item[] = []
  @Local loading: boolean = false
  accessToken: string = get()
  empty: boolean | undefined = undefined

  build() {
    NavDestination() {
      List() {
        ForEach(this.viplogArray, (item: Item) => {
          ListItem() {
            Column() {
              Row() {
                Text('时长')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.duration === 0 ? '终身' : String(item.duration) + ' 天')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('类型')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.type === 'pay' ? '付费' :
                  item.type === 'vipcode' ? '兑换码' :
                    'undefined')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('详情')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(item.info)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('时间')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(new Date(item.date)))
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')
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
        if (this.viplogArray.length === 0 && !this.loading) {
          ListItem() {
            Text('无数据')
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
        right: $r('sys.float.ohos_id_max_padding_end'),
        top: $r('sys.float.ohos_id_elements_margin_vertical_m')
      })
      .onReachEnd(async () => {
        if (this.empty === false) {
          this.loading = true
          const res = await request('/product/getViplogList', {
            accessToken: get(),
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
      this.loading = true
      const res = await request('/product/getViplogList', {
        accessToken: get(),
        product: 'password'
      })
      this.loading = false
      if (res !== 'fail') {
        const viplogs = JSON.parse(res).data as Item[]
        this.viplogArray = viplogs
        this.empty = false
      }
    })
  }
}