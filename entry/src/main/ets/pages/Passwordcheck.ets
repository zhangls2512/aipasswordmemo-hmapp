import { promptAction } from '@kit.ArkUI'
import { deviceInfo } from '@kit.BasicServicesKit'
import { getRepeatPasswordList, ListItem, RepeatItem } from '../common/Passwordcheck'
import UpdatePassword from './Updatepassword'

@ComponentV2
export default struct Passwordcheck {
  @Provider() isShowUpdateSheet: boolean = false
  @Local repeatArray: RepeatItem[] = []
  context = this.getUIContext().getHostContext()
  preferType = 1
  passwordId = 0

  @Builder
  UpdateSheetBuilder(id: number) {
    UpdatePassword({
      passwordId: id
    })
  }

  build() {
    List() {
      ListItem() {
        Text('重复')
          .fontWeight(FontWeight.Bold)
      }

      if (this.repeatArray.length === 0) {
        ListItem() {
          Text('无数据')
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })
        .width('100%')
      }
      ForEach(this.repeatArray, (item: RepeatItem) => {
        ListItem() {
          Column() {
            Text('使用 ' + item.password + ' 的 ' + item.count + ' 账号')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12,
                right: 12
              })
            Column() {
              ForEach(item.list, (item: ListItem, index) => {
                if (index !== 0) {
                  Divider()
                    .padding({
                      left: 12,
                      right: 12
                    })
                }
                Row() {
                  Text(item.name)
                    .fontWeight(FontWeight.Medium)
                  Blank()
                  Image($r('app.media.right'))
                    .fillColor($r('sys.color.icon_fourth'))
                    .height(12)
                    .width(12)
                }
                .borderRadius(12)
                .padding(12)
                .stateStyles({
                  normal: {
                    .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                  },
                  pressed: {
                    .backgroundColor($r('sys.color.interactive_pressed'))
                  }
                })
                .width('100%')
                .onClick(() => {
                  this.passwordId = item.id
                  this.isShowUpdateSheet = true
                })
              })
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
      })
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_max_padding_start'),
      right: $r('sys.float.ohos_id_max_padding_end')
    })
    .onAppear(async () => {
      if (deviceInfo.deviceType === 'phone') {
        this.preferType = 0
      }
      this.repeatArray = await getRepeatPasswordList()
    })
    .bindSheet(this.isShowUpdateSheet!!, this.UpdateSheetBuilder(this.passwordId), {
      preferType: this.preferType,
      title: {
        title: '修改密码'
      },
      onWillDismiss: (async (DismissSheetAction) => {
        const data = await promptAction.showDialog({
          title: '提示',
          message: '数据尚未保存，确定退出？',
          buttons: [
            {
              text: '取消',
              color: $r('sys.color.font_primary')
            },
            {
              text: '确定',
              color: $r('sys.color.font_emphasize')
            }
          ]
        })
        if (data.index === 1) {
          DismissSheetAction.dismiss()
        }
      })
    })
  }
}