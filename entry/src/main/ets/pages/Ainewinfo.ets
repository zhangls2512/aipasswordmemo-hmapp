import { preferences } from '@kit.ArkData'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { deviceInfo } from '@kit.BasicServicesKit'
import { camera, cameraPicker as picker } from '@kit.CameraKit'
import { fileIo } from '@kit.CoreFileKit'
import { textRecognition } from '@kit.CoreVisionKit'
import { image } from '@kit.ImageKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { EntityType, textProcessing } from '@kit.NaturalLanguageKit'
import {
  CollaborationServiceFilter,
  CollaborationServiceStateDialog,
  createCollaborationServiceMenuItems
} from '@kit.ServiceCollaborationKit'
import { CardRecognition, CardSide, CardType } from '@kit.VisionKit'
import getCloudServiceStatus from '../common/Cloudservice'
import { getKey } from '../common/Crypto'
import { newInfo } from '../common/Datachange'

interface Item {
  type: string,
  value: string
}

@ComponentV2
export default struct Ainewinfo {
  @Consumer() isShowAinewSheet: boolean = false
  @Local list: Item[] = []
  @Local text: string = ''
  @Local showCard: boolean = false
  @Local hoverId: number = -1
  context = this.getUIContext().getHostContext()
  cloudBackup = false
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '识别中...'
    })
  })

  async getList(value: string) {
    this.list = []
    if (value) {
      const entity = await textProcessing.getEntity(value, {
        entityTypes: [
          EntityType.EMAIL,
          EntityType.NAME,
          EntityType.PHONE_NO,
          EntityType.URL,
          EntityType.ID_NO
        ]
      })
      entity.forEach((item) => {
        if (item.type === EntityType.EMAIL) {
          this.list.push({
            type: '邮箱',
            value: item.text
          })
        }
        if (item.type === EntityType.NAME) {
          this.list.push({
            type: '姓名',
            value: item.text
          })
        }
        if (item.type === EntityType.PHONE_NO) {
          this.list.push({
            type: '手机号',
            value: item.text
          })
        }
        if (item.type === EntityType.URL) {
          this.list.push({
            type: 'URL',
            value: item.text
          })
        }
        if (item.type === EntityType.ID_NO) {
          this.list.push({
            type: '身份证号',
            value: item.text
          })
        }
      })
    }
  }

  @Builder
  ChooseImageMenu() {
    Menu() {
      MenuItem({ content: '拍照' })
        .onClick(async () => {
          try {
            const pickerres = await picker.pick(this.context, [picker.PickerMediaType.PHOTO], {
              cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK
            })
            const fileSource = await fileIo.open(pickerres.resultUri)
            const imageSource = image.createImageSource(fileSource.fd)
            const imagePixelMap = await imageSource.createPixelMap()
            const initres = await textRecognition.init()
            if (initres) {
              this.dialogControllerProgress.open()
              const textrecognitionres = await textRecognition.recognizeText({
                pixelMap: imagePixelMap
              })
              this.dialogControllerProgress.close()
              this.text = textrecognitionres.value
              await textRecognition.release()
              this.getList(this.text)
            }
          } catch (err) {
            if (err.code !== 13900002) {
              promptAction.openToast({
                message: '发生错误，错误码：' + err.code
              })
            }
          }
        })
      MenuItem({ content: '从图库中选择' })
        .onClick(async () => {
          try {
            const photoPicker = new photoAccessHelper.PhotoViewPicker()
            const pickerres = await photoPicker.select({
              MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
              maxSelectNumber: 1,
              isPhotoTakingSupported: false,
              isOriginalSupported: false
            })
            const fileSource = await fileIo.open(pickerres.photoUris[0])
            const imageSource = image.createImageSource(fileSource.fd)
            const imagePixelMap = await imageSource.createPixelMap()
            const initres = await textRecognition.init()
            if (initres) {
              this.dialogControllerProgress.open()
              const textrecognitionres = await textRecognition.recognizeText({
                pixelMap: imagePixelMap
              })
              this.dialogControllerProgress.close()
              this.text = textrecognitionres.value
              await textRecognition.release()
              this.getList(this.text)
            }
          } catch (err) {
            if (err.code !== 13900020) {
              promptAction.openToast({
                message: '发生错误，错误码：' + err.code
              })
            }
          }
        })
      if (deviceInfo.deviceType !== 'phone') {
        MenuItem({
          content: '从其他设备导入',
          builder: this.SubMenu()
        })
      }
    }
  }

  @Builder
  SubMenu() {
    Menu() {
      createCollaborationServiceMenuItems([CollaborationServiceFilter.TAKE_PHOTO,
        CollaborationServiceFilter.IMAGE_PICKER], 1)
    }
  }

  build() {
    List() {
      ListItem() {
        Column() {
          CollaborationServiceStateDialog({
            async onState(stateCode: number, bufferType: string, buffer: ArrayBuffer) {
              if (stateCode !== 0) {
                promptAction.openToast({
                  message: '发生错误，错误码：' + stateCode
                })
                return
              }
              if (bufferType !== 'general.image') {
                promptAction.openToast({
                  message: '请导入图片'
                })
                return
              }
              const imageSource = image.createImageSource(buffer)
              const imagePixelMap = await imageSource.createPixelMap()
              const initres = await textRecognition.init()
              if (initres) {
                this.dialogControllerProgress.open()
                const textrecognitionres = await textRecognition.recognizeText({
                  pixelMap: imagePixelMap
                })
                this.dialogControllerProgress.close()
                this.text = textrecognitionres.value
                await textRecognition.release()
                this.getList(this.text)
              }
            }
          })
          Row() {
            Button('图片识别')
              .layoutWeight(1)
              .bindMenu(this.ChooseImageMenu, {
                hapticFeedbackMode: HapticFeedbackMode.AUTO
              })
            Blank()
              .width($r('sys.float.ohos_id_elements_margin_horizontal_m'))
            Button('卡证识别')
              .layoutWeight(1)
              .onClick(() => {
                this.showCard = true
              })
          }

          if (this.showCard) {
            CardRecognition({
              cardSide: CardSide.FRONT,
              onResult: (res) => {
                this.showCard = false
                if (res.code === 200) {
                  if (res.cardType === CardType.CARD_ID && res.cardInfo?.front) {
                    this.list.push({
                      type: '姓名',
                      value: String(res.cardInfo?.front.name)
                    })
                    this.list.push({
                      type: '身份证号',
                      value: String(res.cardInfo?.front.idNumber)
                    })
                  }
                  if (res.cardType === CardType.CARD_BANK) {
                    this.list.push({
                      type: '银行卡号',
                      value: String(res.cardInfo?.main.bankNum)
                    })
                  }
                  if (res.cardType === CardType.CARD_PASSPORT) {
                    this.list.push({
                      type: '姓名',
                      value: String(res.cardInfo?.main.name)
                    })
                  }
                  if (res.cardType === CardType.CARD_DRIVER_LICENSE && res.cardInfo?.front) {
                    this.list.push({
                      type: '姓名',
                      value: String(res.cardInfo?.front.name)
                    })
                  }
                  if (res.cardType === CardType.CARD_VEHICLE_LICENSE && res.cardInfo?.front) {
                    this.list.push({
                      type: '姓名',
                      value: String(res.cardInfo?.front.owner)
                    })
                  }
                }
              }
            })
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
          }
          TextArea({
            placeholder: '请输入待识别文本，AI将自动识别、提取其中的邮箱、姓名、手机号、URL、身份证号',
            text: this.text!!
          })
            .enableAutoSpacing(true)
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
            .onChange((value) => {
              this.getList(value)
            })
        }
        .alignItems(HorizontalAlign.Start)
      }

      ListItem() {
        Text('AI识别结果')
          .enableAutoSpacing(true)
          .fontWeight(FontWeight.Medium)
      }
      .margin({
        bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      ForEach(this.list, (item: Item, index) => {
        ListItem() {
          Column() {
            Row() {
              Text('类型')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(item.type)
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .layoutWeight(1)
                .textAlign(TextAlign.End)
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('内容')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(item.value)
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .layoutWeight(1)
                .textAlign(TextAlign.End)
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('新增')
                .fontColor($r('sys.color.font_emphasize'))
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Image($r('app.media.right'))
                .fillColor($r('sys.color.icon_fourth'))
                .height(12)
                .width(12)
            }
            .borderRadius(12)
            .padding(12)
            .stateStyles({
              normal: {
                .backgroundColor(this.hoverId === index ? $r('sys.color.interactive_hover') :
                  $r('sys.color.ohos_id_color_card_bg'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .width('100%')
            .onHover((isHover) => {
              if (!isHover) {
                this.hoverId = -1
              }
              if (isHover) {
                this.hoverId = index
              }
            })
            .onClick(() => {
              newInfo({
                type: item.type,
                value: item.value,
                cloudBackup: this.cloudBackup
              })
            })
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
      })
      if (this.list.length === 0) {
        ListItem() {
          Text('无数据')
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
        .width('100%')
      }
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_max_padding_start'),
      right: $r('sys.float.ohos_id_max_padding_end')
    })
    .onAppear(async () => {
      await textProcessing.init()
      const res = await getCloudServiceStatus()
      const key = getKey()
      if (res && key) {
        const cloudbackupSettingDataPreferences = preferences.getPreferencesSync(this.context, {
          name: 'cloudbackupSetting'
        })
        const autoOn = cloudbackupSettingDataPreferences.getSync('autoOn', []) as string[]
        if (autoOn.includes('info')) {
          this.cloudBackup = true
        }
      }
    })
  }
}