import { common } from '@kit.AbilityKit'
import { LengthMetrics, LoadingDialog, promptAction } from '@kit.ArkUI'
import { hdsEffect } from '@kit.UIDesignKit'
import getCloudServiceStatus from '../common/Cloudservice'
import { getKeyAlg } from '../common/Crypto'
import { deleteCloudBackup, deleteData, setCloudBackup } from '../common/Datachange'
import { getTagList, Tag } from '../common/Dataget'
import { getPreferType } from '../common/Prefertype'
import NewTag from './Newtag'
import UpdateTag from './Updatetag'

@ComponentV2
export default struct TagPage {
  @Provider() isShowNewSheet: boolean = false
  @Provider() isShowUpdateSheet: boolean = false
  @Local preferType: number = 1
  @Local tagArray: Tag[] = []
  @Local loading: boolean = false
  @Local enableCloudBackup: boolean = false
  @Local multipleSelect: boolean = false
  @Local multipleSelectArray: Tag[] = []
  @Local hoverId: number = -1
  @Local buttonHoverId: number = -1
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  orderColumn = 'updateTime'
  updateId = 0
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '请求中...'
    })
  })

  @Builder
  MenuBuilder(item: Tag) {
    Menu() {
      if (this.multipleSelect) {
        MenuItem({
          startIcon: $r('app.media.multipleselect'),
          content: '取消多选'
        })
          .onClick(() => {
            this.multipleSelect = false
            this.multipleSelectArray = []
          })
      }
      if (!this.multipleSelect) {
        MenuItem({
          startIcon: $r('app.media.multipleselect'),
          content: '多选'
        })
          .onClick(() => {
            this.multipleSelect = true
            this.multipleSelectArray.push(item)
          })
        MenuItem({
          startIcon: $r('app.media.delete'),
          content: '删除'
        })
          .onClick(async () => {
            const promptAction = this.UIContext.getPromptAction()
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
              await deleteData(this.context, 'tag', item.id)
              this.loading = true
            }
          })
        if (this.enableCloudBackup && !item.isCloudBackup) {
          MenuItem({
            startIcon: $r('app.media.cloud'),
            content: '云备份'
          })
            .onClick(async () => {
              this.dialogControllerProgress.open()
              await setCloudBackup(this.context, {
                type: 'tag',
                id: item.id,
                content: JSON.stringify({
                  value: item.value,
                  color: item.color,
                  updateTime: item.updateTime,
                  cloudBackupTime: item.cloudBackupTime
                })
              })
              this.dialogControllerProgress.close()
              this.loading = true
            })
        }
        if (this.enableCloudBackup && item.isCloudBackup) {
          MenuItem({
            startIcon: $r('app.media.clouddelete'),
            content: '取消云备份'
          })
            .onClick(async () => {
              this.dialogControllerProgress.open()
              await deleteCloudBackup(this.context, {
                type: 'tag',
                id: item.id
              })
              this.dialogControllerProgress.close()
              this.loading = true
            })
        }
      }
    }
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
    Scroll() {
      Column() {
        if (this.multipleSelect) {
          Row() {
            Column() {
              Image($r('app.media.cancel'))
            }
            .borderRadius(20)
            .height(40)
            .margin({
              right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
            })
            .padding(11)
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.interactive_hover'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .visualEffect(new hdsEffect.HdsEffectBuilder()
              .pointLight({
                sourceType: hdsEffect.PointLightSourceType.SOFT,
                illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
              })
              .buildEffect())
            .width(40)
            .onClick(() => {
              this.multipleSelect = false
              this.multipleSelectArray = []
            })

            Text('已选择 ' + this.multipleSelectArray.length + ' 项')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
            Column() {
              Image($r('app.media.delete'))
            }
            .borderRadius(20)
            .height(40)
            .padding(11)
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.interactive_hover'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .visualEffect(new hdsEffect.HdsEffectBuilder()
              .pointLight({
                sourceType: hdsEffect.PointLightSourceType.SOFT,
                illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
              })
              .buildEffect())
            .width(40)
            .onClick(async () => {
              const promptAction = this.UIContext.getPromptAction()
              if (this.multipleSelectArray.length === 0) {
                await promptAction.openToast({
                  message: '未选择'
                })
                return
              }
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
                const promises = this.multipleSelectArray.map(async (item) => {
                  await deleteData(this.context, 'tag', item.id)
                })
                await Promise.all(promises)
                this.multipleSelect = false
                this.multipleSelectArray = []
                this.loading = true
              }
            })

            if (this.enableCloudBackup) {
              Column() {
                Image($r('app.media.cloud'))
              }
              .borderRadius(20)
              .height(40)
              .margin({
                left: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .padding(11)
              .stateStyles({
                normal: {
                  .backgroundColor($r('sys.color.interactive_hover'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .visualEffect(new hdsEffect.HdsEffectBuilder()
                .pointLight({
                  sourceType: hdsEffect.PointLightSourceType.SOFT,
                  illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
                })
                .buildEffect())
              .width(40)
              .onClick(async () => {
                if (this.multipleSelectArray.length === 0) {
                  await promptAction.openToast({
                    message: '未选择'
                  })
                  return
                }
                for (let i = 0; i < this.multipleSelectArray.length; i++) {
                  const dialogControllerProgress = new CustomDialogController({
                    builder: LoadingDialog({
                      content: '批量云备份中，进度：' + i + '/' + this.multipleSelectArray.length
                    })
                  })
                  dialogControllerProgress.open()
                  await setCloudBackup(this.context, {
                    type: 'tag',
                    id: this.multipleSelectArray[i].id,
                    content: JSON.stringify({
                      value: this.multipleSelectArray[i].value,
                      color: this.multipleSelectArray[i].color,
                      updateTime: this.multipleSelectArray[i].updateTime,
                      cloudBackupTime: this.multipleSelectArray[i].cloudBackupTime
                    })
                  })
                  dialogControllerProgress.close()
                }
                this.multipleSelect = false
                this.multipleSelectArray = []
                this.loading = true
              })
            }
          }
          .margin({
            bottom: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
        }
        if (!this.multipleSelect) {
          Row() {
            Column() {
              Image($r('app.media.new_white'))
            }
            .borderRadius(20)
            .height(40)
            .padding(11)
            .stateStyles({
              normal: {
                .backgroundColor(this.buttonHoverId === 0 ? '#0754EB' : $r('sys.color.background_emphasize'))
              },
              pressed: {
                .backgroundColor('#0A50DE')
              }
            })
            .width(40)
            .onHover(isHover => {
              if (!isHover) {
                this.buttonHoverId = -1
              }
              if (isHover) {
                this.buttonHoverId = 0
              }
            })
            .onClick(() => {
              this.isShowNewSheet = true
            })
            .bindSheet(this.isShowNewSheet!!, this.NewSheetBuilder(), {
              height: SheetSize.FIT_CONTENT,
              preferType: this.preferType,
              title: {
                title: '新增标签'
              },
              onDisappear: () => {
                this.loading = true
              },
              onWillDismiss: async (DismissSheetAction) => {
                const promptAction = this.UIContext.getPromptAction()
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
              }
            })

            Blank()
            Column() {
              Image($r('app.media.sort'))
            }
            .borderRadius(20)
            .height(40)
            .padding(11)
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.interactive_hover'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .visualEffect(new hdsEffect.HdsEffectBuilder()
              .pointLight({
                sourceType: hdsEffect.PointLightSourceType.SOFT,
                illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
              })
              .buildEffect())
            .width(40)
            .bindMenu([
              {
                value: '按修改时间排序',
                action: () => {
                  this.orderColumn = 'updateTime'
                  this.loading = true
                }
              },
              {
                value: '按内容排序',
                action: () => {
                  this.orderColumn = 'value'
                  this.loading = true
                }
              }
            ], {
              hapticFeedbackMode: HapticFeedbackMode.AUTO
            })
          }
          .margin({
            bottom: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .width('100%')
        }
        Refresh({
          refreshing: $$this.loading
        }) {
          List() {
            ListItem() {
              Flex({
                wrap: FlexWrap.Wrap,
                space: {
                  main: LengthMetrics.vp(8),
                  cross: LengthMetrics.vp(8)
                }
              }) {
                ForEach(this.tagArray, (item: Tag, index) => {
                  Column() {
                    Row() {
                      if (this.multipleSelect) {
                        Toggle({
                          type: ToggleType.Checkbox,
                          isOn: this.multipleSelectArray.some(selectItem => selectItem.id === item.id)
                        })
                          .margin({
                            right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                          })
                          .onChange(isOn => {
                            if (!isOn) {
                              this.multipleSelectArray.splice(this.multipleSelectArray.findIndex(selectItem => selectItem.id ===
                                item.id), 1)
                            }
                            if (isOn) {
                              this.multipleSelectArray.push(item)
                            }
                          })
                      }
                      if (item.isCloudBackup) {
                        Image($r('app.media.cloud'))
                          .height(16)
                          .margin({
                            right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                          })
                          .width(16)
                      }
                      Text(item.value)
                        .enableAutoSpacing(true)
                        .fontColor(item.color)
                        .fontWeight(FontWeight.Medium)
                    }
                    .borderRadius(12)
                    .padding(12)
                    .stateStyles({
                      normal: {
                        .backgroundColor(this.hoverId === index ? $r('sys.color.interactive_hover') :
                          $r('sys.color.comp_background_primary'))
                      },
                      pressed: {
                        .backgroundColor($r('sys.color.comp_background_secondary'))
                      }
                    })
                    .onHover(isHover => {
                      if (!isHover) {
                        this.hoverId = -1
                      }
                      if (isHover) {
                        this.hoverId = index
                      }
                    })
                    .onClick(() => {
                      if (this.multipleSelect) {
                        return
                      }
                      this.updateId = item.id
                      this.isShowUpdateSheet = true
                    })
                    .bindContextMenu(this.MenuBuilder(item), ResponseType.LongPress, {
                      hapticFeedbackMode: HapticFeedbackMode.AUTO
                    })
                    .bindContextMenu(this.MenuBuilder(item), ResponseType.RightClick, {
                      hapticFeedbackMode: HapticFeedbackMode.AUTO
                    })
                  }
                  .backgroundColor($r('sys.color.comp_background_primary'))
                  .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                  .padding($r('sys.float.ohos_id_corner_radius_mark'))
                })
              }
            }

            ListItem()
              .margin({
                bottom: this.preferType === 0 ? 80 : 0
              })
          }
        }
        .layoutWeight(1)
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
        .onRefreshing(async () => {
          this.tagArray = await getTagList(this.context, this.orderColumn)
          this.loading = false
        })
      }
    }
    .padding({
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      top: this.preferType === 0 ? 0 : $r('sys.float.ohos_id_default_padding_top')
    })
    .onAppear(async () => {
      this.preferType = getPreferType(this.UIContext)
      this.context.eventHub.on('refreshTag', async () => {
        this.enableCloudBackup = false
        this.loading = true
        const cloudServiceStatus = await getCloudServiceStatus(this.context)
        if (cloudServiceStatus && getKeyAlg()) {
          this.enableCloudBackup = true
        }
      })
      this.loading = true
      const cloudServiceStatus = await getCloudServiceStatus(this.context)
      if (cloudServiceStatus && getKeyAlg()) {
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
      onDisappear: () => {
        this.loading = true
      },
      onWillDismiss: async (DismissSheetAction) => {
        const promptAction = this.UIContext.getPromptAction()
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
      }
    })
  }
}