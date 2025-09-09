import { common } from '@kit.AbilityKit'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { deviceInfo } from '@kit.BasicServicesKit'
import { getAccountInfo } from '../common/Accesstoken'
import getCloudServiceStatus from '../common/Cloudservice'
import { getKey } from '../common/Crypto'
import { deleteCloudBackup, deleteData, setCloudBackup } from '../common/Datachange'
import { CloudBackupTimeItem, getTagList, Tag } from '../common/Dataget'
import NewTag from './Newtag'
import UpdateTag from './Updatetag'

@ComponentV2
export default struct TagPage {
  @Provider() isShowNewSheet: boolean = false
  @Provider() isShowUpdateSheet: boolean = false
  @Local tagArray: Tag[] = []
  @Local loading: boolean = false
  @Local isShowMenu: boolean = false
  @Local enableCloudBackup: boolean = false
  @Local orderColumnText: string = '修改时间'
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  preferType = 1
  orderColumn = 'updateTime'
  updateId = 0

  @Builder
  NewSheetBuilder() {
    NewTag()
  }

  @Builder
  UpdateSheetBuilder(id: number) {
    UpdateTag({
      tagId: id
    })
  }

  build() {
    Refresh({
      refreshing: $$this.loading
    }) {
      List() {
        ListItem() {
          Row() {
            Button('新增')
              .onClick(() => {
                this.isShowNewSheet = true
              })
              .bindSheet(this.isShowNewSheet!!, this.NewSheetBuilder(), {
                height: SheetSize.FIT_CONTENT,
                preferType: this.preferType,
                title: {
                  title: '新增标签'
                },
                onDisappear: (() => {
                  this.loading = true
                }),
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
            Blank()
            Button('按' + this.orderColumnText + '排序')
              .buttonStyle(ButtonStyleMode.NORMAL)
              .bindMenu([
                {
                  value: '修改时间',
                  action: () => {
                    this.orderColumn = 'updateTime'
                    this.orderColumnText = '修改时间'
                    this.loading = true
                  }
                },
                {
                  value: '内容',
                  action: () => {
                    this.orderColumn = 'value'
                    this.orderColumnText = '内容'
                    this.loading = true
                  }
                }
              ], {
                hapticFeedbackMode: HapticFeedbackMode.AUTO
              })
          }
          .width('100%')
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
        ForEach(this.tagArray, (item: Tag) => {
          ListItem() {
            Column() {
              Row() {
                if (item.isCloudBackup) {
                  Image($r('app.media.cloud'))
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                    .width('5%')
                }
                Row() {
                  Circle({
                    height: 16,
                    width: 16
                  })
                    .fill(item.color)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                  Text(item.value)
                    .fontWeight(FontWeight.Medium)
                }
                .width('90%')
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
              .bindMenu([
                {
                  value: '修改',
                  icon: $r('app.media.edit'),
                  action: () => {
                    this.updateId = item.id
                    this.isShowUpdateSheet = true
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
                      await deleteData('tag', item.id)
                      this.loading = true
                    }
                  }
                },
                {
                  value: '云备份',
                  icon: $r('app.media.cloud'),
                  enabled: this.enableCloudBackup && !item.isCloudBackup,
                  action: async () => {
                    let cloudBackupTime = JSON.stringify([])
                    if (typeof (item.cloudBackupTime) === 'string') {
                      cloudBackupTime = item.cloudBackupTime
                    }
                    const cloudBackupTimeArray = JSON.parse(cloudBackupTime) as CloudBackupTimeItem[]
                    const accountInfo = await getAccountInfo()
                    const cloudBackupTimeIndex = cloudBackupTimeArray.findIndex(item => item.uid === accountInfo.uid)
                    if (cloudBackupTimeIndex !== -1) {
                      cloudBackupTimeArray[cloudBackupTimeIndex].time = Date.now()
                    } else {
                      cloudBackupTimeArray.push({
                        uid: accountInfo.uid,
                        time: Date.now()
                      })
                    }
                    const dialogControllerProgress = new CustomDialogController({
                      builder: LoadingDialog({
                        content: '云备份中...'
                      })
                    })
                    dialogControllerProgress.open()
                    await setCloudBackup({
                      type: 'tag',
                      id: item.id,
                      content: JSON.stringify({
                        value: item.value,
                        color: item.color,
                        updateTime: item.updateTime,
                        cloudBackupTime: JSON.stringify(cloudBackupTimeArray)
                      })
                    })
                    dialogControllerProgress.close()
                    this.loading = true
                  }
                },
                {
                  value: '删除云备份',
                  icon: $r('app.media.clouddelete'),
                  enabled: this.enableCloudBackup && item.isCloudBackup,
                  action: async () => {
                    const dialogControllerProgress = new CustomDialogController({
                      builder: LoadingDialog({
                        content: '删除云备份中...'
                      })
                    })
                    dialogControllerProgress.open()
                    await deleteCloudBackup({
                      type: 'tag',
                      id: item.id
                    })
                    dialogControllerProgress.close()
                    this.loading = true
                  }
                }
              ], {
                hapticFeedbackMode: HapticFeedbackMode.AUTO
              })
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
      .height('100%')
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
      .onAppear(async () => {
        if (deviceInfo.deviceType === 'phone') {
          this.preferType = 0
        }
        this.context.eventHub.on('refreshTag', async () => {
          this.enableCloudBackup = false
          this.loading = true
          const cloudServiceStatus = await getCloudServiceStatus()
          if (cloudServiceStatus && getKey()) {
            this.enableCloudBackup = true
          }
        })
        this.loading = true
        const cloudServiceStatus = await getCloudServiceStatus()
        if (cloudServiceStatus && getKey()) {
          this.enableCloudBackup = true
        }
      })
      .onDisAppear(() => {
        this.context.eventHub.off('refreshTag')
      })
      .bindSheet(this.isShowUpdateSheet!!, this.UpdateSheetBuilder(this.updateId), {
        height: SheetSize.FIT_CONTENT,
        preferType: this.preferType,
        title: {
          title: '修改标签'
        },
        onDisappear: (() => {
          this.loading = true
        }),
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
    .onRefreshing(async () => {
      this.tagArray = await getTagList(this.orderColumn)
      this.loading = false
    })
  }
}