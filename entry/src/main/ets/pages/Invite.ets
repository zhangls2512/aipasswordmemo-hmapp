import { common } from '@kit.AbilityKit'
import { uniformTypeDescriptor } from '@kit.ArkData'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { fileIo, fileUri } from '@kit.CoreFileKit'
import { image } from '@kit.ImageKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { generateBarcode, scanCore } from '@kit.ScanKit'
import { harmonyShare, systemShare } from '@kit.ShareKit'
import { hdsEffect } from '@kit.UIDesignKit'
import { get } from '../common/Accesstoken'
import getDeviceToken from '../common/Devicetoken'
import copy from '../common/Pasteboard'
import request from '../common/Request'

@Builder
export function InviteBuilder() {
  Invite()
}

@ComponentV2
struct Invite {
  @Local deviceToken: string = ''
  @Local invitationcode: string = ''
  @Local inviteusercount: number = -1
  @Local loading: boolean = false
  @Local inputInvitationcode: string = ''
  @Local accessToken: string = ''
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            if (!this.loading && this.invitationcode && this.inviteusercount !== -1) {
              Text('邀请码')
                .fontWeight(FontWeight.Bold)
              Text(this.invitationcode)
                .fontColor($r('sys.color.font_emphasize'))
                .fontWeight(FontWeight.Medium)
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
                .onClick(() => {
                  copy(this.invitationcode)
                })
              Text('邀请链接')
                .fontWeight(FontWeight.Bold)
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_l')
                })
              Text('https://www.zhangls2512.cn/product/password?invitationcode=' + this.invitationcode)
                .fontColor($r('sys.color.font_emphasize'))
                .fontWeight(FontWeight.Medium)
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
                .onClick(() => {
                  const shareData = new systemShare.SharedData({
                    utd: uniformTypeDescriptor.UniformDataType.HYPERLINK,
                    title: '邀请您使用轩铭密码智能备忘录',
                    description: '邀请您使用轩铭密码智能备忘录，方便、智能地记录、管理密码。',
                    thumbnail: this.context.resourceManager.getMediaByNameSync('icon'),
                    content: 'https://www.zhangls2512.cn/product/password?invitationcode=' + this.invitationcode
                  })
                  const shareController = new systemShare.ShareController(shareData)
                  shareController.show(this.context, {})
                })
              Row() {
                Text('邀请二维码')
                  .fontWeight(FontWeight.Bold)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Button('分享')
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .onClick(async () => {
                    const qrcodeDir = this.context.filesDir + '/media/invitationqrcode'
                    const qrcodePath = qrcodeDir + '/' + this.invitationcode + '.png'
                    if (!fileIo.accessSync(qrcodePath)) {
                      const qrcodePixelMap =
                        await generateBarcode.createBarcode('https://www.zhangls2512.cn/product/password?invitationcode=' +
                        this.invitationcode, {
                          scanType: scanCore.ScanType.QR_CODE,
                          width: 200,
                          height: 200
                        })
                      if (!fileIo.accessSync(qrcodeDir)) {
                        fileIo.mkdirSync(qrcodeDir, true)
                      }
                      const qrcodeFile =
                        fileIo.openSync(qrcodePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE)
                      const imagePacker = image.createImagePacker()
                      await imagePacker.packToFile(qrcodePixelMap, qrcodeFile.fd, {
                        format: 'image/png',
                        quality: 100
                      })
                      fileIo.closeSync(qrcodeFile)
                    }
                    const qrcodeUri = fileUri.getUriFromPath(qrcodePath)
                    const shareData = new systemShare.SharedData({
                      utd: uniformTypeDescriptor.UniformDataType.IMAGE,
                      title: '邀请您使用轩铭密码智能备忘录',
                      description: '邀请您使用轩铭密码智能备忘录，方便、智能地记录、管理密码。',
                      thumbnailUri: qrcodeUri,
                      uri: qrcodeUri
                    })
                    const shareController = new systemShare.ShareController(shareData)
                    await shareController.show(this.context, {})
                  })
                Button('保存')
                  .buttonStyle(ButtonStyleMode.NORMAL)
                  .visualEffect(new hdsEffect.HdsEffectBuilder()
                    .pointLight({
                      sourceType: hdsEffect.PointLightSourceType.SOFT,
                      illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
                    })
                    .buildEffect())
                  .onClick(async () => {
                    const qrcodeDir = this.context.filesDir + '/media/invitationqrcode'
                    const qrcodePath = qrcodeDir + '/' + this.invitationcode + '.png'
                    if (!fileIo.accessSync(qrcodePath)) {
                      const qrcodePixelMap =
                        await generateBarcode.createBarcode('https://www.zhangls2512.cn/product/password?invitationcode=' +
                        this.invitationcode, {
                          scanType: scanCore.ScanType.QR_CODE,
                          width: 200,
                          height: 200
                        })
                      if (!fileIo.accessSync(qrcodeDir)) {
                        fileIo.mkdirSync(qrcodeDir, true)
                      }
                      const qrcodeFile =
                        fileIo.openSync(qrcodePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE)
                      const imagePacker = image.createImagePacker()
                      await imagePacker.packToFile(qrcodePixelMap, qrcodeFile.fd, {
                        format: 'image/png',
                        quality: 100
                      })
                      fileIo.closeSync(qrcodeFile)
                    }
                    const qrcodeUri = fileUri.getUriFromPath(qrcodePath)
                    const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(this.context)
                    try {
                      const uris = await phAccessHelper.showAssetsCreationDialog([qrcodeUri], [{
                        fileNameExtension: 'png',
                        photoType: photoAccessHelper.PhotoType.IMAGE
                      }])
                      const srcFile = fileIo.openSync(qrcodeUri)
                      const destFile = fileIo.openSync(uris[0], fileIo.OpenMode.WRITE_ONLY)
                      fileIo.copyFileSync(srcFile.fd, destFile.fd)
                      fileIo.closeSync(srcFile)
                      fileIo.closeSync(destFile)
                      promptAction.openToast({
                        message: '保存成功'
                      })
                    } catch (err) {
                      if (err.code === 13900020) {
                        return
                      }
                      promptAction.openToast({
                        message: '发生错误，错误码：' + err.code
                      })
                    }
                  })
              }
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })

              QRCode('https://www.zhangls2512.cn/product/password?invitationcode=' + this.invitationcode)
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
              Row() {
                Text('已邀请新用户数')
                  .fontWeight(FontWeight.Bold)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(String(this.inviteusercount))
                  .fontWeight(FontWeight.Medium)
              }
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })
            }
            if (this.loading) {
              LoadingProgress()
                .height(20)
                .width(20)
            }
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Column() {
            TextArea({
              placeholder: '请输入邀请码',
              text: this.inputInvitationcode!!
            })
              .enableAutoSpacing(true)
              .maxLength(62)
              .showCounter(true)
            Button('提交')
              .enabled(this.accessToken !== '' && this.deviceToken !== '' && this.inputInvitationcode.length === 62)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })
              .onClick(async () => {
                const dialogControllerProgress = new CustomDialogController({
                  builder: LoadingDialog({
                    content: '验证中...'
                  })
                })
                dialogControllerProgress.open()
                const res = await request('/product/useInvitationcode', {
                  accessToken: this.accessToken,
                  deviceToken: this.deviceToken,
                  product: 'password',
                  invitationcode: this.inputInvitationcode
                })
                dialogControllerProgress.close()
                if (res !== 'fail') {
                  promptAction.openToast({
                    message: '验证通过，已获得 30 天会员'
                  })
                  this.pageInfos.pop()
                  this.context.eventHub.emit('refreshVip')
                }
              })
          }
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('参与活动')
              .fontWeight(FontWeight.Bold)
            Text('1. 点击复制蓝色的邀请码，发送给新用户，让其进入本页面输入邀请码并提交。')
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_m')
              })
            Text() {
              Span('2. 点击分享蓝色的邀请链接给新用户，让其')
                .fontWeight(FontWeight.Medium)
              Span('登录轩铭2512统一账号后')
                .fontWeight(FontWeight.Bold)
              Span('访问邀请链接进入本应用。')
                .fontWeight(FontWeight.Medium)
            }
            .enableAutoSpacing(true)
            .margin({
              top: $r('sys.float.ohos_id_text_paragraph_margin_s')
            })

            Text() {
              Span('3. 本设备停留在本页面，让新用户')
                .fontWeight(FontWeight.Medium)
              Span('登录轩铭2512统一账号后')
                .fontWeight(FontWeight.Bold)
              Span('与本设备碰一碰/隔空传送进入本应用。')
                .fontWeight(FontWeight.Medium)
            }
            .enableAutoSpacing(true)
            .margin({
              top: $r('sys.float.ohos_id_text_paragraph_margin_s')
            })
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('活动说明')
              .fontWeight(FontWeight.Bold)
            Text('1. 其他账号每使用本账号邀请码一次，本账号获得7天会员，其他账号获得30天会员。')
              .fontWeight(FontWeight.Medium)
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_m')
              })
            Text('2. 每个账号、设备仅能使用一次邀请码。')
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_s')
              })
            Text('3. 本账号邀请码可以被不限制数量的其他账号、设备使用，但不可被本账号使用。')
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_s')
              })
            Text('4. 本账号当前邀请码在取消开通云服务后会失效，重新开通无法恢复 (会生成新的邀请码)。')
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_s')
              })
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })
      }
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    /*.titleBar({
      content: {
        title: {
          mainTitle: ''
        }
      }
    })*/
    .title('邀请新用户，免费得会员')
    .onReady(async (context) => {
      this.pageInfos = context.pathStack
      this.accessToken = await get()
      if (this.accessToken) {
        this.loading = true
        this.deviceToken = await getDeviceToken()
        const userres = await request('/product/getUserInfo', {
          accessToken: this.accessToken,
          product: 'password'
        })
        if (userres !== 'fail') {
          this.invitationcode = JSON.parse(userres).data.invitationCode as string
          const shareData = new systemShare.SharedData({
            utd: uniformTypeDescriptor.UniformDataType.HYPERLINK,
            title: '邀请您使用轩铭密码智能备忘录',
            description: '邀请您使用轩铭密码智能备忘录，方便、智能地记录、管理密码。',
            thumbnail: this.context.resourceManager.getMediaByNameSync('icon'),
            content: 'https://www.zhangls2512.cn/product/password?invitationcode=' + this.invitationcode
          })
          harmonyShare.on('knockShare', (sharableTarget) => {
            sharableTarget.share(shareData)
          })
          harmonyShare.on('gesturesShare', (sharableTarget) => {
            sharableTarget.share(shareData)
          })
        }
        const countres = await request('/product/getInviteUserCount', {
          accessToken: this.accessToken,
          product: 'password'
        })
        this.loading = false
        if (countres !== 'fail') {
          this.inviteusercount = JSON.parse(countres).count as number
        }
      }
    })
    .onDisAppear(() => {
      harmonyShare.off('knockShare')
      harmonyShare.off('gesturesShare')
    })
  }
}