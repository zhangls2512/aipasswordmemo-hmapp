import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { fileIo, fileUri } from '@kit.CoreFileKit'
import { image } from '@kit.ImageKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import {
  CollaborationServiceFilter,
  CollaborationServiceStateDialog,
  createCollaborationServiceMenuItems
} from '@kit.ServiceCollaborationKit'
import { hdsEffect } from '@kit.UIDesignKit'
import getCloudServiceStatus from '../common/Cloudservice'
import { getKey } from '../common/Crypto'
import { newInfo } from '../common/Datachange'
import { SelectItem } from './Newpassword'

@ComponentV2
export default struct Newinfo {
  @Consumer() isShowNewSheet: boolean = false
  @Local infoType: string = ''
  @Local infoTypeIndex: number = 0
  @Local infoTypeValue: string = ''
  @Local infoValue: string = ''
  @Local cloudBackup: boolean = false
  @Local allowCloudBackup: boolean = false
  @Local alertText: string = ''
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  oftenUsedInfoTypes = ['自定义']
  specialInfoTypes = ['图标', '昵称', '用户名', '密码', '姓名', '手机号', '邮箱', '银行卡号', '身份证号', 'URL']

  getCurrentInfoType() {
    let infoType = this.infoType
    if (this.infoTypeValue !== '自定义') {
      infoType = this.infoTypeValue
    }
    return infoType
  }

  @Builder
  ChooseImageMenu() {
    Menu() {
      MenuItem({ content: '本设备' })
        .onClick(async () => {
          try {
            const photoPicker = new photoAccessHelper.PhotoViewPicker()
            const pickerres = await photoPicker.select({
              MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
              maxSelectNumber: 1,
              isPhotoTakingSupported: false
            })
            const fileSource = await fileIo.open(pickerres.photoUris[0])
            const imageSource = image.createImageSource(fileSource.fd)
            const imagePixelMap = await imageSource.createPixelMap()
            const imageSize = imagePixelMap.getImageInfoSync().size
            if (imageSize.width !== imageSize.height) {
              promptAction.openToast({
                message: '请选择宽高比为 1:1 的图片'
              })
              return
            }
            if (this.infoValue) {
              try {
                fileIo.unlinkSync(this.infoValue.replace('file://com.zhangxm.aipasswordmemo', ''))
              } catch (err) {
                promptAction.openToast({
                  message: '发生错误，错误码：' + err.code
                })
              }
            }
            const passwordIconDir = this.context.filesDir + '/media/passwordicon'
            if (!fileIo.accessSync(passwordIconDir)) {
              fileIo.mkdirSync(passwordIconDir, true)
            }
            const filePath = passwordIconDir + '/' + Date.now() + '.png'
            const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE)
            const imagePacker = image.createImagePacker()
            await imagePacker.packToFile(imagePixelMap, file.fd, {
              format: 'image/png',
              quality: 100
            })
            fileIo.closeSync(file)
            this.infoValue = fileUri.getUriFromPath(filePath)
          } catch (err) {
            if (err.code !== 13900020) {
              promptAction.openToast({
                message: '发生错误，错误码：' + err.code
              })
            }
          }
        })
      MenuItem({
        content: '其他设备',
        builder: this.SubMenu()
      })
    }
  }

  @Builder
  SubMenu() {
    Menu() {
      createCollaborationServiceMenuItems([CollaborationServiceFilter.IMAGE_PICKER], 1)
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
                  message: '请选择图片'
                })
                return
              }
              const imageSource = image.createImageSource(buffer)
              const imagePixelMap = await imageSource.createPixelMap()
              const imageSize = imagePixelMap.getImageInfoSync().size
              if (imageSize.width !== imageSize.height) {
                promptAction.openToast({
                  message: '请选择宽高比为 1:1 的图片'
                })
                return
              }
              if (this.infoValue) {
                try {
                  fileIo.unlinkSync(this.infoValue.replace('file://com.zhangxm.aipasswordmemo', ''))
                } catch (err) {
                  promptAction.openToast({
                    message: '发生错误，错误码：' + err.code
                  })
                }
              }
              const passwordIconDir = this.context.filesDir + '/media/passwordicon'
              if (!fileIo.accessSync(passwordIconDir)) {
                fileIo.mkdirSync(passwordIconDir, true)
              }
              const filePath = passwordIconDir + '/' + Date.now() + '.png'
              const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE)
              const imagePacker = image.createImagePacker()
              await imagePacker.packToFile(imagePixelMap, file.fd, {
                format: 'image/png',
                quality: 100
              })
              fileIo.closeSync(file)
              this.infoValue = fileUri.getUriFromPath(filePath)
            }
          })
          Select(this.oftenUsedInfoTypes.map((item): SelectItem => {
            return {
              value: item
            }
          }))
            .selected(this.infoTypeIndex!!)
            .value(this.infoTypeValue!!)
            .onSelect((index, value) => {
              if (value === '图标') {
                this.infoValue = ''
              }
              if (this.infoValue.startsWith('file://com.zhangxm.aipasswordmemo')) {
                try {
                  fileIo.unlinkSync(this.infoValue.replace('file://com.zhangxm.aipasswordmemo', ''))
                } catch (err) {
                  promptAction.openToast({
                    message: '发生错误，错误码：' + err.code
                  })
                }
                this.infoValue = ''
              }
            })
          if (this.infoTypeValue === '自定义') {
            TextInput({
              placeholder: '请输入类型',
              text: this.infoType!!
            })
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .onChange((value) => {
                if (this.oftenUsedInfoTypes.includes(value)) {
                  this.infoTypeIndex = this.oftenUsedInfoTypes.indexOf(value)
                  this.infoTypeValue = value
                  this.infoType = ''
                }
                if (value === '图标') {
                  this.infoValue = ''
                }
                if (this.infoValue.startsWith('file://com.zhangxm.aipasswordmemo')) {
                  try {
                    fileIo.unlinkSync(this.infoValue.replace('file://com.zhangxm.aipasswordmemo', ''))
                  } catch (err) {
                    promptAction.openToast({
                      message: '发生错误，错误码：' + err.code
                    })
                  }
                  this.infoValue = ''
                }
              })
          }
          if (this.getCurrentInfoType() === '图标') {
            Button('选择图片')
              .buttonStyle(ButtonStyleMode.NORMAL)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .visualEffect(new hdsEffect.HdsEffectBuilder()
                .pointLight({
                  sourceType: hdsEffect.PointLightSourceType.SOFT,
                  illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
                })
                .buildEffect())
              .bindMenu(this.ChooseImageMenu, {
                hapticFeedbackMode: HapticFeedbackMode.AUTO
              })
            TextInput({
              placeholder: '请选择图片',
              text: this.infoValue
            })
              .enableAutoSpacing(true)
              .enabled(false)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
          }
          if (this.getCurrentInfoType() === '昵称') {
            TextInput({
              placeholder: '请输入内容',
              text: this.infoValue!!
            })
              .contentType(ContentType.NICKNAME)
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
          }
          if (this.getCurrentInfoType() === '用户名') {
            TextInput({
              placeholder: '请输入内容',
              text: this.infoValue!!
            })
              .contentType(ContentType.USER_NAME)
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .type(InputType.USER_NAME)
          }
          if (this.getCurrentInfoType() === '密码') {
            TextInput({
              placeholder: '请输入内容',
              text: this.infoValue!!
            })
              .enableAutoFill(false)
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .type(InputType.Password)
          }
          if (this.getCurrentInfoType() === '姓名') {
            TextInput({
              placeholder: '请输入内容',
              text: this.infoValue!!
            })
              .contentType(ContentType.PERSON_FULL_NAME)
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
          }
          if (this.getCurrentInfoType() === '手机号') {
            TextInput({
              placeholder: '请输入内容',
              text: this.infoValue!!
            })
              .contentType(ContentType.PHONE_NUMBER)
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .type(InputType.PhoneNumber)
          }
          if (this.getCurrentInfoType() === '邮箱') {
            TextInput({
              placeholder: '请输入内容',
              text: this.infoValue!!
            })
              .contentType(ContentType.EMAIL_ADDRESS)
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .type(InputType.Email)
          }
          if (this.getCurrentInfoType() === '银行卡号') {
            TextInput({
              placeholder: '请输入内容',
              text: this.infoValue!!
            })
              .contentType(ContentType.BANK_CARD_NUMBER)
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .type(InputType.Number)
          }
          if (this.getCurrentInfoType() === '身份证号') {
            TextInput({
              placeholder: '请输入内容',
              text: this.infoValue!!
            })
              .contentType(ContentType.ID_CARD_NUMBER)
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
          }
          if (this.getCurrentInfoType() === 'URL') {
            TextInput({
              placeholder: '请输入内容',
              text: this.infoValue!!
            })
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .type(InputType.URL)
          }
          if (!this.specialInfoTypes.includes(this.getCurrentInfoType())) {
            TextInput({
              placeholder: '请输入内容',
              text: this.infoValue!!
            })
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
          }
        }
        .alignItems(HorizontalAlign.Start)
      }

      ListItem() {
        Column() {
          Column() {
            Row() {
              Text('云备份')
                .fontWeight(FontWeight.Medium)
              Blank()
              Toggle({
                type: ToggleType.Switch,
                isOn: this.cloudBackup!!
              })
                .enabled(this.allowCloudBackup && this.getCurrentInfoType() !== '图标')
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))

          if (!this.allowCloudBackup) {
            Text(this.alertText)
              .fontColor($r('sys.color.warning'))
              .fontSize($r('sys.float.ohos_id_text_size_body3'))
              .margin({
                top: 6,
                left: 12,
                right: 12
              })
          }
        }
        .alignItems(HorizontalAlign.Start)
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      ListItem() {
        Button('新增')
          .onClick(async () => {
            const infoType = this.getCurrentInfoType()
            if (!infoType) {
              promptAction.openToast({
                message: '请输入类型'
              })
              return
            }
            if (!this.infoValue) {
              promptAction.openToast({
                message: '请输入内容'
              })
              return
            }
            const res = await newInfo({
              type: infoType,
              value: this.infoValue,
              cloudBackup: this.cloudBackup
            })
            if (res === 'success') {
              this.isShowNewSheet = false
            }
          })
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })
      .width('100%')
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_max_padding_start'),
      right: $r('sys.float.ohos_id_max_padding_end')
    })
    .onAppear(async () => {
      const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
        name: 'commonSetting'
      })
      const oftenUsedInfoType = commonSettingDataPreferences.getSync('oftenUsedInfoType', ['密码', '图标']) as string[]
      this.oftenUsedInfoTypes = oftenUsedInfoType.concat(this.oftenUsedInfoTypes)
      this.infoTypeValue = this.oftenUsedInfoTypes[0]
      const res = await getCloudServiceStatus()
      const key = getKey()
      if (!res) {
        this.alertText = '未登录账号或账号未开通云服务，云备份不可用'
      }
      if (res) {
        if (!key) {
          this.alertText = '未导入密钥，云备份不可用。请前往“我的”>“设置”>“云备份”>“密钥”导入密钥'
        }
        if (key) {
          this.allowCloudBackup = true
          this.alertText = ''
          const abilityContext = this.getUIContext().getHostContext()
          const cloudbackupSettingDataPreferences = preferences.getPreferencesSync(abilityContext, {
            name: 'cloudbackupSetting'
          })
          const autoOn: string[] = cloudbackupSettingDataPreferences.getSync('autoOn', []) as string[]
          if (autoOn.includes('info')) {
            this.cloudBackup = true
          }
        }
      }
    })
  }
}