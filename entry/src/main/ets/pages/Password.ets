import { common } from '@kit.AbilityKit'
import { FunctionComponent } from '@kit.AgentFrameworkKit'
import { LengthMetrics, LoadingDialog, promptAction, window } from '@kit.ArkUI'
import { deviceInfo } from '@kit.BasicServicesKit'
import { hdsEffect } from '@kit.UIDesignKit'
import getCloudServiceStatus from '../common/Cloudservice'
import { getKeyAlg } from '../common/Crypto'
import { deleteCloudBackup, deleteData, setCloudBackup } from '../common/Datachange'
import { getFilterPasswordList, getTagList, Password, PasswordInfoItem, PasswordTagItem } from '../common/Dataget'
import { getFlushPreference, getTempPreference, setTempPreference } from '../common/Preference'
import { getPreferType } from '../common/Prefertype'
import {
  deleteQuickBarPassword,
  getQuickBarPasswordIdList,
  setQuickBarPassword,
  syncQuickBarPassword
} from '../common/Quickbar'
import getTotp from '../common/Totp'
import FilterPassword from './Filterpassword'
import NewPassword from './Newpassword'
import PasswordInfo from './Passwordinfo'
import UpdatePassword from './Updatepassword'

interface Data {
  nameKeyword: string,
  info: PasswordInfoItem[],
  tag: string[]
}

interface MfaItem {
  id: number,
  mfa: string
}

@ComponentV2
export default struct PasswordPage {
  @Provider() isShowNewSheet: boolean = false
  @Provider() isShowUpdateSheet: boolean = false
  @Provider() isShowFilterSheet: boolean = false
  @Local isShowInfoSheet: boolean = false
  @Local preferType: number = 1
  @Local passwordArray: Password[] = []
  @Local loading: boolean = false
  @Local enableCloudBackup: boolean = false
  @Local nameKeyword: string = ''
  @Local info: PasswordInfoItem[] = []
  @Local tag: string[] = []
  @Local tags: PasswordTagItem[] = []
  @Local showPassword: boolean = false
  @Local hideTag: boolean = false
  @Local multipleSelect: boolean = false
  @Local multipleSelectArray: Password[] = []
  @Local hoverId: number = -1
  @Local buttonHoverId: number = -1
  @Local mfaArray: MfaItem[] = []
  @Local quickBarPasswordIdArray: number[] = []
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  orderColumn = 'updateTime'
  passwordId = 0
  intervalId = -1
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '请求中...'
    })
  })

  @Builder
  MenuBuilder(item: Password) {
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
        if (deviceInfo.deviceType === '2in1') {
          if (!this.quickBarPasswordIdArray.includes(item.id)) {
            MenuItem({
              startIcon: $r('app.media.addcircle'),
              content: '添加至快捷栏'
            })
              .onClick(async () => {
                await setQuickBarPassword(this.context, item.id, item.name)
                await syncQuickBarPassword(this.context)
                this.quickBarPasswordIdArray = await getQuickBarPasswordIdList(this.context)
                if (this.quickBarPasswordIdArray.includes(item.id)) {
                  const promptAction = this.UIContext.getPromptAction()
                  await promptAction.openToast({
                    message: '添加成功'
                  })
                }
              })
          }
          if (this.quickBarPasswordIdArray.includes(item.id)) {
            MenuItem({
              startIcon: $r('app.media.removecircle'),
              content: '从快捷栏移除'
            })
              .onClick(async () => {
                await deleteQuickBarPassword(this.context, item.id)
                await syncQuickBarPassword(this.context)
                this.quickBarPasswordIdArray = await getQuickBarPasswordIdList(this.context)
                if (!this.quickBarPasswordIdArray.includes(item.id)) {
                  const promptAction = this.UIContext.getPromptAction()
                  await promptAction.openToast({
                    message: '移除成功'
                  })
                }
              })
          }
        }
        MenuItem({
          startIcon: $r('app.media.edit'),
          content: '修改'
        })
          .onClick(() => {
            this.passwordId = item.id
            this.isShowUpdateSheet = true
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
              await deleteData(this.context, 'password', item.id)
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
                type: 'password',
                id: item.id,
                content: JSON.stringify({
                  name: item.name,
                  info: item.info,
                  tag: item.tag.map(item => item.value),
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
                type: 'password',
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
    NewPassword()
  }

  @Builder
  InfoSheetBuilder(id: number) {
    PasswordInfo({
      passwordId: id
    })
  }

  @Builder
  UpdateSheetBuilder(id: number) {
    UpdatePassword({
      passwordId: id
    })
  }

  @Builder
  FilterSheetBuilder() {
    FilterPassword()
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
                  await deleteData(this.context, 'password', item.id)
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
                      content: '批量云备份中，进度：' + (i + 1) + '/' + this.multipleSelectArray.length
                    })
                  })
                  dialogControllerProgress.open()
                  await setCloudBackup(this.context, {
                    type: 'password',
                    id: this.multipleSelectArray[i].id,
                    content: JSON.stringify({
                      name: this.multipleSelectArray[i].name,
                      info: this.multipleSelectArray[i].info,
                      tag: this.multipleSelectArray[i].tag.map(item => item.value),
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
                title: '新增密码'
              },
              onAppear: async () => {
                const disallowScreenshot =
                  getFlushPreference(this.context, 'commonSetting', 'disallowScreenshot', true) as boolean
                if (disallowScreenshot) {
                  const lastWindow = await window.getLastWindow(this.context)
                  await lastWindow.setWindowPrivacyMode(true)
                }
              },
              onDisappear: async () => {
                if (!this.showPassword) {
                  const lastWindow = await window.getLastWindow(this.context)
                  await lastWindow.setWindowPrivacyMode(false)
                }
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
            if (deviceInfo.deviceType !== '2in1') {
              Column() {
                FunctionComponent({
                  agentId: 'agentfac9ae6847d743ca80f8e9528124cedb',
                  onError: () => {
                  }
                })
              }
              .borderRadius(20)
              .height(40)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .visualEffect(new hdsEffect.HdsEffectBuilder()
                .pointLight({
                  sourceType: hdsEffect.PointLightSourceType.SOFT,
                  illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
                })
                .buildEffect())
              .width(40)
            }
            Column() {
              Image($r('app.media.sort'))
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
            .bindMenu([
              {
                value: '按修改时间排序',
                action: () => {
                  this.orderColumn = 'updateTime'
                  this.loading = true
                }
              },
              {
                value: '按名称排序',
                action: () => {
                  this.orderColumn = 'name'
                  this.loading = true
                }
              }
            ], {
              hapticFeedbackMode: HapticFeedbackMode.AUTO
            })

            Column() {
              Image($r('app.media.search_icon'))
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
            .onClick(() => {
              this.isShowFilterSheet = true
            })
            .bindSheet(this.isShowFilterSheet!!, this.FilterSheetBuilder(), {
              height: SheetSize.FIT_CONTENT,
              preferType: this.preferType,
              title: {
                title: '筛选密码'
              },
              onAppear: async () => {
                const disallowScreenshot =
                  getFlushPreference(this.context, 'commonSetting', 'disallowScreenshot', true) as boolean
                if (disallowScreenshot) {
                  const lastWindow = await window.getLastWindow(this.context)
                  await lastWindow.setWindowPrivacyMode(true)
                }
              },
              onDisappear: async () => {
                if (!this.showPassword) {
                  const lastWindow = await window.getLastWindow(this.context)
                  await lastWindow.setWindowPrivacyMode(false)
                }
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
          .width('100%')

          Search({
            placeholder: '请输入名称关键词',
            value: this.nameKeyword!!
          })
            .searchButton('搜索')
            .onChange(value => {
              setTempPreference(this.context, 'filterPassword', 'nameKeyword', value)
            })
            .onSubmit(() => {
              this.loading = true
            })
          Scroll() {
            Row() {
              ForEach(this.tags, (item: PasswordTagItem, index) => {
                if (!this.tag.includes(item.value)) {
                  Column() {
                    Row() {
                      Text(item.value)
                        .enableAutoSpacing(true)
                        .fontColor(item.color)
                        .fontWeight(FontWeight.Medium)
                    }
                    .padding(12)
                    .onClick(() => {
                      this.tag.push(item.value)
                      setTempPreference(this.context, 'filterPassword', 'tag', this.tag)
                      this.loading = true
                    })
                  }
                  .backgroundColor($r('sys.color.comp_background_primary'))
                  .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                  .margin({
                    right: index === this.tags.length - 1 ? 0 : $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                }
                if (this.tag.includes(item.value)) {
                  Column() {
                    Row() {
                      Text(item.value)
                        .enableAutoSpacing(true)
                        .fontColor(Color.White)
                        .fontWeight(FontWeight.Medium)
                    }
                    .padding(12)
                    .onClick(() => {
                      this.tag.splice(this.tag.indexOf(item.value), 1)
                      setTempPreference(this.context, 'filterPassword', 'tag', this.tag)
                      this.loading = true
                    })
                  }
                  .backgroundColor($r('sys.color.background_emphasize'))
                  .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                  .margin({
                    right: index === this.tags.length - 1 ? 0 : $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                }
              })
            }
          }
          .edgeEffect(EdgeEffect.Spring)
          .margin({
            bottom: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
        }
        Refresh({
          refreshing: $$this.loading
        }) {
          List() {
            ForEach(this.passwordArray, (item: Password, index) => {
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
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                        .width('5%')
                    }
                    if (item.info.find(infoItem => infoItem.type === '图标')) {
                      Image(item.info.find(infoItem => infoItem.type === '图标')?.value)
                        .autoResize(true)
                        .copyOption(CopyOptions.LocalDevice)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                        .width('10%')
                        .onError(async (err) => {
                          await promptAction.openToast({
                            message: '发生错误，错误信息：' + err.message
                          })
                        })
                    }
                    Column() {
                      Text(item.name)
                        .enableAutoSpacing(true)
                        .fontWeight(FontWeight.Bold)
                      if (this.showPassword) {
                        if (item.info.find(infoItem => infoItem.type === '密码')) {
                          Row() {
                            Text('密码')
                              .fontWeight(FontWeight.Medium)
                              .margin({
                                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                              })
                            Text(item.info.find(infoItem => infoItem.type === '密码')?.value)
                              .copyOption(CopyOptions.LocalDevice)
                              .layoutWeight(1)
                          }
                          .margin({
                            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                          })
                        }
                        if (item.info.find(infoItem => infoItem.type === 'MFA')) {
                          Row() {
                            Text('MFA')
                              .fontWeight(FontWeight.Medium)
                              .margin({
                                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                              })
                            Text(this.mfaArray.find(mfaItem => mfaItem.id === item.id)?.mfa)
                              .copyOption(CopyOptions.LocalDevice)
                              .layoutWeight(1)
                          }
                          .margin({
                            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                          })
                        }
                      }
                      if (item.tag.length > 0 && !this.hideTag) {
                        Flex({
                          wrap: FlexWrap.Wrap,
                          space: {
                            main: LengthMetrics.vp(8),
                            cross: LengthMetrics.vp(8)
                          }
                        }) {
                          ForEach(item.tag, (item: PasswordTagItem) => {
                            Text(item.value)
                              .enableAutoSpacing(true)
                              .fontColor(item.color)
                              .fontWeight(FontWeight.Medium)
                          })
                        }
                        .margin({
                          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                        })
                      }
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
                    this.passwordId = item.id
                    this.isShowInfoSheet = true
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
            })
            ListItem()
              .margin({
                bottom: this.preferType === 0 ? 80 : 0
              })
          }
        }
        .layoutWeight(1)
        .onRefreshing(async () => {
          this.tag = []
          this.multipleSelect = false
          this.multipleSelectArray = []
          this.passwordArray = []
          this.passwordArray =
            await getFilterPasswordList(this.context, this.nameKeyword, this.info, this.tag, this.orderColumn)
          if (deviceInfo.deviceType === '2in1') {
            await syncQuickBarPassword(this.context)
            this.quickBarPasswordIdArray = await getQuickBarPasswordIdList(this.context)
          }
          this.tags = await getTagList(this.context, 'value')
          this.loading = false
        })
        .bindSheet(this.isShowInfoSheet!!, this.InfoSheetBuilder(this.passwordId), {
          height: SheetSize.FIT_CONTENT,
          preferType: this.preferType,
          title: {
            title: '密码详情'
          },
          onAppear: async () => {
            const disallowScreenshot =
              getFlushPreference(this.context, 'commonSetting', 'disallowScreenshot', true) as boolean
            if (disallowScreenshot) {
              const lastWindow = await window.getLastWindow(this.context)
              await lastWindow.setWindowPrivacyMode(true)
            }
          },
          onDisappear: async () => {
            if (!this.showPassword) {
              const lastWindow = await window.getLastWindow(this.context)
              await lastWindow.setWindowPrivacyMode(false)
            }
          }
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
      this.showPassword = getFlushPreference(this.context, 'commonSetting', 'showPasswordInIndex', false) as boolean
      this.hideTag = getFlushPreference(this.context, 'commonSetting', 'hideTagInIndex', false) as boolean
      const disallowScreenshot =
        getFlushPreference(this.context, 'commonSetting', 'disallowScreenshot', true) as boolean
      if (disallowScreenshot) {
        const lastWindow = await window.getLastWindow(this.context)
        await lastWindow.setWindowPrivacyMode(this.showPassword)
      }
      this.context.eventHub.on('newPassword', () => {
        if (!this.isShowNewSheet && !this.isShowInfoSheet && !this.isShowUpdateSheet && !this.isShowFilterSheet) {
          this.isShowNewSheet = true
        }
      })
      this.context.eventHub.on('searchPassword', () => {
        if (!this.isShowNewSheet && !this.isShowInfoSheet && !this.isShowUpdateSheet && !this.isShowFilterSheet) {
          this.isShowFilterSheet = true
        }
      })
      this.context.eventHub.on('refreshPassword', async () => {
        this.enableCloudBackup = false
        this.showPassword = getFlushPreference(this.context, 'commonSetting', 'showPasswordInIndex', false) as boolean
        this.hideTag = getFlushPreference(this.context, 'commonSetting', 'hideTagInIndex', false) as boolean
        const disallowScreenshot =
          getFlushPreference(this.context, 'commonSetting', 'disallowScreenshot', true) as boolean
        if (disallowScreenshot) {
          const lastWindow = await window.getLastWindow(this.context)
          await lastWindow.setWindowPrivacyMode(this.showPassword)
        }
        this.loading = true
        const cloudServiceStatus = await getCloudServiceStatus(this.context)
        if (cloudServiceStatus && getKeyAlg()) {
          this.enableCloudBackup = true
        }
      })
      this.context.eventHub.on('refreshFilterPassword', () => {
        const data: Data = {
          nameKeyword: getTempPreference(this.context, 'filterPassword', 'nameKeyword', '') as string,
          info: getTempPreference(this.context, 'filterPassword', 'info', []) as PasswordInfoItem[],
          tag: getTempPreference(this.context, 'filterPassword', 'tag', []) as string[]
        }
        this.nameKeyword = data.nameKeyword
        this.info = data.info
        this.tag = data.tag
        this.loading = true
      })
      this.context.eventHub.on('passwordInfo', (passwordId: number) => {
        if (this.isShowInfoSheet) {
          this.isShowInfoSheet = false
        }
        this.passwordId = passwordId
        this.isShowInfoSheet = true
      })
      this.intervalId = setInterval(async () => {
        const mfaArray: MfaItem[] = []
        const promises = this.passwordArray.map(async (item) => {
          const mfaInfo = item.info.find(infoItem => infoItem.type === 'MFA')
          if (mfaInfo) {
            const mfaInfoArray = mfaInfo.value.split('\0')
            const res = await getTotp(mfaInfoArray[0], Number(mfaInfoArray[1]), Number(mfaInfoArray[2]))
            if (res.value !== 'fail') {
              mfaArray.push({
                id: item.id,
                mfa: res.value
              })
            }
            if (res.value === 'fail') {
              clearInterval(this.intervalId)
            }
          }
        })
        await Promise.all(promises)
        this.mfaArray = mfaArray
      }, 500)
      this.loading = true
      const cloudServiceStatus = await getCloudServiceStatus(this.context)
      if (cloudServiceStatus && getKeyAlg()) {
        this.enableCloudBackup = true
      }
    })
    .onDisAppear(() => {
      if (this.intervalId !== -1) {
        clearInterval(this.intervalId)
      }
      this.context.eventHub.off('passwordInfo')
      this.context.eventHub.off('refreshFilterPassword')
      this.context.eventHub.off('refreshPassword')
      this.context.eventHub.off('searchPassword')
      this.context.eventHub.off('newPassword')
    })
    .bindSheet(this.isShowUpdateSheet!!, this.UpdateSheetBuilder(this.passwordId), {
      height: SheetSize.FIT_CONTENT,
      preferType: this.preferType,
      title: {
        title: '修改密码'
      },
      onAppear: async () => {
        const disallowScreenshot =
          getFlushPreference(this.context, 'commonSetting', 'disallowScreenshot', true) as boolean
        if (disallowScreenshot) {
          const lastWindow = await window.getLastWindow(this.context)
          await lastWindow.setWindowPrivacyMode(true)
        }
      },
      onDisappear: async () => {
        if (!this.showPassword) {
          const lastWindow = await window.getLastWindow(this.context)
          await lastWindow.setWindowPrivacyMode(false)
        }
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