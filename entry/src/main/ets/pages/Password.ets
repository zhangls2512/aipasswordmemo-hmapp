import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { LoadingDialog, promptAction, window } from '@kit.ArkUI'
import { deviceInfo } from '@kit.BasicServicesKit'
import { getAccountInfo } from '../common/Accesstoken'
import getCloudServiceStatus from '../common/Cloudservice'
import { getKey } from '../common/Crypto'
import {
  CloudBackupTimeItem,
  getFilterPasswordList,
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
  @Local orderColumnText: string = '修改时间'
  @Local nameKeyword: string = ''
  @Local info: PasswordInfoItem[] = []
  @Local tag: string[] = []
  @Local showPassword: boolean = false
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  preferType = 1
  orderColumn = 'updateTime'
  passwordId = 0
  filterPasswordDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'filterPassword'
  })

  @Builder
  MenuBuilder(item: Password) {
    Menu() {
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
        .enabled(!item.info.some(itema => itema.type === '图标'))
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
      MenuItem({
        startIcon: $r('app.media.cloud'),
        content: '云备份'
      })
        .enabled(this.enableCloudBackup && !item.isCloudBackup)
        .onClick(async () => {
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
            type: 'password',
            id: item.id,
            content: JSON.stringify({
              id: item.id,
              name: item.name,
              info: item.info,
              tag: item.tag.map(item => item.value),
              updateTime: item.updateTime,
              cloudBackupTime: JSON.stringify(cloudBackupTimeArray)
            })
          })
          dialogControllerProgress.close()
          this.loading = true
        })
      MenuItem({
        startIcon: $r('app.media.clouddelete'),
        content: '删除云备份'
      })
        .enabled(this.enableCloudBackup && item.isCloudBackup)
        .onClick(async () => {
          const dialogControllerProgress = new CustomDialogController({
            builder: LoadingDialog({
              content: '删除云备份中...'
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
        ListItem() {
          Row() {
            Button('新增')
              .onClick(() => {
                this.isShowNewSheet = true
              })
              .bindSheet(this.isShowNewSheet!!, this.NewSheetBuilder(), {
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
                    lastWindow.setWindowPrivacyMode(true)
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
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
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
                  value: '名称',
                  action: () => {
                    this.orderColumn = 'name'
                    this.orderColumnText = '名称'
                    this.loading = true
                  }
                }
              ], {
                hapticFeedbackMode: HapticFeedbackMode.AUTO
              })
            Button('筛选')
              .buttonStyle(ButtonStyleMode.NORMAL)
              .onClick(() => {
                this.isShowFilterSheet = true
              })
              .bindSheet(this.isShowFilterSheet!!, this.FilterSheetBuilder(), {
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
                    lastWindow.setWindowPrivacyMode(true)
                  }
                }),
                onDisappear: (async () => {
                  if (!this.showPassword) {
                    const lastWindow = await window.getLastWindow(this.context)
                    lastWindow.setWindowPrivacyMode(false)
                  }
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
            .onSubmit(async () => {
              this.loading = true
            })
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ForEach(this.passwordArray, (item: Password) => {
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
                if (item.info.some(itema => itema.type === '图标')) {
                  Image(item.info[item.info.findIndex(itema => itema.type === '图标')].value)
                    .copyOption(CopyOptions.LocalDevice)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                    .width('10%')
                    .onError((err) => {
                      promptAction.openToast({
                        message: '发生错误，错误码：' + err.error?.code + '，错误信息：' + err.error?.message
                      })
                    })
                }
                Column() {
                  Text(item.name)
                    .fontWeight(FontWeight.Bold)
                  if (this.showPassword && item.info.findIndex(infoItem => infoItem.type === '密码') !== -1) {
                    Row() {
                      Text('密码')
                        .fontWeight(FontWeight.Medium)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                      Text(item.info[item.info.findIndex(infoItem => infoItem.type === '密码')].value)
                    }
                    .margin({
                      top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                    })
                  }
                  ForEach(item.tag, (item: PasswordTagItem) => {
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
                    .margin({
                      top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                    })
                  })
                }
                .alignItems(HorizontalAlign.Start)
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
              .onClick(() => {
                this.passwordId = item.id
                this.isShowInfoSheet = true
              })
              .bindContextMenu(this.MenuBuilder(item), ResponseType.LongPress | ResponseType.RightClick, {
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
                lastWindow.setWindowPrivacyMode(true)
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
        this.context.eventHub.on('refreshFilterPassword', async () => {
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
            lastWindow.setWindowPrivacyMode(true)
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
      this.loading = false
    })
  }
}