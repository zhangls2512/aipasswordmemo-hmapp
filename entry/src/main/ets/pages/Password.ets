import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { LoadingDialog, promptAction, window } from '@kit.ArkUI'
import getCloudServiceStatus from '../common/Cloudservice'
import { getKey } from '../common/Crypto'
import {
  getFilterPasswordList,
  getPasswordList,
  PasswordInfoItem,
  PasswordOut,
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
  @Local passwordArray: PasswordOut[] = []
  @Local loading: boolean = false
  @Local isShowMenu: boolean = false
  @Local enableCloudBackup: boolean = false
  @Local orderColumnText: string = '修改时间'
  context = getContext(this) as common.UIAbilityContext
  filterPasswordDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'filterPassword'
  })
  orderColumn: string = 'updateTime'
  passwordId: number = 0

  async getList() {
    this.loading = true
    this.passwordArray = await getPasswordList(this.orderColumn)
    this.loading = false
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
                title: '新增密码'
              },
              onAppear: (async () => {
                const lastWindow = await window.getLastWindow(this.context)
                await lastWindow.setWindowPrivacyMode(true)
              }),
              onDisappear: (async () => {
                const lastWindow = await window.getLastWindow(this.context)
                await lastWindow.setWindowPrivacyMode(false)
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
                  this.getList()
                }
              },
              {
                value: '名称',
                action: () => {
                  this.orderColumn = 'name'
                  this.orderColumnText = '名称'
                  this.getList()
                }
              }
            ])
          Button('筛选')
            .buttonStyle(ButtonStyleMode.NORMAL)
            .onClick(() => {
              this.isShowFilterSheet = !this.isShowFilterSheet
            })
            .bindSheet($$this.isShowFilterSheet, this.FilterSheetBuilder(), {
              height: SheetSize.FIT_CONTENT,
              preferType: SheetType.BOTTOM,
              title: {
                title: '筛选密码'
              },
              onAppear: (async () => {
                const lastWindow = await window.getLastWindow(this.context)
                await lastWindow.setWindowPrivacyMode(true)
              }),
              onDisappear: (async () => {
                const lastWindow = await window.getLastWindow(this.context)
                await lastWindow.setWindowPrivacyMode(false)
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
      ForEach(this.passwordArray, (item: PasswordOut) => {
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
                Text(item.name)
                  .fontWeight('bold')
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
                      .fontWeight('medium')
                  }
                  .margin({
                    top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                  })
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
                value: '详情',
                icon: $r('app.media.info'),
                action: () => {
                  this.passwordId = item.id
                  this.isShowInfoSheet = !this.isShowInfoSheet
                }
              },
              {
                value: '修改',
                icon: $r('app.media.edit'),
                action: () => {
                  this.passwordId = item.id
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
                    await deleteData('password', item.id)
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
                    type: 'password',
                    id: item.id,
                    content: JSON.stringify({
                      id: item.id,
                      name: item.name,
                      info: item.info,
                      tag: item.tag.map(item => item.value),
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
                      type: 'password',
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
      ListItem()
        .bindSheet($$this.isShowInfoSheet, this.InfoSheetBuilder(this.passwordId), {
          height: SheetSize.FIT_CONTENT,
          preferType: SheetType.BOTTOM,
          title: {
            title: '密码详情'
          },
          onAppear: (async () => {
            const lastWindow = await window.getLastWindow(this.context)
            await lastWindow.setWindowPrivacyMode(true)
          }),
          onDisappear: (async () => {
            const lastWindow = await window.getLastWindow(this.context)
            await lastWindow.setWindowPrivacyMode(false)
            this.getList()
          })
        })
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_max_padding_start'),
      right: $r('sys.float.ohos_id_max_padding_end')
    })
    .onAppear(async () => {
      this.filterPasswordDataPreferences.clearSync()
      await this.getList()
      const cloudServiceStatus = await getCloudServiceStatus()
      if (cloudServiceStatus && getKey()) {
        this.enableCloudBackup = true
      }
      this.context.eventHub.on('refreshPassword', async () => {
        this.enableCloudBackup = false
        this.filterPasswordDataPreferences.clearSync()
        await this.getList()
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
        this.loading = true
        this.passwordArray = await getFilterPasswordList(data.nameKeyword, data.info, data.tag, this.orderColumn)
        this.loading = false
      })
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshPassword')
      this.context.eventHub.off('refreshFilterPassword')
    })
    .bindSheet($$this.isShowUpdateSheet, this.UpdateSheetBuilder(this.passwordId), {
      height: SheetSize.FIT_CONTENT,
      preferType: SheetType.BOTTOM,
      title: {
        title: '修改密码'
      },
      onAppear: (async () => {
        const lastWindow = await window.getLastWindow(this.context)
        await lastWindow.setWindowPrivacyMode(true)
      }),
      onDisappear: (async () => {
        const lastWindow = await window.getLastWindow(this.context)
        await lastWindow.setWindowPrivacyMode(false)
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