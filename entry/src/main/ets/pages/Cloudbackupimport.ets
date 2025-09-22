import { preferences } from '@kit.ArkData'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
//import { HdsNavDestination } from '@kit.UIDesignKit'
import { importCloudBackupInfo, importCloudBackupPassword, importCloudBackupTag } from '../common/Cloudbackimport'
import { getKey } from '../common/Crypto'

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
  @Local autoImport: string[] = []
  context = this.getUIContext().getHostContext()
  cloudbackupSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'cloudbackupSetting'
  })
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '导入中...'
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
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Row() {
              Text('冲突解决模式')
                .fontWeight(FontWeight.Medium)
              Blank()
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
                left: 12
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
                  Blank()
                  Toggle({
                    type: ToggleType.Switch,
                    isOn: this.autoImport.includes(item.value)
                  })
                    .onChange((isOn) => {
                      let autoImport: string[] = []
                      if (!isOn) {
                        autoImport = this.autoImport.filter(itema => itema !== item.value)
                      }
                      if (isOn) {
                        autoImport = [...this.autoImport, item.value]
                      }
                      const cloudbackupSettingDataPreferences = preferences.getPreferencesSync(this.context, {
                        name: 'cloudbackupSetting'
                      })
                      cloudbackupSettingDataPreferences.putSync('autoImport', autoImport)
                      cloudbackupSettingDataPreferences.flushSync()
                      this.getSetting()
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
                left: 12
              })
            Column() {
              Row() {
                Text('密码')
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
              .onClick(async () => {
                if (!getKey()) {
                  const promptAction = this.getUIContext().getPromptAction()
                  promptAction.showDialog({
                    title: '导入失败',
                    message: '未导入密钥。请前往“我的”>“设置”>“云备份”>“密钥”导入密钥',
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
                const res = await importCloudBackupPassword()
                this.dialogControllerProgress.close()
                if (res === 'success') {
                  promptAction.openToast({
                    message: '导入成功'
                  })
                }
                if (res === 'fail') {
                  promptAction.openToast({
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
              .onClick(async () => {
                if (!getKey()) {
                  const promptAction = this.getUIContext().getPromptAction()
                  promptAction.showDialog({
                    title: '导入失败',
                    message: '未导入密钥。请前往“我的”>“设置”>“云备份”>“密钥”导入密钥',
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
                const res = await importCloudBackupInfo()
                this.dialogControllerProgress.close()
                if (res === 'success') {
                  promptAction.openToast({
                    message: '导入成功'
                  })
                }
                if (res === 'fail') {
                  promptAction.openToast({
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
              .onClick(async () => {
                if (!getKey()) {
                  const promptAction = this.getUIContext().getPromptAction()
                  promptAction.showDialog({
                    title: '导入失败',
                    message: '未导入密钥。请前往“我的”>“设置”>“云备份”>“密钥”导入密钥',
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
                const res = await importCloudBackupTag()
                this.dialogControllerProgress.close()
                if (res === 'success') {
                  promptAction.openToast({
                    message: '导入成功'
                  })
                }
                if (res === 'fail') {
                  promptAction.openToast({
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
    .title('导入云备份')
    .onAppear(() => {
      this.getSetting()
    })
  }
}