import { common } from '@kit.AbilityKit'
import { window } from '@kit.ArkUI'
import Password from './Password'
import Info from './Info'
import Tag from './Tag'
import Me from './Me'

@Entry
@ComponentV2
struct Index {
  @Local index: number = 0
  @Local title: string = '密码'
  context = getContext(this) as common.UIAbilityContext

  @Builder
  tabBuilder(title: string, index: number, img: Resource) {
    Column() {
      Image(img)
        .fillColor(this.index !== index ? $r('sys.color.icon_secondary') : $r('sys.color.icon_emphasize'))
        .height(24)
        .width(24)
      Text(title)
        .fontColor(this.index === index ? $r('sys.color.font_emphasize') : '')
        .fontSize($r('sys.float.ohos_id_text_size_body3'))
        .margin({
          top: 4
        })
    }
  }

  build() {
    Navigation() {
      Tabs({
        barPosition: BarPosition.End,
        index: $$this.index
      }) {
        TabContent() {
          Password()
            .height('100%')
        }
        .tabBar(this.tabBuilder('密码', 0, $r('app.media.password')))

        TabContent() {
          Info()
            .height('100%')
        }
        .tabBar(this.tabBuilder('常用信息', 1, $r('app.media.info')))

        TabContent() {
          Tag()
            .height('100%')
        }
        .tabBar(this.tabBuilder('标签', 2, $r('app.media.tag')))

        TabContent() {
          Me()
            .height('100%')
        }
        .tabBar(this.tabBuilder('我的', 3, $r('app.media.me')))
      }
      .scrollable(false)
      .onAnimationStart(async (index: number, targetIndex: number) => {
        if (targetIndex !== 1) {
          const lastWindow = await window.getLastWindow(this.context)
          await lastWindow.setWindowPrivacyMode(false)
        }
        if (targetIndex === 0) {
          this.title = '密码'
        }
        if (targetIndex === 1) {
          const lastWindow = await window.getLastWindow(this.context)
          await lastWindow.setWindowPrivacyMode(true)
          this.title = '常用信息'
        }
        if (targetIndex === 2) {
          this.title = '标签'
        }
        if (targetIndex === 3) {
          this.title = '我的'
        }
      })
    }
    .backgroundColor($r('sys.color.background_secondary'))
    .hideBackButton(true)
    .title(this.title)
    .titleMode(NavigationTitleMode.Mini)
  }
}