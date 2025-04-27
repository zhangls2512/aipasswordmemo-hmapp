import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { get } from '../common/Accesstoken'
import { decrypt, getKey } from '../common/Crypto'
import { Password, PasswordInfoItem, Info, Tag } from '../common/Dataget'
import { importPassword, importInfo, importTag } from '../common/Dataimport'
import request from '../common/Request'

interface Item {
  id: number,
  content: string,
  iv: string
}

interface PasswordCloudBackup {
  name: string,
  info: PasswordInfoItem[],
  tag: string[],
  updateTime: number,
  cloudBackTime: number
}

interface InfoCloudBackup {
  type: string,
  value: string,
  updateTime: number,
  cloudBackTime: number
}

interface TagCloudBackup {
  value: string,
  color: string,
  updateTime: number,
  cloudBackTime: number
}

@Builder
export function CloudbackupimportBuilder() {
  Cloudbackupimport()
}

@ComponentV2
struct Cloudbackupimport {
  @Local index: number = 0
  @Local value: string = '保留'
  text: string = ''
  dialogControllerProgress: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: '导入中...' + this.text
    })
  })

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Row() {
              Text('冲突解决模式')
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontWeight('medium')
              Blank()
              Select([
                { value: '保留' },
                { value: '覆盖' }
              ])
                .selected($$this.index)
                .value($$this.value)
            }
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
            .padding($r('sys.float.ohos_id_corner_radius_default_m'))
            .width('100%')
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('导入')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: $r('sys.float.ohos_id_corner_radius_default_m')
              })
            Column() {
              Row() {
                Text('密码')
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
                  accessToken: get(),
                  type: 'password'
                })
                if (countres !== 'fail') {
                  const total = JSON.parse(countres).count as number
                  for (let i = 0; i < total; i += 10) {
                    this.text = '(' + i + '/' + total + ')'
                    const listres = await request('/password/getBackupList', {
                      accessToken: get(),
                      type: 'password',
                      skip: i
                    })
                    if (listres !== 'fail') {
                      const listarray = JSON.parse(listres).data as Item[]
                      const array: Password[] = []
                      const promises = listarray.map(async (item) => {
                        const itemstring = await decrypt({
                          content: item.content,
                          iv: item.iv
                        })
                        const itemobject = JSON.parse(itemstring) as PasswordCloudBackup
                        array.push({
                          id: item.id,
                          name: itemobject.name,
                          info: itemobject.info,
                          tag: itemobject.tag,
                          updateTime: itemobject.updateTime,
                          cloudBackupTime: itemobject.cloudBackTime
                        })
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
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('常用信息')
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
                  accessToken: get(),
                  type: 'info'
                })
                if (countres !== 'fail') {
                  const total = JSON.parse(countres).count as number
                  for (let i = 0; i < total; i += 10) {
                    this.text = '(' + i + '/' + total + ')'
                    const listres = await request('/password/getBackupList', {
                      accessToken: get(),
                      type: 'info',
                      skip: i
                    })
                    if (listres !== 'fail') {
                      const listarray = JSON.parse(listres).data as Item[]
                      const array: Info[] = []
                      const promises = listarray.map(async (item) => {
                        const itemstring = await decrypt({
                          content: item.content,
                          iv: item.iv
                        })
                        const itemobject = JSON.parse(itemstring) as InfoCloudBackup
                        array.push({
                          id: item.id,
                          type: itemobject.type,
                          value: itemobject.value,
                          updateTime: itemobject.updateTime,
                          cloudBackupTime: itemobject.cloudBackTime
                        })
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
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('标签')
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
                  accessToken: get(),
                  type: 'tag'
                })
                if (countres !== 'fail') {
                  const total = JSON.parse(countres).count as number
                  for (let i = 0; i < total; i += 10) {
                    this.text = '(' + i + '/' + total + ')'
                    const listres = await request('/password/getBackupList', {
                      accessToken: get(),
                      type: 'tag',
                      skip: i
                    })
                    if (listres !== 'fail') {
                      const listarray = JSON.parse(listres).data as Item[]
                      const array: Tag[] = []
                      const promises = listarray.map(async (item) => {
                        const itemstring = await decrypt({
                          content: item.content,
                          iv: item.iv
                        })
                        const itemobject = JSON.parse(itemstring) as TagCloudBackup
                        array.push({
                          id: item.id,
                          value: itemobject.value,
                          color: itemobject.color,
                          updateTime: itemobject.updateTime,
                          cloudBackupTime: itemobject.cloudBackTime
                        })
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
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title('导入云备份')
  }
}