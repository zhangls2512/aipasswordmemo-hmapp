@Entry
@Component
struct PasswordentranceCard {
  build() {
    Row() {
      Image($r('app.media.new_form'))
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
      Image($r('app.media.search_form'))
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
  }
}