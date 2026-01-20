import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { uri } from '@kit.ArkTS'
import { display, promptAction } from '@kit.ArkUI'
import { deviceInfo } from '@kit.BasicServicesKit'
import { fileIo, fileUri } from '@kit.CoreFileKit'
import { image } from '@kit.ImageKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { scanBarcode, scanCore } from '@kit.ScanKit'
import {
  CollaborationServiceFilter,
  CollaborationServiceStateDialog,
  createCollaborationServiceMenuItems
} from '@kit.ServiceCollaborationKit'
import getCloudServiceStatus from '../common/Cloudservice'
import { getKey } from '../common/Crypto'
import { newInfo, newTag, updatePassword } from '../common/Datachange'
import { getPasswordInfo, getTagList, getTypeInfoList, Password, PasswordInfoItem, Tag } from '../common/Dataget'
import getPreferType from '../common/Prefertype'
import { SelectItem } from './Newpassword'
import Passwordgenerate from './Passwordgenerate'

@ComponentV2
export default struct Updatepassword {
  @Consumer() isShowUpdateSheet: boolean = false
  @Provider() isShowPasswordgenerateSheet: boolean = false
  @Local preferType: number = 1
  @Param passwordId: number = 0
  @Local passwordName: string = ''
  @Local passwordInfoArray: PasswordInfoItem[] = []
  @Local infoType: string = ''
  @Local infoTypeIndex: number = 0
  @Local infoTypeValue: string = ''
  @Local infoValue: string = ''
  @Local otpauthUri: string = ''
  @Local mfaStep: string = '30'
  @Local mfaDigits: string = '6'
  @Local infoArray: string[] = []
  @Local passwordTagArray: string[] = []
  @Local passwordTag: string = ''
  @Local tagArray: Tag[] = []
  @Local autoNewInfo: boolean = false
  @Local autoNewTag: boolean = true
  @Local cloudBackup: boolean = false
  @Local allowCloudBackup: boolean = false
  @Local alertText: string = ''
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  pushItemWhenBlur = false
  oftenUsedInfoTypes = ['自定义']
  specialInfoTypes = ['图标', '昵称', '用户名', '密码', 'MFA', '姓名', '手机号', '邮箱', '银行卡号', '身份证号', 'URL']
  cloudbackupSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'cloudbackupSetting'
  })

  getCurrentInfoType() {
    let infoType = this.infoType
    if (this.infoTypeValue !== '自定义') {
      infoType = this.infoTypeValue
    }
    return infoType
  }

  async inputBlur() {
    const infoType = this.getCurrentInfoType()
    if (this.pushItemWhenBlur && infoType && !this.passwordInfoArray.some(item => item.type === infoType) &&
    this.infoValue) {
      this.passwordInfoArray.push({
        type: infoType,
        value: this.infoValue
      })
      this.infoType = ''
      this.infoTypeIndex = 0
      this.infoTypeValue = this.oftenUsedInfoTypes[0]
      this.infoValue = ''
      this.otpauthUri = ''
      this.mfaStep = '30'
      this.mfaDigits = '6'
      if (this.infoTypeValue !== 'MFA' && this.infoTypeValue !== '自定义') {
        this.infoArray = await getTypeInfoList(this.context, this.infoTypeValue)
      }
    }
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
              isPhotoTakingSupported: false,
              isOriginalSupported: false
            })
            const fileSource = fileIo.openSync(pickerres.photoUris[0])
            const imageSource = image.createImageSource(fileSource.fd)
            const imagePixelMap = await imageSource.createPixelMap()
            const imageSize = imagePixelMap.getImageInfoSync().size
            if (imageSize.width !== imageSize.height) {
              await promptAction.openToast({
                message: '请选择宽高比为 1:1 的图片'
              })
              return
            }
            const passwordIconDir = this.context.filesDir + '/media/passwordicon/'
            if (!fileIo.accessSync(passwordIconDir)) {
              await fileIo.mkdir(passwordIconDir, true)
            }
            const filePath = passwordIconDir + Date.now() + '.png'
            const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
            const imagePacker = image.createImagePacker()
            await imagePacker.packToFile(imagePixelMap, file.fd, {
              format: 'image/png',
              quality: 100
            })
            await imagePacker.release()
            await imagePixelMap.release()
            await imageSource.release()
            fileIo.closeSync(file)
            this.infoValue = fileUri.getUriFromPath(filePath)
          } catch {
          }
        })
      if (deviceInfo.deviceType !== 'phone') {
        MenuItem({
          content: '其他设备',
          builder: this.SubMenu()
        })
      }
    }
  }

  @Builder
  SubMenu() {
    Menu() {
      createCollaborationServiceMenuItems([CollaborationServiceFilter.IMAGE_PICKER], 1)
    }
  }

  @Builder
  PasswordgenerateSheetBuilder() {
    Passwordgenerate({
      inputPassword: true
    })
  }

  build() {
    List() {
      ListItem() {
        TextInput({
          placeholder: '请输入名称',
          text: this.passwordName!!
        })
          .enableAutoSpacing(true)
      }

      ListItem() {
        Text('信息')
          .fontWeight(FontWeight.Medium)
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      ListItem() {
        Column() {
          CollaborationServiceStateDialog({
            async onState(stateCode: number, bufferType: string, buffer: ArrayBuffer) {
              if (stateCode !== 0) {
                await promptAction.openToast({
                  message: '发生错误，错误码：' + stateCode
                })
                return
              }
              if (bufferType !== 'general.image') {
                await promptAction.openToast({
                  message: '请选择图片'
                })
                return
              }
              const imageSource = image.createImageSource(buffer)
              const imagePixelMap = await imageSource.createPixelMap()
              const imageSize = imagePixelMap.getImageInfoSync().size
              if (imageSize.width !== imageSize.height) {
                await promptAction.openToast({
                  message: '请选择宽高比为 1:1 的图片'
                })
                return
              }
              const passwordIconDir = this.context.filesDir + '/media/passwordicon/'
              if (!fileIo.accessSync(passwordIconDir)) {
                await fileIo.mkdir(passwordIconDir, true)
              }
              const filePath = passwordIconDir + Date.now() + '.png'
              const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
              const imagePacker = image.createImagePacker()
              await imagePacker.packToFile(imagePixelMap, file.fd, {
                format: 'image/png',
                quality: 100
              })
              await imagePacker.release()
              await imagePixelMap.release()
              await imageSource.release()
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
            .onSelect(async (index, value) => {
              if (value === '图标') {
                this.infoValue = ''
              }
              if (value !== 'MFA') {
                this.infoArray = await getTypeInfoList(this.context, value)
              }
              if (value === 'MFA' || value === '自定义') {
                this.infoArray = []
              }
              if (this.infoValue.startsWith('file://com.zhangxm.aipasswordmemo')) {
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
              .onChange(async (value) => {
                if (this.oftenUsedInfoTypes.includes(value)) {
                  this.infoTypeIndex = this.oftenUsedInfoTypes.indexOf(value)
                  this.infoTypeValue = value
                  this.infoType = ''
                }
                if (value === '图标') {
                  this.infoValue = ''
                }
                if (value !== 'MFA') {
                  this.infoArray = await getTypeInfoList(this.context, value)
                }
                if (value === 'MFA' || value === '自定义') {
                  this.infoArray = []
                }
                if (this.infoValue.startsWith('file://com.zhangxm.aipasswordmemo')) {
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
              .width('100%')
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
              .onBlur(async () => {
                await this.inputBlur()
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
              .onBlur(async () => {
                await this.inputBlur()
              })
          }
          if (this.getCurrentInfoType() === '密码') {
            Button('随机生成')
              .buttonStyle(ButtonStyleMode.NORMAL)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .width('100%')
              .onClick(() => {
                this.isShowPasswordgenerateSheet = true
              })
              .bindSheet(this.isShowPasswordgenerateSheet!!, this.PasswordgenerateSheetBuilder(), {
                height: SheetSize.FIT_CONTENT,
                preferType: this.preferType,
                title: {
                  title: '密码随机生成'
                },
                onAppear: () => {
                  this.context.eventHub.on('inputPassword', (password: string) => {
                    this.infoValue = password
                  })
                },
                onDisappear: () => {
                  this.context.eventHub.off('inputPassword')
                }
              })
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
              .onBlur(async () => {
                await this.inputBlur()
              })
          }
          if (this.getCurrentInfoType() === 'MFA') {
            TextInput({
              placeholder: 'otpauth://...',
              text: this.otpauthUri!!
            })
              .enableAutoFill(false)
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .onBlur(async () => {
                const infoType = this.getCurrentInfoType()
                if (this.pushItemWhenBlur && infoType && !this.passwordInfoArray.some(item => item.type === infoType) &&
                this.otpauthUri) {
                  const uriInstance = new uri.URI(this.otpauthUri)
                  if (uriInstance.scheme !== 'otpauth') {
                    return
                  }
                  const uriSecret = uriInstance.getQueryValue('secret')
                  if (!uriSecret) {
                    return
                  }
                  let step = '30'
                  let digits = '6'
                  const uriStep = uriInstance.getQueryValue('period')
                  const uriDigits = uriInstance.getQueryValue('digits')
                  if (uriStep) {
                    step = uriStep
                  }
                  if (uriDigits) {
                    digits = uriDigits
                  }
                  this.passwordInfoArray.push({
                    type: infoType,
                    value: uriSecret + '\0' + step + '\0' + digits
                  })
                  this.infoType = ''
                  this.infoTypeIndex = 0
                  this.infoTypeValue = this.oftenUsedInfoTypes[0]
                  this.infoValue = ''
                  this.otpauthUri = ''
                  this.mfaStep = '30'
                  this.mfaDigits = '6'
                  if (this.infoTypeValue !== 'MFA' && this.infoTypeValue !== '自定义') {
                    this.infoArray = await getTypeInfoList(this.context, this.infoTypeValue)
                  }
                }
              })
            if (!this.otpauthUri) {
              TextInput({
                placeholder: '请输入密钥',
                text: this.infoValue!!
              })
                .enableAutoFill(false)
                .enableAutoSpacing(true)
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
                .type(InputType.Password)
              TextInput({
                placeholder: '请输入步长 (单位：秒)',
                text: this.mfaStep!!
              })
                .enableAutoSpacing(true)
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
                .type(InputType.Number)
              TextInput({
                placeholder: '请输入位数',
                text: this.mfaDigits!!
              })
                .enableAutoSpacing(true)
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
                .type(InputType.Number)
            }
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
              .onBlur(async () => {
                await this.inputBlur()
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
              .onBlur(async () => {
                await this.inputBlur()
              })
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
              .onBlur(async () => {
                await this.inputBlur()
              })
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
              .onBlur(async () => {
                await this.inputBlur()
              })
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
              .onBlur(async () => {
                await this.inputBlur()
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
              .onBlur(async () => {
                await this.inputBlur()
              })
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
              .onBlur(async () => {
                await this.inputBlur()
              })
          }
        }
        .alignItems(HorizontalAlign.Start)
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      ForEach(this.infoArray, (item: string) => {
        if (!this.passwordInfoArray.some(infoItem => infoItem.value === item)) {
          ListItem() {
            Column() {
              Row() {
                if (this.getCurrentInfoType() !== '图标') {
                  Text(item)
                    .enableAutoSpacing(true)
                    .layoutWeight(1)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                }
                if (this.getCurrentInfoType() === '图标') {
                  Image(item)
                    .autoResize(true)
                    .copyOption(CopyOptions.LocalDevice)
                    .layoutWeight(1)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                    .width('10%')
                    .onError(async (err) => {
                      await promptAction.openToast({
                        message: '发生错误，错误信息：' + err.message
                      })
                    })
                }
                Image($r('app.media.add'))
                  .width('8%')
                  .onClick(async () => {
                    if (this.passwordInfoArray.some(item => item.type === this.getCurrentInfoType())) {
                      await promptAction.openToast({
                        message: '已添加此类型信息'
                      })
                      return
                    }
                    this.passwordInfoArray.push({
                      type: this.getCurrentInfoType(),
                      value: item
                    })
                  })
              }
              .borderRadius(12)
              .padding(12)
              .width('100%')
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
        }
      })
      ListItem() {
        Column() {
          Row() {
            Button('添加')
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .onClick(async () => {
                const infoType = this.getCurrentInfoType()
                if (!infoType) {
                  await promptAction.openToast({
                    message: '请输入类型'
                  })
                  return
                }
                if (this.passwordInfoArray.some(item => item.type === infoType)) {
                  await promptAction.openToast({
                    message: '已添加此类型信息'
                  })
                  return
                }
                let value = this.infoValue
                if (infoType === '图标' && !value) {
                  await promptAction.openToast({
                    message: '请选择图片'
                  })
                  return
                }
                if (infoType !== '图标' && infoType !== 'MFA' && !value) {
                  await promptAction.openToast({
                    message: '请输入内容'
                  })
                  return
                }
                if (infoType === 'MFA') {
                  if (!this.otpauthUri) {
                    if (!value) {
                      await promptAction.openToast({
                        message: '请输入密钥'
                      })
                      return
                    }
                    if (!this.mfaStep) {
                      await promptAction.openToast({
                        message: '请输入步长'
                      })
                      return
                    }
                    if (!this.mfaDigits) {
                      await promptAction.openToast({
                        message: '请输入位数'
                      })
                      return
                    }
                    value = this.infoValue + '\0' + this.mfaStep + '\0' + this.mfaDigits
                  }
                  if (this.otpauthUri) {
                    const uriInstance = new uri.URI(this.otpauthUri)
                    if (uriInstance.scheme !== 'otpauth') {
                      await promptAction.openToast({
                        message: '请输入有效的 otpauthUri'
                      })
                      return
                    }
                    const uriSecret = uriInstance.getQueryValue('secret')
                    if (!uriSecret) {
                      await promptAction.openToast({
                        message: '请输入有效的 otpauthUri'
                      })
                      return
                    }
                    let step = '30'
                    let digits = '6'
                    const uriStep = uriInstance.getQueryValue('period')
                    const uriDigits = uriInstance.getQueryValue('digits')
                    if (uriStep) {
                      step = uriStep
                    }
                    if (uriDigits) {
                      digits = uriDigits
                    }
                    value = uriSecret + '\0' + step + '\0' + digits
                  }
                }
                this.passwordInfoArray.push({
                  type: infoType,
                  value: value
                })
                this.infoType = ''
                this.infoTypeIndex = 0
                this.infoTypeValue = this.oftenUsedInfoTypes[0]
                this.infoValue = ''
                this.otpauthUri = ''
                this.mfaStep = '30'
                this.mfaDigits = '6'
                if (this.infoTypeValue !== 'MFA' && this.infoTypeValue !== '自定义') {
                  this.infoArray = await getTypeInfoList(this.context, this.infoTypeValue)
                }
              })
            if (this.getCurrentInfoType() === 'MFA') {
              Button('扫码添加')
                .buttonStyle(ButtonStyleMode.NORMAL)
                .onClick(async () => {
                  if (this.passwordInfoArray.some(item => item.type === 'MFA')) {
                    await promptAction.openToast({
                      message: '已添加此类型信息'
                    })
                    return
                  }
                  try {
                    const res = await scanBarcode.startScanForResult(this.context, {
                      scanTypes: [scanCore.ScanType.QR_CODE]
                    })
                    const uriInstance = new uri.URI(res.originalValue)
                    if (uriInstance.scheme !== 'otpauth') {
                      await promptAction.openToast({
                        message: '请扫描有效的 MFA 添加二维码'
                      })
                      return
                    }
                    const uriSecret = uriInstance.getQueryValue('secret')
                    if (!uriSecret) {
                      await promptAction.openToast({
                        message: '请扫描有效的 MFA 添加二维码'
                      })
                      return
                    }
                    let step = '30'
                    let digits = '6'
                    const uriStep = uriInstance.getQueryValue('period')
                    const uriDigits = uriInstance.getQueryValue('digits')
                    if (uriStep) {
                      step = uriStep
                    }
                    if (uriDigits) {
                      digits = uriDigits
                    }
                    this.passwordInfoArray.push({
                      type: 'MFA',
                      value: uriSecret + '\0' + step + '\0' + digits
                    })
                    this.infoType = ''
                    this.infoTypeIndex = 0
                    this.infoTypeValue = this.oftenUsedInfoTypes[0]
                    this.infoValue = ''
                    this.otpauthUri = ''
                    this.mfaStep = '30'
                    this.mfaDigits = '6'
                    if (this.infoTypeValue !== 'MFA' && this.infoTypeValue !== '自定义') {
                      this.infoArray = await getTypeInfoList(this.context, this.infoTypeValue)
                    }
                  } catch (err) {
                    if (err.code !== 1000500002) {
                      await promptAction.openToast({
                        message: '发生错误，错误码：' + err.code
                      })
                    }
                  }
                })
            }
          }
        }
        .width('100%')
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_m')
      })

      ForEach(this.passwordInfoArray, (item: PasswordInfoItem, index) => {
        ListItem() {
          Column() {
            Row() {
              Column() {
                if (item.type === '图标') {
                  Image(item.value)
                    .autoResize(true)
                    .copyOption(CopyOptions.LocalDevice)
                    .width('10%')
                    .onError(async (err) => {
                      await promptAction.openToast({
                        message: '发生错误，错误信息：' + err.message
                      })
                    })
                }
                if (item.type === 'MFA') {
                  Text('密钥：' + item.value.split('\0')[0] + '\n步长：' + item.value.split('\0')[1] + '\n位数：' +
                  item.value.split('\0')[2])
                    .fontWeight(FontWeight.Medium)
                }
                if (item.type !== '图标' && item.type !== 'MFA') {
                  Text(item.value)
                    .enableAutoSpacing(true)
                    .fontWeight(FontWeight.Medium)
                }
                Text(item.type)
                  .enableAutoSpacing(true)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })

              if (index !== 0) {
                Image($r('app.media.up'))
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .width('8%')
                  .onClick(() => {
                    const temp = this.passwordInfoArray[index]
                    this.passwordInfoArray[index] = this.passwordInfoArray[index - 1]
                    this.passwordInfoArray[index - 1] = temp
                  })
              }
              if (index !== this.passwordInfoArray.length - 1) {
                Image($r('app.media.down'))
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .width('8%')
                  .onClick(() => {
                    const temp = this.passwordInfoArray[index]
                    this.passwordInfoArray[index] = this.passwordInfoArray[index + 1]
                    this.passwordInfoArray[index + 1] = temp
                  })
              }
              Image($r('app.media.delete'))
                .width('8%')
                .onClick(() => {
                  this.passwordInfoArray.splice(index, 1)
                })
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
      })
      ListItem() {
        Text('标签')
          .fontWeight(FontWeight.Medium)
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      ListItem() {
        TextInput({
          placeholder: '请输入内容',
          text: this.passwordTag!!
        })
          .enableAutoSpacing(true)
          .onBlur(() => {
            if (this.pushItemWhenBlur && this.passwordTag &&
              !this.passwordTagArray.some(item => item === this.passwordTag)) {
              this.passwordTagArray.push(this.passwordTag)
              this.passwordTag = ''
            }
          })
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      ForEach(this.tagArray, (item: Tag) => {
        if (!this.passwordTagArray.includes(item.value)) {
          ListItem() {
            Column() {
              Row() {
                Text(item.value)
                  .enableAutoSpacing(true)
                  .fontColor(item.color)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Image($r('app.media.add'))
                  .width('8%')
                  .onClick(async () => {
                    if (this.passwordTagArray.some(tagItem => tagItem === item.value)) {
                      await promptAction.openToast({
                        message: '已添加此标签'
                      })
                      return
                    }
                    this.passwordTagArray.push(item.value)
                  })
              }
              .borderRadius(12)
              .padding(12)
              .width('100%')
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
        }
      })
      ListItem() {
        Button('添加')
          .width('100%')
          .onClick(async () => {
            if (!this.passwordTag) {
              await promptAction.openToast({
                message: '请输入内容'
              })
              return
            }
            if (this.passwordTagArray.some(item => item === this.passwordTag)) {
              await promptAction.openToast({
                message: '已添加此标签'
              })
              return
            }
            this.passwordTagArray.push(this.passwordTag)
            this.passwordTag = ''
          })
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_m')
      })

      ForEach(this.passwordTagArray, (item: string, index) => {
        ListItem() {
          Column() {
            Row() {
              Text(item)
                .enableAutoSpacing(true)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              if (index !== 0) {
                Image($r('app.media.up'))
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .width('8%')
                  .onClick(() => {
                    const temp = this.passwordTagArray[index]
                    this.passwordTagArray[index] = this.passwordTagArray[index - 1]
                    this.passwordTagArray[index - 1] = temp
                  })
              }
              if (index !== this.passwordTagArray.length - 1) {
                Image($r('app.media.down'))
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .width('8%')
                  .onClick(() => {
                    const temp = this.passwordTagArray[index]
                    this.passwordTagArray[index] = this.passwordTagArray[index + 1]
                    this.passwordTagArray[index + 1] = temp
                  })
              }
              Image($r('app.media.delete'))
                .width('8%')
                .onClick(() => {
                  this.passwordTagArray.splice(index, 1)
                })
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
      })
      ListItem() {
        Column() {
          Text('自动新增')
            .fontColor($r('sys.color.font_secondary'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontWeight(FontWeight.Medium)
            .margin({
              bottom: 6,
              left: 12,
              right: 12
            })
          Column() {
            Row() {
              Text('常用信息')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Toggle({
                type: ToggleType.Switch,
                isOn: this.autoNewInfo!!
              })
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
              Text('标签')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Toggle({
                type: ToggleType.Switch,
                isOn: this.autoNewTag!!
              })
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .alignItems(HorizontalAlign.Start)
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      ListItem() {
        Column() {
          Column() {
            Row() {
              Text('云备份')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Toggle({
                type: ToggleType.Switch,
                isOn: this.cloudBackup!!
              })
                .enabled(this.allowCloudBackup)
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
        Button('修改')
          .width('100%')
          .onClick(async () => {
            if (!this.passwordName) {
              await promptAction.openToast({
                message: '请输入名称'
              })
              return
            }
            if (this.passwordInfoArray.length === 0) {
              await promptAction.openToast({
                message: '请添加信息'
              })
              return
            }
            await updatePassword(this.context, this.passwordId, {
              name: this.passwordName,
              info: this.passwordInfoArray,
              tag: this.passwordTagArray,
              cloudBackup: this.cloudBackup
            })
            let infoCloudBackup = false
            let tagCloudBackup = false
            const autoOn = this.cloudbackupSettingDataPreferences.getSync('autoOn', []) as string[]
            if (this.allowCloudBackup && autoOn.includes('info')) {
              infoCloudBackup = true
            }
            if (this.allowCloudBackup && autoOn.includes('tag')) {
              tagCloudBackup = true
            }
            if (this.autoNewInfo) {
              const promises = this.passwordInfoArray.map(async (item) => {
                if (item.type !== 'MFA') {
                  await newInfo(this.context, {
                    type: item.type,
                    value: item.value,
                    cloudBackup: infoCloudBackup
                  })
                }
              })
              await Promise.all(promises)
            }
            if (this.autoNewTag) {
              const promises = this.passwordTagArray.map(async (item) => {
                await newTag(this.context, {
                  value: item,
                  color: '',
                  cloudBackup: tagCloudBackup
                })
              })
              await Promise.all(promises)
            }
            this.isShowUpdateSheet = false
          })
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
    })
    .onAppear(async () => {
      this.preferType = getPreferType(this.UIContext)
      display.on('change', () => {
        setTimeout(() => {
          this.preferType = getPreferType(this.UIContext)
        }, 200)
      })
      const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
        name: 'commonSetting'
      })
      this.pushItemWhenBlur = commonSettingDataPreferences.getSync('pushItemWhenBlur', true) as boolean
      const oftenUsedInfoType =
        commonSettingDataPreferences.getSync('oftenUsedInfoType', ['密码', 'MFA', '图标']) as string[]
      this.oftenUsedInfoTypes = oftenUsedInfoType.concat(this.oftenUsedInfoTypes)
      this.infoTypeValue = this.oftenUsedInfoTypes[0]
      if (this.infoTypeValue !== 'MFA' && this.infoTypeValue !== '自定义') {
        this.infoArray = await getTypeInfoList(this.context, this.infoTypeValue)
      }
      this.tagArray = await getTagList(this.context, 'value')
      const passwordInfo = await getPasswordInfo(this.context, this.passwordId) as Password
      this.passwordName = passwordInfo.name
      this.passwordInfoArray = passwordInfo.info
      this.passwordTagArray = passwordInfo.tag.map(item => item.value)
      const res = await getCloudServiceStatus(this.context)
      const key = getKey()
      if (!res) {
        this.alertText = '未登录账号或账号未开通云服务，云备份不可用'
      }
      if (res) {
        if (!key) {
          this.alertText = '未导入密钥，云备份不可用。请前往“我的”>“设置”>“密钥”导入密钥'
        }
        if (key) {
          this.allowCloudBackup = true
          this.alertText = ''
          const autoOn = this.cloudbackupSettingDataPreferences.getSync('autoOn', []) as string[]
          if (autoOn.includes('password')) {
            this.cloudBackup = true
          }
        }
      }
    })
    .onDisAppear(() => {
      display.off('change')
    })
  }
}