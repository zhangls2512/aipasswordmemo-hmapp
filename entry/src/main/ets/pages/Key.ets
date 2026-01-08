import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { window } from '@kit.ArkUI'
import { HdsNavDestination } from '@kit.UIDesignKit'
import { getKey, removeKey, setRandomKey } from '../common/Crypto'
import copy from '../common/Pasteboard'

@Builder
export function KeyBuilder() {
  Keypage()
}

@ComponentV2
struct Keypage {
  @Local keyValue: string = ''
  @Local hoverId: number = -1
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()

  build() {
    HdsNavDestination() {
      List() {
        if (this.keyValue) {
          ListItem() {
            Column() {
              Column() {
                Row() {
                  Text('密钥')
                    .fontWeight(FontWeight.Medium)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                  Text(this.keyValue)
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .layoutWeight(1)
                    .textAlign(TextAlign.End)
                }
                .borderRadius(12)
                .padding(12)
                .stateStyles({
                  normal: {
                    .backgroundColor(this.hoverId === 0 ? $r('sys.color.interactive_hover') :
                      $r('sys.color.ohos_id_color_card_bg'))
                  },
                  pressed: {
                    .backgroundColor($r('sys.color.interactive_pressed'))
                  }
                })
                .width('100%')
                .onHover((isHover) => {
                  if (!isHover) {
                    this.hoverId = -1
                  }
                  if (isHover) {
                    this.hoverId = 0
                  }
                })
                .onClick(async () => {
                  await copy(this.context, this.UIContext, this.keyValue)
                })
              }
              .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
              .padding($r('sys.float.ohos_id_corner_radius_mark'))

              Text('建议点击上方密钥内容将其复制到剪贴板并妥善备份，防止其丢失导致无法解密使用其加密的云备份数据。')
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body3'))
                .margin({
                  top: 6,
                  left: 12,
                  right: 12
                })
            }
            .alignItems(HorizontalAlign.Start)
          }
          .margin({
            bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
        }
        ListItem() {
          Column() {
            Row() {
              Text('导入')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
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
                .backgroundColor(this.hoverId === 1 ? $r('sys.color.interactive_hover') :
                  $r('sys.color.ohos_id_color_card_bg'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .width('100%')
            .onHover((isHover) => {
              if (!isHover) {
                this.hoverId = -1
              }
              if (isHover) {
                this.hoverId = 1
              }
            })
            .onClick(async () => {
              if (!this.keyValue) {
                const promptAction = this.UIContext.getPromptAction()
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
                  this.keyValue = getKey()
                }
                if (data.index === 1) {
                  this.pageInfos.pushPath({
                    name: 'Importkey'
                  })
                }
                return
              }
              if (this.keyValue) {
                const promptAction = this.UIContext.getPromptAction()
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
                  const promptAction = this.UIContext.getPromptAction()
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
                  left: 12,
                  right: 12
                })
              Row() {
                Text('删除')
                  .fontColor($r('sys.color.warning'))
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
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
                  .backgroundColor(this.hoverId === 2 ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onHover((isHover) => {
                if (!isHover) {
                  this.hoverId = -1
                }
                if (isHover) {
                  this.hoverId = 2
                }
              })
              .onClick(async () => {
                const promptAction = this.UIContext.getPromptAction()
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
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
      }
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
        right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .titleBar({
      content: {
        title: {
          mainTitle: '密钥'
        }
      },
      enableComponentSafeArea: true
    })
    .onReady((context) => {
      this.pageInfos = context.pathStack
      this.keyValue = getKey()
      this.context.eventHub.on('refreshKey', () => {
        this.keyValue = getKey()
      })
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshKey')
    })
    .onShown(async () => {
      const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
        name: 'commonSetting'
      })
      const disallowScreenshot = commonSettingDataPreferences.getSync('disallowScreenshot', true) as boolean
      if (disallowScreenshot) {
        const lastWindow = await window.getLastWindow(this.context)
        await lastWindow.setWindowPrivacyMode(true)
      }
    })
    .onHidden(async () => {
      const lastWindow = await window.getLastWindow(this.context)
      await lastWindow.setWindowPrivacyMode(false)
    })
  }
}