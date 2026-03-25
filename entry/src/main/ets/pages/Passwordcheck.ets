import { common } from '@kit.AbilityKit'
import { SegmentButtonV2Items, TabSegmentButtonV2 } from '@kit.ArkUI'
import {
  getOldPasswordList,
  getPasswordStrengthList,
  getRepeatPasswordList,
  ListItem,
  RepeatItem
} from '../common/Passwordcheck'
import { getPreferType } from '../common/Prefertype'
import UpdatePassword from './Updatepassword'

@ComponentV2
export default struct Passwordcheck {
  @Provider() isShowUpdateSheet: boolean = false
  @Local preferType: number = 1
  @Local selectedIndex: number = 0
  @Local lowStrengthPasswordArray: ListItem[] = []
  @Local mediumStrengthPasswordArray: ListItem[] = []
  @Local highStrengthPasswordArray: ListItem[] = []
  @Local repeatArray: RepeatItem[] = []
  @Local oldArray: ListItem[] = []
  @Local hoverId: number | string = -1
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  passwordId = 0

  @Builder
  UpdateSheetBuilder(id: number) {
    UpdatePassword({
      passwordId: id
    })
  }

  build() {
    Scroll() {
      Column() {
        TabSegmentButtonV2({
          items: new SegmentButtonV2Items([
            { text: '强度' },
            { text: '重复' },
            { text: '近一年未修改' }
          ]),
          selectedIndex: this.selectedIndex!!
        })
          .margin({
            bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
        List() {
          if (this.selectedIndex === 0) {
            ListItem() {
              Column() {
                Text('弱')
                  .fontColor(Color.Red)
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontWeight(FontWeight.Medium)
                  .margin({
                    bottom: 6,
                    left: 12,
                    right: 12
                  })
                if (this.lowStrengthPasswordArray.length === 0) {
                  Text('无数据')
                    .textAlign(TextAlign.Center)
                    .width('100%')
                }
                Column() {
                  ForEach(this.lowStrengthPasswordArray, (item: ListItem, index) => {
                    if (index !== 0) {
                      Divider()
                        .padding({
                          left: 12,
                          right: 12
                        })
                    }
                    Row() {
                      Text(item.name)
                        .enableAutoSpacing(true)
                        .fontWeight(FontWeight.Medium)
                        .layoutWeight(1)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                      Image($r('app.media.right'))
                        .fillColor($r('sys.color.icon_fourth'))
                        .height(12)
                        .width(12)
                    }
                    .borderRadius(12)
                    .padding(12)
                    .stateStyles({
                      normal: {
                        .backgroundColor(this.hoverId === 'low' + index ? $r('sys.color.interactive_hover') :
                          $r('sys.color.ohos_id_color_card_bg'))
                      },
                      pressed: {
                        .backgroundColor($r('sys.color.interactive_pressed'))
                      }
                    })
                    .width('100%')
                    .onHover((isHover) => {
                      if (!isHover) {
                        this.hoverId = -1
                      }
                      if (isHover) {
                        this.hoverId = 'low' + index
                      }
                    })
                    .onClick(() => {
                      this.passwordId = item.id
                      this.isShowUpdateSheet = true
                    })
                  })
                }
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                .padding($r('sys.float.ohos_id_corner_radius_mark'))

                Text('中')
                  .fontColor(Color.Orange)
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontWeight(FontWeight.Medium)
                  .margin({
                    bottom: 6,
                    left: 12,
                    right: 12,
                    top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                  })
                if (this.mediumStrengthPasswordArray.length === 0) {
                  Text('无数据')
                    .textAlign(TextAlign.Center)
                    .width('100%')
                }
                Column() {
                  ForEach(this.mediumStrengthPasswordArray, (item: ListItem, index) => {
                    if (index !== 0) {
                      Divider()
                        .padding({
                          left: 12,
                          right: 12
                        })
                    }
                    Row() {
                      Text(item.name)
                        .enableAutoSpacing(true)
                        .fontWeight(FontWeight.Medium)
                        .layoutWeight(1)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                      Image($r('app.media.right'))
                        .fillColor($r('sys.color.icon_fourth'))
                        .height(12)
                        .width(12)
                    }
                    .borderRadius(12)
                    .padding(12)
                    .stateStyles({
                      normal: {
                        .backgroundColor(this.hoverId === 'medium' + index ? $r('sys.color.interactive_hover') :
                          $r('sys.color.ohos_id_color_card_bg'))
                      },
                      pressed: {
                        .backgroundColor($r('sys.color.interactive_pressed'))
                      }
                    })
                    .width('100%')
                    .onHover((isHover) => {
                      if (!isHover) {
                        this.hoverId = -1
                      }
                      if (isHover) {
                        this.hoverId = 'medium' + index
                      }
                    })
                    .onClick(() => {
                      this.passwordId = item.id
                      this.isShowUpdateSheet = true
                    })
                  })
                }
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                .padding($r('sys.float.ohos_id_corner_radius_mark'))

                Text('强')
                  .fontColor(Color.Green)
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontWeight(FontWeight.Medium)
                  .margin({
                    bottom: 6,
                    left: 12,
                    right: 12,
                    top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                  })
                if (this.highStrengthPasswordArray.length === 0) {
                  Text('无数据')
                    .textAlign(TextAlign.Center)
                    .width('100%')
                }
                Column() {
                  ForEach(this.highStrengthPasswordArray, (item: ListItem, index) => {
                    if (index !== 0) {
                      Divider()
                        .padding({
                          left: 12,
                          right: 12
                        })
                    }
                    Row() {
                      Text(item.name)
                        .enableAutoSpacing(true)
                        .fontWeight(FontWeight.Medium)
                        .layoutWeight(1)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                      Image($r('app.media.right'))
                        .fillColor($r('sys.color.icon_fourth'))
                        .height(12)
                        .width(12)
                    }
                    .borderRadius(12)
                    .padding(12)
                    .stateStyles({
                      normal: {
                        .backgroundColor(this.hoverId === 'high' + index ? $r('sys.color.interactive_hover') :
                          $r('sys.color.ohos_id_color_card_bg'))
                      },
                      pressed: {
                        .backgroundColor($r('sys.color.interactive_pressed'))
                      }
                    })
                    .width('100%')
                    .onHover((isHover) => {
                      if (!isHover) {
                        this.hoverId = -1
                      }
                      if (isHover) {
                        this.hoverId = 'high' + index
                      }
                    })
                    .onClick(() => {
                      this.passwordId = item.id
                      this.isShowUpdateSheet = true
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
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
          }
          if (this.selectedIndex === 1) {
            if (this.repeatArray.length === 0) {
              ListItem() {
                Text('无数据')
              }
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .width('100%')
            }
            ForEach(this.repeatArray, (item: RepeatItem, index) => {
              ListItem() {
                Column() {
                  Text('使用 ' + item.password + ' 的 ' + item.count + ' 账号')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .fontWeight(FontWeight.Medium)
                    .margin({
                      bottom: 6,
                      left: 12,
                      right: 12
                    })
                  Column() {
                    ForEach(item.list, (item: ListItem, itemIndex) => {
                      if (itemIndex !== 0) {
                        Divider()
                          .padding({
                            left: 12,
                            right: 12
                          })
                      }
                      Row() {
                        Text(item.name)
                          .enableAutoSpacing(true)
                          .fontWeight(FontWeight.Medium)
                          .layoutWeight(1)
                          .margin({
                            right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                          })
                        Image($r('app.media.right'))
                          .fillColor($r('sys.color.icon_fourth'))
                          .height(12)
                          .width(12)
                      }
                      .borderRadius(12)
                      .padding(12)
                      .stateStyles({
                        normal: {
                          .backgroundColor(this.hoverId === index + ',' + itemIndex ?
                            $r('sys.color.interactive_hover') :
                            $r('sys.color.ohos_id_color_card_bg'))
                        },
                        pressed: {
                          .backgroundColor($r('sys.color.interactive_pressed'))
                        }
                      })
                      .width('100%')
                      .onHover((isHover) => {
                        if (!isHover) {
                          this.hoverId = -1
                        }
                        if (isHover) {
                          this.hoverId = index + ',' + itemIndex
                        }
                      })
                      .onClick(() => {
                        this.passwordId = item.id
                        this.isShowUpdateSheet = true
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
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
            })
          }
          if (this.selectedIndex === 2) {
            if (this.oldArray.length === 0) {
              ListItem() {
                Text('无数据')
              }
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .width('100%')
            }
            ForEach(this.oldArray, (item: ListItem, index) => {
              ListItem() {
                Column() {
                  Row() {
                    Text(item.name)
                      .enableAutoSpacing(true)
                      .fontWeight(FontWeight.Medium)
                      .layoutWeight(1)
                      .margin({
                        right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                      })
                    Image($r('app.media.right'))
                      .fillColor($r('sys.color.icon_fourth'))
                      .height(12)
                      .width(12)
                  }
                  .borderRadius(12)
                  .padding(12)
                  .stateStyles({
                    normal: {
                      .backgroundColor(this.hoverId === index ? $r('sys.color.interactive_hover') :
                        $r('sys.color.ohos_id_color_card_bg'))
                    },
                    pressed: {
                      .backgroundColor($r('sys.color.interactive_pressed'))
                    }
                  })
                  .width('100%')
                  .onHover((isHover) => {
                    if (!isHover) {
                      this.hoverId = -1
                    }
                    if (isHover) {
                      this.hoverId = index
                    }
                  })
                  .onClick(() => {
                    this.passwordId = item.id
                    this.isShowUpdateSheet = true
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
            ListItem() {
              Text('数据不准确说明')
                .fontColor($r('sys.color.font_emphasize'))
                .fontSize($r('sys.float.ohos_id_text_size_body3'))
                .onClick(async () => {
                  const promptAction = this.UIContext.getPromptAction()
                  await promptAction.showDialog({
                    title: '数据不准确说明',
                    message: '因为 2.0.8.0 之前版本存储密码的底层数据结构未记录“密码”类型信息内容的修改时间，只记录了“密码”类型信息所在数据行整体的修改时间，所以此处仅列出使用 2.0.8.0 及之后版本新增、修改的“密码”类型信息内容修改时间早于近一年的密码，未列出使用 2.0.8.0 之前版本新增、修改的“密码”类型信息内容修改时间早于近一年的密码，请知悉。',
                    buttons: [
                      {
                        text: '确定',
                        color: $r('sys.color.font_emphasize')
                      }
                    ]
                  })
                })
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_l')
            })
            .width('100%')
          }
        }
        .layoutWeight(1)
      }
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
    })
    .onAppear(async () => {
      this.preferType = getPreferType(this.UIContext)
      const passwordStrengthArray = await getPasswordStrengthList(this.context)
      this.lowStrengthPasswordArray = passwordStrengthArray[0]
      this.mediumStrengthPasswordArray = passwordStrengthArray[1]
      this.highStrengthPasswordArray = passwordStrengthArray[2]
      this.repeatArray = await getRepeatPasswordList(this.context)
      this.oldArray = await getOldPasswordList(this.context)
    })
    .bindSheet(this.isShowUpdateSheet!!, this.UpdateSheetBuilder(this.passwordId), {
      preferType: this.preferType,
      title: {
        title: '修改密码'
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