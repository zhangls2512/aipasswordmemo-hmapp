import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { uri } from '@kit.ArkTS'
import { display, window } from '@kit.ArkUI'
import { fileIo } from '@kit.CoreFileKit'
import { image } from '@kit.ImageKit'
import { get } from '../common/Accesstoken'
import { importCsvPassword } from '../common/Csv'
import { importInfo, importPassword, importTag } from '../common/Dataimport'
import getDeviceToken from '../common/Devicetoken'
import { read } from '../common/File'
import request from '../common/Request'
import Password from './Password'
import Info from './Info'
import Tag from './Tag'
import Me from './Me'
import Cleardata from './Cleardata'

@Entry
@ComponentV2
struct Index {
  @Local backgroundImagePixelMap: PixelMap | undefined = undefined
  @Local preferType: number = 1
  @Local index: number = 0
  @Local title: string = '密码'
  @Local isShowCleardataSheet: boolean = false
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext

  getBackgroundImage() {
    const backgroundImagePath = this.context.filesDir + '/media/backgroundimage.png'
    const res = fileIo.accessSync(backgroundImagePath)
    if (res) {
      const backgroundImageSource = image.createImageSource(backgroundImagePath)
      return backgroundImageSource.createPixelMapSync()
    }
    return
  }

  @Builder
  tabBuilder(index: number, image: Resource, title: string) {
    Column() {
      Image(image)
        .fillColor(this.index === index ? $r('sys.color.icon_emphasize') : $r('sys.color.icon_secondary'))
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

  @Builder
  CleardataSheetBuilder() {
    Cleardata()
  }

  build() {
    Column() {
      if (this.preferType === 0) {
        Text(this.title)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({
            bottom: $r('sys.float.ohos_id_elements_margin_vertical_l'),
            left: $r('sys.float.ohos_id_default_padding_start')
          })
      }
      Tabs({
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
          Tag()
            .height('100%')
        }
        .tabBar(this.tabBuilder(2, $r('app.media.tag'), '标签'))

        TabContent() {
          Me()
            .height('100%')
        }
        .tabBar(this.tabBuilder(3, $r('app.media.me'), '我的'))
      }
      .barBackgroundBlurStyle(BlurStyle.Regular)
      .barPosition(this.preferType === 0 ? BarPosition.End : BarPosition.Start)
      .scrollable(false)
      .vertical(this.preferType === 0 ? false : true)
      .onAnimationStart(async (index, targetIndex) => {
        if (targetIndex !== 1) {
          const lastWindow = await window.getLastWindow(this.context)
          await lastWindow.setWindowPrivacyMode(false)
        }
        if (targetIndex === 0) {
          this.title = '密码'
          this.context.eventHub.emit('refreshPassword')
        }
        if (targetIndex === 1) {
          const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
            name: 'commonSetting'
          })
          const disallowScreenshot = commonSettingDataPreferences.getSync('disallowScreenshot', true) as boolean
          if (disallowScreenshot) {
            const lastWindow = await window.getLastWindow(this.context)
            await lastWindow.setWindowPrivacyMode(true)
          }
          this.title = '常用信息'
          this.context.eventHub.emit('refreshInfo')
        }
        if (targetIndex === 2) {
          this.title = '标签'
          this.context.eventHub.emit('refreshTag')
        }
        if (targetIndex === 3) {
          this.title = '我的'
          this.context.eventHub.emit('refreshMe')
        }
      })
    }
    .alignItems(HorizontalAlign.Start)
    .backgroundColor($r('sys.color.background_secondary'))
    .backgroundImage(this.backgroundImagePixelMap)
    .backgroundImageSize(ImageSize.FILL)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .padding({
      bottom: this.preferType === 0 ? 36 : 0,
      top: this.preferType === 0 ? 12 : 0
    })
    .onAppear(() => {
      this.context.eventHub.on('clearData', () => {
        if (!this.isShowCleardataSheet) {
          this.isShowCleardataSheet = true
        }
      })
      this.context.eventHub.on('wantUri', async (wantUri: string) => {
        if (wantUri.endsWith('.txt') || wantUri.endsWith('.csv')) {
          const filestring = read(wantUri)
          if (wantUri.endsWith('.txt')) {
            const promptAction = this.UIContext.getPromptAction()
            const data = await promptAction.showActionMenu({
              title: '选择导入类型',
              buttons: [
                {
                  text: '密码',
                  color: $r('sys.color.font_primary')
                },
                {
                  text: '常用信息',
                  color: $r('sys.color.font_primary')
                },
                {
                  text: '标签',
                  color: $r('sys.color.font_primary')
                }
              ]
            })
            if (data.index === 0) {
              await importPassword(this.context, filestring, 0)
              this.context.eventHub.emit('refreshPassword')
            }
            if (data.index === 1) {
              await importInfo(this.context, filestring, 0)
              this.context.eventHub.emit('refreshInfo')
            }
            if (data.index === 2) {
              await importTag(this.context, filestring, 0)
              this.context.eventHub.emit('refreshTag')
            }
            promptAction.openToast({
              message: '导入成功'
            })
          }
          if (wantUri.endsWith('.csv')) {
            await importCsvPassword(this.context, filestring)
            this.context.eventHub.emit('refreshPassword')
          }
        }
        if (wantUri.startsWith('https://www.zhangls2512.cn/product/password')) {
          const promptAction = this.UIContext.getPromptAction()
          const urires = new uri.URI(wantUri)
          const invitationCode = urires.getQueryValue('invitationcode')
          const vipCode = urires.getQueryValue('vipcode')
          const accessToken = await get()
          if (invitationCode) {
            if (!accessToken) {
              promptAction.showDialog({
                title: '提示',
                message: '邀请码使用失败，原因：未登录账号',
                buttons: [
                  {
                    text: '确定',
                    color: $r('sys.color.font_emphasize')
                  }
                ]
              })
            }
            if (accessToken) {
              const deviceToken = await getDeviceToken()
              if (deviceToken) {
                const res = await request(this.context, this.UIContext, '/product/useInvitationcode', {
                  accessToken: accessToken,
                  deviceToken: deviceToken,
                  product: 'password',
                  invitationcode: invitationCode
                })
                if (res !== 'fail') {
                  promptAction.showDialog({
                    title: '提示',
                    message: '邀请码使用成功',
                    buttons: [
                      {
                        text: '确定',
                        color: $r('sys.color.font_emphasize')
                      }
                    ]
                  })
                }
              }
            }
          }
          if (vipCode) {
            if (!accessToken) {
              promptAction.showDialog({
                title: '提示',
                message: '兑换码使用失败，原因：未登录账号',
                buttons: [
                  {
                    text: '确定',
                    color: $r('sys.color.font_emphasize')
                  }
                ]
              })
            }
            if (accessToken) {
              const res = await request(this.context, this.UIContext, '/product/useVipcode', {
                accessToken: accessToken,
                vipcode: vipCode
              })
              if (res !== 'fail') {
                promptAction.showDialog({
                  title: '提示',
                  message: '兑换码使用成功',
                  buttons: [
                    {
                      text: '确定',
                      color: $r('sys.color.font_emphasize')
                    }
                  ]
                })
              }
            }
          }
        }
      })
      const currentOrientation = display.getDefaultDisplaySync().orientation
      if (currentOrientation === display.Orientation.PORTRAIT ||
        currentOrientation === display.Orientation.PORTRAIT_INVERTED) {
        this.preferType = 0
        const currentIndex = this.index
        this.index = -1
        this.index = currentIndex
      }
      if (currentOrientation === display.Orientation.LANDSCAPE ||
        currentOrientation === display.Orientation.LANDSCAPE_INVERTED) {
        this.preferType = 1
        const currentIndex = this.index
        this.index = -1
        this.index = currentIndex
      }
      display.on('change', (displayId) => {
        const orientation = display.getDisplayByIdSync(displayId).orientation
        if (orientation === display.Orientation.PORTRAIT || orientation === display.Orientation.PORTRAIT_INVERTED) {
          this.preferType = 0
          const currentIndex = this.index
          this.index = -1
          this.index = currentIndex
        }
        if (orientation === display.Orientation.LANDSCAPE || orientation === display.Orientation.LANDSCAPE_INVERTED) {
          this.preferType = 1
          const currentIndex = this.index
          this.index = -1
          this.index = currentIndex
        }
      })
      this.context.eventHub.on('refreshIndex', () => {
        this.backgroundImagePixelMap = this.getBackgroundImage()
      })
      this.backgroundImagePixelMap = this.getBackgroundImage()
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshIndex')
      this.context.eventHub.off('wantUri')
      this.context.eventHub.off('clearData')
      display.off('change')
    })
    .bindSheet(this.isShowCleardataSheet!!, this.CleardataSheetBuilder(), {
      preferType: this.preferType,
      title: {
        title: '清理数据'
      }
    })
  }
}