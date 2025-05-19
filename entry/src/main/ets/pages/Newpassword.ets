import { preferences } from '@kit.ArkData'
import { uri } from '@kit.ArkTS'
import { promptAction } from '@kit.ArkUI'
import { scanBarcode, scanCore } from '@kit.ScanKit'
import getCloudServiceStatus from '../common/Cloudservice'
import { getKey } from '../common/Crypto'
import { newPassword } from '../common/Datachange'
import { getTagList, getTypeInfoList, PasswordInfoItem } from '../common/Dataget'

@ComponentV2
export default struct Newpassword {
  @Consumer() isShowNewSheet: boolean = false
  @Local passwordName: string = ''
  @Local passwordInfoArray: PasswordInfoItem[] = []
  @Local infoType: string = '密码'
  @Local infoTypeIndex: number = 2
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
  context = getContext(this)
  specialTypes: string[] = ['昵称', '用户名', '密码', 'MFA', '姓名', '手机号', '邮箱', '银行卡号', '身份证号', 'URL']

  build() {
    List() {
      ListItem() {
        TextInput({
          placeholder: '请输入名称',
          text: $$this.passwordName
        })
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
          Select([
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
            .selected($$this.infoTypeIndex)
            .value($$this.infoTypeValue)
            .onSelect(async (index: number, value: string) => {
              if (index === 10) {
                this.infoType = ''
                this.infoArray = []
              }
              if (index !== 10) {
                this.infoType = value
                this.infoArray = await getTypeInfoList(value)
              }
            })
          if (!this.specialTypes.includes(this.infoType)) {
            TextInput({
              placeholder: '请输入类型',
              text: $$this.infoType
            })
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .onChange(async (value: string) => {
                if (this.specialTypes.includes(value)) {
                  this.infoTypeIndex = this.specialTypes.indexOf(value)
                  this.infoTypeValue = value
                }
                this.infoArray = await getTypeInfoList(value)
              })
          }
          if (this.infoType === '昵称') {
            TextInput({
              placeholder: '请输入内容',
              text: $$this.infoValue
            })
              .contentType(ContentType.NICKNAME)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
          }
          if (this.infoType === '用户名') {
            TextInput({
              placeholder: '请输入内容',
              text: $$this.infoValue
            })
              .contentType(ContentType.USER_NAME)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .type(InputType.USER_NAME)
          }
          if (this.infoType === '密码') {
            TextInput({
              placeholder: '请输入内容',
              text: $$this.infoValue
            })
              .enableAutoFill(false)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .type(InputType.Password)
          }
          if (this.infoType === 'MFA') {
            TextInput({
              placeholder: '请输入密钥',
              text: $$this.infoValue
            })
              .enableAutoFill(false)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .type(InputType.Password)
            TextInput({
              placeholder: '请输入步长（单位：秒）',
              text: $$this.mfaStep
            })
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .type(InputType.Number)
            TextInput({
              placeholder: '请输入位数',
              text: $$this.mfaDigits
            })
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .type(InputType.Number)
          }
          if (this.infoType === '姓名') {
            TextInput({
              placeholder: '请输入内容',
              text: $$this.infoValue
            })
              .contentType(ContentType.PERSON_FULL_NAME)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
          }
          if (this.infoType === '手机号') {
            TextInput({
              placeholder: '请输入内容',
              text: $$this.infoValue
            })
              .contentType(ContentType.PHONE_NUMBER)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .type(InputType.PhoneNumber)
          }
          if (this.infoType === '邮箱') {
            TextInput({
              placeholder: '请输入内容',
              text: $$this.infoValue
            })
              .contentType(ContentType.EMAIL_ADDRESS)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .type(InputType.Email)
          }
          if (this.infoType === '银行卡号') {
            TextInput({
              placeholder: '请输入内容',
              text: $$this.infoValue
            })
              .contentType(ContentType.BANK_CARD_NUMBER)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .type(InputType.Number)
          }
          if (this.infoType === '身份证号') {
            TextInput({
              placeholder: '请输入内容',
              text: $$this.infoValue
            })
              .contentType(ContentType.ID_CARD_NUMBER)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
          }
          if (this.infoType === 'URL') {
            TextInput({
              placeholder: '请输入内容',
              text: $$this.infoValue
            })
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .type(InputType.URL)
          }
          if (!this.specialTypes.includes(this.infoType)) {
            TextInput({
              placeholder: '请输入内容',
              text: $$this.infoValue
            })
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
                    promptAction.showToast({
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
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
            .padding($r('sys.float.ohos_id_corner_radius_default_m'))
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
                  promptAction.showToast({
                    message: '请输入类型'
                  })
                  return
                }
                if (this.passwordInfoArray.some(item => item.type === this.infoType)) {
                  promptAction.showToast({
                    message: '已添加此类型信息'
                  })
                  return
                }
                let value = this.infoValue
                if (this.infoType !== 'MFA' && !value) {
                  promptAction.showToast({
                    message: '请输入内容'
                  })
                  return
                }
                if (this.infoType === 'MFA') {
                  if (!value) {
                    promptAction.showToast({
                      message: '请输入密钥'
                    })
                    return
                  }
                  if (!this.mfaStep) {
                    promptAction.showToast({
                      message: '请输入步长'
                    })
                    return
                  }
                  if (!this.mfaDigits) {
                    promptAction.showToast({
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
                this.infoTypeIndex = 2
                this.infoTypeValue = '密码'
                this.infoValue = ''
                this.infoArray = await getTypeInfoList('密码')
              })
            if (this.infoType === 'MFA') {
              Button('扫码添加')
                .buttonStyle(ButtonStyleMode.NORMAL)
                .onClick(async () => {
                  if (this.passwordInfoArray.some(item => item.type === 'MFA')) {
                    promptAction.showToast({
                      message: '已添加此类型信息'
                    })
                    return
                  }
                  const res = await scanBarcode.startScanForResult(this.context, {
                    scanTypes: [scanCore.ScanType.QR_CODE]
                  })
                  const uriInstance = new uri.URI(res.originalValue)
                  if (uriInstance.scheme !== 'otpauth') {
                    promptAction.showToast({
                      message: '请扫描有效的 MFA 添加二维码'
                    })
                    return
                  }
                  const uriSecret = uriInstance.getQueryValue('secret')
                  if (!uriSecret) {
                    promptAction.showToast({
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
                  this.infoTypeIndex = 2
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
                  this.passwordInfoArray.splice(index, 1)
                })
            }
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
            .padding($r('sys.float.ohos_id_corner_radius_default_m'))
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
          text: $$this.passwordTag
        })
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
                    promptAction.showToast({
                      message: '已添加此标签'
                    })
                    return
                  }
                  this.passwordTagArray.push(item)
                })
            }
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
            .padding($r('sys.float.ohos_id_corner_radius_default_m'))
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
                promptAction.showToast({
                  message: '请输入内容'
                })
                return
              }
              if (this.passwordTagArray.some(item => item === this.passwordTag)) {
                promptAction.showToast({
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
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
            .padding($r('sys.float.ohos_id_corner_radius_default_m'))
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
                isOn: $$this.cloudBackup
              })
                .enabled(this.allowCloudBackup)
            }
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
            .padding($r('sys.float.ohos_id_corner_radius_default_m'))
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
                left: $r('sys.float.ohos_id_corner_radius_default_m'),
                right: $r('sys.float.ohos_id_corner_radius_default_m')
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
          Button('新增')
            .onClick(async () => {
              if (!this.passwordName) {
                promptAction.showToast({
                  message: '请输入名称'
                })
                return
              }
              if (this.passwordInfoArray.length === 0) {
                promptAction.showToast({
                  message: '请添加信息'
                })
                return
              }
              await newPassword({
                name: this.passwordName,
                info: this.passwordInfoArray,
                tag: this.passwordTagArray,
                cloudBackup: this.cloudBackup
              })
              this.isShowNewSheet = false
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
          const cloudbackupSettingDataPreferences = preferences.getPreferencesSync(this.context, {
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