@Builder
export function KeyBuilder() {
  Key()
}

@ComponentV2
export struct Key {
  build() {
    NavDestination() {
      List() {
        ListItem() {
          Text('开发中')
        }
      }
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title('密钥')
  }
}