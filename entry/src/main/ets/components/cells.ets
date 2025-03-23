interface SettingItem {
  image: string,
  name: string
}

@Component
export default struct Cells {
  @State startText: string = ''
  @State endText: string = ''
  @State settingItems: Array<SettingItem> = []

  build() {
    Column() {
      Text(this.startText)
        .fontColor($r('sys.color.font_secondary'))
        .margin({
          bottom: 10,
          left: 15
        })
      Column() {
        ForEach(this.settingItems, (item: SettingItem, index) => {
          if (index !== 0) {
            Divider()
              .padding({
                left: 15,
                right: 15
              })
          }
          Row() {
            Image($r(item.image))
              .fillColor($r('sys.color.icon_primary'))
              .height(24)
              .width(24)
              .margin({
                right: 5
              })
            Text(item.name)
              .fontWeight('bold')
            Blank()
            Image($r('app.media.right'))
              .fillColor($r('sys.color.icon_tertiary'))
              .height(12)
              .width(12)
          }
          .borderRadius(15)
          .height(48)
          .padding(15)
          .stateStyles({
            normal: {
              .backgroundColor($r('sys.color.comp_background_primary'))
            },
            pressed: {
              .backgroundColor($r('sys.color.comp_background_secondary'))
            }
          })
          .width('100%')
        })
      }
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(15)
      .width('100%')

      Text(this.endText)
        .fontColor($r('sys.color.font_secondary'))
        .margin({
          top: 10,
          left: 15
        })
        .align(Alignment.Start)
    }
    .alignItems(HorizontalAlign.Start)
    .padding(20)
    .width('100%')
  }
}