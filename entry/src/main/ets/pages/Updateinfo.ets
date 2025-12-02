import { common } from '@kit.AbilityKit'
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
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  specialInfoTypes = ['昵称', '用户名', '密码', '姓名', '手机号', '邮箱', '银行卡号', '身份证号', 'URL']

  build() {
    List() {
      ListItem() {
        Column() {
          TextInput({
            placeholder: '请输入类型',
            text: this.infoType!!
          })
            .enableAutoSpacing(true)
            .onChange((value) => {
              if (value === '图标') {
                this.cloudBackup = false
              }
            })
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
              .type(InputType.NEW_PASSWORD)
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
      }

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
                .enabled(this.allowCloudBackup && this.infoType !== '图标')
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
            if (!this.infoType) {
              await promptAction.openToast({
                message: '请输入类型'
              })
              return
            }
            if (!this.infoValue) {
              await promptAction.openToast({
                message: '请输入内容'
              })
              return
            }
            const res = await updateInfo(this.context, this.infoId, {
              type: this.infoType,
              value: this.infoValue,
              cloudBackup: this.cloudBackup
            })
            if (res === 'success') {
              this.isShowUpdateSheet = false
            }
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
      const infoInfo = await getInfoInfo(this.context, this.infoId) as Info
      this.infoType = infoInfo.type
      this.infoValue = infoInfo.value
      const res = await getCloudServiceStatus(this.context)
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
          const cloudbackupSettingDataPreferences = preferences.getPreferencesSync(this.context, {
            name: 'cloudbackupSetting'
          })
          const autoOn = cloudbackupSettingDataPreferences.getSync('autoOn', []) as string[]
          if (autoOn.includes('info')) {
            this.cloudBackup = true
          }
        }
      }
    })
  }
}