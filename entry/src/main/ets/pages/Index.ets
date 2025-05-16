import { window } from '@kit.ArkUI'
import Password from './Password'
import Info from './Info'
import Aihelper from './Aihelper'
import Tag from './Tag'
import Me from './Me'

@Entry
@ComponentV2
struct Index {
  @Local index: number = 0
  @Local title: string = '密码'
  context = getContext(this)

  @Builder
  tabBuilder(index: number, image: Resource, title: string) {
    Column() {
      Image(image)
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
    Column() {
      Text(this.title)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({
          bottom: $r('sys.float.ohos_id_elements_margin_vertical_l'),
          left: $r('sys.float.ohos_id_default_padding_start')
        })
      Tabs({
        barPosition: BarPosition.End,
        index: $$this.index
      }) {
        TabContent() {
          Password()
            .height('100%')
        }
        .tabBar(this.tabBuilder(0, $r('app.media.password'), '密码'))

        TabContent() {
          Info()
            .height('100%')
        }
        .tabBar(this.tabBuilder(1, $r('app.media.info'), '常用信息'))

        TabContent() {
          Aihelper()
            .height('100%')
        }
        .tabBar(this.tabBuilder(2, $r('app.media.microphone'), 'AI 助手'))

        TabContent() {
          Tag()
            .height('100%')
        }
        .tabBar(this.tabBuilder(3, $r('app.media.tag'), '标签'))

        TabContent() {
          Me()
            .height('100%')
        }
        .tabBar(this.tabBuilder(4, $r('app.media.me'), '我的'))
      }
      .scrollable(false)
      .onAnimationStart(async (index: number, targetIndex: number) => {
        if (targetIndex !== 1) {
          const lastWindow = await window.getLastWindow(this.context)
          await lastWindow.setWindowPrivacyMode(false)
        }
        if (targetIndex === 0) {
          this.title = '密码'
          this.context.eventHub.emit('refreshPassword')
        }
        if (targetIndex === 1) {
          const lastWindow = await window.getLastWindow(this.context)
          await lastWindow.setWindowPrivacyMode(true)
          this.title = '常用信息'
          this.context.eventHub.emit('refreshInfo')
        }
        if (targetIndex === 2) {
          this.title = 'AI 助手'
        }
        if (targetIndex === 3) {
          this.title = '标签'
          this.context.eventHub.emit('refreshTag')
        }
        if (targetIndex === 4) {
          this.title = '我的'
          this.context.eventHub.emit('refreshMe')
        }
      })
    }
    .alignItems(HorizontalAlign.Start)
    .backgroundColor($r('sys.color.background_secondary'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .padding({
      bottom: 36,
      top: 12
    })
  }
}