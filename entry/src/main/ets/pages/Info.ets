import { common } from '@kit.AbilityKit'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import getCloudServiceStatus from '../common/Cloudservice'
import { getKey } from '../common/Crypto'
import { getInfoList, Info } from '../common/Dataget'
import { deleteCloudBackup, deleteData, setCloudBackup } from '../common/Datachange'
import AinewInfo from './Ainewinfo'
import NewInfo from './Newinfo'
import UpdateInfo from './Updateinfo'

@ComponentV2
export default struct InfoPage {
  @Provider() isShowNewSheet: boolean = false
  @Provider() isShowUpdateSheet: boolean = false
  @Provider() isShowAinewSheet: boolean = false
  @Local infoArray: Info[] = []
  @Local loading: boolean = false
  @Local isShowMenu: boolean = false
  @Local enableCloudBackup: boolean = false
  context = getContext(this) as common.UIAbilityContext
  updateId: number = 0

  async getList() {
    this.loading = true
    this.infoArray = await getInfoList()
    this.loading = false
  }

  @Builder
  NewSheetBuilder() {
    NewInfo()
  }

  @Builder
  UpdateSheetBuilder(id: number) {
    UpdateInfo({
      infoId: id
    })
  }

  @Builder
  AinewSheetBuilder() {
    AinewInfo()
  }

  build() {
    List() {
      ListItem() {
        Row() {
          Button('新增')
            .margin({
              right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
            })
            .onClick(() => {
              this.isShowNewSheet = !this.isShowNewSheet
            })
            .bindSheet($$this.isShowNewSheet, this.NewSheetBuilder(), {
              height: SheetSize.FIT_CONTENT,
              preferType: SheetType.BOTTOM,
              title: {
                title: '新增常用信息'
              },
              onDisappear: (() => {
                this.getList()
              }),
              onWillDismiss: (async (DismissSheetAction: DismissSheetAction) => {
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
          Button('AI 识别新增')
            .buttonStyle(ButtonStyleMode.NORMAL)
            .onClick(() => {
              this.isShowAinewSheet = !this.isShowAinewSheet
            })
            .bindSheet($$this.isShowAinewSheet, this.AinewSheetBuilder(), {
              preferType: SheetType.BOTTOM,
              title: {
                title: 'AI 识别新增常用信息'
              },
              onDisappear: (() => {
                this.getList()
              })
            })
        }
      }
      .margin({
        bottom: $r('sys.float.ohos_id_elements_margin_vertical_m')
      })

      if (this.loading) {
        ListItem() {
          LoadingProgress()
            .width('10%')
        }
        .margin({
          bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
        .width('100%')
      }
      ForEach(this.infoArray, (item: Info) => {
        ListItem() {
          Column() {
            Row() {
              if (item.cloudBackupTime >= item.updateTime) {
                Image($r('app.media.cloud'))
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .width('5%')
              }
              Column() {
                Text(item.value)
                  .fontWeight('medium')
                Text(item.type)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .width('90%')
            }
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
            .padding($r('sys.float.ohos_id_corner_radius_default_m'))
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .width('100%')
            .bindMenu([
              {
                value: '修改',
                icon: $r('app.media.edit'),
                action: () => {
                  this.updateId = item.id
                  this.isShowUpdateSheet = !this.isShowUpdateSheet
                }
              },
              {
                value: '删除',
                icon: $r('app.media.delete'),
                action: async () => {
                  const data = await promptAction.showDialog({
                    title: '提示',
                    message: '删除成功后无法恢复，确定删除？',
                    buttons: [
                      {
                        text: '取消',
                        color: $r('sys.color.font_primary')
                      },
                      {
                        text: '删除',
                        color: $r('sys.color.warning')
                      }
                    ]
                  })
                  if (data.index === 1) {
                    await deleteData('info', item.id)
                    this.getList()
                  }
                }
              },
              {
                value: '云备份',
                icon: $r('app.media.cloud'),
                enabled: this.enableCloudBackup && item.cloudBackupTime < item.updateTime,
                action: async () => {
                  const dialogControllerProgress: CustomDialogController = new CustomDialogController({
                    builder: LoadingDialog({
                      content: '云备份中...'
                    })
                  })
                  dialogControllerProgress.open()
                  await setCloudBackup({
                    type: 'info',
                    id: item.id,
                    content: JSON.stringify({
                      type: item.type,
                      value: item.value,
                      updateTime: item.updateTime,
                      cloudBackupTime: item.updateTime
                    })
                  })
                  dialogControllerProgress.close()
                  this.getList()
                }
              },
              {
                value: '删除云备份',
                icon: $r('app.media.clouddelete'),
                enabled: this.enableCloudBackup && item.cloudBackupTime >= item.updateTime,
                action: async () => {
                  const data = await promptAction.showDialog({
                    title: '提示',
                    message: '删除成功后无法恢复，确定删除？',
                    buttons: [
                      {
                        text: '取消',
                        color: $r('sys.color.font_primary')
                      },
                      {
                        text: '删除',
                        color: $r('sys.color.warning')
                      }
                    ]
                  })
                  if (data.index === 1) {
                    const dialogControllerProgress: CustomDialogController = new CustomDialogController({
                      builder: LoadingDialog({
                        content: '删除云备份中...'
                      })
                    })
                    dialogControllerProgress.open()
                    await deleteCloudBackup({
                      type: 'info',
                      id: item.id
                    })
                    dialogControllerProgress.close()
                    this.getList()
                  }
                }
              }
            ])
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
      })
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_max_padding_start'),
      right: $r('sys.float.ohos_id_max_padding_end')
    })
    .onAppear(async () => {
      await this.getList()
      const cloudServiceStatus = await getCloudServiceStatus()
      if (cloudServiceStatus && getKey()) {
        this.enableCloudBackup = true
      }
      this.context.eventHub.on('refreshInfo', async () => {
        this.enableCloudBackup = false
        await this.getList()
        const cloudServiceStatus = await getCloudServiceStatus()
        if (cloudServiceStatus && getKey()) {
          this.enableCloudBackup = true
        }
      })
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshInfo')
    })
    .bindSheet($$this.isShowUpdateSheet, this.UpdateSheetBuilder(this.updateId), {
      height: SheetSize.FIT_CONTENT,
      preferType: SheetType.BOTTOM,
      title: {
        title: '修改常用信息'
      },
      onDisappear: (() => {
        this.getList()
      }),
      onWillDismiss: (async (DismissSheetAction: DismissSheetAction) => {
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