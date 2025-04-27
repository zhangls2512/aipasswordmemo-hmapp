import { getOtp } from '../common/Totp'

@ComponentV2
export default struct Password {
  @Local value: string = ''
  @Local secondsRemaining: string = ''

  build() {
    Column() {
      Text('TOTP 测试')
      Text('当前值：' + this.value)
      Text('剩余秒数：' + this.secondsRemaining)
    }
    .onAppear(() => {
      const key = 'PNNDCOJUKV2FUVSHHARVEYKRPF6TSY2AGRFFI6DXJMWGC2D5FFIQ'
      setInterval(() => {
        const res = getOtp(key, 30, 6)
        this.value = res.value
        this.secondsRemaining = res.secondsRemaining
      }, 500)
    })
  }
}