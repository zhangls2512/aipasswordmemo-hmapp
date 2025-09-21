import { LoadingDialog } from '@kit.ArkUI'
//import { HdsNavDestination } from '@kit.UIDesignKit'
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
  @Local accessToken: string = ''

  async getCount() {
    if (this.accessToken) {
      this.loading = true
      const countres = await request('/password/getBackupCount', {
        accessToken: this.accessToken
      })
      this.loading = false
      if (countres !== 'fail') {
        const count = JSON.parse(countres).count as Count
        this.total = String(count.password + count.info + count.tag)
        this.password = String(count.password)
        this.info = String(count.info)
        this.tag = String(count.tag)
      }
    }
  }

  build() {
    NavDestination() {
      List() {
        if (this.loading) {
          ListItem() {
            LoadingProgress()
              .width('50%')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .width('100%')
        }
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
                    .selectAll(this.allSelected!!)
                    .onChange((itemName) => {
                      this.types = itemName.name
                    })
                  Text('全部')
                    .fontWeight(FontWeight.Bold)
                  Blank()
                  Text(this.total)
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                }
                .borderRadius(12)
                .padding(12)
                .width('100%')

                Divider()
                  .padding({
                    left: 12,
                    right: 12
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
                    .select(this.passwordSelected!!)
                  Text('密码')
                    .fontWeight(FontWeight.Medium)
                  Blank()
                  Text(this.password)
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                }
                .borderRadius(12)
                .padding(12)
                .width('100%')

                Divider()
                  .padding({
                    left: 12,
                    right: 12
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
                    .select(this.infoSelected!!)
                  Text('常用信息')
                    .fontWeight(FontWeight.Medium)
                  Blank()
                  Text(this.info)
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                }
                .borderRadius(12)
                .padding(12)
                .width('100%')

                Divider()
                  .padding({
                    left: 12,
                    right: 12
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
                    .select(this.tagSelected!!)
                  Text('标签')
                    .fontWeight(FontWeight.Medium)
                  Blank()
                  Text(this.tag)
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                }
                .borderRadius(12)
                .padding(12)
                .width('100%')
              }
              .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
              .padding($r('sys.float.ohos_id_corner_radius_mark'))

              Button('清理')
                .enabled(this.accessToken !== '' && this.types.length > 0)
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_l')
                })
                .role(ButtonRole.ERROR)
                .onClick(async () => {
                  const promptAction = this.getUIContext().getPromptAction()
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
                    const dialogControllerProgress = new CustomDialogController({
                      builder: LoadingDialog({
                        content: '清理中...'
                      })
                    })
                    dialogControllerProgress.open()
                    const res = await request('/password/clearBackup', {
                      accessToken: this.accessToken,
                      types: this.types
                    })
                    dialogControllerProgress.close()
                    if (res !== 'fail') {
                      promptAction.openToast({
                        message: '清理成功'
                      })
                      this.getCount()
                    }
                  }
                })
            }
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
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
    /*.titleBar({
      content: {
        title: {
          mainTitle: ''
        }
      }
    })*/
    .title('管理云备份')
    .onAppear(async () => {
      this.accessToken = await get()
      this.getCount()
    })
  }
}