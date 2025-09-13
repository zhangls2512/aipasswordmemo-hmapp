import { preferences } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import getCloudServiceStatus from '../common/Cloudservice'
import { getKey } from '../common/Crypto'
import { newTag } from '../common/Datachange'

@ComponentV2
export default struct Newtag {
  @Consumer() isShowNewSheet: boolean = false
  @Local tagValue: string = ''
  @Local tagColor: string = 'rgba(0,0,0,0)'
  @Local cloudBackup: boolean = false
  @Local allowCloudBackup: boolean = false
  @Local alertText: string = ''
  colorArray: string[] = [
    '#000000',
    '#0000FF',
    '#A52A2A',
    '#808080',
    '#008000',
    '#FFA500',
    '#FFC0CB',
    '#FF0000',
    '#FFFFFF',
    '#FFFF00',
    'rgba(0,0,0,0)'
  ]

  build() {
    List() {
      ListItem() {
        Column() {
          TextInput({
            placeholder: '请输入内容',
            text: this.tagValue!!
          })
            .defaultFocus(true)
            .enableAutoSpacing(true)
          Row() {
            ForEach(this.colorArray, (item: string) => {
              Circle({
                height: 20,
                width: 20
              })
                .fill(item)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .onClick(() => {
                  this.tagColor = item
                })
            })
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })

          Row() {
            Circle({
              height: 20,
              width: 20
            })
              .fill(this.tagColor)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
            TextInput({
              placeholder: '请输入颜色',
              text: this.tagColor!!
            })
              .enableAutoSpacing(true)
              .width('90%')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })

          Text('颜色示例：#FFFFFF、#FF000000、rgb(255, 100, 255)、rgba(255, 100, 255, 0.5)')
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
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
          Button('新增')
            .onClick(async () => {
              if (!this.tagValue) {
                promptAction.openToast({
                  message: '请输入内容'
                })
                return
              }
              if (!this.tagColor) {
                promptAction.openToast({
                  message: '请输入颜色'
                })
                return
              }
              await newTag({
                value: this.tagValue,
                color: this.tagColor,
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
          const abilityContext = this.getUIContext().getHostContext()
          const cloudbackupSettingDataPreferences = preferences.getPreferencesSync(abilityContext, {
            name: 'cloudbackupSetting'
          })
          const autoOn: string[] = cloudbackupSettingDataPreferences.getSync('autoOn', []) as string[]
          if (autoOn.includes('tag')) {
            this.cloudBackup = true
          }
        }
      }
    })
  }
}