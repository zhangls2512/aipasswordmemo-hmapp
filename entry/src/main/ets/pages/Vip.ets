import { common } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { iap } from '@kit.IAPKit'
import { get } from '../common/Accesstoken'
import openLink from '../common/Openlink'
import copy from '../common/Pasteboard'
import request from '../common/Request'

interface VipItem {
  id: string,
  name: string,
  type: iap.ProductType,
  price: string
}

@Builder
export function VipBuilder() {
  Vip()
}

@ComponentV2
struct Vip {
  @Local vipStatus: string = '未开通'
  @Local vipStatusColor: string = 'red'
  @Local vipStatusLoading: boolean = false
  @Local vipEndDate: string = ''
  @Local uid: string = ''
  @Local iapStatus: boolean = false
  @Local iapStatusLoading: boolean = false
  @Local agree: boolean = false
  context = getContext(this) as common.UIAbilityContext
  pageInfos = new NavPathStack()
  vipArray: VipItem[] = [
    {
      id: 'CG3_PfAJZa84niLQ',
      name: '连续包月',
      type: iap.ProductType.AUTORENEWABLE,
      price: '￥1'
    },
    {
      id: 'QIX7fU1KM3.IMVyb',
      name: '1 个月',
      type: iap.ProductType.NONRENEWABLE,
      price: '￥1.5'
    },
    {
      id: 'eD9OBaei.m7VJUo_',
      name: '连续包季',
      type: iap.ProductType.AUTORENEWABLE,
      price: '￥3'
    },
    {
      id: 'jYXNGP2VEuQOoXPA',
      name: '1 季度',
      type: iap.ProductType.NONRENEWABLE,
      price: '￥4.5'
    },
    {
      id: 'ZiRMWWgpOAXq3ErF',
      name: '连续包年',
      type: iap.ProductType.AUTORENEWABLE,
      price: '￥12'
    },
    {
      id: 'Y3V08cwoFrvLTPR7',
      name: '1 年',
      type: iap.ProductType.NONRENEWABLE,
      price: '￥18'
    },
    {
      id: 'DC3GXhbuWbw7tkpC',
      name: '终身',
      type: iap.ProductType.NONCONSUMABLE,
      price: '￥72'
    }
  ]

  async getVipStatus() {
    this.vipStatusLoading = true
    const userres = await request('/product/getUserInfo', {
      accessToken: get(),
      product: 'password'
    })
    this.vipStatusLoading = false
    if (userres !== 'fail') {
      const vipenddate = JSON.parse(userres).data.vipEndDate as number
      if (vipenddate < 0) {
        this.vipStatus = '未开通'
        this.vipStatusColor = 'red'
        this.vipEndDate = ''
      }
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
          this.vipStatusColor = 'red'
        }
      }
    }
  }

  async buyVip(id: string, type: iap.ProductType) {
    if (!this.agree) {
      promptAction.showToast({
        message: '请阅读并同意服务协议'
      })
      return
    }
    try {
      await iap.createPurchase(this.context, {
        productId: id,
        productType: type,
        developerPayload: this.uid
      })
      promptAction.showToast({
        message: '服务器正在验证，大约需要 5-20 秒，请稍候'
      })
    } catch (err) {
      const errCode = err.code as number
      if (errCode === 1001860000) {
        return
      }
      if (errCode === 1001860051) {
        promptAction.showToast({
          message: '已购买，无需重复购买'
        })
        return
      }
      promptAction.showToast({
        message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
      })
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
                .fontWeight(FontWeight.Bold)
              if (this.vipEndDate) {
                Text('到期时间：' + this.vipEndDate)
                  .fontWeight(FontWeight.Medium)
                  .margin({
                    top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                  })
              }
              if (this.uid) {
                Text() {
                  Span('UID：')
                  Span(this.uid)
                    .fontColor($r('sys.color.font_emphasize'))
                    .onClick(() => {
                      copy(this.uid)
                    })
                }
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
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
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        if (this.iapStatusLoading) {
          ListItem() {
            Column() {
              LoadingProgress()
                .width('20%')
            }
            .width('100%')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_l')
          })
        }
        if (this.iapStatus && this.vipEndDate !== '终身') {
          ListItem() {
            Column() {
              Text('付费开通')
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .fontWeight(FontWeight.Medium)
                .margin({
                  bottom: 6,
                  left: 12
                })
              Column() {
                Column() {
                  ForEach(this.vipArray, (item: VipItem, index) => {
                    if (index !== 0) {
                      Divider()
                        .padding({
                          left: 12,
                          right: 12
                        })
                    }
                    Row() {
                      Text(item.name)
                        .fontWeight(FontWeight.Medium)
                      Blank()
                      Text(item.price)
                        .fontColor($r('sys.color.font_secondary'))
                        .fontSize($r('sys.float.ohos_id_text_size_body2'))
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
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
                      this.buyVip(item.id, item.type)
                    })
                  })
                }
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                .padding($r('sys.float.ohos_id_corner_radius_mark'))

                Row() {
                  Column() {
                    Toggle({
                      type: ToggleType.Checkbox,
                      isOn: $$this.agree
                    })
                  }
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .width('10%')

                  Text() {
                    Span('已阅读并同意')
                    Span('《轩铭密码智能备忘录会员服务协议》')
                      .fontColor($r('sys.color.font_emphasize'))
                      .onClick(() => {
                        openLink('https://docs.qq.com/doc/p/4e810651bda479462dc9a5e8677273e5e1b72383')
                      })
                    Span('。如果购买连续包月/季/年，已阅读并同意')
                    Span('《轩铭密码智能备忘录会员自动续订服务协议》')
                      .fontColor($r('sys.color.font_emphasize'))
                      .onClick(() => {
                        openLink('https://docs.qq.com/doc/p/b205f991609f7a39a58b309a6d271bf160d65cc5')
                      })
                    Span('。')
                  }
                  .fontSize($r('sys.float.ohos_id_text_size_body3'))
                  .width('85%')
                }
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
              }
              .width('100%')
            }
            .alignItems(HorizontalAlign.Start)
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_l')
          })
        }
        ListItem() {
          Column() {
            Text('会员权益')
              .fontWeight(FontWeight.Bold)
            Text('· 云备份不限个数')
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('更多')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              if (this.iapStatus) {
                Row() {
                  Text('订阅管理')
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
                  const uiWindowParameter: iap.UIWindowParameter = {
                    windowScreenMode: iap.WindowScreenMode.DIALOG_BOX
                  }
                  iap.showManagedSubscriptions(this.context, uiWindowParameter)
                })

                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
              }
              Row() {
                Text('兑换码')
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
                this.pageInfos.pushPath({
                  name: 'Vipcode'
                })
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('开通记录')
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
                this.pageInfos.pushPath({
                  name: 'Viplog'
                })
              })
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
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
    .title('会员中心')
    .onReady(async (context: NavDestinationContext) => {
      this.pageInfos = context.pathStack
      await this.getVipStatus()
      this.context.eventHub.on('refreshVip', () => {
        this.getVipStatus()
      })
      this.iapStatusLoading = true
      const res = await request('/account/getAccountInfo', {
        accessToken: get()
      })
      if (res !== 'fail') {
        this.uid = JSON.parse(res).data.uid as string
      }
      if (this.vipEndDate === '终身') {
        this.iapStatusLoading = false
      }
      if (this.vipEndDate !== '终身') {
        try {
          await iap.queryEnvironmentStatus(this.context)
          this.iapStatusLoading = false
          this.iapStatus = true
        } catch (err) {
          this.iapStatusLoading = false
          promptAction.showToast({
            message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
          })
        }
      }
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshVip')
      this.context.eventHub.emit('refreshSetting')
    })
  }
}