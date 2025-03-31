import { accessibility } from '@kit.AccessibilityKit'
import { display, window } from '@kit.ArkUI'
import { batteryInfo, deviceInfo, power, systemLoad, thermal } from '@kit.BasicServicesKit'
import { atomicService } from '@kit.ScenarioFusionKit'

interface DeviceInfoElement {
  name: string
  value: string
}

interface SystemInfoElement {
  name: string
  value: string | undefined
}

@Builder
export function DebugBuilder() {
  Debug()
}

@ComponentV2
export struct Debug {
  deviceInfoArray: DeviceInfoElement[] = [
    { name: '设备厂家名称', value: deviceInfo.manufacture },
    { name: '设备品牌名称', value: deviceInfo.brand },
    { name: '外部产品系列', value: deviceInfo.marketName },
    { name: '产品系列', value: deviceInfo.productSeries },
    { name: '认证型号', value: deviceInfo.productModel },
    { name: '认证型号别名', value: deviceInfo.productModelAlias },
    { name: '内部软件子型号', value: deviceInfo.softwareModel },
    { name: '硬件版本号', value: deviceInfo.hardwareModel },
    { name: 'Bootloader 版本号', value: deviceInfo.bootloaderVersion },
    { name: '应用二进制接口', value: deviceInfo.abiList },
    { name: '安全补丁级别', value: deviceInfo.securityPatchTag },
    { name: '产品版本', value: deviceInfo.displayVersion },
    { name: '差异版本号', value: deviceInfo.incrementalVersion },
    { name: '系统的发布类型', value: deviceInfo.osReleaseType },
    { name: '系统版本', value: deviceInfo.osFullName },
    { name: 'Major 版本号', value: String(deviceInfo.majorVersion) },
    { name: 'Senior 版本号', value: String(deviceInfo.seniorVersion) },
    { name: 'Feature 版本号', value: String(deviceInfo.featureVersion) },
    { name: 'Build 版本号', value: String(deviceInfo.buildVersion) },
    { name: '系统软件 API 版本', value: String(deviceInfo.sdkApiVersion) },
    { name: '首个版本系统软件 API 版本', value: String(deviceInfo.firstApiVersion) },
    { name: '版本 ID', value: deviceInfo.versionId },
    { name: '构建类型', value: deviceInfo.buildType },
    { name: '构建用户', value: deviceInfo.buildUser },
    { name: '构建主机', value: deviceInfo.buildHost },
    { name: '构建时间', value: deviceInfo.buildTime },
    { name: '构建版本 Hash', value: deviceInfo.buildRootHash },
    { name: '发行版系统名称', value: deviceInfo.distributionOSName },
    { name: '发行版系统版本号', value: deviceInfo.distributionOSVersion },
    { name: '发行版系统 API 版本', value: String(deviceInfo.distributionOSApiVersion) },
    { name: '发行版系统 API 版本名称', value: deviceInfo.distributionOSApiName },
    { name: '发行版系统类型', value: deviceInfo.distributionOSReleaseType },
    { name: '开发者匿名设备标识符', value: deviceInfo.ODID }
  ]
  stateArray: Array<atomicService.SystemInfoType> = [
    'brand',
    'deviceModel',
    'screenWidth',
    'screenHeight',
    'statusBarHeight',
    'language',
    'osFullName',
    'fontSizeSetting',
    'sdkApiVersion',
    'bluetoothEnabled',
    'locationEnabled',
    'wifiEnabled',
    'deviceOrientation',
    'theme',
    'windowWidth',
    'windowHeight'
  ]
  systemInfoArray: SystemInfoElement[] = [
    { name: '设备类型', value: atomicService.getSystemInfoSync(this.stateArray).deviceModel },
    { name: '屏幕的宽度', value: String(atomicService.getSystemInfoSync(this.stateArray).screenWidth) + ' px' },
    { name: '屏幕的高度', value: String(atomicService.getSystemInfoSync(this.stateArray).screenHeight) + ' px' },
    { name: '状态栏的高度', value: String(atomicService.getSystemInfoSync(this.stateArray).statusBarHeight) + ' px' },
    { name: '系统语言', value: atomicService.getSystemInfoSync(this.stateArray).language },
    { name: '系统版本', value: atomicService.getSystemInfoSync(this.stateArray).osFullName },
    { name: '显示设备逻辑像素的密度', value: String(atomicService.getSystemInfoSync(this.stateArray).fontSizeSetting) },
    { name: '系统软件 API 版本', value: String(atomicService.getSystemInfoSync(this.stateArray).sdkApiVersion) },
    {
      name: '蓝牙系统开关',
      value: atomicService.getSystemInfoSync(this.stateArray).bluetoothEnabled ? '开启' : '关闭'
    },
    {
      name: '地理位置的系统开关',
      value: atomicService.getSystemInfoSync(this.stateArray).locationEnabled ? '开启' : '关闭'
    },
    { name: 'Wi-Fi 的系统开关', value: atomicService.getSystemInfoSync(this.stateArray).wifiEnabled ? '开启' : '关闭' },
    { name: '设备方向', value: atomicService.getSystemInfoSync(this.stateArray).deviceOrientation },
    {
      name: '深浅色模式',
      value: atomicService.getSystemInfoSync(this.stateArray).theme === -1 ? '未设置' :
        atomicService.getSystemInfoSync(this.stateArray).theme === 0 ? '深色模式' :
          atomicService.getSystemInfoSync(this.stateArray).theme === 1 ? '浅色模式' :
            'undefined'
    },
    { name: '可使用窗口宽度', value: String(atomicService.getSystemInfoSync(this.stateArray).windowWidth) + ' px' },
    { name: '可使用窗口高度', value: String(atomicService.getSystemInfoSync(this.stateArray).windowHeight) + ' px' }
  ]
  @Local systemLoadValue: number = -1

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Text('设备信息')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: $r('sys.float.ohos_id_corner_radius_default_m')
              })
            Column() {
              Row() {
                Text('设备类型')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('35%')
                Blank()
                  .width('5%')
                Text(deviceInfo.deviceType)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('60%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              ForEach(this.deviceInfoArray, (item: DeviceInfoElement) => {
                if (item.value) {
                  Divider()
                    .padding({
                      left: $r('sys.float.ohos_id_corner_radius_default_l'),
                      right: $r('sys.float.ohos_id_corner_radius_default_l')
                    })
                  Row() {
                    Text(item.name)
                      .fontSize($r('sys.float.ohos_id_text_size_body1'))
                      .fontWeight('medium')
                      .width('45%')
                    Blank()
                      .width('5%')
                    Text(item.value)
                      .fontColor($r('sys.color.font_secondary'))
                      .fontSize($r('sys.float.ohos_id_text_size_body2'))
                      .textAlign(TextAlign.End)
                      .width('50%')
                  }
                  .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
                  .padding($r('sys.float.ohos_id_corner_radius_default_m'))
                  .width('100%')
                }
              })
            }
            .backgroundColor($r('sys.color.comp_background_list_card'))
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
            Text('系统信息')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: $r('sys.float.ohos_id_corner_radius_default_m')
              })
            Column() {
              Row() {
                Text('设备类型')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('35%')
                Blank()
                  .width('5%')
                Text(atomicService.getSystemInfoSync(this.stateArray).brand)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('60%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              ForEach(this.systemInfoArray, (item: SystemInfoElement) => {
                if (item.value) {
                  Divider()
                    .padding({
                      left: $r('sys.float.ohos_id_corner_radius_default_l'),
                      right: $r('sys.float.ohos_id_corner_radius_default_l')
                    })
                  Row() {
                    Text(item.name)
                      .fontSize($r('sys.float.ohos_id_text_size_body1'))
                      .fontWeight('medium')
                      .width('45%')
                    Blank()
                      .width('5%')
                    Text(item.value)
                      .fontColor($r('sys.color.font_secondary'))
                      .fontSize($r('sys.float.ohos_id_text_size_body2'))
                      .textAlign(TextAlign.End)
                      .width('50%')
                  }
                  .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
                  .padding($r('sys.float.ohos_id_corner_radius_default_m'))
                  .width('100%')
                }
              })
            }
            .backgroundColor($r('sys.color.comp_background_list_card'))
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
            Text('屏幕信息')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: $r('sys.float.ohos_id_corner_radius_default_m')
              })
            Column() {
              Row() {
                Text('id 号')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(display.getDefaultDisplaySync().id))
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('名称')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(display.getDefaultDisplaySync().name)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('是否启用')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(display.getDefaultDisplaySync().alive ? '是' : '否')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('状态')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(display.getDefaultDisplaySync().state === 0 ? '未知' :
                  display.getDefaultDisplaySync().state === 1 ? '关闭' :
                    display.getDefaultDisplaySync().state === 2 ? '开启' :
                      display.getDefaultDisplaySync().state === 3 ? '低点耗模式' :
                        display.getDefaultDisplaySync().state === 4 ? '睡眠模式' :
                          display.getDefaultDisplaySync().state === 5 ? 'VR 模式' :
                            display.getDefaultDisplaySync().state === 6 ? '开启，CPU 为挂起' :
                              'undefined'
                )
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('刷新率')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(display.getDefaultDisplaySync().refreshRate) + ' Hz')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('屏幕顺时针旋转角度')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(display.getDefaultDisplaySync().rotation === 0 ? '屏幕顺时针旋转 0°' :
                  display.getDefaultDisplaySync().rotation === 1 ? '屏幕顺时针旋转 90°' :
                    display.getDefaultDisplaySync().rotation === 2 ? '屏幕顺时针旋转 180°' :
                      display.getDefaultDisplaySync().rotation === 3 ? '屏幕顺时针旋转 270°' :
                        'undefined'
                )
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('屏幕宽度')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(display.getDefaultDisplaySync().width) + ' px')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('屏幕高度')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(display.getDefaultDisplaySync().height) + ' px')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('屏幕的物理像素密度')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(display.getDefaultDisplaySync().densityDPI) + ' px')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('屏幕当前显示的方向')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(display.getDefaultDisplaySync().orientation === 0 ? '竖屏' :
                  display.getDefaultDisplaySync().orientation === 1 ? '横屏' :
                    display.getDefaultDisplaySync().orientation === 2 ? '反向竖屏' :
                      display.getDefaultDisplaySync().orientation === 3 ? '反向横屏' :
                        'undefined'
                )
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('逻辑像素的密度')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(display.getDefaultDisplaySync().densityPixels))
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('显示字体的缩放因子')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(display.getDefaultDisplaySync().scaledDensity))
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('x 方向中每英寸屏幕的确切物理像素值')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(display.getDefaultDisplaySync().xDPI))
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('y 方向中每英寸屏幕的确切物理像素值')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(display.getDefaultDisplaySync().yDPI))
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('屏幕的可用区域宽度')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(display.getDefaultDisplaySync().availableWidth) + ' px')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('屏幕的可用区域高度')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(display.getDefaultDisplaySync().availableHeight) + ' px')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('设备是否可折叠')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(display.isFoldable() ? '是' : '否')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('是否正在截屏、投屏、录屏')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(display.isCaptured() ? '是' : '否')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')
            }
            .backgroundColor($r('sys.color.comp_background_list_card'))
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
            Text('电量信息')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: $r('sys.float.ohos_id_corner_radius_default_m')
              })
            Column() {
              Row() {
                Text('剩余电池电量百分比')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(batteryInfo.batterySOC))
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('电池的充电状态')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(
                  batteryInfo.chargingStatus === 0 ? '未知' :
                    batteryInfo.chargingStatus === 1 ? '使能' :
                      batteryInfo.chargingStatus === 2 ? '停止' :
                        batteryInfo.chargingStatus === 3 ? '充满' :
                          'undefined'
                )
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('电池的健康状态')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(
                  batteryInfo.healthStatus === 0 ? '未知' :
                    batteryInfo.healthStatus === 1 ? '正常' :
                      batteryInfo.healthStatus === 2 ? '过热' :
                        batteryInfo.healthStatus === 3 ? '过压' :
                          batteryInfo.healthStatus === 4 ? '低温' :
                            batteryInfo.healthStatus === 5 ? '僵死' :
                              'undefined'
                )
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('连接的充电器类型')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(
                  batteryInfo.pluggedType === 0 ? '未知' :
                    batteryInfo.pluggedType === 1 ? '交流' :
                      batteryInfo.pluggedType === 2 ? 'USB' :
                        batteryInfo.pluggedType === 3 ? '无线' :
                          'undefined'
                )
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('电池的电压')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(batteryInfo.voltage) + ' μV')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('电池的技术型号')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(batteryInfo.technology)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('电池的温度')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String((batteryInfo.batteryTemperature) / 10) + ' °C')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('是否支持电池或者电池是否在位')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(batteryInfo.isBatteryPresent ? '是' : '否')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('电池电量的等级')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(
                  batteryInfo.batteryCapacityLevel === 1 ? '满' :
                    batteryInfo.batteryCapacityLevel === 2 ? '高' :
                      batteryInfo.batteryCapacityLevel === 3 ? '正常' :
                        batteryInfo.batteryCapacityLevel === 4 ? '低' :
                          batteryInfo.batteryCapacityLevel === 5 ? '告警' :
                            batteryInfo.batteryCapacityLevel === 6 ? '极低' :
                              batteryInfo.batteryCapacityLevel === 7 ? '关机' :
                                'undefined'
                )
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('电池的电流')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(String(batteryInfo.nowCurrent) + ' mA')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')
            }
            .backgroundColor($r('sys.color.comp_background_list_card'))
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
            Text('电源管理信息')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: $r('sys.float.ohos_id_corner_radius_default_m')
              })
            Column() {
              Row() {
                Text('是否处于活动状态')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(power.isActive() ? '是' : '否')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('是否进入待机低功耗续航模式')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(power.isStandby() ? '是' : '否')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('电源模式')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(
                  power.getPowerMode() === 600 ? '标准' :
                    power.getPowerMode() === 601 ? '省电' :
                      power.getPowerMode() === 602 ? '性能' :
                        power.getPowerMode() === 603 ? '超级省电' :
                          'undefined'
                )
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')
            }
            .backgroundColor($r('sys.color.comp_background_list_card'))
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
            Text('热管理信息')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: $r('sys.float.ohos_id_corner_radius_default_m')
              })
            Column() {
              Row() {
                Text('热档位')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(
                  thermal.getLevel() === 0 ? '清凉' :
                    thermal.getLevel() === 1 ? '正常' :
                      thermal.getLevel() === 2 ? '温热' :
                        thermal.getLevel() === 3 ? '发热明显' :
                          thermal.getLevel() === 4 ? '发热严重' :
                            thermal.getLevel() === 5 ? '过热即将进入紧急状态' :
                              thermal.getLevel() === 6 ? '过热紧急状态' :
                                thermal.getLevel() === 7 ? '热逃生状态' :
                                  'undefined'
                )
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')
            }
            .backgroundColor($r('sys.color.comp_background_list_card'))
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
            Text('系统负载信息')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: $r('sys.float.ohos_id_corner_radius_default_m')
              })
            Column() {
              Row() {
                Text('系统负载融合档位')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(
                  this.systemLoadValue === 0 ? '温度、负载比较低，无高负载场景' :
                    this.systemLoadValue === 1 ? '温度、负载正常，但邻近中等状态' :
                      this.systemLoadValue === 2 ? '温度、负载有一项或多项稍高，或者当前处于高负载场景' :
                        this.systemLoadValue === 3 ? '发热明显或负载比较高，或处于负载温度中等但处于高负载场景' :
                          this.systemLoadValue === 4 ? '发热严重或者负载较重' :
                            this.systemLoadValue === 5 ?
                              '过热或负载过重，或者温度较高但处于高负载场景，即将进入紧急状态' :
                              this.systemLoadValue === 6 ?
                                '已经进入过热状态或负载极高紧急状态，或接近紧急状态但处于高负载场景' :
                                this.systemLoadValue === 7 ?
                                  '即将进入热逃生状态或当前负载已经不堪重负，或已经处于紧急状态且高负载状态' :
                                  'undefined'
                )
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')
            }
            .backgroundColor($r('sys.color.comp_background_list_card'))
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
            Text('辅助功能信息')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: $r('sys.float.ohos_id_corner_radius_default_m')
              })
            Column() {
              Row() {
                Text('辅助功能')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(accessibility.isOpenAccessibilitySync() ? '开启' : '关闭')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')

              Divider()
                .padding({
                  left: $r('sys.float.ohos_id_corner_radius_default_l'),
                  right: $r('sys.float.ohos_id_corner_radius_default_l')
                })
              Row() {
                Text('触摸浏览模式')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight('medium')
                  .width('45%')
                Blank()
                  .width('5%')
                Text(accessibility.isOpenTouchGuideSync() ? '开启' : '关闭')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('50%')
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .padding($r('sys.float.ohos_id_corner_radius_default_m'))
              .width('100%')
            }
            .backgroundColor($r('sys.color.comp_background_list_card'))
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
    .title('调试')
    .onShown(() => {
      systemLoad.getLevel().then((res: systemLoad.SystemLoadLevel) => {
        this.systemLoadValue = res
      })
    })
  }
}