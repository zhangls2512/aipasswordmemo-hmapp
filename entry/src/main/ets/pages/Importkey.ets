import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { LengthMetrics, promptAction, window } from '@kit.ArkUI'
import { hdsMaterial, HdsNavDestination } from '@kit.UIDesignKit'
import { importOldCustomKey } from '../common/Crypto'

@Builder
export function ImportkeyBuilder() {
  Importkey()
}

@ComponentV2
struct Importkey {
  @Local keyValue: string = ''
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()

  build() {
    HdsNavDestination() {
      List() {
        ListItem() {
          Column() {
            TextArea({
              placeholder: '请输入Base64编码、长度44的AES256密钥',
              text: this.keyValue!!
            })
              .defaultFocus(true)
              .enableAutoSpacing(true)
              .maxLength(44)
              .showCounter(true)
            Button('导入')
              .enabled(this.keyValue.length === 44 ? true : false)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })
              .width('100%')
              .onClick(async () => {
                try {
                  await importOldCustomKey(this.keyValue)
                  this.pageInfos.pop()
                  this.context.eventHub.emit('refreshKey')
                } catch (err) {
                  await promptAction.openToast({
                    message: '导入失败，原因：密钥格式不正确（错误码：' + err.code + '，错误信息：' + err.message + '）'
                  })
                }
              })
          }
          .width('100%')
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
      padding: {
        end: LengthMetrics.vp(60)
      },
      style: {
        thermoCtrl: true,
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.ADAPTIVE,
          materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
        }
      },
      content: {
        title: {
          mainTitle: '导入自定义密钥'
        }
      },
      enableComponentSafeArea: true
    })
    .onReady((context) => {
      this.pageInfos = context.pathStack
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