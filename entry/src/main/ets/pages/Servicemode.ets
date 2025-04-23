import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { AppStorageV2 } from '@kit.ArkUI'
import openLink from '../common/Openlink'
import { AllService } from './Setting'

@Builder
export function ServicemodeBuilder() {
  Servicemode()
}

@ComponentV2
struct Servicemode {
  @Local AllService: AllService = AppStorageV2.connect(AllService, () => new AllService())!
  context = getContext(this) as common.UIAbilityContext
  commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'commonSetting'
  })

  getSetting() {
    const allService: preferences.ValueType =
      this.commonSettingDataPreferences.getSync('allService', true)
    this.AllService.allService = allService as boolean
  }

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Column() {
              Row() {
                Text('全量模式')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.AllService.allService
                })
                  .enabled(!this.AllService.allService)
                  .onChange((isOn: boolean) => {
                    this.AllService.allService = isOn
                    this.commonSettingDataPreferences.putSync('allService', isOn)
                    this.commonSettingDataPreferences.flushSync()
                  })
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))

            Text() {
              Span('全量模式下，本应用需联网，除可使用记录密码等离线功能外，还可使用账号登录、云备份、自动上传故障日志等在线功能。我们仅在您使用具体业务功能时，才会触发上述行为收集使用相关的个人信息。详情请参阅')
                .fontColor($r('sys.color.font_secondary'))
              Span('关于轩铭密码智能备忘录与隐私的声明')
                .fontColor($r('sys.color.font_emphasize'))
                .fontWeight('medium')
                .onClick(() => {
                  openLink('https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=1657460888438843904')
                })
              Span('。开启开关，即表示您知悉并同意我们向您提供本应用服务。')
                .fontColor($r('sys.color.font_secondary'))
            }
            .fontSize($r('sys.float.ohos_id_text_size_body3'))
            .margin({
              top: 6,
              left: $r('sys.float.ohos_id_corner_radius_default_m'),
              right: $r('sys.float.ohos_id_corner_radius_default_m')
            })
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Column() {
              Row() {
                Text('基本模式')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: !this.AllService.allService
                })
                  .enabled(this.AllService.allService)
                  .onChange((isOn: boolean) => {
                    this.AllService.allService = !isOn
                    this.commonSettingDataPreferences.putSync('allService', !isOn)
                    this.commonSettingDataPreferences.flushSync()
                  })
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))

            Text('基本模式下，本应用无需联网，可使用记录密码等离线功能。此模式下无法使用账号登录、云备份、自动上传故障日志等在线功能。')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body3'))
              .margin({
                top: 6,
                left: $r('sys.float.ohos_id_corner_radius_default_m'),
                right: $r('sys.float.ohos_id_corner_radius_default_m')
              })
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
    .title('应用服务模式')
    .onReady(() => {
      this.getSetting()
    })
  }
}