import { appRecovery } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'

@Builder
export function RecoverysettingBuilder() {
  Recoverysetting()
}

@ComponentV2
struct Recoverysetting {
  pageInfos: NavPathStack = new NavPathStack()
  restart: appRecovery.RestartFlag = appRecovery.RestartFlag.RESTART_WHEN_APP_FREEZE
  saveOccasion: appRecovery.SaveOccasionFlag = appRecovery.SaveOccasionFlag.SAVE_WHEN_ERROR
  saveMode: appRecovery.SaveModeFlag = appRecovery.SaveModeFlag.SAVE_WITH_FILE

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Column() {
              Row() {
                Text('重启时机')
                  .fontWeight('medium')
                Blank()
                Select([
                  { value: '总是' },
                  { value: 'JS_CRASH' },
                  { value: 'APP_FREEZE' },
                  { value: '总不' }
                ])
                  .selected(2)
                  .value('APP_FREEZE')
                  .onSelect((index: number) => {
                    if (index === 0) {
                      this.restart = appRecovery.RestartFlag.ALWAYS_RESTART
                    }
                    if (index === 1) {
                      this.restart = appRecovery.RestartFlag.RESTART_WHEN_JS_CRASH
                    }
                    if (index === 2) {
                      this.restart = appRecovery.RestartFlag.RESTART_WHEN_APP_FREEZE
                    }
                    if (index === 3) {
                      this.restart = appRecovery.RestartFlag.NO_RESTART
                    }
                  })
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
                Text('状态保存时机')
                  .fontWeight('medium')
                Blank()
                Select([
                  { value: '发生故障' },
                  { value: '切入后台' }
                ])
                  .selected(0)
                  .value('发生故障')
                  .onSelect((index: number) => {
                    if (index === 0) {
                      this.saveOccasion = appRecovery.SaveOccasionFlag.SAVE_WHEN_ERROR
                    }
                    if (index === 1) {
                      this.saveOccasion = appRecovery.SaveOccasionFlag.SAVE_WHEN_BACKGROUND
                    }
                  })
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
                Text('状态保存方式')
                  .fontWeight('medium')
                Blank()
                Select([
                  { value: '写入到本地文件缓存' },
                  { value: '先保存在内存中，故障退出时写入到本地文件缓存' }
                ])
                  .selected(0)
                  .value('写入到本地文件缓存')
                  .onSelect((index: number) => {
                    if (index === 0) {
                      this.saveMode = appRecovery.SaveModeFlag.SAVE_WITH_FILE
                    }
                    if (index === 1) {
                      this.saveMode = appRecovery.SaveModeFlag.SAVE_WITH_SHARED_MEMORY
                    }
                  })
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))

            Button('保存')
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })
              .onClick(() => {
                appRecovery.enableAppRecovery(this.restart, this.saveOccasion, this.saveMode)
                promptAction.showToast({
                  message: '保存成功'
                })
                this.pageInfos.pop()
              })
          }
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
    .title('应用恢复设置')
    .onReady((context: NavDestinationContext) => {
      this.pageInfos = context.pathStack
    })
  }
}