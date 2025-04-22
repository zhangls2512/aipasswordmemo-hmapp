import { common } from '@kit.AbilityKit'
import { privacyManager } from '@kit.AppGalleryKit'
import { preferences } from '@kit.ArkData'
import { AppStorageV2, promptAction } from '@kit.ArkUI'
import { get } from '../common/Accesstoken'
import openLink from '../common/Openlink'
import request from '../common/Request'

@ObservedV2
export class AllService {
  @Trace allService: boolean = true
}

@ObservedV2
export class CloudService {
  @Trace status: boolean = false
}

@ComponentV2
export default struct Setting {
  @Local AllService: AllService = AppStorageV2.connect(AllService, () => new AllService())!
  @Local CloudService: CloudService = AppStorageV2.connect(CloudService, () => new CloudService())!
  @Local cloudServiceLoading: boolean = false
  @Local vipStatus: string = '未开通'
  @Local vipStatusLoading: boolean = false
  @Local vipStatusColor: string = 'red'
  @Local autoCloudBackup: boolean = false
  @Local agreedPrivacyAgreement: number | undefined = undefined
  context = getContext(this) as common.UIAbilityContext
  pageInfos: NavPathStack = new NavPathStack()
  commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'commonSetting'
  })
  accessToken: string = get()

  getSetting() {
    const allService: preferences.ValueType = this.commonSettingDataPreferences.getSync('allService', true)
    this.AllService.allService = allService as boolean
    const autoCloudBackup: preferences.ValueType = this.commonSettingDataPreferences.getSync('autoCloudBackup', false)
    this.autoCloudBackup = autoCloudBackup as boolean
    try {
      const appPrivacyResults: privacyManager.AppPrivacyResult[] = privacyManager.getAppPrivacyResult()
      this.agreedPrivacyAgreement = appPrivacyResults.find(item => item.type === 1)?.result
    } catch (err) {
      promptAction.showToast({
        message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
      })
    }
  }

  build() {
    Navigation(this.pageInfos) {
      List() {
        if (this.accessToken) {
          ListItem() {
            Column() {
              Text('账号')
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .fontWeight('medium')
                .margin({
                  bottom: 6,
                  left: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Column() {
                Row() {
                  Text('绑定华为账号')
                    .fontSize($r('sys.float.ohos_id_text_size_body1'))
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
                .onClick(() => {
                  this.pageInfos.pushPath({
                    name: 'Huaweiaccount'
                  })
                })

                if (!this.cloudServiceLoading) {
                  Divider()
                    .padding({
                      left: $r('sys.float.ohos_id_corner_radius_default_m'),
                      right: $r('sys.float.ohos_id_corner_radius_default_m')
                    })
                  Row() {
                    if (!this.CloudService.status) {
                      Text('开通云服务')
                        .fontColor($r('sys.color.font_emphasize'))
                        .fontSize($r('sys.float.ohos_id_text_size_body1'))
                        .fontWeight('medium')
                    }
                    if (this.CloudService.status) {
                      Text('取消开通云服务')
                        .fontColor($r('sys.color.warning'))
                        .fontSize($r('sys.float.ohos_id_text_size_body1'))
                        .fontWeight('medium')
                    }
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
                  .onClick(() => {
                    this.pageInfos.pushPath({
                      name: 'Cloudservice'
                    })
                  })

                  if (this.CloudService.status) {
                    Divider()
                      .padding({
                        left: $r('sys.float.ohos_id_corner_radius_default_m'),
                        right: $r('sys.float.ohos_id_corner_radius_default_m')
                      })
                    Row() {
                      Text('会员中心')
                        .fontColor('#FFD700')
                        .fontSize($r('sys.float.ohos_id_text_size_body1'))
                        .fontWeight('medium')
                      Blank()
                      if (!this.vipStatusLoading) {
                        Text(this.vipStatus)
                          .fontColor(this.vipStatusColor)
                          .fontSize($r('sys.float.ohos_id_text_size_body2'))
                          .margin({
                            right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                          })
                      }
                      if (this.vipStatusLoading) {
                        LoadingProgress()
                          .height(14)
                          .margin({
                            right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                          })
                          .width(14)
                      }
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
                    .onClick(() => {
                      this.pageInfos.pushPath({
                        name: 'Vip'
                      })
                    })
                  }
                }
              }
              .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
              .padding($r('sys.float.ohos_id_corner_radius_mark'))

              if (this.cloudServiceLoading) {
                LoadingProgress()
                  .height(20)
                  .margin({
                    top: 6,
                    left: $r('sys.float.ohos_id_corner_radius_default_m')
                  })
                  .width(20)
              }
            }
            .alignItems(HorizontalAlign.Start)
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_l')
          })

          if (!this.cloudServiceLoading && this.CloudService.status) {
            ListItem() {
              Column() {
                Text('云备份')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontWeight('medium')
                  .margin({
                    bottom: 6,
                    left: $r('sys.float.ohos_id_corner_radius_default_m')
                  })
                Column() {
                  Row() {
                    Text('自动开启')
                      .fontSize($r('sys.float.ohos_id_text_size_body1'))
                      .fontWeight('medium')
                    Blank()
                    Toggle({
                      type: ToggleType.Switch,
                      isOn: $$this.autoCloudBackup
                    })
                      .onChange((isOn: boolean) => {
                        this.commonSettingDataPreferences.putSync('autoCloudBackup', isOn)
                        this.commonSettingDataPreferences.flushSync()
                      })
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
                  .onClick(() => {
                    this.pageInfos.pushPath({
                      name: 'Cloudbackupmanage'
                    })
                  })

                  Divider()
                    .padding({
                      left: $r('sys.float.ohos_id_corner_radius_default_m'),
                      right: $r('sys.float.ohos_id_corner_radius_default_m')
                    })
                  Row() {
                    Text('管理')
                      .fontSize($r('sys.float.ohos_id_text_size_body1'))
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
                  .onClick(() => {
                    this.pageInfos.pushPath({
                      name: 'Cloudbackupmanage'
                    })
                  })

                  Divider()
                    .padding({
                      left: $r('sys.float.ohos_id_corner_radius_default_m'),
                      right: $r('sys.float.ohos_id_corner_radius_default_m')
                    })
                  Row() {
                    Text('导入')
                      .fontSize($r('sys.float.ohos_id_text_size_body1'))
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
                  .onClick(() => {
                    promptAction.showToast({
                      message: '敬请期待'
                    })
                  })

                  Divider()
                    .padding({
                      left: $r('sys.float.ohos_id_corner_radius_default_m'),
                      right: $r('sys.float.ohos_id_corner_radius_default_m')
                    })
                  Row() {
                    Text('密钥')
                      .fontSize($r('sys.float.ohos_id_text_size_body1'))
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
                  .onClick(() => {
                    this.pageInfos.pushPath({
                      name: 'Key'
                    })
                  })
                }
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                .padding($r('sys.float.ohos_id_corner_radius_mark'))

                Text('安全保障说明')
                  .fontColor($r('sys.color.font_emphasize'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontWeight('medium')
                  .margin({
                    top: 6,
                    left: $r('sys.float.ohos_id_corner_radius_default_m')
                  })
                  .onClick(() => {
                    openLink('https://docs.qq.com/doc/p/2fc9d7d60e5b79dcc09dec8251cb049fb29c7705')
                  })
              }
              .alignItems(HorizontalAlign.Start)
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_l')
            })
          }
        }

        ListItem() {
          Column() {
            Row() {
              Text('通用')
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
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
            .onClick(() => {
              this.pageInfos.pushPath({
                name: 'Commonsetting'
              })
            })
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
            Row() {
              Text('消息通知')
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
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
            .onClick(() => {
              this.pageInfos.pushPath({
                name: 'Notice'
              })
            })
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
            Text('数据与隐私')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: $r('sys.float.ohos_id_corner_radius_default_m')
              })
            Column() {
              Row() {
                Text('权限管理')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
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
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'Permissionsetting'
                })
              })

              if (typeof (this.agreedPrivacyAgreement) === 'number') {
                Divider()
                  .padding({
                    left: $r('sys.float.ohos_id_corner_radius_default_m'),
                    right: $r('sys.float.ohos_id_corner_radius_default_m')
                  })
              }
              if (this.agreedPrivacyAgreement === 0 || this.agreedPrivacyAgreement === 2) {
                Row() {
                  if (this.agreedPrivacyAgreement === 0) {
                    Text('阅读并签署隐私协议')
                      .fontSize($r('sys.float.ohos_id_text_size_body1'))
                      .fontWeight('medium')
                  }
                  if (this.agreedPrivacyAgreement === 2) {
                    Badge({
                      value: '',
                      position: BadgePosition.Right,
                      style: {
                        badgeSize: 12,
                        badgeColor: '#FA2A2D'
                      }
                    }) {
                      Text('阅读并签署隐私协议')
                        .fontSize($r('sys.float.ohos_id_text_size_body1'))
                        .fontWeight('medium')
                        .margin({
                          right: 16
                        })
                    }
                  }
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
                  try {
                    await privacyManager.requestAppPrivacyConsent(this.context)
                    this.getSetting()
                  } catch (err) {
                    promptAction.showToast({
                      message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
                    })
                  }
                })
              }
              if (this.agreedPrivacyAgreement === 1) {
                Row() {
                  Text('撤回同意隐私协议')
                    .fontColor($r('sys.color.warning'))
                    .fontSize($r('sys.float.ohos_id_text_size_body1'))
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
                .onClick(() => {
                  try {
                    privacyManager.disableService()
                  } catch (err) {
                    promptAction.showToast({
                      message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
                    })
                  }
                  this.context.terminateSelf()
                })
              }
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
            Text('了解我们如何使用您的数据')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: $r('sys.float.ohos_id_corner_radius_default_m')
              })
            Column() {
              Row() {
                Text('业务与隐私的声明')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
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
              .onClick(() => {
                openLink('https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=1657460888438843904')
              })

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('第三方共享信息清单')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
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
              .onClick(() => {
                openLink('https://docs.qq.com/doc/p/2bde62f6c2aaea97fbcca04c929c284005326d37')
              })

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('已收集个人信息清单')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
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
              .onClick(() => {
                promptAction.showToast({
                  message: '敬请期待'
                })
              })

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('隐私声明摘要')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
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
              .onClick(() => {
                openLink('https://docs.qq.com/doc/p/bdc2799638a46746599c68d82697b10a2becb2e4')
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
            Text('更多')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: $r('sys.float.ohos_id_corner_radius_default_m')
              })
            Column() {
              Row() {
                Text('应用服务模式')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                Blank()
                Text(this.AllService.allService ? '全量模式' : '基本模式')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
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
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'Servicemode'
                })
              })

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_m'),
                  right: $r('sys.float.ohos_id_corner_radius_default_m')
                })
              Row() {
                Text('其他')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
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
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'Moresetting'
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
            Row() {
              Text('关于')
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontWeight('medium')
              Blank()
              Text('版本 ')
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
              Text($r('app.string.app_version'))
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
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
            .onClick(() => {
              this.pageInfos.pushPath({
                name: 'About'
              })
            })

            Divider()
              .padding({
                left: $r('sys.float.ohos_id_corner_radius_default_m'),
                right: $r('sys.float.ohos_id_corner_radius_default_m')
              })
            Row() {
              Text('服务协议与规则')
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
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
            .onClick(() => {
              this.pageInfos.pushPath({
                name: 'Agreements'
              })
            })
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })
      }
      .nestedScroll({
        scrollForward: NestedScrollMode.SELF_ONLY,
        scrollBackward: NestedScrollMode.SELF_ONLY
      })
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .hideBackButton(true)
    .padding({
      top: $r('sys.float.ohos_id_elements_margin_vertical_m')
    })
    .title('设置')
    .titleMode(NavigationTitleMode.Mini)
    .onAppear(async () => {
      this.getSetting()
      if (this.accessToken) {
        this.cloudServiceLoading = true
        const infores = await request('/account/getAccountInfo', {
          accessToken: this.accessToken
        })
        this.cloudServiceLoading = false
        if (infores !== 'fail') {
          const service = JSON.parse(infores).data.service as string[]
          const status = service.includes('password')
          this.CloudService.status = status
          if (status) {
            this.vipStatusLoading = true
            const userres = await request('/product/getUserInfo', {
              accessToken: this.accessToken,
              product: 'password'
            })
            this.vipStatusLoading = false
            if (userres !== 'fail') {
              const vipenddate = JSON.parse(userres).data.vipEndDate as number
              if (vipenddate === 0 || vipenddate >= Date.now()) {
                this.vipStatus = '已开通'
                this.vipStatusColor = '#FFD700'
              }
            }
          }
        }
      }
    })
  }
}