import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { LengthMetrics, LoadingDialog, promptAction } from '@kit.ArkUI'
import { hdsMaterial, HdsNavDestination } from '@kit.UIDesignKit'
import { importCloudBackupInfo, importCloudBackupPassword, importCloudBackupTag } from '../common/Cloudbackupimport'
import { getKeyAlg } from '../common/Crypto'

interface Type {
  name: string,
  value: string
}

@Builder
export function CloudbackupimportBuilder() {
  Cloudbackupimport()
}

@ComponentV2
struct Cloudbackupimport {
  @Local index: number = 0
  @Local value: string = '保留'
  @Local hoverId: number = -1
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  autoImport: string[] = []
  cloudbackupSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'cloudbackupSetting'
  })
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '请求中...'
    })
  })
  typeArray: Type[] = [
    {
      name: '密码',
      value: 'password'
    },
    {
      name: '常用信息',
      value: 'info'
    },
    {
      name: '标签',
      value: 'tag'
    }
  ]

  getSetting() {
    this.autoImport = this.cloudbackupSettingDataPreferences.getSync('autoImport', []) as string[]
  }

  build() {
    HdsNavDestination() {
      List() {
        ListItem() {
          Column() {
            Row() {
              Text('冲突解决模式')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Select([
                { value: '保留' },
                { value: '覆盖' }
              ])
                .selected(this.index!!)
                .value(this.value!!)
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

        ListItem() {
          Column() {
            Text('自动 (应用启动时，冲突解决模式：保留)')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12,
                right: 12
              })
            Column() {
              ForEach(this.typeArray, (item: Type, index) => {
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
                    .layoutWeight(1)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                  Toggle({
                    type: ToggleType.Switch,
                    isOn: this.autoImport.includes(item.value)
                  })
                    .onChange((isOn) => {
                      if (!isOn) {
                        this.autoImport = this.autoImport.filter(inItem => inItem !== item.value)
                      }
                      if (isOn) {
                        this.autoImport = Array.from(new Set([...this.autoImport, item.value]))
                      }
                      this.cloudbackupSettingDataPreferences.putSync('autoImport', this.autoImport)
                      this.cloudbackupSettingDataPreferences.flushSync()
                    })
                }
                .borderRadius(12)
                .padding(12)
                .width('100%')
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

        ListItem() {
          Column() {
            Text('手动')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12,
                right: 12
              })
            Column() {
              Row() {
                Text('密码')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor(this.hoverId === 0 ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onHover((isHover) => {
                if (!isHover) {
                  this.hoverId = -1
                }
                if (isHover) {
                  this.hoverId = 0
                }
              })
              .onClick(async () => {
                if (!getKeyAlg()) {
                  const promptAction = this.UIContext.getPromptAction()
                  await promptAction.showDialog({
                    title: '导入失败',
                    message: '未导入密钥。请前往“我的”>“设置”>“密钥”导入密钥',
                    buttons: [
                      {
                        text: '确定',
                        color: $r('sys.color.font_emphasize')
                      }
                    ]
                  })
                  return
                }
                this.dialogControllerProgress.open()
                const res = await importCloudBackupPassword(this.context)
                this.dialogControllerProgress.close()
                if (res === 'success') {
                  await promptAction.openToast({
                    message: '导入成功'
                  })
                }
                if (res === 'fail') {
                  await promptAction.openToast({
                    message: '导入失败'
                  })
                }
              })

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
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor(this.hoverId === 1 ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onHover((isHover) => {
                if (!isHover) {
                  this.hoverId = -1
                }
                if (isHover) {
                  this.hoverId = 1
                }
              })
              .onClick(async () => {
                if (!getKeyAlg()) {
                  const promptAction = this.UIContext.getPromptAction()
                  await promptAction.showDialog({
                    title: '导入失败',
                    message: '未导入密钥。请前往“我的”>“设置”>“密钥”导入密钥',
                    buttons: [
                      {
                        text: '确定',
                        color: $r('sys.color.font_emphasize')
                      }
                    ]
                  })
                  return
                }
                this.dialogControllerProgress.open()
                const res = await importCloudBackupInfo(this.context)
                this.dialogControllerProgress.close()
                if (res === 'success') {
                  await promptAction.openToast({
                    message: '导入成功'
                  })
                }
                if (res === 'fail') {
                  await promptAction.openToast({
                    message: '导入失败'
                  })
                }
              })

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
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor(this.hoverId === 2 ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onHover((isHover) => {
                if (!isHover) {
                  this.hoverId = -1
                }
                if (isHover) {
                  this.hoverId = 2
                }
              })
              .onClick(async () => {
                if (!getKeyAlg()) {
                  const promptAction = this.UIContext.getPromptAction()
                  await promptAction.showDialog({
                    title: '导入失败',
                    message: '未导入密钥。请前往“我的”>“设置”>“密钥”导入密钥',
                    buttons: [
                      {
                        text: '确定',
                        color: $r('sys.color.font_emphasize')
                      }
                    ]
                  })
                  return
                }
                this.dialogControllerProgress.open()
                const res = await importCloudBackupTag(this.context)
                this.dialogControllerProgress.close()
                if (res === 'success') {
                  await promptAction.openToast({
                    message: '导入成功'
                  })
                }
                if (res === 'fail') {
                  await promptAction.openToast({
                    message: '导入失败'
                  })
                }
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
      }
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
        right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .titleBar({
      padding: {
        end: LengthMetrics.vp(60)
      },
      style: {
        thermoCtrl: true,
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.ADAPTIVE,
          materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
        }
      },
      content: {
        title: {
          mainTitle: '导入云备份'
        }
      },
      enableComponentSafeArea: true
    })
    .onAppear(() => {
      this.getSetting()
    })
  }
}