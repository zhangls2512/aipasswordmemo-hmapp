import { bundleManager, common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { webview } from '@kit.ArkWeb'
import { asset } from '@kit.AssetStoreKit'
import { fileIo } from '@kit.CoreFileKit'
import { stringToArray } from '../common/Crypto'
import { getPasswordList, getTypeInfoList } from '../common/Dataget'
import { getDirectorySize } from '../common/File'
import { getSizeString } from '../common/Stringformat'

@ComponentV2
export default struct Cleardata {
  @Local setting: string[] = []
  @Local allSetting: boolean = false
  @Local cloudbackupSetting: boolean = false
  @Local dataSetting: boolean = false
  @Local commonSetting: boolean = false
  @Local permissionSetting: boolean = false
  @Local debugSetting: boolean = false
  @Local cache: string[] = []
  @Local allCache: boolean = false
  @Local appCache: boolean = false
  @Local webviewCache: boolean = false
  @Local invitationQrcodeCache: boolean = false
  @Local invitationQrcodeCacheSize: string = ''
  @Local log: string[] = []
  @Local allLog: boolean = false
  @Local errorLog: boolean = false
  @Local errorLogSize: string = ''
  @Local nouse: string[] = []
  @Local allNouse: boolean = false
  @Local tempFileNouse: boolean = false
  @Local tempFileNouseSize: string = ''
  @Local speakSettingNouse: boolean = false
  @Local oldaccountNouse: boolean = false
  @Local passwordIconNouse: boolean = false
  @Local passwordIconNouseSize: string = ''
  @Local oldInvitationQrcodeNouse: boolean = false
  @Local oldInvitationQrcodeNouseSize: string = ''
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext

  async getSize() {
    const invitationQrcodeCacheSize = await getDirectorySize(this.context.cacheDir + '/media/invitationqrcode/')
    this.invitationQrcodeCacheSize = getSizeString(invitationQrcodeCacheSize)
    const errorLogSize = await getDirectorySize(this.context.filesDir + '/log/error/')
    this.errorLogSize = getSizeString(errorLogSize)
    const tempFileNouseSize = await getDirectorySize(this.context.tempDir)
    this.tempFileNouseSize = getSizeString(tempFileNouseSize)
    const nousePasswordIconFilePathArray = await this.getNousePasswordIconFilePathArray()
    let passwordIconNouseSize = 0
    nousePasswordIconFilePathArray.forEach(item => {
      passwordIconNouseSize += fileIo.statSync(item).size
    })
    this.passwordIconNouseSize = getSizeString(passwordIconNouseSize)
    const oldInvitationQrcodeNouseSize = await getDirectorySize(this.context.filesDir + '/media/invitationqrcode/')
    this.oldInvitationQrcodeNouseSize = getSizeString(oldInvitationQrcodeNouseSize)
  }

  async getNousePasswordIconFilePathArray() {
    const passwordIconDir = this.context.filesDir + '/media/passwordicon/'
    if (!fileIo.accessSync(passwordIconDir)) {
      return []
    }
    const passwordIconFileNameArray = await fileIo.listFile(passwordIconDir)
    const passwordIconFilePathArray = passwordIconFileNameArray.map(item => passwordIconDir + item)
    const passwordArray = await getPasswordList(this.context)
    const passwordIconPathArray: string[] = []
    passwordArray.forEach(item => {
      const infoItem = item.info.find(infoItem => infoItem.type === '图标')
      if (infoItem) {
        passwordIconPathArray.push(infoItem.value.replace('file://com.zhangxm.aipasswordmemo', ''))
      }
    })
    const infoArray = await getTypeInfoList(this.context, '图标')
    const infoIconPathArray = infoArray.map(item => item.replace('file://com.zhangxm.aipasswordmemo', ''))
    const iconPathSet = new Set(passwordIconPathArray.concat(infoIconPathArray))
    return passwordIconFilePathArray.filter(item => !iconPathSet.has(item))
  }

  build() {
    List() {
      ListItem() {
        Column() {
          Text('设置')
            .fontColor($r('sys.color.font_secondary'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontWeight(FontWeight.Medium)
            .margin({
              bottom: 6,
              left: 12,
              right: 12
            })
          Column() {
            Row() {
              Text('全部')
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              CheckboxGroup({
                group: 'setting'
              })
                .checkboxShape(CheckBoxShape.ROUNDED_SQUARE)
                .selectAll(this.allSetting!!)
                .onChange((itemName) => {
                  this.setting = itemName.name
                })
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('云备份')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Checkbox({
                name: 'cloudbackupSetting',
                group: 'setting'
              })
                .select(this.cloudbackupSetting!!)
                .shape(CheckBoxShape.ROUNDED_SQUARE)
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('数据')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Checkbox({
                name: 'dataSetting',
                group: 'setting'
              })
                .select(this.dataSetting!!)
                .shape(CheckBoxShape.ROUNDED_SQUARE)
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('通用')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Checkbox({
                name: 'commonSetting',
                group: 'setting'
              })
                .select(this.commonSetting!!)
                .shape(CheckBoxShape.ROUNDED_SQUARE)
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('权限')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Checkbox({
                name: 'permissionSetting',
                group: 'setting'
              })
                .select(this.permissionSetting!!)
                .shape(CheckBoxShape.ROUNDED_SQUARE)
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('调试')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Checkbox({
                name: 'debugSetting',
                group: 'setting'
              })
                .select(this.debugSetting!!)
                .shape(CheckBoxShape.ROUNDED_SQUARE)
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .alignItems(HorizontalAlign.Start)
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_m')
      })

      ListItem() {
        Button('清理设置')
          .enabled(this.setting.length > 0)
          .role(ButtonRole.ERROR)
          .width('100%')
          .onClick(async () => {
            const promptAction = this.UIContext.getPromptAction()
            const data = await promptAction.showDialog({
              title: '提示',
              message: '清理成功后将恢复所选设置为默认，无法恢复。确定清理？',
              buttons: [
                {
                  text: '取消',
                  color: $r('sys.color.font_primary')
                },
                {
                  text: '清理',
                  color: $r('sys.color.warning')
                }
              ]
            })
            if (data.index === 1) {
              this.setting.forEach((item) => {
                const dataPreferences = preferences.getPreferencesSync(this.context, {
                  name: item
                })
                if (item === 'dataSetting') {
                  Object.keys(dataPreferences.getAllSync()).forEach(keyItem => {
                    const cannotDeleteKeys =
                      ['onTables', 'huaweiCloudSyncOnTables', 'huaweiCloudSyncNetworkStrategy', 'isBackupTables']
                    if (!cannotDeleteKeys.includes(keyItem)) {
                      dataPreferences.deleteSync(keyItem)
                    }
                  })
                } else {
                  dataPreferences.clearSync()
                }
                dataPreferences.flushSync()
              })
              const res = await promptAction.showDialog({
                title: '提示',
                message: '清理成功，需重启应用生效，是否重启？',
                buttons: [
                  {
                    text: '取消',
                    color: $r('sys.color.font_primary')
                  },
                  {
                    text: '重启',
                    color: $r('sys.color.font_emphasize')
                  }
                ]
              })
              if (res.index === 1) {
                const applicationContext = this.context.getApplicationContext()
                applicationContext.restartApp({
                  bundleName: 'com.zhangxm.aipasswordmemo',
                  abilityName: 'EntryAbility'
                })
              }
            }
          })
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_m')
      })

      ListItem() {
        Column() {
          Text('缓存')
            .fontColor($r('sys.color.font_secondary'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontWeight(FontWeight.Medium)
            .margin({
              bottom: 6,
              left: 12,
              right: 12
            })
          Column() {
            Row() {
              Text('全部')
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              CheckboxGroup({
                group: 'cache'
              })
                .checkboxShape(CheckBoxShape.ROUNDED_SQUARE)
                .selectAll(this.allCache!!)
                .onChange((itemName) => {
                  this.cache = itemName.name
                })
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('应用')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Checkbox({
                name: 'appCache',
                group: 'cache'
              })
                .select(this.appCache!!)
                .shape(CheckBoxShape.ROUNDED_SQUARE)
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('Webview')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Checkbox({
                name: 'webviewCache',
                group: 'cache'
              })
                .select(this.webviewCache!!)
                .shape(CheckBoxShape.ROUNDED_SQUARE)
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('邀请二维码图片')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(this.invitationQrcodeCacheSize)
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                })
              Checkbox({
                name: 'invitationQrcodeCache',
                group: 'cache'
              })
                .select(this.invitationQrcodeCache!!)
                .shape(CheckBoxShape.ROUNDED_SQUARE)
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .alignItems(HorizontalAlign.Start)
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      ListItem() {
        Button('清理缓存')
          .enabled(this.cache.length > 0)
          .role(ButtonRole.ERROR)
          .width('100%')
          .onClick(async () => {
            const promptAction = this.UIContext.getPromptAction()
            const data = await promptAction.showDialog({
              title: '提示',
              message: '清理成功后性能可能略微降低，但不会影响正常使用。确定清理？',
              buttons: [
                {
                  text: '取消',
                  color: $r('sys.color.font_primary')
                },
                {
                  text: '清理',
                  color: $r('sys.color.warning')
                }
              ]
            })
            if (data.index === 1) {
              const promises = this.cache.map(async (item) => {
                if (item === 'appCache') {
                  await bundleManager.cleanBundleCacheFilesForSelf()
                }
                if (item === 'webviewCache') {
                  webview.WebviewController.removeAllCache(true)
                }
                if (item === 'invitationQrcodeCache') {
                  const invitationcodeQrcodeDir = this.context.cacheDir + '/media/invitationqrcode/'
                  if (fileIo.accessSync(invitationcodeQrcodeDir)) {
                    const fileNames = await fileIo.listFile(invitationcodeQrcodeDir)
                    const promises = fileNames.map(async (item) => {
                      await fileIo.unlink(invitationcodeQrcodeDir + item)
                    })
                    await Promise.all(promises)
                  }
                }
              })
              await Promise.all(promises)
              await promptAction.openToast({
                message: '清理成功'
              })
              await this.getSize()
            }
          })
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_m')
      })

      ListItem() {
        Column() {
          Text('日志')
            .fontColor($r('sys.color.font_secondary'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontWeight(FontWeight.Medium)
            .margin({
              bottom: 6,
              left: 12,
              right: 12
            })
          Column() {
            Row() {
              Text('全部')
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              CheckboxGroup({
                group: 'log'
              })
                .checkboxShape(CheckBoxShape.ROUNDED_SQUARE)
                .selectAll(this.allLog!!)
                .onChange((itemName) => {
                  this.log = itemName.name
                })
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('故障')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(this.errorLogSize)
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                })
              Checkbox({
                name: 'errorLog',
                group: 'log'
              })
                .select(this.errorLog!!)
                .shape(CheckBoxShape.ROUNDED_SQUARE)
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .alignItems(HorizontalAlign.Start)
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      ListItem() {
        Button('清理日志')
          .enabled(this.log.length > 0)
          .role(ButtonRole.ERROR)
          .width('100%')
          .onClick(async () => {
            const promptAction = this.UIContext.getPromptAction()
            const data = await promptAction.showDialog({
              title: '提示',
              message: '日志有助于开发者定位问题。清理成功后无法恢复，确定清理？',
              buttons: [
                {
                  text: '取消',
                  color: $r('sys.color.font_primary')
                },
                {
                  text: '清理',
                  color: $r('sys.color.warning')
                }
              ]
            })
            if (data.index === 1) {
              const promises = this.log.map(async (item) => {
                if (item === 'errorLog') {
                  const errorLogDir = this.context.filesDir + '/log/error/'
                  if (fileIo.accessSync(errorLogDir)) {
                    const fileNames = await fileIo.listFile(errorLogDir)
                    const promises = fileNames.map(async (item) => {
                      await fileIo.unlink(errorLogDir + item)
                    })
                    await Promise.all(promises)
                  }
                }
              })
              await Promise.all(promises)
              await promptAction.openToast({
                message: '清理成功'
              })
              await this.getSize()
            }
          })
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_m')
      })

      ListItem() {
        Column() {
          Text('无用数据')
            .fontColor($r('sys.color.font_secondary'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontWeight(FontWeight.Medium)
            .margin({
              bottom: 6,
              left: 12,
              right: 12
            })
          Column() {
            Row() {
              Text('全部')
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              CheckboxGroup({
                group: 'nouse'
              })
                .checkboxShape(CheckBoxShape.ROUNDED_SQUARE)
                .selectAll(this.allNouse!!)
                .onChange((itemName) => {
                  this.nouse = itemName.name
                })
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('临时文件')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(this.tempFileNouseSize)
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                })
              Checkbox({
                name: 'tempFileNouse',
                group: 'nouse'
              })
                .select(this.tempFileNouse!!)
                .shape(CheckBoxShape.ROUNDED_SQUARE)
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('AI助手设置数据')
                .enableAutoSpacing(true)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Checkbox({
                name: 'speakSettingNouse',
                group: 'nouse'
              })
                .select(this.speakSettingNouse!!)
                .shape(CheckBoxShape.ROUNDED_SQUARE)
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('旧账号数据')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Checkbox({
                name: 'oldaccountNouse',
                group: 'nouse'
              })
                .select(this.oldaccountNouse!!)
                .shape(CheckBoxShape.ROUNDED_SQUARE)
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('无用密码图标图片')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(this.passwordIconNouseSize)
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                })
              Checkbox({
                name: 'passwordIconNouse',
                group: 'nouse'
              })
                .select(this.passwordIconNouse!!)
                .shape(CheckBoxShape.ROUNDED_SQUARE)
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('旧邀请二维码图片')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(this.oldInvitationQrcodeNouseSize)
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                })
              Checkbox({
                name: 'invitationQrcodeNouse',
                group: 'nouse'
              })
                .select(this.oldInvitationQrcodeNouse!!)
                .shape(CheckBoxShape.ROUNDED_SQUARE)
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .alignItems(HorizontalAlign.Start)
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      ListItem() {
        Button('清理无用数据')
          .enabled(this.nouse.length > 0)
          .role(ButtonRole.ERROR)
          .width('100%')
          .onClick(async () => {
            const promises = this.nouse.map(async (item) => {
              if (item === 'tempFileNouse') {
                const tempDir = this.context.tempDir
                const tempFiles = await fileIo.listFile(tempDir)
                tempFiles.forEach(async (item) => {
                  const path = tempDir + '/' + item
                  const isDirectory = fileIo.statSync(path)
                  if (!isDirectory) {
                    await fileIo.unlink(path)
                  }
                  if (isDirectory) {
                    await fileIo.rmdir(path)
                  }
                })
              }
              if (item === 'oldaccountNouse') {
                try {
                  const query: asset.AssetMap = new Map()
                  query.set(asset.Tag.ALIAS, stringToArray('accessToken'))
                  asset.removeSync(query)
                  await preferences.deletePreferences(this.context, {
                    name: 'login'
                  })
                } catch {
                }
              }
              if (item === 'speakSettingNouse') {
                await preferences.deletePreferences(this.context, 'speakSetting')
              }
              if (item === 'passwordIconNouse') {
                const nousePasswordIconFilePathArray = await this.getNousePasswordIconFilePathArray()
                const promises = nousePasswordIconFilePathArray.map(async (item) => {
                  await fileIo.unlink(item)
                })
                await Promise.all(promises)
              }
              if (item === 'oldInvitationQrcodeNouse') {
                await fileIo.rmdir(this.context.filesDir + '/media/invitationqrcode')
              }
            })
            await Promise.all(promises)
            await promptAction.openToast({
              message: '清理成功'
            })
            await this.getSize()
          })
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_m')
      })
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
    })
    .onAppear(async () => {
      await this.getSize()
    })
    .onDisAppear(() => {
      this.context.eventHub.emit('refreshSetting')
    })
  }
}