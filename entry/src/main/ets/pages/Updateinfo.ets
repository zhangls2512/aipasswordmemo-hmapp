import { preferences } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import getCloudServiceStatus from '../common/Cloudservice'
import { getKey } from '../common/Crypto'
import { updateInfo } from '../common/Datachange'
import { getInfoInfo, Info } from '../common/Dataget'

@ComponentV2
export default struct Updateinfo {
  @Consumer() isShowUpdateSheet: boolean = false
  @Param infoId: number = 0
  @Local infoType: string = ''
  @Local infoValue: string = ''
  @Local cloudBackup: boolean = false
  @Local allowCloudBackup: boolean = false
  @Local alertText: string = ''
  specialTypes: string[] = ['昵称', '用户名', '密码', '姓名', '手机号', '邮箱', '银行卡号', '身份证号', 'URL']

  build() {
    List() {
      ListItem() {
        Column() {
          TextInput({
            placeholder: '请输入类型',
            text: $$this.infoType
          })
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
              .type(InputType.NEW_PASSWORD)
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
                isOn: $$this.cloudBackup
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
              if (!this.infoType) {
                promptAction.showToast({
                  message: '请输入类型'
                })
                return
              }
              if (!this.infoValue) {
                promptAction.showToast({
                  message: '请输入内容'
                })
                return
              }
              await updateInfo(this.infoId, {
                type: this.infoType,
                value: this.infoValue,
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
      const infoInfo = await getInfoInfo(this.infoId) as Info
      this.infoType = infoInfo.type
      this.infoValue = infoInfo.value
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
          const abilityContext = getContext(this)
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