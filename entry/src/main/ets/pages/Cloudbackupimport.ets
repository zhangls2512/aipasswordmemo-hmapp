import { preferences } from '@kit.ArkData'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { get, getAccountInfo } from '../common/Accesstoken'
import { decrypt, getKey } from '../common/Crypto'
import { PasswordInfoItem } from '../common/Dataget'
import { importInfo, importPassword, importTag, InfoInItem, PasswordInItem, TagInItem } from '../common/Dataimport'
import request from '../common/Request'

interface Type {
  name: string,
  value: string
}

export interface Item {
  id: number,
  content: string,
  iv: string
}

export interface PasswordCloudBackup {
  name: string,
  info: PasswordInfoItem[],
  tag: string[],
  updateTime: number,
  cloudBackupTime: string | number
}

export interface InfoCloudBackup {
  type: string,
  value: string,
  updateTime: number,
  cloudBackupTime: string | number
}

export interface TagCloudBackup {
  value: string,
  color: string,
  updateTime: number,
  cloudBackupTime: string | number
}

@Builder
export function CloudbackupimportBuilder() {
  Cloudbackupimport()
}

@ComponentV2
struct Cloudbackupimport {
  @Local index: number = 0
  @Local value: string = '保留'
  @Local autoImport: string[] = []
  @Local accessToken: string = ''
  @Local uid: string = ''
  context = this.getUIContext().getHostContext()
  cloudbackupSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'cloudbackupSetting'
  })
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '导入中...'
    })
  })
  typeArray: Type[] = [
    {
      name: '密码',
      value: 'password'
    },
    {
      name: '常用信息',
      value: 'info'
    },
    {
      name: '标签',
      value: 'tag'
    }
  ]

  getSetting() {
    const autoImport = this.cloudbackupSettingDataPreferences.getSync('autoImport', [])
    this.autoImport = autoImport as string[]
  }

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Row() {
              Text('冲突解决模式')
                .fontWeight(FontWeight.Medium)
              Blank()
              Select([
                { value: '保留' },
                { value: '覆盖' }
              ])
                .selected($$this.index)
                .value($$this.value)
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Column() {
            Text('自动 (应用启动时，冲突解决模式：保留)')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              ForEach(this.typeArray, (item: Type, index) => {
                if (index !== 0) {
                  Divider()
                    .padding({
                      left: 12,
                      right: 12
                    })
                }
                Row() {
                  Text(item.name)
                    .fontWeight(FontWeight.Medium)
                  Blank()
                  Toggle({
                    type: ToggleType.Switch,
                    isOn: this.autoImport.includes(item.value)
                  })
                    .onChange((isOn) => {
                      let autoImport: string[] = []
                      if (!isOn) {
                        autoImport = this.autoImport.filter(itema => itema !== item.value)
                      }
                      if (isOn) {
                        autoImport = [...this.autoImport, item.value]
                      }
                      const cloudbackupSettingDataPreferences = preferences.getPreferencesSync(this.context, {
                        name: 'cloudbackupSetting'
                      })
                      cloudbackupSettingDataPreferences.putSync('autoImport', autoImport)
                      cloudbackupSettingDataPreferences.flushSync()
                      this.getSetting()
                    })
                }
                .borderRadius(12)
                .padding(12)
                .width('100%')
              })
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

        if (this.accessToken) {
          ListItem() {
            Column() {
              Text('手动')
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .fontWeight(FontWeight.Medium)
                .margin({
                  bottom: 6,
                  left: 12
                })
              Column() {
                Row() {
                  Text('密码')
                    .fontWeight(FontWeight.Medium)
                  Blank()
                  Image($r('app.media.right'))
                    .fillColor($r('sys.color.icon_fourth'))
                    .height(12)
                    .width(12)
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
                .onClick(async () => {
                  if (!getKey()) {
                    promptAction.showDialog({
                      title: '导入失败',
                      message: '未导入密钥。请前往“我的”>“设置”>“密钥”导入密钥',
                      buttons: [
                        {
                          text: '确定',
                          color: $r('sys.color.font_emphasize')
                        }
                      ]
                    })
                    return
                  }
                  this.dialogControllerProgress.open()
                  const countres = await request('/password/getBackupCount', {
                    accessToken: this.accessToken
                  })
                  if (countres !== 'fail') {
                    const total = JSON.parse(countres).count.password as number
                    for (let i = 0; i < total; i += 50) {
                      const listres = await request('/password/getBackupList', {
                        accessToken: this.accessToken,
                        type: 'password',
                        skip: i,
                        count: 50
                      })
                      if (listres !== 'fail') {
                        const listarray = JSON.parse(listres).data as Item[]
                        const array: PasswordInItem[] = []
                        const promises = listarray.map(async (item) => {
                          const itemstring = await decrypt({
                            content: item.content,
                            iv: item.iv
                          })
                          if (itemstring !== 'fail') {
                            const itemobject = JSON.parse(itemstring) as PasswordCloudBackup
                            let cloudBackupTime = itemobject.cloudBackupTime
                            if (typeof (cloudBackupTime) === 'number') {
                              cloudBackupTime = JSON.stringify([{
                                uid: this.uid,
                                time: itemobject.cloudBackupTime
                              }])
                            }
                            array.push({
                              id: item.id,
                              name: itemobject.name,
                              info: itemobject.info,
                              tag: itemobject.tag,
                              updateTime: itemobject.updateTime,
                              cloudBackupTime: cloudBackupTime
                            })
                          }
                        })
                        await Promise.all(promises)
                        let conflictResolution = 0
                        if (this.index === 1) {
                          conflictResolution = 5
                        }
                        await importPassword(JSON.stringify(array), conflictResolution)
                      } else {
                        this.dialogControllerProgress.close()
                      }
                    }
                    this.dialogControllerProgress.close()
                    promptAction.showToast({
                      message: '导入成功'
                    })
                  } else {
                    this.dialogControllerProgress.close()
                  }
                })

                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Text('常用信息')
                    .fontWeight(FontWeight.Medium)
                  Blank()
                  Image($r('app.media.right'))
                    .fillColor($r('sys.color.icon_fourth'))
                    .height(12)
                    .width(12)
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
                .onClick(async () => {
                  if (!getKey()) {
                    promptAction.showDialog({
                      title: '导入失败',
                      message: '未导入密钥。请前往“我的”>“设置”>“密钥”导入密钥',
                      buttons: [
                        {
                          text: '确定',
                          color: $r('sys.color.font_emphasize')
                        }
                      ]
                    })
                    return
                  }
                  this.dialogControllerProgress.open()
                  const countres = await request('/password/getBackupCount', {
                    accessToken: this.accessToken
                  })
                  if (countres !== 'fail') {
                    const total = JSON.parse(countres).count.info as number
                    for (let i = 0; i < total; i += 50) {
                      const listres = await request('/password/getBackupList', {
                        accessToken: this.accessToken,
                        type: 'info',
                        skip: i,
                        count: 50
                      })
                      if (listres !== 'fail') {
                        const listarray = JSON.parse(listres).data as Item[]
                        const array: InfoInItem[] = []
                        const promises = listarray.map(async (item) => {
                          const itemstring = await decrypt({
                            content: item.content,
                            iv: item.iv
                          })
                          if (itemstring !== 'fail') {
                            const itemobject = JSON.parse(itemstring) as InfoCloudBackup
                            let cloudBackupTime = itemobject.cloudBackupTime
                            if (typeof (cloudBackupTime) === 'number') {
                              cloudBackupTime = JSON.stringify([{
                                uid: this.uid,
                                time: itemobject.cloudBackupTime
                              }])
                            }
                            array.push({
                              id: item.id,
                              type: itemobject.type,
                              value: itemobject.value,
                              updateTime: itemobject.updateTime,
                              cloudBackupTime: cloudBackupTime
                            })
                          }
                        })
                        await Promise.all(promises)
                        let conflictResolution = 0
                        if (this.index === 1) {
                          conflictResolution = 5
                        }
                        await importInfo(JSON.stringify(array), conflictResolution)
                      } else {
                        this.dialogControllerProgress.close()
                      }
                    }
                    this.dialogControllerProgress.close()
                    promptAction.showToast({
                      message: '导入成功'
                    })
                  } else {
                    this.dialogControllerProgress.close()
                  }
                })

                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Text('标签')
                    .fontWeight(FontWeight.Medium)
                  Blank()
                  Image($r('app.media.right'))
                    .fillColor($r('sys.color.icon_fourth'))
                    .height(12)
                    .width(12)
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
                .onClick(async () => {
                  if (!getKey()) {
                    promptAction.showDialog({
                      title: '导入失败',
                      message: '未导入密钥。请前往“我的”>“设置”>“密钥”导入密钥',
                      buttons: [
                        {
                          text: '确定',
                          color: $r('sys.color.font_emphasize')
                        }
                      ]
                    })
                    return
                  }
                  this.dialogControllerProgress.open()
                  const countres = await request('/password/getBackupCount', {
                    accessToken: this.accessToken
                  })
                  if (countres !== 'fail') {
                    const total = JSON.parse(countres).count.tag as number
                    for (let i = 0; i < total; i += 50) {
                      const listres = await request('/password/getBackupList', {
                        accessToken: this.accessToken,
                        type: 'tag',
                        skip: i,
                        count: 50
                      })
                      if (listres !== 'fail') {
                        const listarray = JSON.parse(listres).data as Item[]
                        const array: TagInItem[] = []
                        const promises = listarray.map(async (item) => {
                          const itemstring = await decrypt({
                            content: item.content,
                            iv: item.iv
                          })
                          if (itemstring !== 'fail') {
                            const itemobject = JSON.parse(itemstring) as TagCloudBackup
                            let cloudBackupTime = itemobject.cloudBackupTime
                            if (typeof (cloudBackupTime) === 'number') {
                              cloudBackupTime = JSON.stringify([{
                                uid: this.uid,
                                time: itemobject.cloudBackupTime
                              }])
                            }
                            array.push({
                              id: item.id,
                              value: itemobject.value,
                              color: itemobject.color,
                              updateTime: itemobject.updateTime,
                              cloudBackupTime: cloudBackupTime
                            })
                          }
                        })
                        await Promise.all(promises)
                        let conflictResolution = 0
                        if (this.index === 1) {
                          conflictResolution = 5
                        }
                        await importTag(JSON.stringify(array), conflictResolution)
                      } else {
                        this.dialogControllerProgress.close()
                      }
                    }
                    this.dialogControllerProgress.close()
                    promptAction.showToast({
                      message: '导入成功'
                    })
                  } else {
                    this.dialogControllerProgress.close()
                  }
                })
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
        }
      }
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title('导入云备份')
    .onReady(async () => {
      this.accessToken = await get()
      const accountInfo = await getAccountInfo()
      this.uid = accountInfo.uid
      this.getSetting()
    })
  }
}