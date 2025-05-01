import { LoadingDialog, promptAction } from '@kit.ArkUI'
import getCloudServiceStatus from '../common/Cloudservice'
import { getKey } from '../common/Crypto'
import { getTagList, Tag } from '../common/Dataget'
import { deleteCloudBackup, deleteData, setCloudBackup } from '../common/Datachange'
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
  orderColumn: string = 'updateTime'
  updateId: number = 0

  async getList() {
    this.loading = true
    this.tagArray = await getTagList(this.orderColumn)
    this.loading = false
  }

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
    List() {
      ListItem() {
        Row() {
          Button('新增')
            .onClick(() => {
              this.isShowNewSheet = !this.isShowNewSheet
            })
            .bindSheet($$this.isShowNewSheet, this.NewSheetBuilder(), {
              height: SheetSize.FIT_CONTENT,
              preferType: SheetType.BOTTOM,
              title: {
                title: '新增标签'
              },
              onDisappear: (() => {
                this.getList()
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
                  this.getList()
                }
              },
              {
                value: '内容',
                action: () => {
                  this.orderColumn = 'value'
                  this.orderColumnText = '内容'
                  this.getList()
                }
              }
            ])
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
              if (item.cloudBackupTime >= item.updateTime) {
                Image($r('app.media.cloud'))
                  .height(16)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .width(16)
              }
              Circle({
                height: 16,
                width: 16
              })
                .fill(item.color)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(item.value)
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontWeight('medium')
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
                    await deleteData('tag', item.id)
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
                    type: 'tag',
                    id: item.id,
                    content: JSON.stringify({
                      value: item.value,
                      color: item.color,
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
                      type: 'tag',
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
    })
    .bindSheet($$this.isShowUpdateSheet, this.UpdateSheetBuilder(this.updateId), {
      height: SheetSize.FIT_CONTENT,
      preferType: SheetType.BOTTOM,
      title: {
        title: '修改标签'
      },
      onDisappear: (() => {
        this.getList()
      })
    })
  }
}