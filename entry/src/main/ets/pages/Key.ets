import { common } from '@kit.AbilityKit'
import { promptAction, window } from '@kit.ArkUI'
import { getKey, setRandomKey, removeKey } from '../common/Crypto'
import { copy } from '../common/Pasteboard'

@Builder
export function KeyBuilder() {
  Keypage()
}

@ComponentV2
struct Keypage {
  @Local keyValue: string = ''
  context = getContext(this) as common.UIAbilityContext
  pageInfos: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      List() {
        if (this.keyValue) {
          ListItem() {
            Column() {
              Row() {
                Text('密钥')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(this.keyValue)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
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
                copy(this.keyValue)
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
        ListItem() {
          Column() {
            Row() {
              Text('导入')
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontWeight('medium')
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
            .onClick(async () => {
              if (!this.keyValue) {
                const data = await promptAction.showActionMenu({
                  title: '选择导入方式',
                  buttons: [
                    {
                      text: '随机',
                      color: $r('sys.color.font_primary')
                    },
                    {
                      text: '自定义',
                      color: $r('sys.color.font_primary')
                    }
                  ]
                })
                if (data.index === 0) {
                  await setRandomKey()
                  promptAction.showToast({
                    message: '导入成功'
                  })
                  this.keyValue = getKey()
                }
                if (data.index === 1) {
                  this.pageInfos.pushPath({
                    name: 'Importkey'
                  })
                }
              } else {
                const confirm = await promptAction.showDialog({
                  title: '提示',
                  message: '导入成功后新密钥将覆盖当前密钥，当前密钥无法恢复，需重新导入当前密钥才可解密使用当前密钥加密的云备份数据，确定导入？',
                  buttons: [
                    {
                      text: '取消',
                      color: $r('sys.color.font_primary')
                    },
                    {
                      text: '导入',
                      color: $r('sys.color.font_emphasize')
                    }
                  ]
                })
                if (confirm.index === 1) {
                  const data = await promptAction.showActionMenu({
                    title: '选择导入方式',
                    buttons: [
                      {
                        text: '随机',
                        color: $r('sys.color.font_primary')
                      },
                      {
                        text: '自定义',
                        color: $r('sys.color.font_primary')
                      }
                    ]
                  })
                  if (data.index === 0) {
                    await setRandomKey()
                    promptAction.showToast({
                      message: '导入成功'
                    })
                    this.keyValue = getKey()
                  }
                  if (data.index === 1) {
                    this.pageInfos.pushPath({
                      name: 'Importkey'
                    })
                  }
                }
              }
            })

            if (this.keyValue) {
              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('删除')
                  .fontColor($r('sys.color.warning'))
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
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
              .onClick(async () => {
                const data = await promptAction.showDialog({
                  title: '提示',
                  message: '删除成功后无法恢复，需重新导入此密钥才可解密使用此密钥加密的云备份数据，确定删除？',
                  buttons: [
                    {
                      text: '取消',
                      color: $r('sys.color.font_primary')
                    },
                    {
                      text: '删除',
                      color: $r('sys.color.warning')
                    }
                  ]
                })
                if (data.index === 1) {
                  await removeKey()
                  promptAction.showToast({
                    message: '删除成功'
                  })
                  this.keyValue = getKey()
                }
              })
            }
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
    .title('密钥')
    .onReady((context: NavDestinationContext) => {
      this.pageInfos = context.pathStack
      this.keyValue = getKey()
    })
    .onShown(async () => {
      const lastWindow = await window.getLastWindow(this.context)
      await lastWindow.setWindowPrivacyMode(true)
    })
    .onHidden(async () => {
      const lastWindow = await window.getLastWindow(this.context)
      await lastWindow.setWindowPrivacyMode(false)
    })
  }
}