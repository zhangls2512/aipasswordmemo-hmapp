@ComponentV2
export default struct Password {
  build() {
    Button('触发崩溃事件')
      .onClick(() => {
        const result: object = JSON.parse('')
        return result
      })
  }
}