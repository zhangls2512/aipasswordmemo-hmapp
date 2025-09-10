import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { uri } from '@kit.ArkTS'
import { promptAction } from '@kit.ArkUI'
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
import { updatePassword } from '../common/Datachange'
import { getPasswordInfo, getTagList, getTypeInfoList, Password, PasswordInfoItem } from '../common/Dataget'

@ComponentV2
export default struct Newpassword {
  @Consumer() isShowUpdateSheet: boolean = false
  @Param passwordId: number = 0
  @Local passwordName: string = ''
  @Local passwordInfoArray: PasswordInfoItem[] = []
  @Local infoType: string = '密码'
  @Local infoTypeIndex: number = 3
  @Local infoTypeValue: string = '密码'
  @Local infoValue: string = ''
  @Local mfaStep: string = '30'
  @Local mfaDigits: string = '6'
  @Local infoArray: string[] = []
  @Local passwordTagArray: string[] = []
  @Local passwordTag: string = ''
  @Local tagArray: string[] = []
  @Local cloudBackup: boolean = false
  @Local allowCloudBackup: boolean = false
  @Local alertText: string = ''
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  specialTypes: string[] =
    ['图标', '昵称', '用户名', '密码', 'MFA', '姓名', '手机号', '邮箱', '银行卡号', '身份证号', 'URL']

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
              fileIo.unlinkSync(this.infoValue.replace('file://com.zhangxm.aipasswordmemo', ''))
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
            if (err.code === 13900020) {
              return
            }
            promptAction.openToast({
              message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
            })
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
                fileIo.unlinkSync(this.infoValue.replace('file://com.zhangxm.aipasswordmemo', ''))
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
          Select([
            { value: '图标' },
            { value: '昵称' },
            { value: '用户名' },
            { value: '密码' },
            { value: 'MFA' },
            { value: '姓名' },
            { value: '手机号' },
            { value: '邮箱' },
            { value: '银行卡号' },
            { value: '身份证号' },
            { value: 'URL' },
            { value: '自定义' }
          ])
            .enabled((this.infoType === '图标' && this.infoValue === '') || this.infoType !== '图标')
            .selected(this.infoTypeIndex!!)
            .value(this.infoTypeValue!!)
            .onSelect(async (index, value) => {
              if (index !== 11) {
                this.infoType = value
                this.infoArray = await getTypeInfoList(value)
              }
              if (index === 11) {
                this.infoType = ''
                this.infoArray = []
              }
            })
          if (!this.specialTypes.includes(this.infoType)) {
            TextInput({
              placeholder: '请输入类型',
              text: this.infoType!!
            })
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .onChange(async (value) => {
                if (this.specialTypes.includes(value)) {
                  this.infoTypeIndex = this.specialTypes.indexOf(value)
                  this.infoTypeValue = value
                }
                this.infoArray = await getTypeInfoList(value)
              })
          }
          if (this.infoType === '图标') {
            Button('选择图片')
              .buttonStyle(ButtonStyleMode.NORMAL)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .bindMenu(this.ChooseImageMenu, {
                hapticFeedbackMode: HapticFeedbackMode.AUTO
              })
            TextInput({
              placeholder: '请选择图片',
              text: this.infoValue
            })
              .enabled(false)
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
          }
          if (this.infoType === '昵称') {
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
          if (this.infoType === '用户名') {
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
          if (this.infoType === '密码') {
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
          if (this.infoType === 'MFA') {
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
          if (this.infoType === '姓名') {
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
          if (this.infoType === '手机号') {
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
          if (this.infoType === '邮箱') {
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
          if (this.infoType === '银行卡号') {
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
          if (this.infoType === '身份证号') {
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
          if (this.infoType === 'URL') {
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
          if (!this.specialTypes.includes(this.infoType)) {
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
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      ForEach(this.infoArray, (item: string) => {
        ListItem() {
          Column() {
            Row() {
              Text(item)
                .width('75%')
              Blank()
                .width('5%')
              Button('添加')
                .width('20%')
                .onClick(() => {
                  if (this.passwordInfoArray.some(item => item.type === this.infoType)) {
                    promptAction.openToast({
                      message: '已添加此类型信息'
                    })
                    return
                  }
                  this.passwordInfoArray.push({
                    type: this.infoType,
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
      })
      ListItem() {
        Column() {
          Row() {
            Button('添加')
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .onClick(async () => {
                if (!this.infoType) {
                  promptAction.openToast({
                    message: '请输入类型'
                  })
                  return
                }
                if (this.passwordInfoArray.some(item => item.type === this.infoType)) {
                  promptAction.openToast({
                    message: '已添加此类型信息'
                  })
                  return
                }
                let value = this.infoValue
                if (this.infoType === '图标' && !value) {
                  promptAction.openToast({
                    message: '请选择图片'
                  })
                  return
                }
                if (this.infoType !== '图标' && this.infoType !== 'MFA' && !value) {
                  promptAction.openToast({
                    message: '请输入内容'
                  })
                  return
                }
                if (this.infoType === 'MFA') {
                  if (!value) {
                    promptAction.openToast({
                      message: '请输入密钥'
                    })
                    return
                  }
                  if (!this.mfaStep) {
                    promptAction.openToast({
                      message: '请输入步长'
                    })
                    return
                  }
                  if (!this.mfaDigits) {
                    promptAction.openToast({
                      message: '请输入位数'
                    })
                    return
                  }
                  value = this.infoValue + '\0' + this.mfaStep + '\0' + this.mfaDigits
                }
                this.passwordInfoArray.push({
                  type: this.infoType,
                  value: value
                })
                this.infoType = '密码'
                this.infoTypeIndex = 3
                this.infoTypeValue = '密码'
                this.infoValue = ''
                this.infoArray = await getTypeInfoList('密码')
              })
            if (this.infoType === 'MFA') {
              Button('扫码添加')
                .buttonStyle(ButtonStyleMode.NORMAL)
                .onClick(async () => {
                  if (this.passwordInfoArray.some(item => item.type === 'MFA')) {
                    promptAction.openToast({
                      message: '已添加此类型信息'
                    })
                    return
                  }
                  const res = await scanBarcode.startScanForResult(this.context, {
                    scanTypes: [scanCore.ScanType.QR_CODE]
                  })
                  const uriInstance = new uri.URI(res.originalValue)
                  if (uriInstance.scheme !== 'otpauth') {
                    promptAction.openToast({
                      message: '请扫描有效的 MFA 添加二维码'
                    })
                    return
                  }
                  const uriSecret = uriInstance.getQueryValue('secret')
                  if (!uriSecret) {
                    promptAction.openToast({
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
                  this.infoType = '密码'
                  this.infoTypeIndex = 3
                  this.infoTypeValue = '密码'
                  this.infoValue = ''
                  this.infoArray = await getTypeInfoList('密码')
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
                Text(item.value)
                  .fontWeight(FontWeight.Medium)
                Text(item.type)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .width('75%')

              Blank()
                .width('5%')
              Button('删除')
                .role(ButtonRole.ERROR)
                .width('20%')
                .onClick(() => {
                  if (item.type === '图标') {
                    try {
                      fileIo.unlinkSync(item.value.replace('file://com.zhangxm.aipasswordmemo', ''))
                    } catch (err) {
                      promptAction.openToast({
                        message: '发生错误，错误码：' + err.code
                      })
                    }
                  }
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
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      ForEach(this.tagArray, (item: string) => {
        ListItem() {
          Column() {
            Row() {
              Text(item)
                .width('75%')
              Blank()
                .width('5%')
              Button('添加')
                .width('20%')
                .onClick(() => {
                  if (this.passwordTagArray.some(tagItem => tagItem === item)) {
                    promptAction.openToast({
                      message: '已添加此标签'
                    })
                    return
                  }
                  this.passwordTagArray.push(item)
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
          Button('添加')
            .onClick(() => {
              if (!this.passwordTag) {
                promptAction.openToast({
                  message: '请输入内容'
                })
                return
              }
              if (this.passwordTagArray.some(item => item === this.passwordTag)) {
                promptAction.openToast({
                  message: '已添加此标签'
                })
                return
              }
              this.passwordTagArray.push(this.passwordTag)
              this.passwordTag = ''
            })
        }
        .width('100%')
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_m')
      })

      ForEach(this.passwordTagArray, (item: string, index) => {
        ListItem() {
          Column() {
            Row() {
              Text(item)
                .width('75%')
              Blank()
                .width('5%')
              Button('删除')
                .role(ButtonRole.ERROR)
                .width('20%')
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
          Column() {
            Row() {
              Text('云备份')
                .fontWeight(FontWeight.Medium)
              Blank()
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
        Column() {
          Button('修改')
            .onClick(async () => {
              if (!this.passwordName) {
                promptAction.openToast({
                  message: '请输入名称'
                })
                return
              }
              if (this.passwordInfoArray.length === 0) {
                promptAction.openToast({
                  message: '请添加信息'
                })
                return
              }
              await updatePassword(this.passwordId, {
                name: this.passwordName,
                info: this.passwordInfoArray,
                tag: this.passwordTagArray,
                cloudBackup: this.cloudBackup
              })
              this.isShowUpdateSheet = false
            })
        }
        .width('100%')
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
    .onAppear(async () => {
      const passwordInfo = await getPasswordInfo(this.passwordId) as Password
      this.passwordName = passwordInfo.name
      this.passwordInfoArray = passwordInfo.info
      this.passwordTagArray = passwordInfo.tag.map(item => item.value)
      this.infoArray = await getTypeInfoList(this.infoType)
      const tags = await getTagList()
      this.tagArray = tags.map(item => item.value)
      const res = await getCloudServiceStatus()
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
          const abilityContext = this.context
          const cloudbackupSettingDataPreferences = preferences.getPreferencesSync(abilityContext, {
            name: 'cloudbackupSetting'
          })
          const autoOn: string[] = cloudbackupSettingDataPreferences.getSync('autoOn', []) as string[]
          if (autoOn.includes('password')) {
            this.cloudBackup = true
          }
        }
      }
    })
  }
}