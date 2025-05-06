import { common } from '@kit.AbilityKit'
import { util } from '@kit.ArkTS'
import { promptAction } from '@kit.ArkUI'
import { fileIo as fs, picker } from '@kit.CoreFileKit'
import { getInfoList, getPasswordList, getTagList, PasswordInfoItem } from '../common/Dataget'
import { importInfo, importPassword, importTag } from '../common/Dataimport'

interface PasswordOutItem {
  id: number,
  name: string,
  info: PasswordInfoItem[],
  tag: string[],
  updateTime: number,
  cloudBackupTime: number
}

@Builder
export function DataInOutBuilder() {
  DataInOut()
}

@ComponentV2
struct DataInOut {
  @Local index: number = 0
  @Local value: string = '保留'
  context = getContext(this) as common.Context

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Row() {
              Text('冲突解决模式')
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
                  .fontWeight('medium')
                Blank()
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
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
                const documentSelectOptions = new picker.DocumentSelectOptions()
                documentSelectOptions.maxSelectNumber = 1
                documentSelectOptions.fileSuffixFilters = ['.txt']
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.select(documentSelectOptions)
                const file = fs.openSync(uris[0])
                const size = fs.statSync(file.fd).size
                const filebuffer = new ArrayBuffer(size)
                fs.readSync(file.fd, filebuffer)
                const decoder = util.TextDecoder.create()
                const filestring = decoder.decodeToString(new Uint8Array(filebuffer))
                fs.closeSync(file)
                let conflictResolution = 0
                if (this.index === 1) {
                  conflictResolution = 5
                }
                await importPassword(filestring, conflictResolution)
                promptAction.showToast({
                  message: '导入成功'
                })
              })

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('常用信息')
                  .fontWeight('medium')
                Blank()
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
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
                const documentSelectOptions = new picker.DocumentSelectOptions()
                documentSelectOptions.maxSelectNumber = 1
                documentSelectOptions.fileSuffixFilters = ['.txt']
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.select(documentSelectOptions)
                const file = fs.openSync(uris[0])
                const size = fs.statSync(file.fd).size
                const filebuffer = new ArrayBuffer(size)
                fs.readSync(file.fd, filebuffer)
                const decoder = util.TextDecoder.create()
                const filestring = decoder.decodeToString(new Uint8Array(filebuffer))
                fs.closeSync(file)
                let conflictResolution = 0
                if (this.index === 1) {
                  conflictResolution = 5
                }
                await importInfo(filestring, conflictResolution)
                promptAction.showToast({
                  message: '导入成功'
                })
              })

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('标签')
                  .fontWeight('medium')
                Blank()
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
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
                const documentSelectOptions = new picker.DocumentSelectOptions()
                documentSelectOptions.maxSelectNumber = 1
                documentSelectOptions.fileSuffixFilters = ['.txt']
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.select(documentSelectOptions)
                const file = fs.openSync(uris[0])
                const size = fs.statSync(file.fd).size
                const filebuffer = new ArrayBuffer(size)
                fs.readSync(file.fd, filebuffer)
                const decoder = util.TextDecoder.create()
                const filestring = decoder.decodeToString(new Uint8Array(filebuffer))
                fs.closeSync(file)
                let conflictResolution = 0
                if (this.index === 1) {
                  conflictResolution = 5
                }
                await importTag(filestring, conflictResolution)
                promptAction.showToast({
                  message: '导入成功'
                })
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

        ListItem() {
          Column() {
            Text('导出')
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
                  .fontWeight('medium')
                Blank()
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
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
                const documentSaveOptions = new picker.DocumentSaveOptions()
                documentSaveOptions.newFileNames = ['password']
                documentSaveOptions.fileSuffixChoices = ['.txt']
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.save(documentSaveOptions)
                const file = fs.openSync(uris[0], fs.OpenMode.READ_WRITE)
                const array = await getPasswordList()
                const arrayOut = array.map((item): PasswordOutItem => ({
                  id: item.id,
                  name: item.name,
                  info: item.info,
                  tag: item.tag.map(item => item.value),
                  updateTime: item.updateTime,
                  cloudBackupTime: item.cloudBackupTime
                }))
                fs.writeSync(file.fd, JSON.stringify(arrayOut))
                fs.closeSync(file)
                promptAction.showToast({
                  message: '导出成功'
                })
              })

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('常用信息')
                  .fontWeight('medium')
                Blank()
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
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
                const documentSaveOptions = new picker.DocumentSaveOptions()
                documentSaveOptions.newFileNames = ['info']
                documentSaveOptions.fileSuffixChoices = ['.txt']
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.save(documentSaveOptions)
                const file = fs.openSync(uris[0], fs.OpenMode.READ_WRITE)
                const array = await getInfoList()
                fs.writeSync(file.fd, JSON.stringify(array))
                fs.closeSync(file)
                promptAction.showToast({
                  message: '导出成功'
                })
              })

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('标签')
                  .fontWeight('medium')
                Blank()
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
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
                const documentSaveOptions = new picker.DocumentSaveOptions()
                documentSaveOptions.newFileNames = ['tag']
                documentSaveOptions.fileSuffixChoices = ['.txt']
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.save(documentSaveOptions)
                const file = fs.openSync(uris[0], fs.OpenMode.READ_WRITE)
                const array = await getTagList()
                fs.writeSync(file.fd, JSON.stringify(array))
                fs.closeSync(file)
                promptAction.showToast({
                  message: '导出成功'
                })
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
    .title('数据导入与导出')
  }
}