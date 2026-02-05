import { common } from '@kit.AbilityKit'
import { preferences, relationalStore } from '@kit.ArkData'
import { uri } from '@kit.ArkTS'
import { display, LoadingDialog, window } from '@kit.ArkUI'
import { zlib } from '@kit.BasicServicesKit'
import { fileIo } from '@kit.CoreFileKit'
import { image } from '@kit.ImageKit'
import { HdsTabs, HdsTabsController } from '@kit.UIDesignKit'
import { getAccountAccessToken } from '../common/Accesstoken'
import { getKey } from '../common/Crypto'
import { importCsvPassword } from '../common/Csv'
import { importInfo, importPassword, importTag } from '../common/Dataimport'
import getDeviceToken from '../common/Devicetoken'
import { readUri } from '../common/File'
import { getPreferType } from '../common/Prefertype'
import request from '../common/Request'
import Cleardata from './Cleardata'
import Info from './Info'
import Me from './Me'
import Notice from './Notice'
import Password from './Password'
import Tag from './Tag'
import Uploaderrorlog from './Uploaderrorlog'

@Entry
@ComponentV2
struct Index {
  @Provider() isShowUploaderrorlogSheet: boolean = false
  @Local errorType: string = ''
  @Local errorObject: string = ''
  @Local backgroundImagePixelMap: PixelMap | undefined = undefined
  @Local preferType: number = 1
  @Local index: number = 0
  @Local title: string = '密码'
  @Local isShowCleardataSheet: boolean = false
  @Local isShowNoticeSheet: boolean = false
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  controller = new HdsTabsController()

  async getBackgroundImage() {
    const backgroundImagePath = this.context.filesDir + '/media/backgroundimage.png'
    const res = fileIo.accessSync(backgroundImagePath)
    if (res) {
      const backgroundImageSource = image.createImageSource(backgroundImagePath)
      const backgroundImagePixelMap = await backgroundImageSource.createPixelMap()
      return backgroundImagePixelMap
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

  @Builder
  NoticeSheetBuilder() {
    Notice()
  }

  @Builder
  UploaderrorlogSheetBuilder() {
    Uploaderrorlog({
      errorType: this.errorType,
      errorObject: this.errorObject
    })
  }

  build() {
    Column() {
      if (this.preferType === 0) {
        Text(this.title)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({
            bottom: $r('sys.float.ohos_id_elements_margin_vertical_l'),
            left: $r('sys.float.ohos_id_elements_margin_horizontal_l')
          })
      }
      HdsTabs({
        controller: this.controller
      }) {
        TabContent() {
          Password()
        }
        .tabBar(this.tabBuilder(0, $r('app.media.password'), '密码'))
        .bindSheet(this.isShowNoticeSheet!!, this.NoticeSheetBuilder(), {
          preferType: this.preferType,
          title: {
            title: '消息通知'
          }
        })

        TabContent() {
          Info()
        }
        .tabBar(this.tabBuilder(1, $r('app.media.info'), '常用信息'))

        TabContent() {
          Tag()
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
      .barWidth(this.preferType === 0 ? '100%' : 56)
      .scrollable(false)
      .vertical(this.preferType === 0 ? false : true)
      .onChange((index) => {
        this.index = index
      })
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
      .bindSheet(this.isShowUploaderrorlogSheet!!, this.UploaderrorlogSheetBuilder(), {
        height: SheetSize.FIT_CONTENT,
        preferType: this.preferType,
        title: {
          title: '上传故障日志'
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
    .onAppear(async () => {
      this.context.eventHub.on('clearData', () => {
        if (!this.isShowCleardataSheet) {
          this.isShowCleardataSheet = true
        }
      })
      this.context.eventHub.on('notice', () => {
        if (!this.isShowNoticeSheet) {
          this.isShowNoticeSheet = true
        }
      })
      const promptAction = this.UIContext.getPromptAction()
      this.context.eventHub.on('wantUri', async (wantUri: string) => {
        if (wantUri.endsWith('.txt') || wantUri.endsWith('.csv') || wantUri.endsWith('.zip')) {
          const filestring = await readUri(wantUri)
          if (wantUri.endsWith('.txt')) {
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
              await importPassword(this.context, filestring, relationalStore.ConflictResolution.ON_CONFLICT_IGNORE)
              this.context.eventHub.emit('refreshPassword')
            }
            if (data.index === 1) {
              await importInfo(this.context, filestring, relationalStore.ConflictResolution.ON_CONFLICT_IGNORE)
              this.context.eventHub.emit('refreshInfo')
            }
            if (data.index === 2) {
              await importTag(this.context, filestring, relationalStore.ConflictResolution.ON_CONFLICT_IGNORE)
              this.context.eventHub.emit('refreshTag')
            }
            await promptAction.openToast({
              message: '导入成功'
            })
          }
          if (wantUri.endsWith('.csv')) {
            await importCsvPassword(this.context, filestring)
            this.context.eventHub.emit('refreshPassword')
          }
          if (wantUri.endsWith('.zip')) {
            const passwordIconDir = this.context.filesDir + '/media/passwordicon/'
            if (!fileIo.accessSync(passwordIconDir)) {
              await fileIo.mkdir(passwordIconDir, true)
            }
            const filePath = passwordIconDir + 'passwordicon.zip'
            const srcFile = fileIo.openSync(wantUri)
            const destFile = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
            await fileIo.copyFile(srcFile.fd, destFile.fd)
            fileIo.closeSync(srcFile)
            fileIo.closeSync(destFile)
            await zlib.decompressFile(filePath, passwordIconDir)
            await fileIo.unlink(filePath)
            const data = await promptAction.showDialog({
              title: '提示',
              message: '导入成功，需重启应用生效，是否重启？',
              buttons: [
                {
                  text: '取消',
                  color: $r('sys.color.font_primary')
                },
                {
                  text: '重启',
                  color: $r('sys.color.font_emphasize')
                }
              ]
            })
            if (data.index === 1) {
              const applicationContext = this.context.getApplicationContext()
              applicationContext.restartApp({
                bundleName: 'com.zhangxm.aipasswordmemo',
                abilityName: 'EntryAbility'
              })
            }
          }
        }
        const accessToken = await getAccountAccessToken()
        const dialogControllerProgress = new CustomDialogController({
          builder: LoadingDialog({
            content: '加载中...'
          })
        })
        if (wantUri.startsWith('https://www.zhangls2512.cn/product/password')) {
          const urires = new uri.URI(wantUri)
          const invitationCode = urires.getQueryValue('invitationcode')
          const vipCode = urires.getQueryValue('vipcode')
          if (!invitationCode && !vipCode) {
            await promptAction.showDialog({
              title: '提示',
              message: '链接格式错误',
              buttons: [
                {
                  text: '确定',
                  color: $r('sys.color.font_emphasize')
                }
              ]
            })
          }
          if (invitationCode) {
            if (!accessToken) {
              await promptAction.showDialog({
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
                dialogControllerProgress.open()
                const res = await request(this.context, '/product/useInvitationcode', {
                  accessToken: accessToken,
                  deviceToken: deviceToken,
                  product: 'password',
                  invitationcode: invitationCode
                })
                dialogControllerProgress.close()
                if (res !== 'fail') {
                  await promptAction.showDialog({
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
              await promptAction.showDialog({
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
              dialogControllerProgress.open()
              const res = await request(this.context, '/product/useVipcode', {
                accessToken: accessToken,
                vipcode: vipCode
              })
              dialogControllerProgress.close()
              if (res !== 'fail') {
                await promptAction.showDialog({
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
        if (wantUri.startsWith('https://www.zhangls2512.cn/product/account/login')) {
          const urires = new uri.URI(wantUri)
          const ticket = urires.getQueryValue('ticket')
          if (!ticket) {
            await promptAction.showDialog({
              title: '提示',
              message: '链接格式错误',
              buttons: [
                {
                  text: '确定',
                  color: $r('sys.color.font_emphasize')
                }
              ]
            })
          }
          if (ticket) {
            const accessToken = await getAccountAccessToken()
            if (!accessToken) {
              await promptAction.showDialog({
                title: '提示',
                message: '扫码登录失败，原因：未登录账号',
                buttons: [
                  {
                    text: '确定',
                    color: $r('sys.color.font_emphasize')
                  }
                ]
              })
            }
            if (accessToken) {
              const confirm = await promptAction.showDialog({
                title: '提示',
                message: '确定登录？',
                buttons: [
                  {
                    text: '取消',
                    color: $r('sys.color.font_primary')
                  },
                  {
                    text: '确定',
                    color: $r('sys.color.font_emphasize')
                  }
                ]
              })
              if (confirm.index === 1) {
                dialogControllerProgress.open()
                const res = await request(this.context, '/account/confirmTicket', {
                  accessToken: accessToken,
                  ticket: ticket
                })
                dialogControllerProgress.close()
                if (res !== 'fail') {
                  await promptAction.showDialog({
                    title: '提示',
                    message: '确定成功',
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
        }
      })
      this.context.eventHub.on('dialog', async (title: string, message: string) => {
        await promptAction.showDialog({
          title: title,
          message: message,
          buttons: [
            {
              text: '确定',
              color: $r('sys.color.font_emphasize')
            }
          ]
        })
      })
      this.context.eventHub.on('uploadErrorLog', (errorType: string, errorObject: string) => {
        this.errorType = errorType
        this.errorObject = errorObject
        this.isShowUploaderrorlogSheet = true
      })
      this.preferType = getPreferType(this.UIContext)
      display.on('change', () => {
        setTimeout(() => {
          this.preferType = getPreferType(this.UIContext)
        }, 200)
      })
      this.context.eventHub.on('refreshIndex', async () => {
        this.backgroundImagePixelMap = await this.getBackgroundImage()
      })
      this.backgroundImagePixelMap = await this.getBackgroundImage()
      if (!getKey()) {
        await promptAction.showDialog({
          title: '提示',
          message: '检测到未导入密钥，建议前往“我的”>“设置”>“密钥”导入密钥以加密数据，提高安全性',
          buttons: [
            {
              text: '确定',
              color: $r('sys.color.font_emphasize')
            }
          ]
        })
      }
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshIndex')
      this.context.eventHub.off('uploadErrorLog')
      this.context.eventHub.off('dialog')
      this.context.eventHub.off('wantUri')
      this.context.eventHub.off('notice')
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