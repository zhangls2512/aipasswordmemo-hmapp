import Password from './Password'
import Info from './Info'
import Tag from './Tag'
import Me from './Me'

@Entry
@ComponentV2
struct Index {
  @Local name: string = 'password'
  @Local title: string = '密码'

  build() {
    Navigation() {
      if (this.name === 'password') {
        Password()
      }
      if (this.name === 'info') {
        Info()
      }
      if (this.name === 'tag') {
        Tag()
      }
      if (this.name === 'me') {
        Me()
      }
    }
    .backgroundColor($r('sys.color.background_secondary'))
    .hideBackButton(true)
    .title(this.title)
    .titleMode(NavigationTitleMode.Mini)
    .toolbarConfiguration([
      {
        value: '密码',
        icon: $r('app.media.password'),
        action: (() => {
          this.name = 'password'
          this.title = '密码'
        }),
        status: this.name === 'password' ? ToolbarItemStatus.ACTIVE : ToolbarItemStatus.NORMAL,
        activeIcon: $r('app.media.passwordselected')
      },
      {
        value: '常用信息',
        icon: $r('app.media.info'),
        action: (() => {
          this.name = 'info'
          this.title = '常用信息'
        }),
        status: this.name === 'info' ? ToolbarItemStatus.ACTIVE : ToolbarItemStatus.NORMAL,
        activeIcon: $r('app.media.infoselected')
      },
      {
        value: '标签',
        icon: $r('app.media.tag'),
        action: (() => {
          this.name = 'tag'
          this.title = '标签'
        }),
        status: this.name === 'tag' ? ToolbarItemStatus.ACTIVE : ToolbarItemStatus.NORMAL,
        activeIcon: $r('app.media.tagselected')
      },
      {
        value: '我的',
        icon: $r('app.media.me'),
        action: (() => {
          this.name = 'me'
          this.title = '我的'
        }),
        status: this.name === 'me' ? ToolbarItemStatus.ACTIVE : ToolbarItemStatus.NORMAL,
        activeIcon: $r('app.media.meselected')
      }
    ])
  }
}