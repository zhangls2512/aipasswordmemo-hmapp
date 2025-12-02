import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { getTagList, getTypeInfoList, PasswordInfoItem, Tag } from '../common/Dataget'
import { SelectItem } from './Newpassword'

@ComponentV2
export default struct Filterpassword {
  @Consumer() isShowFilterSheet: boolean = false
  @Local passwordNameKeyword: string = ''
  @Local passwordInfoArray: PasswordInfoItem[] = []
  @Local infoType: string = ''
  @Local infoTypeIndex: number = 0
  @Local infoTypeValue: string = ''
  @Local infoValue: string = ''
  @Local infoArray: string[] = []
  @Local passwordTagArray: string[] = []
  @Local passwordTag: string = ''
  @Local tagArray: Tag[] = []
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  pushItemWhenBlur = false
  oftenUsedInfoTypes = ['自定义']
  specialInfoTypes = ['图标', '昵称', '用户名', '密码', '姓名', '手机号', '邮箱', '银行卡号', '身份证号', 'URL']
  filterPasswordDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'filterPassword'
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
      if (this.infoTypeValue !== '自定义') {
        this.infoArray = await getTypeInfoList(this.context, this.infoTypeValue)
      }
    }
  }

  build() {
    List() {
      ListItem() {
        TextInput({
          placeholder: '请输入名称关键词',
          text: this.passwordNameKeyword!!
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
          Select(this.oftenUsedInfoTypes.map((item): SelectItem => {
            return {
              value: item
            }
          }))
            .selected(this.infoTypeIndex!!)
            .value(this.infoTypeValue!!)
            .onSelect(async (index, value) => {
              if (value !== '自定义') {
                this.infoArray = await getTypeInfoList(this.context, value)
              }
              if (value === '自定义') {
                this.infoArray = []
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
                if (value !== '自定义') {
                  this.infoArray = await getTypeInfoList(this.context, value)
                }
                if (value === '自定义') {
                  this.infoArray = []
                }
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
        if (!this.passwordInfoArray.some(itema => itema.value === item)) {
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
      if (this.getCurrentInfoType() !== '图标') {
        ListItem() {
          Button('添加')
            .width('100%')
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
              if (!this.infoValue) {
                await promptAction.openToast({
                  message: '请输入内容'
                })
                return
              }
              this.passwordInfoArray.push({
                type: infoType,
                value: this.infoValue
              })
              this.infoType = ''
              this.infoTypeIndex = 0
              this.infoTypeValue = this.oftenUsedInfoTypes[0]
              this.infoValue = ''
              if (this.infoTypeValue !== '自定义') {
                this.infoArray = await getTypeInfoList(this.context, this.infoTypeValue)
              }
            })
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
      }
      ForEach(this.passwordInfoArray, (item: PasswordInfoItem, index) => {
        ListItem() {
          Column() {
            Row() {
              Column() {
                Text(item.value)
                  .enableAutoSpacing(true)
                  .fontWeight(FontWeight.Medium)
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
        Button('确定')
          .width('100%')
          .onClick(() => {
            this.isShowFilterSheet = false
            this.filterPasswordDataPreferences.putSync('nameKeyword', this.passwordNameKeyword)
            this.filterPasswordDataPreferences.putSync('info', this.passwordInfoArray)
            this.filterPasswordDataPreferences.putSync('tag', this.passwordTagArray)
            this.context.eventHub.emit('refreshFilterPassword')
          })
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
      const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
        name: 'commonSetting'
      })
      this.pushItemWhenBlur = commonSettingDataPreferences.getSync('pushItemWhenBlur', false) as boolean
      const oftenUsedInfoType = commonSettingDataPreferences.getSync('oftenUsedInfoType', ['密码', '图标']) as string[]
      this.oftenUsedInfoTypes = oftenUsedInfoType.concat(this.oftenUsedInfoTypes)
      this.infoTypeValue = this.oftenUsedInfoTypes[0]
      if (this.infoTypeValue !== 'MFA' && this.infoTypeValue !== '自定义') {
        this.infoArray = await getTypeInfoList(this.context, this.infoTypeValue)
      }
      this.tagArray = await getTagList(this.context)
      this.passwordNameKeyword = this.filterPasswordDataPreferences.getSync('nameKeyword', '') as string
      this.passwordInfoArray = this.filterPasswordDataPreferences.getSync('info', []) as PasswordInfoItem[]
      this.passwordTagArray = this.filterPasswordDataPreferences.getSync('tag', []) as string[]
    })
  }
}