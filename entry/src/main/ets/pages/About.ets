import { common } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { updateManager } from '@kit.AppGalleryKit'
import { call } from '@kit.TelephonyKit'
import pasteboard from '@ohos.pasteboard'

@Builder
export function AboutBuilder() {
  About()
}

@ComponentV2
export struct About {
  context = getContext(this) as common.UIAbilityContext
  pageInfos: NavPathStack = new NavPathStack()
  @Local hasUpdate: number = -1
  @Local updateLoading: boolean = false

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Image($r('app.media.foreground'))
              .height(80)
              .width(80)
              .gesture(
                TapGesture({
                  count: 2
                })
                  .onAction((event: GestureEvent) => {
                    if (event) {
                      this.pageInfos.pushPath({
                        name: 'Debug'
                      })
                    }
                  })
              )
            Text($r('app.string.app_name'))
              .fontSize($r('sys.float.ohos_id_text_size_dialog_tittle'))
              .fontWeight('bold')
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .textAlign(TextAlign.Center)
          }
          .width('100%')
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Row() {
              Column() {
                Text('版本信息')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                Text($r('app.string.app_version'))
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body3'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)

              Blank()
              if (!this.updateLoading) {
                if (this.hasUpdate === -1) {
                  Text('检测新版本')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                }
                if (this.hasUpdate === 0) {
                  Text('已是最新版本')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                }
                if (this.hasUpdate === 1) {
                  Text('存在新版本')
                    .fontColor($r('sys.color.font_emphasize'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                }
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              if (this.updateLoading) {
                LoadingProgress()
                  .height(12)
                  .width(12)
              }
            }
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
            .padding($r('sys.float.ohos_id_corner_radius_default_m'))
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.comp_background_list_card'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .width('100%')
            .onClick(async () => {
              try {
                this.updateLoading = true
                const res = await updateManager.checkAppUpdate(this.context)
                this.updateLoading = false
                this.hasUpdate = res.updateAvailable
                if (res.updateAvailable === 0) {
                  promptAction.showToast({
                    message: '已是最新版本'
                  })
                }
                if (res.updateAvailable === 1) {
                  updateManager.showUpdateDialog(this.context)
                }
              } catch (err) {
                this.updateLoading = false
                this.hasUpdate = -1
                promptAction.showToast({
                  message: '发生异常，错误码：' + err.code + '，错误信息：' + err.message
                })
              }
            })

            Divider()
              .padding({
                left: $r('sys.float.ohos_id_corner_radius_default_l'),
                right: $r('sys.float.ohos_id_corner_radius_default_l')
              })
            Row() {
              Column() {
                Text('更新日志')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                Text('https://www.zhangls2512.cn/product/updatelog/aipasswordmemohmapp')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body3'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)

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
                .backgroundColor($r('sys.color.comp_background_list_card'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .width('100%')
            .onClick(() => {
              this.context.openLink('https://www.zhangls2512.cn/product/updatelog/aipasswordmemohmapp', {
                parameters: {
                  'ohos.ability.params.showDefaultPicker': true
                }
              })
            })
          }
          .backgroundColor($r('sys.color.comp_background_list_card'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('客服')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: $r('sys.float.ohos_id_corner_radius_default_m')
              })
            Column() {
              Row() {
                Text('在线')
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
                  .backgroundColor($r('sys.color.comp_background_list_card'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(() => {
                this.context.openLink('https://chatbot.weixin.qq.com/webapp/5e2JglFAERGl06z0FkTK6eWL6D1Oa5?robotName=轩铭2512产品客服',
                  {
                    parameters: {
                      'ohos.ability.params.showDefaultPicker': true
                    }
                  })
              })

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Column() {
                  Text('电话')
                    .fontSize($r('sys.float.ohos_id_text_size_body1'))
                    .fontWeight('medium')
                  Text('18846496985')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body3'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                }
                .alignItems(HorizontalAlign.Start)

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
                  .backgroundColor($r('sys.color.comp_background_list_card'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(() => {
                call.makeCall('18846496985')
              })

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Column() {
                  Text('邮箱')
                    .fontSize($r('sys.float.ohos_id_text_size_body1'))
                    .fontWeight('medium')
                  Text('2300990296@qq.com')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body3'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                }
                .alignItems(HorizontalAlign.Start)

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
                  .backgroundColor($r('sys.color.comp_background_list_card'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(() => {
                this.context.startAbilityByType('mail', {
                  email: '2300990296@qq.com'
                }, {
                  onError: () => {
                  }
                })
              })

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Column() {
                  Text('微信')
                    .fontSize($r('sys.float.ohos_id_text_size_body1'))
                    .fontWeight('medium')
                  Text('gerenyinsi_z07x17m')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body3'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                }
                .alignItems(HorizontalAlign.Start)

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
                  .backgroundColor($r('sys.color.comp_background_list_card'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(async () => {
                let pasteData: pasteboard.PasteData =
                  pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, 'gerenyinsi_z07x17m')
                let systemPasteBoard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard()
                await systemPasteBoard.setData(pasteData)
                promptAction.showToast({
                  message: '内容已复制到剪贴板'
                })
              })

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Column() {
                  Text('腾讯频道')
                    .fontSize($r('sys.float.ohos_id_text_size_body1'))
                    .fontWeight('medium')
                  Text('https://pd.qq.com/s/cnx7f1zdm')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body3'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                }
                .alignItems(HorizontalAlign.Start)

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
                  .backgroundColor($r('sys.color.comp_background_list_card'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(() => {
                this.context.openLink('https://pd.qq.com/s/cnx7f1zdm', {
                  parameters: {
                    'ohos.ability.params.showDefaultPicker': true
                  }
                })
              })
            }
            .backgroundColor($r('sys.color.comp_background_list_card'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('媒体')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: $r('sys.float.ohos_id_corner_radius_default_m')
              })
            Column() {
              Row() {
                Column() {
                  Text('官网')
                    .fontSize($r('sys.float.ohos_id_text_size_body1'))
                    .fontWeight('medium')
                  Text('https://www.zhangls2512.cn/index')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body3'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                }
                .alignItems(HorizontalAlign.Start)

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
                  .backgroundColor($r('sys.color.comp_background_list_card'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(() => {
                this.context.openLink('https://www.zhangls2512.cn/index', {
                  parameters: {
                    'ohos.ability.params.showDefaultPicker': true
                  }
                })
              })

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Column() {
                  Text('哔哩哔哩')
                    .fontSize($r('sys.float.ohos_id_text_size_body1'))
                    .fontWeight('medium')
                  Text('https://space.bilibili.com/448824492')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body3'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                }
                .alignItems(HorizontalAlign.Start)

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
                  .backgroundColor($r('sys.color.comp_background_list_card'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(() => {
                this.context.openLink('https://space.bilibili.com/448824492', {
                  parameters: {
                    'ohos.ability.params.showDefaultPicker': true
                  }
                })
              })

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Column() {
                  Text('Gitcode')
                    .fontSize($r('sys.float.ohos_id_text_size_body1'))
                    .fontWeight('medium')
                  Text('https://gitcode.com/zhangls2512/aipasswordmemo-hmapp')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body3'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                }
                .alignItems(HorizontalAlign.Start)

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
                  .backgroundColor($r('sys.color.comp_background_list_card'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(() => {
                this.context.openLink('https://gitcode.com/zhangls2512/aipasswordmemo-hmapp', {
                  parameters: {
                    'ohos.ability.params.showDefaultPicker': true
                  }
                })
              })
            }
            .backgroundColor($r('sys.color.comp_background_list_card'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('资质证照')
              .fontColor($r('sys.color.font_emphasize'))
              .fontSize($r('sys.float.ohos_id_text_size_body3'))
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'License'
                })
              })
            Text('版权所有 ©️ 2025 张轩铭保留一切权利')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body3'))
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
              .textAlign(TextAlign.Center)
          }
          .width('100%')
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
    .title('关于')
    .onReady((context: NavDestinationContext) => {
      this.pageInfos = context.pathStack
    })
  }
}