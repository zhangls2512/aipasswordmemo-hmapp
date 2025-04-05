import { AppStorageV2 } from '@kit.ArkUI'
import Setting from './Setting'

export class TitleBar {
  hide: boolean = false
}

@ComponentV2
export default struct Me {
  @Local isShowSheet: boolean = false
  titleBar: TitleBar = AppStorageV2.connect(TitleBar, () => new TitleBar())!

  @Builder
  SheetBuilder() {
    Setting()
      .onDisAppear(() => {
        this.titleBar.hide = false
      })
  }

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Row() {
              Image($r('app.media.setting'))
                .fillColor($r('sys.color.icon_primary'))
                .height(24)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .width(24)
              Text('设置')
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
                .backgroundColor($r('sys.color.comp_background_primary'))
              },
              pressed: {
                .backgroundColor($r('sys.color.comp_background_secondary'))
              }
            })
            .width('100%')
            .onClick(() => {
              this.isShowSheet = !this.isShowSheet
            })
            .bindSheet($$this.isShowSheet, this.SheetBuilder(), {
              preferType: SheetType.BOTTOM
            })
          }
          .backgroundColor($r('sys.color.comp_background_primary'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })
      }
      .padding({
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
    }
    .backgroundColor($r('sys.color.background_secondary'))
  }
}