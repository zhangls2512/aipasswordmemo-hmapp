import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import getCloudServiceStatus from '../common/Cloudservice'
import { getKeyAlg } from '../common/Crypto'
import { updateTag } from '../common/Datachange'
import { getTagInfo, Tag } from '../common/Dataget'

@ComponentV2
export default struct Updatetag {
  @Consumer() isShowUpdateSheet: boolean = false
  @Param tagId: number = 0
  @Local tagValue: string = ''
  @Local tagColor: string = ''
  @Local red: number = 0
  @Local green: number = 0
  @Local blue: number = 0
  @Local alpha: number = 1
  @Local cloudBackup: boolean = false
  @Local allowCloudBackup: boolean = false
  @Local alertText: string = ''
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
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
              .layoutWeight(1)
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })

          Text('颜色示例：#FFFFFF、#FF000000、rgb(255,100,255)、rgba(255,100, 255,0.5)')
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
          Slider({
            value: this.red!!,
            max: 255
          })
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
            .selectedColor(Color.Red)
            .trackColor(Color.Red)
            .onChange(() => {
              this.tagColor = 'rgba(' + this.red + ',' + this.green + ',' + this.blue + ',' + this.alpha + ')'
            })
          Slider({
            value: this.green!!,
            max: 255
          })
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
            .selectedColor(Color.Green)
            .trackColor(Color.Green)
            .onChange(() => {
              this.tagColor = 'rgba(' + this.red + ',' + this.green + ',' + this.blue + ',' + this.alpha + ')'
            })
          Slider({
            value: this.blue!!,
            max: 255
          })
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
            .selectedColor(Color.Blue)
            .trackColor(Color.Blue)
            .onChange(() => {
              this.tagColor = 'rgba(' + this.red + ',' + this.green + ',' + this.blue + ',' + this.alpha + ')'
            })
          Slider({
            value: this.alpha!!,
            max: 1,
            step: 0.01
          })
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
            .onChange(() => {
              this.tagColor = 'rgba(' + this.red + ',' + this.green + ',' + this.blue + ',' + this.alpha + ')'
            })
        }
        .alignItems(HorizontalAlign.Start)
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_m')
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
            if (!this.tagValue) {
              await promptAction.openToast({
                message: '请输入内容'
              })
              return
            }
            const res = await updateTag(this.context, this.tagId, {
              value: this.tagValue,
              color: this.tagColor,
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
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
    })
    .onAppear(async () => {
      const tagInfo = await getTagInfo(this.context, this.tagId) as Tag
      this.tagValue = tagInfo.value
      this.tagColor = tagInfo.color
      const res = await getCloudServiceStatus(this.context)
      const key = getKeyAlg()
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
          const autoOn = cloudbackupSettingDataPreferences.getSync('autoOn', []) as string[]
          if (autoOn.includes('tag')) {
            this.cloudBackup = true
          }
        }
      }
    })
  }
}