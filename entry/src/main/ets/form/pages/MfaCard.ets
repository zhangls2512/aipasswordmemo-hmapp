import { MfaItem } from '../../entryformability/EntryFormAbility'

@Entry(new LocalStorage())
@Component
struct MfaCard {
  @LocalStorageProp('mfaArray') mfaArray: MfaItem[] = []

  build() {
    Column() {
      Button('刷新')
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
        .onClick(() => {
          postCardAction(this, {
            action: 'message',
            params: {
              action: 'refresh'
            }
          })
        })
      if (this.mfaArray.length === 0) {
        Text('无数据')
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_l')
          })
      }
      GridRow({
        columns: 2,
        gutter: {
          x: $r('sys.float.ohos_id_elements_margin_horizontal_m'),
          y: $r('sys.float.ohos_id_elements_margin_vertical_m')
        }
      }) {
        ForEach(this.mfaArray, (item: MfaItem) => {
          GridCol() {
            Row() {
              Text(item.name)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                })
              Text(item.value)
            }
          }
        })
      }
      .layoutWeight(1)
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })
    }
    .padding({
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
    })
  }
}