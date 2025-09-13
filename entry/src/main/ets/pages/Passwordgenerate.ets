import copy from '../common/Pasteboard'

@ComponentV2
export default struct Passwordgenerate {
  @Local length: number = 16
  @Local digit: boolean = true
  @Local lowercaseLetter: boolean = true
  @Local uppercaseLetter: boolean = true
  @Local specialCharacter: boolean = false
  @Local password: string = ''

  build() {
    List() {
      ListItem() {
        Column() {
          Row() {
            Text('长度')
              .fontWeight(FontWeight.Medium)
            Blank()
            Counter() {
              Text(String(this.length))
            }
            .enableDec(this.length > 4)
            .enableInc(this.length < 32)
            .onInc(() => {
              this.length++
            })
            .onDec(() => {
              this.length--
            })
          }
          .borderRadius(12)
          .padding(12)
          .width('100%')

          Divider()
            .padding({
              left: 12,
              right: 12
            })
          Row() {
            Text('数字')
              .fontWeight(FontWeight.Medium)
            Blank()
            Toggle({
              type: ToggleType.Switch,
              isOn: this.digit!!
            })
          }
          .borderRadius(12)
          .padding(12)
          .width('100%')

          Divider()
            .padding({
              left: 12,
              right: 12
            })
          Row() {
            Text('小写字母')
              .fontWeight(FontWeight.Medium)
            Blank()
            Toggle({
              type: ToggleType.Switch,
              isOn: this.lowercaseLetter!!
            })
          }
          .borderRadius(12)
          .padding(12)
          .width('100%')

          Divider()
            .padding({
              left: 12,
              right: 12
            })
          Row() {
            Text('大写字母')
              .fontWeight(FontWeight.Medium)
            Blank()
            Toggle({
              type: ToggleType.Switch,
              isOn: this.uppercaseLetter!!
            })
          }
          .borderRadius(12)
          .padding(12)
          .width('100%')

          Divider()
            .padding({
              left: 12,
              right: 12
            })
          Row() {
            Text('特殊符号')
              .fontWeight(FontWeight.Medium)
            Blank()
            Toggle({
              type: ToggleType.Switch,
              isOn: this.specialCharacter!!
            })
          }
          .borderRadius(12)
          .padding(12)
          .width('100%')
        }
        .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
        .padding($r('sys.float.ohos_id_corner_radius_mark'))
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_m')
      })

      ListItem() {
        Column() {
          Button('生成')
            .enabled(this.digit || this.lowercaseLetter || this.uppercaseLetter || this.specialCharacter)
            .onClick(() => {
              const allowCharacters: string[] = []
              if (this.digit) {
                allowCharacters.push('0123456789')
              }
              if (this.lowercaseLetter) {
                allowCharacters.push('abcdefghijklmnopqrstuvwxyz')
              }
              if (this.uppercaseLetter) {
                allowCharacters.push('ABCDEFGHIJKLMNOPQRSTUVWXYZ')
              }
              if (this.specialCharacter) {
                allowCharacters.push('!@#$%^&*()_+-=[]{}|;:,.<>?')
              }
              const typeCount = allowCharacters.length
              const baseCount = Math.floor(this.length / typeCount)
              const remainCount = this.length % typeCount
              const characterPool: string[] = []
              for (let i = 0; i < typeCount; i++) {
                const currentType = allowCharacters[i]
                const count = i === typeCount - 1 ? baseCount + remainCount : baseCount
                for (let j = 0; j < count; j++) {
                  const randomIndex = Math.floor(Math.random() * currentType.length)
                  characterPool.push(currentType[randomIndex])
                }
              }
              for (let i = characterPool.length - 1; i > 0; i--) {
                const j = Math.floor(Math.random() * (i + 1))
                const temp = characterPool[i]
                characterPool[i] = characterPool[j]
                characterPool[j] = temp
              }
              this.password = characterPool.join('')
            })
        }
        .width('100%')
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      if (this.password) {
        ListItem() {
          Column() {
            Row() {
              Text(this.password)
            }
            .borderRadius(12)
            .padding(12)
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .width('100%')
            .onClick(() => {
              copy(this.password)
            })
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })
      }
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_max_padding_start'),
      right: $r('sys.float.ohos_id_max_padding_end')
    })
  }
}