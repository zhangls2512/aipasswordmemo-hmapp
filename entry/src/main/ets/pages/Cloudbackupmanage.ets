import { common } from '@kit.AbilityKit'
import { LengthMetrics, LoadingDialog } from '@kit.ArkUI'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { getAccountAccessToken } from '../common/Accesstoken'
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
  @Local allSelected: boolean = false
  @Local passwordSelected: boolean = false
  @Local infoSelected: boolean = false
  @Local tagSelected: boolean = false
  @Local types: string[] = []
  @Local accessToken: string = ''
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  total = ''
  password = ''
  info = ''
  tag = ''

  async getCount() {
    if (this.accessToken) {
      this.loading = true
      const countres = await request(this.context, '/password/getBackupCount', {
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
    HdsNavDestination() {
      List() {
        ListItem()
          .margin({
            top: 64
          })
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
                  Text('全部')
                    .fontWeight(FontWeight.Bold)
                    .layoutWeight(1)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                  Text(this.total)
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                    })
                  CheckboxGroup({
                    group: 'type'
                  })
                    .checkboxShape(CheckBoxShape.ROUNDED_SQUARE)
                    .selectAll(this.allSelected!!)
                    .onChange(itemName => {
                      this.types = itemName.name
                    })
                }
                .borderRadius(12)
                .padding(12)

                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Text('密码')
                    .fontWeight(FontWeight.Medium)
                    .layoutWeight(1)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                  Text(this.password)
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                    })
                  Checkbox({
                    name: 'password',
                    group: 'type'
                  })
                    .select(this.passwordSelected!!)
                    .shape(CheckBoxShape.ROUNDED_SQUARE)
                }
                .borderRadius(12)
                .padding(12)

                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Text('常用信息')
                    .fontWeight(FontWeight.Medium)
                    .layoutWeight(1)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                  Text(this.info)
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                    })
                  Checkbox({
                    name: 'info',
                    group: 'type'
                  })
                    .select(this.infoSelected!!)
                    .shape(CheckBoxShape.ROUNDED_SQUARE)
                }
                .borderRadius(12)
                .padding(12)

                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Text('标签')
                    .fontWeight(FontWeight.Medium)
                    .layoutWeight(1)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                  Text(this.tag)
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                    })
                  Checkbox({
                    name: 'tag',
                    group: 'type'
                  })
                    .select(this.tagSelected!!)
                    .shape(CheckBoxShape.ROUNDED_SQUARE)
                }
                .borderRadius(12)
                .padding(12)
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
                .width('100%')
                .onClick(async () => {
                  const promptAction = this.UIContext.getPromptAction()
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
                        content: '请求中...'
                      })
                    })
                    dialogControllerProgress.open()
                    const res = await request(this.context, '/password/clearBackup', {
                      accessToken: this.accessToken,
                      types: this.types
                    })
                    dialogControllerProgress.close()
                    if (res !== 'fail') {
                      await promptAction.openToast({
                        message: '清理成功'
                      })
                      await this.getCount()
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
        ListItem()
          .margin({
            bottom: 28
          })
      }
      .padding({
        left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
        right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .recoverable(true)
    .titleBar({
      padding: {
        end: LengthMetrics.vp(60)
      },
      style: {
        scrollEffectOpts: {
          scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR
        },
        originalStyle: {
          contentStyle: {
            titleStyle: {
              mainTitleColor: $r('sys.color.font_primary')
            },
            backIconStyle: {
              iconColor: $r('sys.color.icon_primary')
            }
          }
        },
        thermoCtrl: true,
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.ADAPTIVE,
          materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
        }
      },
      content: {
        title: {
          mainTitle: '管理云备份'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onAppear(async () => {
      this.accessToken = await getAccountAccessToken()
      await this.getCount()
    })
  }
}