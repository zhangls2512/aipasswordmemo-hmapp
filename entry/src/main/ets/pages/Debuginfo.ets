import {
  abilityManager,
  appManager,
  bundleManager,
  common,
  screenLockFileManager,
  shortcutManager
} from '@kit.AbilityKit'
import { accessibility } from '@kit.AccessibilityKit'
import { process } from '@kit.ArkTS'
import { display, floatingBall, PiPWindow, promptAction, uiAppearance, window } from '@kit.ArkUI'
import { deviceInfo } from '@kit.BasicServicesKit'
import { Environment, storageStatistics } from '@kit.CoreFileKit'
import { cryptoFramework } from '@kit.CryptoArchitectureKit'
import { businessRiskIntelligentDetection, safetyDetect } from '@kit.DeviceSecurityKit'
import { i18n } from '@kit.LocalizationKit'
import { fido2, ifaa, soter } from '@kit.OnlineAuthenticationKit'

interface RootItem {
  type: string,
  nvArray?: NvItem[],
  nvsArray?: NvItem[][]
}

interface NvItem {
  name: string
  value: string
}

@Builder
export function DebuginfoBuilder() {
  Debuginfo()
}

@ComponentV2
struct Debuginfo {
  @Local rootArray: RootItem[] = []

  pushPrimitiveType(type: string, name: string, value: string | boolean | number | object | undefined) {
    const index = this.rootArray.findIndex(item => item.type === type)
    let outValue = ''
    if (typeof (value) !== 'object') {
      outValue = String(value)
    }
    if (typeof (value) === 'object') {
      outValue = JSON.stringify(value)
    }
    if (index !== -1) {
      this.rootArray[index].nvArray?.push({
        name: name,
        value: outValue
      })
    }
    if (index === -1) {
      this.rootArray.push({
        type: type,
        nvArray: [{
          name: name,
          value: outValue
        }]
      })
    }
  }

  pushObject(type: string, result: object) {
    const index = this.rootArray.findIndex(item => item.type === type)
    if (index !== -1) {
      Object.keys(result).forEach((key) => {
        const value = result[key] as string | boolean | number | object
        if (typeof (value) !== 'object') {
          this.rootArray[index].nvArray?.push({
            name: key,
            value: String(value)
          })
        }
        if (typeof (value) === 'object' && value) {
          this.rootArray[index].nvArray?.push({
            name: key,
            value: JSON.stringify(value)
          })
        }
      })
    }
    if (index === -1) {
      const array: NvItem[] = []
      Object.keys(result).forEach((key) => {
        const value = result[key] as string | boolean | number | object
        if (typeof (value) !== 'object') {
          array.push({
            name: key,
            value: String(value)
          })
        }
        if (typeof (value) === 'object' && value) {
          array.push({
            name: key,
            value: JSON.stringify(value)
          })
        }
      })
      this.rootArray.push({
        type: type,
        nvArray: array
      })
    }
  }

  pushArray(type: string, result: object[]) {
    const nvsArray: NvItem[][] = []
    result.forEach(item => {
      const array: NvItem[] = []
      Object.keys(item).forEach((key) => {
        const value = item[key] as string | boolean | number | object
        if (typeof (value) !== 'object') {
          array.push({
            name: key,
            value: String(value)
          })
        }
        if (typeof (value) === 'object' && value) {
          array.push({
            name: key,
            value: JSON.stringify(value)
          })
        }
      })
      nvsArray.push(array)
    })
    this.rootArray.push({
      type: type,
      nvsArray: nvsArray
    })
  }

  build() {
    NavDestination() {
      List() {
        ForEach(this.rootArray, (item: RootItem) => {
          ListItem() {
            Column() {
              Text(item.type)
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .fontWeight('medium')
                .enableAutoSpacing(true)
                .margin({
                  left: 12,
                  right: 12
                })
              if (item.nvArray) {
                Column() {
                  ForEach(item.nvArray, (item: NvItem, index) => {
                    if (item.value) {
                      if (index !== 0) {
                        Divider()
                          .padding({
                            left: 12,
                            right: 12
                          })
                      }
                      Row() {
                        Text(item.name)
                          .fontWeight('medium')
                          .enableAutoSpacing(true)
                          .width('45%')
                        Blank()
                          .width('5%')
                        Text(item.value)
                          .fontColor($r('sys.color.font_secondary'))
                          .fontSize($r('sys.float.ohos_id_text_size_body2'))
                          .textAlign(TextAlign.End)
                          .width('50%')
                      }
                      .borderRadius(12)
                      .padding(12)
                      .width('100%')
                    }
                  })
                }
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                .margin({
                  top: 6
                })
                .padding($r('sys.float.ohos_id_corner_radius_mark'))
              }
              if (item.nvsArray) {
                ForEach(item.nvsArray, (inItem: NvItem[]) => {
                  Column() {
                    ForEach(inItem, (ininItem: NvItem, index) => {
                      if (ininItem.value) {
                        if (index !== 0) {
                          Divider()
                            .padding({
                              left: 12,
                              right: 12
                            })
                        }
                        Row() {
                          Text(ininItem.name)
                            .fontWeight('medium')
                            .width('45%')
                          Blank()
                            .width('5%')
                          Text(ininItem.value)
                            .fontColor($r('sys.color.font_secondary'))
                            .fontSize($r('sys.float.ohos_id_text_size_body2'))
                            .textAlign(TextAlign.End)
                            .width('50%')
                        }
                        .borderRadius(12)
                        .padding(12)
                        .width('100%')
                      }
                    })
                  }
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                  .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                  .margin({
                    top: 6
                  })
                  .padding($r('sys.float.ohos_id_corner_radius_mark'))
                })
              }
            }
            .alignItems(HorizontalAlign.Start)
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
        })
      }
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title('调试信息')
    .onAppear(async () => {
      const bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT |
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION |
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_HAP_MODULE |
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_SIGNATURE_INFO
      const bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleFlags)
      this.pushObject('应用信息', bundleInfo.appInfo)
      this.pushPrimitiveType('应用信息', '锁屏下敏感数据访问权限', screenLockFileManager.queryAppKeyState())
      const isRunningInStabilityTest = await appManager.isRunningInStabilityTest()
      this.pushPrimitiveType('应用信息', '是否处于稳定性测试场景', isRunningInStabilityTest)
      const isRamConstrainedDevice = await appManager.isRamConstrainedDevice()
      this.pushPrimitiveType('应用信息', '是否为ram受限设备', isRamConstrainedDevice)
      const appMemorySize = await appManager.getAppMemorySize()
      this.pushPrimitiveType('应用信息', '可以使用的内存的值', appMemorySize)
      this.pushObject('应用包信息', bundleInfo)
      this.pushArray('Hap Module信息', bundleInfo.hapModulesInfo)
      this.pushObject('签名信息', bundleInfo.signatureInfo)
      this.pushObject('应用启动Want', bundleManager.getLaunchWant())
      const shortcutInfo = await shortcutManager.getAllShortcutInfoForSelf()
      this.pushArray('快捷方式信息', shortcutInfo)
      const abilityRunningInfos = await abilityManager.getAbilityRunningInfos()
      this.pushArray('Ability运行信息', abilityRunningInfos)
      const appRunningProcessInformation = await appManager.getRunningProcessInformation()
      this.pushArray('应用运行中进程信息', appRunningProcessInformation)
      this.pushPrimitiveType('辅助应用信息', '系统内是否存在已开启的辅助应用',
        accessibility.isOpenAccessibilitySync())
      this.pushPrimitiveType('辅助应用信息', '是否开启了触摸浏览模式', accessibility.isOpenTouchGuideSync())
      this.pushPrimitiveType('辅助应用信息', '是否开启了屏幕朗读模式', accessibility.isScreenReaderOpenSync())
      this.pushPrimitiveType('辅助应用信息', '触摸浏览功能下的单击/双击操作模式', accessibility.getTouchModeSync())
      const accessibilityExtensionList = await accessibility.getAccessibilityExtensionListSync('all', 'install')
      this.pushArray('辅助应用列表', accessibilityExtensionList)
      this.pushPrimitiveType('进程信息', '是否已被隔离', process.isIsolatedProcess())
      this.pushPrimitiveType('进程信息', '运行环境是否为64位', process.is64Bit())
      this.pushPrimitiveType('进程信息', '系统启动到进程启动的实时时间', process.getStartRealtime())
      this.pushPrimitiveType('进程信息', '进程启动到当前时间的CPU时间', process.getPastCpuTime())
      const uiContext = this.getUIContext()
      this.pushPrimitiveType('UIContext信息', '是否有效', uiContext.isAvailable())
      this.pushObject('UIContext信息', uiContext.getHostContext() as common.UIAbilityContext)
      this.pushPrimitiveType('UIContext信息', '虚拟键盘弹出时页面的避让模式', uiContext.getKeyboardAvoidMode())
      this.pushPrimitiveType('UIContext信息', '所在窗口的名称', uiContext.getWindowName())
      this.pushPrimitiveType('UIContext信息', '所在窗口的宽度断点枚举值', uiContext.getWindowWidthBreakpoint())
      this.pushPrimitiveType('UIContext信息', '所在窗口的高度断点枚举值', uiContext.getWindowHeightBreakpoint())
      this.pushPrimitiveType('UIContext信息', '是否跟随系统字体倍率', uiContext.isFollowingSystemFontScale())
      this.pushPrimitiveType('UIContext信息', '最大字体倍率', uiContext.getMaxFontScale())
      this.pushPrimitiveType('UIContext信息', '像素取整模式', uiContext.getPixelRoundMode())
      this.pushPrimitiveType('系统外观信息', '深色模式', uiAppearance.getDarkMode())
      this.pushPrimitiveType('系统外观信息', '字体大小缩放比例', uiAppearance.getFontScale())
      this.pushPrimitiveType('系统外观信息', '字体粗细缩放比例', uiAppearance.getFontWeightScale())
      this.pushPrimitiveType('画中画信息', '当前系统是否支持画中画功能', PiPWindow.isPiPEnabled())
      this.pushPrimitiveType('闪控球信息', '当前设备是否支持闪控球功能', floatingBall.isFloatingBallEnabled())
      const lastWindow = await window.getLastWindow(uiContext.getHostContext() as common.UIAbilityContext)
      this.pushObject('窗口信息', lastWindow.getWindowProperties())
      this.pushObject('窗口信息', lastWindow.getWindowDensityInfo())
      this.pushPrimitiveType('窗口信息', '在屏幕上的真实显示区域', lastWindow.getGlobalRect())
      try {
        this.pushPrimitiveType('窗口信息', '是否可以获取到避让区', lastWindow.isSystemAvoidAreaEnabled())
      } catch {
        promptAction.openToast({
          message: '发生错误'
        })
      }
      this.pushPrimitiveType('窗口信息', '避让区 (系统默认)',
        lastWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM))
      this.pushPrimitiveType('窗口信息', '避让区 (刘海屏)',
        lastWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_CUTOUT))
      this.pushPrimitiveType('窗口信息', '避让区 (手势)',
        lastWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM_GESTURE))
      this.pushPrimitiveType('窗口信息', '避让区 (软键盘)',
        lastWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_KEYBOARD))
      this.pushPrimitiveType('窗口信息', '避让区 (底部导航)',
        lastWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR))
      this.pushPrimitiveType('窗口信息', '是否开启沉浸式布局', lastWindow.getImmersiveModeEnabledState())
      this.pushPrimitiveType('窗口信息', '是否处于沉浸式布局状态', lastWindow.isImmersiveLayout())
      this.pushObject('窗口信息', lastWindow.getWindowSystemBarProperties())
      this.pushObject('窗口信息', lastWindow.getStatusBarProperty())
      this.pushPrimitiveType('窗口信息', '显示方向', lastWindow.getPreferredOrientation())
      this.pushPrimitiveType('窗口信息', '是否已显示', lastWindow.isWindowShowing())
      this.pushPrimitiveType('窗口信息', '是否支持广色域模式', lastWindow.isWindowSupportWideGamut())
      this.pushPrimitiveType('窗口信息', '色域模式', lastWindow.getWindowColorSpace())
      this.pushObject('窗口信息', lastWindow.getWindowLimits())
      if (deviceInfo.deviceType !== 'phone') {
        this.pushPrimitiveType('窗口信息', '标题栏是否可见', lastWindow.getWindowDecorVisible())
        this.pushObject('窗口信息', lastWindow.getDecorButtonStyle())
        this.pushPrimitiveType('窗口信息', '标题栏高度', lastWindow.getWindowDecorHeight())
        try {
          this.pushPrimitiveType('窗口信息', '子窗或悬浮窗的圆角半径值', lastWindow.getWindowCornerRadius())
        } catch {
          promptAction.openToast({
            message: '发生错误'
          })
        }
      }
      this.pushPrimitiveType('窗口信息', '标题栏上的最小化、最大化、关闭按钮矩形区域', lastWindow.getTitleButtonRect())
      this.pushPrimitiveType('窗口信息', '模式', lastWindow.getWindowStatus())
      this.pushPrimitiveType('窗口信息', '是否已获焦', lastWindow.isFocused())
      try {
        this.pushPrimitiveType('窗口信息', '是否启用返回手势功能', lastWindow.isGestureBackEnabled())
      } catch {
        promptAction.openToast({
          message: '发生错误'
        })
      }
      this.pushPrimitiveType('窗口信息', '是否为激活态', lastWindow.isWindowHighlighted())
      const allDisplayPhysicalResolution = await display.getAllDisplayPhysicalResolution()
      this.pushArray('当前设备支持的所有显示模式及其对应的物理屏幕分辨率信息', allDisplayPhysicalResolution)
      const allDisplays = await display.getAllDisplays()
      this.pushArray('屏幕列表', allDisplays)
      this.pushPrimitiveType('屏幕信息', '设备是否可折叠', display.isFoldable())
      this.pushPrimitiveType('屏幕信息', '折叠状态', display.getFoldStatus())
      this.pushPrimitiveType('屏幕信息', '显示模式', display.getFoldDisplayMode())
      try {
        this.pushObject('屏幕信息', display.getCurrentFoldCreaseRegion())
      } catch {
        promptAction.openToast({
          message: '发生错误'
        })
      }
      this.pushPrimitiveType('屏幕信息', '设备是否正在截屏、投屏、录屏', display.isCaptured())
      if (deviceInfo.deviceType === '2in1') {
        this.pushPrimitiveType('环境目录信息', '当前用户预授权下载目录的沙箱路径', Environment.getUserDownloadDir())
        this.pushPrimitiveType('环境目录信息', '当前用户预授权桌面目录的沙箱路径', Environment.getUserDesktopDir())
        this.pushPrimitiveType('环境目录信息', '当前用户预授权文档目录的沙箱路径', Environment.getUserDocumentDir())
      }
      const currentBundleStats = await storageStatistics.getCurrentBundleStats()
      this.pushObject('应用空间信息', currentBundleStats)
      this.pushPrimitiveType('内置存储空间信息', '总', storageStatistics.getTotalSizeSync())
      this.pushPrimitiveType('内置存储空间信息', '可用', storageStatistics.getFreeSizeSync())
      this.pushPrimitiveType('国际化信息', '系统支持的语言列表', i18n.System.getSystemLanguages())
      this.pushPrimitiveType('国际化信息', '系统当前设置的语言', i18n.System.getSystemLanguage())
      this.pushPrimitiveType('国际化信息', '系统当前设置的国家地区', i18n.System.getSystemRegion())
      this.pushPrimitiveType('国际化信息', '系统当前设置的区域对象', i18n.System.getSystemLocaleInstance())
      this.pushPrimitiveType('国际化信息', '系统时制是否为24小时制', i18n.System.is24HourClock())
      this.pushPrimitiveType('国际化信息', '系统偏好语言列表', i18n.System.getPreferredLanguageList())
      this.pushPrimitiveType('国际化信息', '系统偏好语言列表中的第一个语言', i18n.System.getFirstPreferredLanguage())
      this.pushPrimitiveType('国际化信息', '应用偏好语言', i18n.System.getAppPreferredLanguage())
      this.pushPrimitiveType('国际化信息', '系统是否使用本地数字', i18n.System.getUsingLocalDigit())
      this.pushPrimitiveType('国际化信息', '系统设置的温度单位', i18n.System.getTemperatureType())
      this.pushPrimitiveType('国际化信息', '系统设置的周起始日', i18n.System.getFirstDayOfWeek())
      try {
        const sysIntegrityOnLocal = await safetyDetect.checkSysIntegrityOnLocal()
        this.pushPrimitiveType('设备安全信息', '系统完整性的本地检测结果', sysIntegrityOnLocal)
      } catch {
        promptAction.openToast({
          message: '发生错误'
        })
      }
      const random = cryptoFramework.createRandom()
      try {
        const fraudRisk = await businessRiskIntelligentDetection.detectFraudRisk({
          nonce: random.generateRandomSync(24).data,
          algorithm: businessRiskIntelligentDetection.SigningAlgorithm.ES256,
          version: 2
        })
        this.pushPrimitiveType('设备安全信息', '涉诈行为风险', fraudRisk)
        const simulatedClickRisk = await businessRiskIntelligentDetection.detectSimulatedClickRisk({})
        this.pushPrimitiveType('设备安全信息', '自动化点击、设备墙等作弊行为检测结果', simulatedClickRisk)
      } catch {
        promptAction.openToast({
          message: '发生错误'
        })
      }
      try {
        this.pushPrimitiveType('在线认证服务信息', 'IFAA免密认证接口的版本号', ifaa.getVersionSync())
        this.pushPrimitiveType('在线认证服务信息', 'IFAA免密认证的协议版本号', ifaa.getProtocolVersionSync())
        this.pushPrimitiveType('在线认证服务信息', 'IFAA免密认证支持的证书格式', ifaa.getSupportedCertTypesSync())
        this.pushPrimitiveType('在线认证服务信息', 'SOTER免密认证API接口的版本号', soter.getVersionSync())
        const fido2ClientCapabilities = await fido2.getClientCapabilities(uiContext.getHostContext())
        this.pushPrimitiveType('在线认证服务信息', '当前设备/版本支持的认证能力列表', fido2ClientCapabilities)
        const fido2PlatformAuthenticators = await fido2.getPlatformAuthenticators(uiContext.getHostContext())
        this.pushPrimitiveType('在线认证服务信息', '当前支持的平台认证器能力列表（人脸、指纹、PIN码）',
          fido2PlatformAuthenticators)
      } catch {
        promptAction.openToast({
          message: '发生错误'
        })
      }
    })
  }
}