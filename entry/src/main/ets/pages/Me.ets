import Cells from '../components/cells'

@Component
export default struct Me {
  build() {
    Column() {
      Cells({
        settingItems: [
          {
            image: 'app.media.setting',
            name: '设置'
          }
        ]
      })
    }
    .height('100%')
  }
}