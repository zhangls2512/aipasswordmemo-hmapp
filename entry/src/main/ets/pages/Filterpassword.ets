import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { getTagList, getTypeInfoList, PasswordInfoItem } from '../common/Dataget'
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
  @Local tagArray: string[] = []
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  oftenUsedInfoTypes: string[] = ['自定义']
  specialInfoTypes: string[] =
    ['图标', '昵称', '用户名', '密码', 'MFA', '姓名', '手机号', '邮箱', '银行卡号', '身份证号', 'URL']
  filterPasswordDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'filterPassword'
  })

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
                this.infoType = value
                this.infoArray = await getTypeInfoList(value)
              }
              if (value === '自定义') {
                this.infoType = ''
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
                }
                if (value !== '自定义') {
                  this.infoArray = await getTypeInfoList(value)
                }
                if (value === '自定义') {
                  this.infoArray = []
                }
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
          if (!this.specialInfoTypes.includes(this.infoType)) {
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
        if (!this.passwordInfoArray.some(itema => itema.value === item)) {
          ListItem() {
            Column() {
              Row() {
                if (this.infoType !== '图标') {
                  Text(item)
                    .enableAutoSpacing(true)
                    .width('87%')
                  Blank()
                    .width('5%')
                }
                if (this.infoType === '图标') {
                  Image(item)
                    .copyOption(CopyOptions.LocalDevice)
                    .width('10%')
                    .onError((err) => {
                      promptAction.openToast({
                        message: '发生错误，错误信息：' + err.message
                      })
                    })
                  Blank()
                    .width('82%')
                }
                Blank()
                  .width('5%')
                Image($r('app.media.add'))
                  .width('8%')
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
        }
      })
      if (this.infoType !== '图标') {
        ListItem() {
          Button('添加')
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
              if (!this.infoValue) {
                promptAction.openToast({
                  message: '请输入内容'
                })
                return
              }
              this.passwordInfoArray.push({
                type: this.infoType,
                value: this.infoValue
              })
              this.infoType = this.oftenUsedInfoTypes[0]
              this.infoTypeIndex = 0
              this.infoTypeValue = this.oftenUsedInfoTypes[0]
              this.infoValue = ''
              if (this.oftenUsedInfoTypes[0] !== 'MFA' && this.oftenUsedInfoTypes[0] !== '自定义') {
                this.infoArray = await getTypeInfoList(this.oftenUsedInfoTypes[0])
              }
            })
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
        .width('100%')
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
              .width('87%')

              Blank()
                .width('5%')
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
        bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      if (this.tagArray.length === 0) {
        ListItem() {
          Column() {
            Text('无数据')
          }
          .width('100%')
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
      }
      ForEach(this.tagArray, (item: string) => {
        if (!this.passwordTagArray.includes(item)) {
          ListItem() {
            Column() {
              Row() {
                Text(item)
                  .enableAutoSpacing(true)
                  .width('87%')
                Blank()
                  .width('5%')
                Image($r('app.media.add'))
                  .width('8%')
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
        }
      })
      if (this.passwordTagArray.length > 0) {
        ListItem() {
          Divider()
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
      }
      ForEach(this.passwordTagArray, (item: string, index) => {
        ListItem() {
          Column() {
            Row() {
              Text(item)
                .enableAutoSpacing(true)
                .width('87%')
              Blank()
                .width('5%')
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
      const oftenUsedInfoType = commonSettingDataPreferences.getSync('oftenUsedInfoType', ['密码']) as string[]
      this.oftenUsedInfoTypes = oftenUsedInfoType.concat(this.oftenUsedInfoTypes)
      if (this.oftenUsedInfoTypes[0] !== '自定义') {
        this.infoType = this.oftenUsedInfoTypes[0]
      }
      this.infoTypeValue = this.oftenUsedInfoTypes[0]
      if (this.oftenUsedInfoTypes[0] !== '自定义') {
        this.infoArray = await getTypeInfoList(this.oftenUsedInfoTypes[0])
      }
      this.passwordNameKeyword = this.filterPasswordDataPreferences.getSync('nameKeyword', '') as string
      this.passwordInfoArray = this.filterPasswordDataPreferences.getSync('info', []) as PasswordInfoItem[]
      this.passwordTagArray = this.filterPasswordDataPreferences.getSync('tag', []) as string[]
      this.infoArray = await getTypeInfoList(this.infoType)
      const tagArray = await getTagList()
      this.tagArray = tagArray.map(item => item.value)
    })
  }
}