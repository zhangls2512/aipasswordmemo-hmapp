import { common } from '@kit.AbilityKit'
import { relationalStore } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { BusinessError } from '@kit.BasicServicesKit'

@Builder
export function DataBackupRecoveryBuilder() {
  DataBackupRecovery()
}

@ComponentV2
struct DataBackupRecovery {
  context = getContext(this) as common.UIAbilityContext

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Text('备份')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: $r('sys.float.ohos_id_corner_radius_default_m')
              })
            Column() {
              Row() {
                Text('密码')
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
                try {
                  const rdbStore = await relationalStore.getRdbStore(this.context, {
                    name: 'password',
                    securityLevel: 4,
                    encrypt: true,
                    allowRebuild: true
                  })
                  await rdbStore.backup('passwordBackup.db')
                  promptAction.showToast({
                    message: '备份成功'
                  })
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
                Text('常用信息')
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
                try {
                  const rdbStore = await relationalStore.getRdbStore(this.context, {
                    name: 'info',
                    securityLevel: 4,
                    encrypt: true,
                    allowRebuild: true
                  })
                  await rdbStore.backup('infoBackup.db')
                  promptAction.showToast({
                    message: '备份成功'
                  })
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
                Text('标签')
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
                try {
                  const rdbStore = await relationalStore.getRdbStore(this.context, {
                    name: 'tag',
                    securityLevel: 1,
                    encrypt: true,
                    allowRebuild: true
                  })
                  await rdbStore.backup('tagBackup.db')
                  promptAction.showToast({
                    message: '备份成功'
                  })
                } catch (err) {
                  promptAction.showToast({
                    message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
                    (err as BusinessError).message
                  })
                }
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

        ListItem() {
          Column() {
            Text('恢复')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: $r('sys.float.ohos_id_corner_radius_default_m')
              })
            Column() {
              Row() {
                Text('密码')
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
                try {
                  const rdbStore = await relationalStore.getRdbStore(this.context, {
                    name: 'password',
                    securityLevel: 4,
                    encrypt: true,
                    allowRebuild: true
                  })
                  await rdbStore.restore('passwordBackup.db')
                  promptAction.showToast({
                    message: '恢复成功'
                  })
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
                Text('常用信息')
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
                try {
                  const rdbStore = await relationalStore.getRdbStore(this.context, {
                    name: 'info',
                    securityLevel: 4,
                    encrypt: true,
                    allowRebuild: true
                  })
                  await rdbStore.restore('infoBackup.db')
                  promptAction.showToast({
                    message: '恢复成功'
                  })
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
                Text('标签')
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
                try {
                  const rdbStore = await relationalStore.getRdbStore(this.context, {
                    name: 'tag',
                    securityLevel: 1,
                    encrypt: true,
                    allowRebuild: true
                  })
                  await rdbStore.restore('tagBackup.db')
                  promptAction.showToast({
                    message: '恢复成功'
                  })
                } catch (err) {
                  promptAction.showToast({
                    message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
                    (err as BusinessError).message
                  })
                }
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
    .title('数据备份与恢复')
  }
}