import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { get } from '../common/Accesstoken'
import request from '../common/Request'

interface Count {
  password: number,
  info: number,
  tag: number
}

@Builder
export function CloudbackupmanageBuilder() {
  Cloudbackupmanage()
}

@ComponentV2
struct Cloudbackupmanage {
  @Local loading: boolean = false
  @Local total: string = ''
  @Local password: string = ''
  @Local info: string = ''
  @Local tag: string = ''
  @Local allSelected: boolean = false
  @Local passwordSelected: boolean = false
  @Local infoSelected: boolean = false
  @Local tagSelected: boolean = false
  @Local types: string[] = []
  dialogControllerProgress: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: '清理中...'
    })
  })

  async getCount() {
    this.loading = true
    const infores = await request('/password/getBackupCount', {
      accessToken: get()
    })
    this.loading = false
    if (infores !== 'fail') {
      const count = JSON.parse(infores).count as Count
      this.total = String(count.password + count.info + count.tag)
      this.password = String(count.password)
      this.info = String(count.info)
      this.tag = String(count.tag)
    } else {
      this.loading = false
    }
  }

  build() {
    NavDestination() {
      List() {
        if (!this.loading) {
          ListItem() {
            Column() {
              Column() {
                Row() {
                  CheckboxGroup({
                    group: 'type'
                  })
                    .checkboxShape(CheckBoxShape.ROUNDED_SQUARE)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                    .selectAll($$this.allSelected)
                    .onChange((itemName: CheckboxGroupResult) => {
                      this.types = itemName.name
                    })
                  Text('全部')
                    .fontSize($r('sys.float.ohos_id_text_size_body1'))
                    .fontWeight('bold')
                  Blank()
                  Text(this.total)
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                }
                .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
                .padding($r('sys.float.ohos_id_corner_radius_default_m'))
                .width('100%')

                Divider()
                  .padding({
                    left: $r('sys.float.ohos_id_corner_radius_default_m'),
                    right: $r('sys.float.ohos_id_corner_radius_default_m')
                  })
                Row() {
                  Checkbox({
                    name: 'password',
                    group: 'type'
                  })
                    .shape(CheckBoxShape.ROUNDED_SQUARE)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                    .select($$this.passwordSelected)
                  Text('密码')
                    .fontSize($r('sys.float.ohos_id_text_size_body1'))
                    .fontWeight('medium')
                  Blank()
                  Text(this.password)
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                }
                .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
                .padding($r('sys.float.ohos_id_corner_radius_default_m'))
                .width('100%')

                Divider()
                  .padding({
                    left: $r('sys.float.ohos_id_corner_radius_default_m'),
                    right: $r('sys.float.ohos_id_corner_radius_default_m')
                  })
                Row() {
                  Checkbox({
                    name: 'info',
                    group: 'type'
                  })
                    .shape(CheckBoxShape.ROUNDED_SQUARE)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                    .select($$this.infoSelected)
                  Text('常用信息')
                    .fontSize($r('sys.float.ohos_id_text_size_body1'))
                    .fontWeight('medium')
                  Blank()
                  Text(this.info)
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                }
                .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
                .padding($r('sys.float.ohos_id_corner_radius_default_m'))
                .width('100%')

                Divider()
                  .padding({
                    left: $r('sys.float.ohos_id_corner_radius_default_m'),
                    right: $r('sys.float.ohos_id_corner_radius_default_m')
                  })
                Row() {
                  Checkbox({
                    name: 'tag',
                    group: 'type'
                  })
                    .shape(CheckBoxShape.ROUNDED_SQUARE)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                    .select($$this.tagSelected)
                  Text('标签')
                    .fontSize($r('sys.float.ohos_id_text_size_body1'))
                    .fontWeight('medium')
                  Blank()
                  Text(this.tag)
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                }
                .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
                .padding($r('sys.float.ohos_id_corner_radius_default_m'))
                .width('100%')
              }
              .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
              .padding($r('sys.float.ohos_id_corner_radius_mark'))

              Button('清理')
                .enabled(this.types.length > 0)
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_l')
                })
                .role(ButtonRole.ERROR)
                .onClick(async () => {
                  const data = await promptAction.showDialog({
                    title: '提示',
                    message: '清理成功后数据无法恢复。确定清理？',
                    buttons: [
                      {
                        text: '取消',
                        color: $r('sys.color.font_primary')
                      },
                      {
                        text: '清理',
                        color: $r('sys.color.warning')
                      }
                    ]
                  })
                  if (data.index === 1) {
                    this.dialogControllerProgress.open()
                    const res = await request('/password/clearBackup', {
                      accessToken: get(),
                      types: this.types
                    })
                    this.dialogControllerProgress.close()
                    if (res !== 'fail') {
                      promptAction.showToast({
                        message: '清理成功'
                      })
                      this.getCount()
                    }
                  }
                })
            }
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_l')
          })
        }
        if (this.loading) {
          ListItem() {
            LoadingProgress()
              .width('50%')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_l')
          })
          .width('100%')
        }
      }
      .backgroundColor($r('app.color.sheet_background'))
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title('管理云备份')
    .onReady(() => {
      this.getCount()
    })
  }
}