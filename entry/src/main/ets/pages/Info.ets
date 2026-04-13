import { common } from '@kit.AbilityKit'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { fileIo } from '@kit.CoreFileKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { hdsEffect } from '@kit.UIDesignKit'
import { getAccountInfo } from '../common/Accesstoken'
import getCloudServiceStatus from '../common/Cloudservice'
import { getKeyAlg } from '../common/Crypto'
import { deleteCloudBackup, deleteData, setCloudBackup } from '../common/Datachange'
import { CloudBackupTimeItem, getInfoList, getInfoTypeList, Info } from '../common/Dataget'
import copy from '../common/Pasteboard'
import { getPreferType } from '../common/Prefertype'
import AinewInfo from './Ainewinfo'
import NewInfo from './Newinfo'
import UpdateInfo from './Updateinfo'

@ComponentV2
export default struct InfoPage {
  @Provider() isShowNewSheet: boolean = false
  @Provider() isShowUpdateSheet: boolean = false
  @Local isShowAinewSheet: boolean = false
  @Local preferType: number = 1
  @Local infoArray: Info[] = []
  @Local loading: boolean = false
  @Local enableCloudBackup: boolean = false
  @Local types: string[] = []
  @Local selectType: string = ''
  @Local multipleSelect: boolean = false
  @Local multipleSelectArray: Info[] = []
  @Local hoverId: number = -1
  @Local buttonHoverId: number = -1
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  updateId = 0
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '请求中...'
    })
  })

  async cloudBackup(item: Info) {
    let cloudBackupTime = JSON.stringify([])
    if (typeof (item.cloudBackupTime) === 'string') {
      cloudBackupTime = item.cloudBackupTime
    }
    const cloudBackupTimeArray = JSON.parse(cloudBackupTime) as CloudBackupTimeItem[]
    const accountInfo = await getAccountInfo()
    const cloudBackupTimeItem = cloudBackupTimeArray.find(item => item.uid === accountInfo.uid)
    if (cloudBackupTimeItem) {
      cloudBackupTimeItem.time = Date.now()
    }
    if (!cloudBackupTimeItem) {
      cloudBackupTimeArray.push({
        uid: accountInfo.uid,
        time: Date.now()
      })
    }
    await setCloudBackup(this.context, {
      type: 'info',
      id: item.id,
      content: JSON.stringify({
        type: item.type,
        value: item.value,
        updateTime: item.updateTime,
        cloudBackupTime: JSON.stringify(cloudBackupTimeArray)
      })
    })
  }

  @Builder
  MenuBuilder(item: Info) {
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
          startIcon: item.type === '图标' ? $r('app.media.save') : $r('app.media.copy'),
          content: item.type === '图标' ? '保存' : '复制'
        })
          .onClick(async () => {
            if (item.type !== '图标') {
              await copy(this.context, this.UIContext, item.type + '：' + item.value)
            }
            if (item.type === '图标') {
              const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(this.context)
              const uris = await phAccessHelper.showAssetsCreationDialog([item.value], [{
                fileNameExtension: 'png',
                photoType: photoAccessHelper.PhotoType.IMAGE
              }])
              await phAccessHelper.release()
              if (uris.length === 1) {
                const srcFile = fileIo.openSync(item.value)
                const destFile = fileIo.openSync(uris[0], fileIo.OpenMode.WRITE_ONLY)
                await fileIo.copyFile(srcFile.fd, destFile.fd)
                fileIo.closeSync(srcFile)
                fileIo.closeSync(destFile)
                await promptAction.openToast({
                  message: '保存成功'
                })
              }
            }
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
              await deleteData(this.context, 'info', item.id)
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
              await this.cloudBackup(item)
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
                type: 'info',
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
                  await deleteData(this.context, 'info', item.id)
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
                  await this.cloudBackup(this.multipleSelectArray[i])
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
            .margin({
              right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
            })
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
            .onHover((isHover) => {
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
                title: '新增常用信息'
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

            Button('AI 识别新增')
              .buttonStyle(ButtonStyleMode.NORMAL)
              .visualEffect(new hdsEffect.HdsEffectBuilder()
                .pointLight({
                  sourceType: hdsEffect.PointLightSourceType.SOFT,
                  illuminatedType: hdsEffect.PointLightIlluminatedType.CONTENT
                })
                .shaderEffect({
                  effectType: hdsEffect.EffectType.DUAL_EDGE_FLOW_LIGHT,
                  animation: {
                    duration: 5000,
                    iterations: -1
                  },
                  params: {
                    firstEdgeFlowLight: {
                      startPos: 0,
                      endPos: 1.0,
                      color: '#1AD0F1'
                    },
                    secondEdgeFlowLight: {
                      startPos: 0.5,
                      endPos: 1.5,
                      color: '#FFA4E5'
                    }
                  }
                })
                .buildEffect())
              .onClick(() => {
                this.isShowAinewSheet = true
              })
              .bindSheet(this.isShowAinewSheet!!, this.AinewSheetBuilder(), {
                preferType: this.preferType,
                title: {
                  title: 'AI 识别新增常用信息'
                },
                onDisappear: () => {
                  this.loading = true
                }
              })
          }

          Scroll() {
            Row() {
              ForEach(this.types, (item: string, index) => {
                if (item !== this.selectType) {
                  Column() {
                    Row() {
                      Text(item)
                        .enableAutoSpacing(true)
                        .fontWeight(FontWeight.Medium)
                    }
                    .padding(12)
                    .onClick(() => {
                      this.selectType = item
                    })
                  }
                  .backgroundColor($r('sys.color.comp_background_primary'))
                  .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                  .margin({
                    right: index === this.types.length - 1 ? 0 : $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                }
                if (item === this.selectType) {
                  Column() {
                    Row() {
                      Text(item)
                        .enableAutoSpacing(true)
                        .fontColor(Color.White)
                        .fontWeight(FontWeight.Medium)
                    }
                    .padding(12)
                    .onClick(() => {
                      this.selectType = ''
                    })
                  }
                  .backgroundColor($r('sys.color.background_emphasize'))
                  .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                  .margin({
                    right: index === this.types.length - 1 ? 0 : $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                }
              })
            }
          }
          .edgeEffect(EdgeEffect.Spring)
          .margin({
            bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
        }
        Refresh({
          refreshing: $$this.loading
        }) {
          List() {
            ForEach(this.infoArray, (item: Info, index) => {
              if (!this.selectType || item.type === this.selectType) {
                ListItem() {
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
                          .onChange((isOn) => {
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
                          .margin({
                            right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                          })
                          .width('5%')
                      }
                      Column() {
                        if (item.type !== '图标') {
                          Text(item.value)
                            .enableAutoSpacing(true)
                            .fontWeight(FontWeight.Medium)
                        }
                        if (item.type === '图标') {
                          Image(item.value)
                            .autoResize(true)
                            .copyOption(CopyOptions.LocalDevice)
                            .width('10%')
                            .onError(async (err) => {
                              await promptAction.openToast({
                                message: '发生错误，错误信息：' + err.message
                              })
                            })
                        }
                        Text(item.type)
                          .enableAutoSpacing(true)
                          .fontColor($r('sys.color.font_secondary'))
                          .fontSize($r('sys.float.ohos_id_text_size_body2'))
                          .margin({
                            top: $r('sys.float.ohos_id_text_margin_vertical')
                          })
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)
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
                    .onHover((isHover) => {
                      if (!isHover) {
                        this.hoverId = -1
                      }
                      if (isHover) {
                        this.hoverId = index
                      }
                    })
                    .onClick(async () => {
                      if (this.multipleSelect) {
                        return
                      }
                      if (item.type === '图标') {
                        await promptAction.openToast({
                          message: '图标类型不支持修改'
                        })
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
                }
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
              }
            })
            ListItem()
              .margin({
                bottom: this.preferType === 0 ? 80 : 0
              })
          }
        }
        .layoutWeight(1)
        .onRefreshing(async () => {
          this.infoArray = await getInfoList(this.context)
          this.types = await getInfoTypeList(this.context)
          this.loading = false
        })
      }
      .alignItems(HorizontalAlign.Start)
    }
    .padding({
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      top: this.preferType === 0 ? 0 : $r('sys.float.ohos_id_default_padding_top')
    })
    .onAppear(async () => {
      this.preferType = getPreferType(this.UIContext)
      this.context.eventHub.on('refreshInfo', async () => {
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
      this.context.eventHub.off('refreshInfo')
    })
    .bindSheet(this.isShowUpdateSheet!!, this.UpdateSheetBuilder(this.updateId), {
      height: SheetSize.FIT_CONTENT,
      preferType: this.preferType,
      title: {
        title: '修改常用信息'
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