import { common } from '@kit.AbilityKit'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { deviceInfo } from '@kit.BasicServicesKit'
import { fileIo } from '@kit.CoreFileKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { hdsEffect } from '@kit.UIDesignKit'
import { getAccountInfo } from '../common/Accesstoken'
import getCloudServiceStatus from '../common/Cloudservice'
import { getKey } from '../common/Crypto'
import { deleteCloudBackup, deleteData, setCloudBackup } from '../common/Datachange'
import { CloudBackupTimeItem, getInfoList, Info } from '../common/Dataget'
import copy from '../common/Pasteboard'
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
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  preferType = 1
  updateId = 0

  @Builder
  MenuBuilder(item: Info) {
    Menu() {
      MenuItem({
        startIcon: item.type === '图标' ? $r('app.media.save') : $r('app.media.copy'),
        content: item.type === '图标' ? '保存' : '复制'
      })
        .onClick(async () => {
          if (item.type !== '图标') {
            copy(item.type + '：' + item.value, false)
          }
          if (item.type === '图标') {
            const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(this.context)
            try {
              const uris = await phAccessHelper.showAssetsCreationDialog([item.value], [{
                fileNameExtension: 'png',
                photoType: photoAccessHelper.PhotoType.IMAGE
              }])
              const srcFile = fileIo.openSync(item.value)
              const destFile = fileIo.openSync(uris[0], fileIo.OpenMode.WRITE_ONLY)
              fileIo.copyFileSync(srcFile.fd, destFile.fd)
              fileIo.closeSync(srcFile)
              fileIo.closeSync(destFile)
              promptAction.openToast({
                message: '保存成功'
              })
            } catch (err) {
              if (err.code === 13900020) {
                return
              }
              promptAction.openToast({
                message: '发生错误，错误码：' + err.code
              })
            }
          }
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
            await deleteData('info', item.id)
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
            type: 'info',
            id: item.id,
            content: JSON.stringify({
              type: item.type,
              value: item.value,
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
            type: 'info',
            id: item.id
          })
          dialogControllerProgress.close()
          this.loading = true
        })
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
    Refresh({
      refreshing: $$this.loading
    }) {
      List() {
        ListItem() {
          Row() {
            Button('新增')
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
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
                onDisappear: (() => {
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
            Button('AI 识别新增')
              .buttonStyle(ButtonStyleMode.NORMAL)
              .visualEffect(new hdsEffect.HdsEffectBuilder()
                .pointLight({
                  sourceType: hdsEffect.PointLightSourceType.SOFT,
                  illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
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
                onDisappear: (() => {
                  this.loading = true
                })
              })
          }
        }
        .margin({
          bottom: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ForEach(this.infoArray, (item: Info) => {
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
                Column() {
                  if (item.type !== '图标') {
                    Text(item.value)
                      .enableAutoSpacing(true)
                      .fontWeight(FontWeight.Medium)
                  }
                  if (item.type === '图标') {
                    Image(item.value)
                      .copyOption(CopyOptions.LocalDevice)
                      .width('10%')
                      .onError((err) => {
                        promptAction.openToast({
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
                if (item.type === '图标') {
                  promptAction.openToast({
                    message: '图标类型不支持修改'
                  })
                  return
                }
                this.updateId = item.id
                this.isShowUpdateSheet = true
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
        this.context.eventHub.on('refreshInfo', async () => {
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
        this.context.eventHub.off('refreshInfo')
      })
      .bindSheet(this.isShowUpdateSheet!!, this.UpdateSheetBuilder(this.updateId), {
        height: SheetSize.FIT_CONTENT,
        preferType: this.preferType,
        title: {
          title: '修改常用信息'
        },
        onDisappear: (() => {
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
      this.infoArray = await getInfoList()
      this.loading = false
    })
  }
}