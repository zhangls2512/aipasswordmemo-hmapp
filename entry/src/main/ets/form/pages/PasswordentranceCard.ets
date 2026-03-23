@Entry
@Component
struct PasswordentranceCard {
  build() {
    Row() {
      Column() {
        Image($r('app.media.new_form'))
          .height('50%')
        Text('新增密码')
          .fontColor($r('sys.color.font_secondary'))
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontWeight(FontWeight.Medium)
          .height('30%')
      }
      .width('50%')
      .onClick(() => {
        postCardAction(this, {
          action: 'router',
          abilityName: 'EntryAbility',
          params: {
            shortcutId: 'newPassword'
          }
        })
      })

      Column() {
        Image($r('app.media.search_form'))
          .height('50%')
        Text('搜索密码')
          .fontColor($r('sys.color.font_secondary'))
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontWeight(FontWeight.Medium)
          .height('30%')
      }
      .width('50%')
      .onClick(() => {
        postCardAction(this, {
          action: 'router',
          abilityName: 'EntryAbility',
          params: {
            shortcutId: 'searchPassword'
          }
        })
      })
    }
    .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
    .height('100%')
  }
}