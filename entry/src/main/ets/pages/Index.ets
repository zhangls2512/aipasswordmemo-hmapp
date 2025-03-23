@Entry
@Component
struct Index {
  @State message: string = '轩铭密码智能备忘录'
  build() {
    Text(this.message)
      .onClick(() => {
        this.message = '开发者：张轩铭'
      })
  }
}