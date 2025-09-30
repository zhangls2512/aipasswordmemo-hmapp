import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { LengthMetrics, LoadingDialog, promptAction, window } from '@kit.ArkUI'
import { deviceInfo } from '@kit.BasicServicesKit'
import { hdsEffect } from '@kit.UIDesignKit'
import { getAccountInfo } from '../common/Accesstoken'
import getCloudServiceStatus from '../common/Cloudservice'
import { getKey } from '../common/Crypto'
import {
  CloudBackupTimeItem,
  getFilterPasswordList,
  getTagList,
  Password,
  PasswordInfoItem,
  PasswordTagItem
} from '../common/Dataget'
import { deleteCloudBackup, deleteData, setCloudBackup } from '../common/Datachange'
import FilterPassword from './Filterpassword'
import NewPassword from './Newpassword'
import PasswordInfo from './Passwordinfo'
import UpdatePassword from './Updatepassword'

interface Data {
  nameKeyword: string,
  info: PasswordInfoItem[],
  tag: string[]
}

@ComponentV2
export default struct PasswordPage {
  @Provider() isShowNewSheet: boolean = false
  @Provider() isShowInfoSheet: boolean = false
  @Provider() isShowUpdateSheet: boolean = false
  @Provider() isShowFilterSheet: boolean = false
  @Local passwordArray: Password[] = []
  @Local loading: boolean = false
  @Local isShowMenu: boolean = false
  @Local enableCloudBackup: boolean = false
  @Local nameKeyword: string = ''
  @Local info: PasswordInfoItem[] = []
  @Local tag: string[] = []
  @Local tags: PasswordTagItem[] = []
  @Local showPassword: boolean = false
  @Local multipleSelect: boolean = false
  @Local multipleSelectArray: Password[] = []
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  preferType = 1
  orderColumn = 'updateTime'
  passwordId = 0
  filterPasswordDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'filterPassword'
  })

  async cloudBackup(item: Password) {
    let cloudBackupTime = JSON.stringify([])
    if (typeof (item.cloudBackupTime) === 'string') {
      cloudBackupTime = item.cloudBackupTime
    }
    const cloudBackupTimeArray = JSON.parse(cloudBackupTime) as CloudBackupTimeItem[]
    const accountInfo = await getAccountInfo()
    const cloudBackupTimeIndex = cloudBackupTimeArray.findIndex(item => item.uid === accountInfo.uid)
    if (cloudBackupTimeIndex !== -1) {
      cloudBackupTimeArray[cloudBackupTimeIndex].time = Date.now()
    }
    if (cloudBackupTimeIndex === -1) {
      cloudBackupTimeArray.push({
        uid: accountInfo.uid,
        time: Date.now()
      })
    }
    await setCloudBackup({
      type: 'password',
      id: item.id,
      content: JSON.stringify({
        id: item.id,
        name: item.name,
        info: item.info.filter(itema => itema.type !== '图标'),
        tag: item.tag.map(item => item.value),
        updateTime: item.updateTime,
        cloudBackupTime: JSON.stringify(cloudBackupTimeArray)
      })
    })
  }

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
            const promptAction = this.getUIContext().getPromptAction()
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
              await deleteData('password', item.id)
              this.loading = true
            }
          })
        if (this.enableCloudBackup && !item.isCloudBackup) {
          MenuItem({
            startIcon: $r('app.media.cloud'),
            content: '云备份'
          })
            .onClick(async () => {
              const dialogControllerProgress = new CustomDialogController({
                builder: LoadingDialog({
                  content: '云备份中...'
                })
              })
              dialogControllerProgress.open()
              await this.cloudBackup(item)
              dialogControllerProgress.close()
              this.loading = true
            })
        }
        if (this.enableCloudBackup && item.isCloudBackup) {
          MenuItem({
            startIcon: $r('app.media.clouddelete'),
            content: '取消云备份'
          })
            .onClick(async () => {
              const dialogControllerProgress = new CustomDialogController({
                builder: LoadingDialog({
                  content: '取消云备份中...'
                })
              })
              dialogControllerProgress.open()
              await deleteCloudBackup({
                type: 'password',
                id: item.id
              })
              dialogControllerProgress.close()
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
    Refresh({
      refreshing: $$this.loading
    }) {
      List() {
        if (this.multipleSelect) {
          ListItem() {
            Row() {
              Column() {
                Image($r('app.media.cancel'))
              }
              .backgroundColor($r('sys.color.interactive_hover'))
              .borderRadius(20)
              .height(40)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .padding(11)
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
              Blank()
              Column() {
                Image($r('app.media.delete'))
              }
              .backgroundColor($r('sys.color.interactive_hover'))
              .borderRadius(20)
              .height(40)
              .padding(11)
              .visualEffect(new hdsEffect.HdsEffectBuilder()
                .pointLight({
                  sourceType: hdsEffect.PointLightSourceType.SOFT,
                  illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
                })
                .buildEffect())
              .width(40)
              .onClick(async () => {
                const promptAction = this.getUIContext().getPromptAction()
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
                    await deleteData('password', item.id)
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
                .backgroundColor($r('sys.color.interactive_hover'))
                .borderRadius(20)
                .height(40)
                .margin({
                  left: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .padding(11)
                .visualEffect(new hdsEffect.HdsEffectBuilder()
                  .pointLight({
                    sourceType: hdsEffect.PointLightSourceType.SOFT,
                    illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
                  })
                  .buildEffect())
                .width(40)
                .onClick(async () => {
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
            .width('100%')
          }
          .margin({
            bottom: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
        }
        if (!this.multipleSelect) {
          ListItem() {
            Row() {
              Column() {
                Image($r('app.media.new_white'))
              }
              .backgroundColor($r('sys.color.background_emphasize'))
              .borderRadius(20)
              .height(40)
              .padding(11)
              .width(40)
              .onClick(() => {
                this.isShowNewSheet = true
              })
              .bindSheet(this.isShowNewSheet!!, this.NewSheetBuilder(), {
                height: SheetSize.FIT_CONTENT,
                preferType: this.preferType,
                title: {
                  title: '新增密码'
                },
                onAppear: (async () => {
                  const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
                    name: 'commonSetting'
                  })
                  const disallowScreenshot = commonSettingDataPreferences.getSync('disallowScreenshot', true) as boolean
                  if (disallowScreenshot) {
                    const lastWindow = await window.getLastWindow(this.context)
                    await lastWindow.setWindowPrivacyMode(true)
                  }
                }),
                onDisappear: (async () => {
                  if (!this.showPassword) {
                    const lastWindow = await window.getLastWindow(this.context)
                    await lastWindow.setWindowPrivacyMode(false)
                  }
                  this.loading = true
                }),
                onWillDismiss: (async (DismissSheetAction) => {
                  const promptAction = this.getUIContext().getPromptAction()
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
              Column() {
                Image($r('app.media.sort'))
              }
              .backgroundColor($r('sys.color.interactive_hover'))
              .borderRadius(20)
              .height(40)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .padding(11)
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
              .backgroundColor($r('sys.color.interactive_hover'))
              .borderRadius(20)
              .height(40)
              .padding(11)
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
                onAppear: (async () => {
                  const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
                    name: 'commonSetting'
                  })
                  const disallowScreenshot = commonSettingDataPreferences.getSync('disallowScreenshot', true) as boolean
                  if (disallowScreenshot) {
                    const lastWindow = await window.getLastWindow(this.context)
                    await lastWindow.setWindowPrivacyMode(true)
                  }
                }),
                onDisappear: (async () => {
                  if (!this.showPassword) {
                    const lastWindow = await window.getLastWindow(this.context)
                    await lastWindow.setWindowPrivacyMode(false)
                  }
                }),
                onWillDismiss: (async (DismissSheetAction) => {
                  const promptAction = this.getUIContext().getPromptAction()
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
            .width('100%')
          }

          ListItem() {
            Search({
              value: this.nameKeyword!!,
              placeholder: '请输入名称关键词'
            })
              .searchButton('搜索')
              .onChange((value) => {
                this.nameKeyword = value
                this.filterPasswordDataPreferences.putSync('nameKeyword', value)
              })
              .onSubmit(() => {
                this.loading = true
              })
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })

          ListItem() {
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
                        this.filterPasswordDataPreferences.putSync('tag', this.tag)
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
                        this.filterPasswordDataPreferences.putSync('tag', this.tag)
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
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
          }
          .margin({
            bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
        }
        ForEach(this.passwordArray, (item: Password) => {
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
                if (item.info.some(itema => itema.type === '图标')) {
                  Image(item.info[item.info.findIndex(itema => itema.type === '图标')].value)
                    .copyOption(CopyOptions.LocalDevice)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                    .width('10%')
                    .onError((err) => {
                      promptAction.openToast({
                        message: '发生错误，错误信息：' + err.message
                      })
                    })
                }
                Column() {
                  Text(item.name)
                    .enableAutoSpacing(true)
                    .fontWeight(FontWeight.Bold)
                  if (this.showPassword && item.info.findIndex(infoItem => infoItem.type === '密码') !== -1) {
                    Row() {
                      Text('密码')
                        .fontWeight(FontWeight.Medium)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                      Text(item.info[item.info.findIndex(infoItem => infoItem.type === '密码')].value)
                        .copyOption(CopyOptions.LocalDevice)
                    }
                    .margin({
                      top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                    })
                  }
                  if (item.tag.length > 0) {
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
                .width('90%')
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor($r('sys.color.comp_background_primary'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.comp_background_secondary'))
                }
              })
              .width('100%')
              .onClick(() => {
                if (this.multipleSelect) {
                  return
                }
                this.passwordId = item.id
                this.isShowInfoSheet = true
              })
              .bindContextMenu(this.MenuBuilder(item), ResponseType.LongPress | ResponseType.RightClick, {
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
          .bindSheet(this.isShowInfoSheet!!, this.InfoSheetBuilder(this.passwordId), {
            height: SheetSize.FIT_CONTENT,
            preferType: this.preferType,
            title: {
              title: '密码详情'
            },
            onAppear: (async () => {
              const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
                name: 'commonSetting'
              })
              const disallowScreenshot = commonSettingDataPreferences.getSync('disallowScreenshot', true) as boolean
              if (disallowScreenshot) {
                const lastWindow = await window.getLastWindow(this.context)
                await lastWindow.setWindowPrivacyMode(true)
              }
            }),
            onDisappear: (async () => {
              if (!this.showPassword) {
                const lastWindow = await window.getLastWindow(this.context)
                await lastWindow.setWindowPrivacyMode(false)
              }
              this.loading = true
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
        const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
          name: 'commonSetting'
        })
        this.showPassword = commonSettingDataPreferences.getSync('showPasswordInIndex', false) as boolean
        const disallowScreenshot = commonSettingDataPreferences.getSync('disallowScreenshot', true) as boolean
        const lastWindow = await window.getLastWindow(this.context)
        if (disallowScreenshot) {
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
          const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
            name: 'commonSetting'
          })
          this.showPassword = commonSettingDataPreferences.getSync('showPasswordInIndex', false) as boolean
          const disallowScreenshot = commonSettingDataPreferences.getSync('disallowScreenshot', true) as boolean
          if (disallowScreenshot) {
            const lastWindow = await window.getLastWindow(this.context)
            await lastWindow.setWindowPrivacyMode(this.showPassword)
          }
          this.loading = true
          const cloudServiceStatus = await getCloudServiceStatus()
          if (cloudServiceStatus && getKey()) {
            this.enableCloudBackup = true
          }
        })
        this.context.eventHub.on('refreshFilterPassword', () => {
          const data: Data = {
            nameKeyword: this.filterPasswordDataPreferences.getSync('nameKeyword', '') as string,
            info: this.filterPasswordDataPreferences.getSync('info', []) as PasswordInfoItem[],
            tag: this.filterPasswordDataPreferences.getSync('tag', []) as string[]
          }
          this.nameKeyword = data.nameKeyword
          this.info = data.info
          this.tag = data.tag
          this.loading = true
        })
        this.loading = true
        const cloudServiceStatus = await getCloudServiceStatus()
        if (cloudServiceStatus && getKey()) {
          this.enableCloudBackup = true
        }
      })
      .onDisAppear(() => {
        this.context.eventHub.off('newPassword')
        this.context.eventHub.off('searchPassword')
        this.context.eventHub.off('refreshPassword')
        this.context.eventHub.off('refreshFilterPassword')
      })
      .bindSheet(this.isShowUpdateSheet!!, this.UpdateSheetBuilder(this.passwordId), {
        height: SheetSize.FIT_CONTENT,
        preferType: this.preferType,
        title: {
          title: '修改密码'
        },
        onAppear: (async () => {
          const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
            name: 'commonSetting'
          })
          const disallowScreenshot = commonSettingDataPreferences.getSync('disallowScreenshot', true) as boolean
          if (disallowScreenshot) {
            const lastWindow = await window.getLastWindow(this.context)
            await lastWindow.setWindowPrivacyMode(true)
          }
        }),
        onDisappear: (async () => {
          if (!this.showPassword) {
            const lastWindow = await window.getLastWindow(this.context)
            await lastWindow.setWindowPrivacyMode(false)
          }
          this.loading = true
        }),
        onWillDismiss: (async (DismissSheetAction) => {
          const promptAction = this.getUIContext().getPromptAction()
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
      this.passwordArray = await getFilterPasswordList(this.nameKeyword, this.info, this.tag, this.orderColumn)
      this.tags = await getTagList('value')
      this.loading = false
    })
  }
}