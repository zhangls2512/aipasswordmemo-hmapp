import Password from './Password'
import Info from './Info'
import Property from './Property'
import Me from './Me'

@Entry
@Component
struct Index {
  @StorageProp('bottomRectHeight')
  bottomRectHeight: number = 0
  @StorageProp('topRectHeight')
  topRectHeight: number = 0
  @State selectedIndex: number = 0
  private tabsController: TabsController = new TabsController()

  @Builder
  tabBuilder(index: number, name: string, selectedImg: Resource, unselectedImg: Resource) {
    Column() {
      Image(this.selectedIndex === index ? selectedImg : unselectedImg)
        .fillColor(this.selectedIndex === index ? $r('sys.color.icon_emphasize') : $r('sys.color.icon_tertiary'))
        .height(24)
        .width(24)
      Text(name)
        .fontColor(this.selectedIndex === index ? $r('sys.color.brand') : $r('sys.color.font_secondary'))
        .fontSize(12)
        .margin({
          top: 4
        })
    }
    .onClick(() => {
      this.selectedIndex = index
      this.tabsController.changeIndex(this.selectedIndex)
    })
  }

  @Builder
  tabContentBuilder(index: number, name: string, selectedImg: Resource, unselectedImg: Resource) {
    TabContent() {
      Column() {
        if (this.selectedIndex === 0) {
          Password()
        }
        if (this.selectedIndex === 1) {
          Info()
        }
        if (this.selectedIndex === 2) {
          Property()
        }
        if (this.selectedIndex === 3) {
          Me()
        }
      }
    }
    .tabBar(this.tabBuilder(index, name, selectedImg, unselectedImg))
  }

  build() {
    Tabs({
      barPosition: BarPosition.End,
      controller: this.tabsController
    }) {
      this.tabContentBuilder(0, '密码', $r('app.media.passwordselected'), $r('app.media.password'))
      this.tabContentBuilder(1, '信息', $r('app.media.infoselected'), $r('app.media.info'))
      this.tabContentBuilder(2, '属性', $r('app.media.propertyselected'), $r('app.media.property'))
      this.tabContentBuilder(3, '我的', $r('app.media.meselected'), $r('app.media.me'))
    }
    .backgroundColor($r('sys.color.comp_background_tertiary'))
    .padding({
      bottom: px2vp(this.bottomRectHeight),
      top: px2vp(this.topRectHeight)
    })
    .onAnimationStart((index: number, targetIndex: number) => {
      this.selectedIndex = targetIndex
    })
  }
}