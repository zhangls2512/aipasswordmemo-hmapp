import { common } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { camera, cameraPicker as picker } from '@kit.CameraKit'
import { fileIo } from '@kit.CoreFileKit'
import { textRecognition } from '@kit.CoreVisionKit'
import { image } from '@kit.ImageKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { EntityType, textProcessing } from '@kit.NaturalLanguageKit'
import { CallbackParam, CardRecognition, CardSide, CardType } from '@kit.VisionKit'
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
  context = getContext(this) as common.UIAbilityContext

  async getList(value: string) {
    this.list = []
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

  build() {
    List() {
      ListItem() {
        Column() {
          Row() {
            Button('图片识别')
              .width('48%')
              .onClick(async () => {
                const data = await promptAction.showActionMenu({
                  title: '选择图片来源',
                  buttons: [
                    {
                      text: '相机',
                      color: $r('sys.color.font_primary')
                    },
                    {
                      text: '图库',
                      color: $r('sys.color.font_primary')
                    }
                  ]
                })
                if (data.index === 0) {
                  const pickerres = await picker.pick(this.context, [picker.PickerMediaType.PHOTO], {
                    cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK
                  })
                  let imageSource: image.ImageSource | undefined = undefined
                  const fileSource = await fileIo.open(pickerres.resultUri)
                  imageSource = image.createImageSource(fileSource.fd)
                  const imagePixelMap = await imageSource.createPixelMap()
                  const initres = await textRecognition.init()
                  if (initres) {
                    const textrecognitionres = await textRecognition.recognizeText({
                      pixelMap: imagePixelMap
                    })
                    this.text = textrecognitionres.value
                    await textRecognition.release()
                    this.getList(this.text)
                  }
                }
                if (data.index === 1) {
                  const photoPicker = new photoAccessHelper.PhotoViewPicker()
                  const pickerres = await photoPicker.select({
                    MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
                    maxSelectNumber: 1
                  })
                  let imageSource: image.ImageSource | undefined = undefined
                  const fileSource = await fileIo.open(pickerres.photoUris[0])
                  imageSource = image.createImageSource(fileSource.fd)
                  const imagePixelMap = await imageSource.createPixelMap()
                  const initres = await textRecognition.init()
                  if (initres) {
                    const textrecognitionres = await textRecognition.recognizeText({
                      pixelMap: imagePixelMap
                    })
                    this.text = textrecognitionres.value
                    await textRecognition.release()
                    this.getList(this.text)
                  }
                }
              })
            Blank()
              .width('4%')
            Button('卡证识别')
              .width('48%')
              .onClick(() => {
                this.showCard = true
              })
          }

          if (this.showCard) {
            CardRecognition({
              cardSide: CardSide.FRONT,
              callback: ((params: CallbackParam) => {
                this.showCard = false
                if (params.code === 200) {
                  if (params.cardType === CardType.CARD_ID) {
                    this.list.push({
                      type: '姓名',
                      value: String(params.cardInfo?.front.name)
                    })
                    this.list.push({
                      type: '身份证号',
                      value: String(params.cardInfo?.front.idNumber)
                    })
                  }
                  if (params.cardType === CardType.CARD_BANK) {
                    this.list.push({
                      type: '银行卡号',
                      value: String(params.cardInfo?.main.bankNum)
                    })
                  }
                  if (params.cardType === CardType.CARD_PASSPORT) {
                    this.list.push({
                      type: '姓名',
                      value: String(params.cardInfo?.main.name)
                    })
                  }
                  if (params.cardType === CardType.CARD_DRIVER_LICENSE) {
                    this.list.push({
                      type: '姓名',
                      value: String(params.cardInfo?.front.name)
                    })
                  }
                  if (params.cardType === CardType.CARD_VEHICLE_LICENSE) {
                    this.list.push({
                      type: '姓名',
                      value: String(params.cardInfo?.front.owner)
                    })
                  }
                }
              })
            })
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
          }
          TextArea({
            placeholder: '请输入待识别文本，AI 将自动识别、提取其中的邮箱、姓名、手机号、URL、身份证号',
            text: $$this.text
          })
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
            .onChange((value: string) => {
              this.getList(value)
            })
        }
        .alignItems(HorizontalAlign.Start)
      }

      ListItem() {
        Text('AI 识别结果')
          .fontWeight('medium')
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      ForEach(this.list, (item: Item) => {
        ListItem() {
          Column() {
            Row() {
              Text('类型')
                .fontWeight('medium')
                .width('45%')
              Blank()
                .width('5%')
              Text(item.type)
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .textAlign(TextAlign.End)
                .width('50%')
            }
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
            .padding($r('sys.float.ohos_id_corner_radius_default_m'))
            .width('100%')

            Divider()
              .padding({
                left: $r('sys.float.ohos_id_corner_radius_default_m'),
                right: $r('sys.float.ohos_id_corner_radius_default_m')
              })
            Row() {
              Text('内容')
                .fontWeight('medium')
                .width('45%')
              Blank()
                .width('5%')
              Text(item.value)
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .textAlign(TextAlign.End)
                .width('50%')
            }
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
            .padding($r('sys.float.ohos_id_corner_radius_default_m'))
            .width('100%')

            Divider()
              .padding({
                left: $r('sys.float.ohos_id_corner_radius_default_m'),
                right: $r('sys.float.ohos_id_corner_radius_default_m')
              })
            Row() {
              Text('新增')
                .fontColor($r('sys.color.font_emphasize'))
                .fontWeight('medium')
              Blank()
              Image($r('app.media.right'))
                .fillColor($r('sys.color.icon_fourth'))
                .height(12)
                .width(12)
            }
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
            .padding($r('sys.float.ohos_id_corner_radius_default_m'))
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .width('100%')
            .onClick(() => {
              newInfo({
                type: item.type,
                value: item.value,
                cloudBackup: false
              })
            })
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })
      })
      if (this.list.length === 0) {
        ListItem() {
          Text('无数据')
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })
        .width('100%')
      }
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_max_padding_start'),
      right: $r('sys.float.ohos_id_max_padding_end')
    })
    .onAppear(() => {
      textProcessing.init()
    })
  }
}