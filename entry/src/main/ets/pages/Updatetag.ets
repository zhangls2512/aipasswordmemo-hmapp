import { common } from '@kit.AbilityKit'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { HdsColorPicker } from '@kit.UIDesignKit'
import getCloudServiceStatus from '../common/Cloudservice'
import { getKeyAlg } from '../common/Crypto'
import { updateTag } from '../common/Datachange'
import { getTagInfo, Tag } from '../common/Dataget'
import { getFavouriteColor, setFavouriteColor } from '../common/Favouritecolor'
import { getFlushPreference } from '../common/Preference'

@ComponentV2
export default struct Updatetag {
  @Consumer() isShowUpdateSheet: boolean = false
  @Param tagId: number = 0
  @Local tagValue: string = ''
  @Local tagColor: string = '#000000'
  @Local favouriteColor: string[] | undefined = undefined
  @Local cloudBackup: boolean = false
  @Local allowCloudBackup: boolean = false
  @Local alertText: string = ''
  context = this.getUIContext().getHostContext() as common.UIAbilityContext

  build() {
    List() {
      ListItem() {
        Row() {
          if (this.favouriteColor) {
            HdsColorPicker({
              initialColor: this.tagColor,
              initialFavoriteColors: this.favouriteColor,
              onColorSelected: (color) => {
                this.tagColor = color
              },
              onFavoriteColorsUpdate: async (list: string[]) => {
                await setFavouriteColor(this.context, list)
              }
            })
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
          }
          TextInput({
            placeholder: '请输入内容',
            text: this.tagValue!!
          })
            .enableAutoSpacing(true)
            .layoutWeight(1)
        }
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_m')
      })

      ListItem() {
        Button('修改')
          .keyboardShortcut('S', [ModifierKey.CTRL])
          .width('100%')
          .onClick(async () => {
            if (!this.tagValue) {
              await promptAction.openToast({
                message: '请输入内容'
              })
              return
            }
            const dialogControllerProgress = new CustomDialogController({
              builder: LoadingDialog({
                content: '修改中...'
              })
            })
            dialogControllerProgress.open()
            const res = await updateTag(this.context, this.tagId, {
              value: this.tagValue,
              color: this.tagColor,
              cloudBackup: this.cloudBackup
            })
            dialogControllerProgress.close()
            await promptAction.openToast({
              message: '修改' + (res === 'success' ? '成功' : '失败，原因：已存在')
            })
            if (res === 'success') {
              this.isShowUpdateSheet = false
              this.context.eventHub.emit('refreshTag')
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
      this.favouriteColor = await getFavouriteColor(this.context)
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
          const autoOn = getFlushPreference(this.context, 'cloudbackupSetting', 'autoOn', []) as string[]
          if (autoOn.includes('tag')) {
            this.cloudBackup = true
          }
        }
      }
    })
  }
}