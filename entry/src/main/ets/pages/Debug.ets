import { abilityManager, appManager, appRecovery, bundleManager, common } from '@kit.AbilityKit'
import { accessibility } from '@kit.AccessibilityKit'
import { preferences } from '@kit.ArkData'
import { process } from '@kit.ArkTS'
import { display, promptAction, window } from '@kit.ArkUI'
import { batteryInfo, deviceInfo, power, systemLoad, thermal } from '@kit.BasicServicesKit'
import { wifiManager } from '@kit.ConnectivityKit'
import { storageStatistics } from '@kit.CoreFileKit'
import { connection } from '@kit.NetworkKit'
import { atomicService } from '@kit.ScenarioFusionKit'
import { data } from '@kit.TelephonyKit'

interface Item {
  name: string
  value: string
}

function decimalToDottedIP(decimalIP: number) {
  return (decimalIP >>> 24) + '.' + (decimalIP >> 16 & 0xFF) + '.' + (decimalIP >> 8 & 0xFF) + '.' + (decimalIP & 0xFF)
}

@Builder
export function DebugBuilder() {
  Debug()
}

@ComponentV2
struct Debug {
  @Local globalErrorShowTypeIndex: number = 0
  @Local globalErrorShowTypeValue: string = 'Toast'
  @Local autoUploadErrorLog: boolean = true
  @Local showMemoryLevelChange: boolean = false
  @Local lowBatteryCapacityLevelIndex: number = 3
  @Local lowBatteryCapacityLevelValue: string = '低'
  @Local showNetAvailableStatusChange: boolean = false
  @Local showNetBlockStatusChange: boolean = false
  @Local showNetLost: boolean = false
  @Local showNetCapabilitiesChange: boolean = false
  @Local showNetQosChange: boolean = false
  @Local showNetSceneChange: boolean = false
  @Local autoReportHighLatency: boolean = true
  @Local highLatencyThreshold: string = '200'
  @Local allService: boolean = true
  @Local windowInfoArray: Item[] = []
  @Local systemLoadValue: number = -1
  context = getContext(this) as common.UIAbilityContext
  pageInfos = new NavPathStack()
  debugSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'debugSetting'
  })
  commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'commonSetting'
  })
  applicationInfoArray: Item[] = [
    {
      name: '名称',
      value: this.context.applicationInfo.name
    },
    {
      name: '是否可以使用',
      value: this.context.applicationInfo.enabled ? '是' : '否'
    },
    {
      name: '进程名称',
      value: this.context.applicationInfo.process
    },
    {
      name: '安装目录',
      value: this.context.applicationInfo.codePath
    },
    {
      name: '是否可以被移除',
      value: this.context.applicationInfo.removable ? '是' : '否'
    },
    {
      name: 'accessTokenId',
      value: String(this.context.applicationInfo.accessTokenId)
    },
    {
      name: 'uid',
      value: String(this.context.applicationInfo.uid)
    },
    {
      name: '签名证书分发类型',
      value: this.context.applicationInfo.appDistributionType
    },
    {
      name: '签名证书文件类型',
      value: this.context.applicationInfo.appProvisionType
    },
    {
      name: '是否为系统应用',
      value: this.context.applicationInfo.systemApp ? '是' : '否'
    },
    {
      name: '包类型',
      value: this.context.applicationInfo.bundleType === 0 ? '应用' :
        this.context.applicationInfo.bundleType === 1 ? '元服务' :
          'undefined'
    },
    {
      name: '是否处于调试模式',
      value: this.context.applicationInfo.debug ? '是' : '否'
    },
    {
      name: '数据是否可被删除',
      value: this.context.applicationInfo.dataUnclearable ? '是' : '否'
    },
    {
      name: '多开最大个数',
      value: String(this.context.applicationInfo.multiAppMode.maxCount)
    },
    {
      name: '包分身索引标识',
      value: String(this.context.applicationInfo.appIndex)
    },
    {
      name: '安装来源',
      value: this.context.applicationInfo.installSource
    },
    {
      name: '打包时使用的 SDK 的发布类型',
      value: this.context.applicationInfo.releaseType
    },
    {
      name: '是否启用端云文件同步能力',
      value: this.context.applicationInfo.cloudFileSyncEnabled ? '是' : '否'
    },
    {
      name: '缓存目录',
      value: this.context.cacheDir
    },
    {
      name: '临时目录',
      value: this.context.tempDir
    },
    {
      name: '资源目录',
      value: this.context.resourceDir
    },
    {
      name: '文件目录',
      value: this.context.filesDir
    },
    {
      name: '数据库目录',
      value: this.context.databaseDir
    },
    {
      name: 'preferences 目录',
      value: this.context.preferencesDir
    },
    {
      name: '安装包目录',
      value: this.context.bundleCodeDir
    },
    {
      name: '分布式文件目录',
      value: this.context.databaseDir
    },
    {
      name: '云文件目录',
      value: this.context.cloudFileDir
    },
    {
      name: '文件分区',
      value: this.context.area === 0 ? 'EL1' :
        this.context.area === 1 ? 'EL2' :
          this.context.area === 2 ? 'EL3' :
            this.context.area === 3 ? 'EL4' :
              this.context.area === 4 ? 'EL5' :
                'undefined'
    },
    {
      name: '是否是 Stage 模型',
      value: this.context.stageMode ? '是' : '否'
    },
    {
      name: '当前语言',
      value: String(this.context.config.language)
    },
    {
      name: '深浅色模式',
      value: this.context.config.colorMode === -1 ? '未设置' :
        this.context.config.colorMode === 0 ? '深色' :
          this.context.config.colorMode === 1 ? '浅色' :
            'undefined'
    },
    {
      name: '屏幕方向',
      value: this.context.config.direction === -1 ? '未设置' :
        this.context.config.direction === 0 ? '垂直' :
          this.context.config.direction === 1 ? '水平' :
            'undefined'
    },
    {
      name: '屏幕像素密度',
      value: this.context.config.screenDensity === 0 ? '未设置' :
        this.context.config.screenDensity === 120 ? 'SDPI' :
          this.context.config.screenDensity === 160 ? 'MDPI' :
            this.context.config.screenDensity === 240 ? 'LDPI' :
              this.context.config.screenDensity === 320 ? 'XLDPI' :
                this.context.config.screenDensity === 480 ? 'XXLDPI' :
                  this.context.config.screenDensity === 640 ? 'XXXLDPI' :
                    'undefined'
    },
    {
      name: '所在物理屏幕 ID',
      value: String(this.context.config.displayId)
    },
    {
      name: '指针类型设备 (如键鼠、触控板等) 是否已连接',
      value: this.context.config.hasPointerDevice ? '是' : '否'
    },
    {
      name: '字体大小缩放比例',
      value: String(this.context.config.fontSizeScale)
    },
    {
      name: '字体粗细缩放比例',
      value: String(this.context.config.fontWeightScale)
    },
    {
      name: '移动设备国家代码',
      value: String(this.context.config.mcc)
    },
    {
      name: '移动设备网络代码',
      value: String(this.context.config.mnc)
    }
  ]
  hapModuleInfoArray: Item[] = [
    {
      name: '名称',
      value: this.context.currentHapModuleInfo.name
    },
    {
      name: '是否支持免安装',
      value: this.context.currentHapModuleInfo.installationFree ? '是' : '否'
    },
    {
      name: '类型',
      value: this.context.currentHapModuleInfo.type === 1 ? '主模块' :
        this.context.currentHapModuleInfo.type === 2 ? '动态特性模块' :
          this.context.currentHapModuleInfo.type === 3 ? '动态共享库模块' :
            'undefined'
    },
    {
      name: '安装路径',
      value: this.context.currentHapModuleInfo.codePath
    }
  ]
  abilityInfoArray: Item[] = [
    {
      name: '应用 Bundle 名称',
      value: this.context.abilityInfo.bundleName
    },
    {
      name: '所属 HAP 名称',
      value: this.context.abilityInfo.moduleName
    },
    {
      name: '名称',
      value: this.context.abilityInfo.name
    },
    {
      name: '是否可以被其他应用调用',
      value: this.context.abilityInfo.exported ? '是' : '否'
    },
    {
      name: '显示模式',
      value: this.context.abilityInfo.orientation === 0 ? '未定义，由系统判定' :
        this.context.abilityInfo.orientation === 1 ? '横屏' :
          this.context.abilityInfo.orientation === 2 ? '竖屏' :
            this.context.abilityInfo.orientation === 3 ? '跟随上一个' :
              this.context.abilityInfo.orientation === 4 ? '反向横屏' :
                this.context.abilityInfo.orientation === 5 ? '反向竖屏' :
                  this.context.abilityInfo.orientation === 6 ? '传感器自动旋转' :
                    this.context.abilityInfo.orientation === 7 ? '传感器自动横向旋转' :
                      this.context.abilityInfo.orientation === 8 ? '传感器自动竖向旋转' :
                        this.context.abilityInfo.orientation === 9 ? '受开关控制的自动旋转' :
                          this.context.abilityInfo.orientation === 10 ? '受开关控制的自动横向旋转' :
                            this.context.abilityInfo.orientation === 11 ? '受开关控制的自动竖向旋转' :
                              this.context.abilityInfo.orientation === 12 ? '锁定' :
                                this.context.abilityInfo.orientation === 13 ? '受开关控制和由系统判定的自动旋转模式' :
                                  this.context.abilityInfo.orientation === 14 ? '跟随桌面旋转' :
                                    'undefined'
    },
    {
      name: '启动模式',
      value: this.context.abilityInfo.launchType === 0 ? '单实例' :
        this.context.abilityInfo.launchType === 1 ? '普通多实例' :
          this.context.abilityInfo.launchType === 2 ? '该 Ability 内部根据业务自己指定多实例' :
            'undefined'
    },
    {
      name: '是否可用',
      value: this.context.abilityInfo.enabled ? '是' : '否'
    },
    {
      name: '自由窗口状态下窗口的最大宽高比',
      value: String(this.context.abilityInfo.windowSize.maxWindowRatio)
    },
    {
      name: '自由窗口状态下窗口的最小宽高比',
      value: String(this.context.abilityInfo.windowSize.minWindowRatio)
    },
    {
      name: '自由窗口状态下窗口的最大宽度',
      value: String(this.context.abilityInfo.windowSize.maxWindowWidth) + ' vp'
    },
    {
      name: '自由窗口状态下窗口的最小宽度',
      value: String(this.context.abilityInfo.windowSize.minWindowWidth) + ' vp'
    },
    {
      name: '自由窗口状态下窗口的最大高度',
      value: String(this.context.abilityInfo.windowSize.maxWindowHeight) + ' vp'
    },
    {
      name: '自由窗口状态下窗口的最小高度',
      value: String(this.context.abilityInfo.windowSize.minWindowHeight) + ' vp'
    },
    {
      name: '是否可以在 dock 区域隐藏图标',
      value: this.context.abilityInfo.excludeFromDock ? '是' : '否'
    }
  ]
  bundleInfoArray: Item[] = []
  deviceInfoArray: Item[] = [
    { name: '设备类型', value: deviceInfo.deviceType },
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
    { name: '系统发布类型', value: deviceInfo.osReleaseType },
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
  stateArray: atomicService.SystemInfoType[] = [
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
  systemInfoArray: Item[] = [
    { name: '设备品牌名称', value: String(atomicService.getSystemInfoSync(this.stateArray).brand) },
    { name: '设备类型', value: String(atomicService.getSystemInfoSync(this.stateArray).deviceModel) },
    { name: '屏幕宽度', value: String(atomicService.getSystemInfoSync(this.stateArray).screenWidth) + ' px' },
    { name: '屏幕高度', value: String(atomicService.getSystemInfoSync(this.stateArray).screenHeight) + ' px' },
    { name: '系统语言', value: String(atomicService.getSystemInfoSync(this.stateArray).language) },
    { name: '系统版本', value: String(atomicService.getSystemInfoSync(this.stateArray).osFullName) },
    { name: '显示设备逻辑像素密度', value: String(atomicService.getSystemInfoSync(this.stateArray).fontSizeSetting) },
    { name: '系统软件 API 版本', value: String(atomicService.getSystemInfoSync(this.stateArray).sdkApiVersion) },
    {
      name: '蓝牙系统开关',
      value: atomicService.getSystemInfoSync(this.stateArray).bluetoothEnabled ? '开启' : '关闭'
    },
    {
      name: '地理位置系统开关',
      value: atomicService.getSystemInfoSync(this.stateArray).locationEnabled ? '开启' : '关闭'
    },
    { name: 'Wi-Fi 系统开关', value: atomicService.getSystemInfoSync(this.stateArray).wifiEnabled ? '开启' : '关闭' },
    { name: '设备方向', value: String(atomicService.getSystemInfoSync(this.stateArray).deviceOrientation) },
    {
      name: '系统主题',
      value: atomicService.getSystemInfoSync(this.stateArray).theme === -1 ? '未设置' :
        atomicService.getSystemInfoSync(this.stateArray).theme === 0 ? '浅色模式' :
          atomicService.getSystemInfoSync(this.stateArray).theme === 1 ? '深色模式' :
            'undefined'
    }
  ]
  displayInfoArray: Item[] = [
    { name: 'id 号', value: String(display.getDefaultDisplaySync().id) },
    { name: '名称', value: display.getDefaultDisplaySync().name },
    { name: '是否启用', value: display.getDefaultDisplaySync().alive ? '是' : '否' },
    {
      name: '状态',
      value: display.getDefaultDisplaySync().state === 0 ? '未知' :
        display.getDefaultDisplaySync().state === 1 ? '关闭' :
          display.getDefaultDisplaySync().state === 2 ? '开启' :
            display.getDefaultDisplaySync().state === 3 ? '低点耗模式' :
              display.getDefaultDisplaySync().state === 4 ? '睡眠模式' :
                display.getDefaultDisplaySync().state === 5 ? 'VR 模式' :
                  display.getDefaultDisplaySync().state === 6 ? '开启，CPU 为挂起' :
                    'undefined'
    },
    { name: '刷新率', value: String(display.getDefaultDisplaySync().refreshRate) + ' Hz' },
    {
      name: '顺时针旋转角度',
      value: display.getDefaultDisplaySync().rotation === 0 ? '0°' :
        display.getDefaultDisplaySync().rotation === 1 ? '90°' :
          display.getDefaultDisplaySync().rotation === 2 ? '180°' :
            display.getDefaultDisplaySync().rotation === 3 ? '270°' :
              'undefined'
    },
    { name: '宽度', value: String(display.getDefaultDisplaySync().width) + ' px' },
    { name: '高度', value: String(display.getDefaultDisplaySync().height) + ' px' },
    { name: '物理像素密度', value: String(display.getDefaultDisplaySync().densityDPI) + ' px' },
    {
      name: '显示方向',
      value: display.getDefaultDisplaySync().orientation === 0 ? '竖屏' :
        display.getDefaultDisplaySync().orientation === 1 ? '横屏' :
          display.getDefaultDisplaySync().orientation === 2 ? '反向竖屏' :
            display.getDefaultDisplaySync().orientation === 3 ? '反向横屏' :
              'undefined'
    },
    { name: '逻辑像素密度', value: String(display.getDefaultDisplaySync().densityPixels) },
    { name: '显示字体缩放因子', value: String(display.getDefaultDisplaySync().scaledDensity) },
    { name: 'x 方向中每英寸屏幕的确切物理像素值', value: String(display.getDefaultDisplaySync().xDPI) },
    { name: 'y 方向中每英寸屏幕的确切物理像素值', value: String(display.getDefaultDisplaySync().yDPI) },
    { name: '可用区域宽度', value: String(display.getDefaultDisplaySync().availableWidth) + ' px' },
    { name: '可用区域高度', value: String(display.getDefaultDisplaySync().availableHeight) + ' px' },
    { name: '设备是否可折叠', value: display.isFoldable() ? '是' : '否' },
    { name: '是否正在截屏、投屏、录屏', value: display.isCaptured() ? '是' : '否' }
  ]
  batteryInfoArray: Item[] = [
    { name: '剩余电池电量百分比', value: String(batteryInfo.batterySOC) + '%' },
    {
      name: '电池充电状态',
      value: batteryInfo.chargingStatus === 0 ? '未知' :
        batteryInfo.chargingStatus === 1 ? '使能' :
          batteryInfo.chargingStatus === 2 ? '停止' :
            batteryInfo.chargingStatus === 3 ? '充满' :
              'undefined'
    },
    {
      name: '电池健康状态',
      value: batteryInfo.healthStatus === 0 ? '未知' :
        batteryInfo.healthStatus === 1 ? '正常' :
          batteryInfo.healthStatus === 2 ? '过热' :
            batteryInfo.healthStatus === 3 ? '过压' :
              batteryInfo.healthStatus === 4 ? '低温' :
                batteryInfo.healthStatus === 5 ? '僵死' :
                  'undefined'
    },
    {
      name: '连接的充电器类型',
      value: batteryInfo.pluggedType === 0 ? '未知' :
        batteryInfo.pluggedType === 1 ? '交流' :
          batteryInfo.pluggedType === 2 ? 'USB' :
            batteryInfo.pluggedType === 3 ? '无线' :
              'undefined'
    },
    { name: '电池电压', value: String(batteryInfo.voltage) + ' μV' },
    { name: '电池技术型号', value: batteryInfo.technology },
    { name: '电池温度', value: String((batteryInfo.batteryTemperature) / 10) + ' °C' },
    { name: '是否支持电池或者电池是否在位', value: batteryInfo.isBatteryPresent ? '是' : '否' },
    {
      name: '电池电量等级',
      value: batteryInfo.batteryCapacityLevel === 1 ? '满' :
        batteryInfo.batteryCapacityLevel === 2 ? '高' :
          batteryInfo.batteryCapacityLevel === 3 ? '正常' :
            batteryInfo.batteryCapacityLevel === 4 ? '低' :
              batteryInfo.batteryCapacityLevel === 5 ? '告警' :
                batteryInfo.batteryCapacityLevel === 6 ? '极低' :
                  batteryInfo.batteryCapacityLevel === 7 ? '关机' :
                    'undefined'
    },
    { name: '电池电流', value: String(batteryInfo.nowCurrent) + ' mA' }
  ]
  networkInfoArray: Item[] = [
    { name: '数据网络句柄', value: String(connection.getDefaultNetSync().netId) },
    { name: '当前网络上的数据流量使用是否被计量', value: connection.isDefaultNetMeteredSync() ? '是' : '否' },
    { name: '默认数据网络是否被激活', value: connection.hasDefaultNetSync() ? '是' : '否' },
    { name: 'WLAN 开关是否已使能', value: wifiManager.isWifiActive() ? '是' : '否' },
    { name: 'WLAN 是否已连接', value: wifiManager.isConnected() ? '是' : '否' },
    { name: 'Ipv4 IP 地址', value: decimalToDottedIP(wifiManager.getIpInfo().ipAddress) },
    { name: 'Ipv4 网关', value: decimalToDottedIP(wifiManager.getIpInfo().gateway) },
    { name: 'Ipv4 掩码', value: decimalToDottedIP(wifiManager.getIpInfo().netmask) },
    { name: 'Ipv4 主 DNS 服务器 IP 地址', value: decimalToDottedIP(wifiManager.getIpInfo().primaryDns) },
    { name: 'Ipv4 备 DNS 服务器 IP 地址', value: decimalToDottedIP(wifiManager.getIpInfo().secondDns) },
    { name: 'Ipv4 DHCP 服务器 IP 地址', value: decimalToDottedIP(wifiManager.getIpInfo().serverIp) },
    { name: 'Ipv4 IP 地址租用时长', value: String(wifiManager.getIpInfo().leaseDuration) + ' s' },
    { name: '链路 Ipv6 地址', value: wifiManager.getIpv6Info().linkIpv6Address },
    { name: '全局 Ipv6 地址', value: wifiManager.getIpv6Info().globalIpv6Address },
    { name: '唯一本地 Ipv6 地址', value: String(wifiManager.getIpv6Info().uniqueIpv6Address) },
    { name: '随机唯一本地 Ipv6 地址', value: String(wifiManager.getIpv6Info().randomUniqueIpv6Address) },
    { name: 'Ipv6 网关', value: wifiManager.getIpv6Info().gateway },
    { name: 'Ipv6 掩码', value: wifiManager.getIpv6Info().netmask },
    { name: 'Ipv6 主 DNS 服务器 IP 地址', value: wifiManager.getIpv6Info().primaryDNS },
    { name: 'Ipv6 备 DNS 服务器 IP 地址', value: wifiManager.getIpv6Info().secondDNS },
    { name: '国家码', value: wifiManager.getCountryCode() },
    { name: '热点是否已使能', value: wifiManager.isHotspotActive() ? '是' : '否' },
    { name: '蜂窝数据业务是否启用', value: data.isCellularDataEnabledSync() ? '是' : '否' }
  ]
  storageStatisticsInfoArray: Item[] = [
    { name: '系统总', value: String(storageStatistics.getTotalSizeSync()) + ' B' },
    { name: '系统空闲', value: String(storageStatistics.getFreeSizeSync()) + ' B' }
  ]
  processInfoArray: Item[] = [
    { name: '是否被隔离', value: process.isIsolatedProcess() ? '是' : '否' },
    { name: '运行环境是否是 64 位', value: process.is64Bit() ? '是' : '否' },
    { name: '从系统启动到进程启动所经过的时间', value: String(process.getStartRealtime()) + ' ms' },
    { name: '从进程启动到当前时间所经过的 CPU 时间', value: String(process.getPastCpuTime()) + ' ms' }
  ]

  getSetting() {
    const globalErrorShowType = this.debugSettingDataPreferences.getSync('globalErrorShowType', 0)
    this.globalErrorShowTypeIndex = globalErrorShowType as number
    if (globalErrorShowType === 0) {
      this.globalErrorShowTypeValue = 'Toast'
    }
    if (globalErrorShowType === 1) {
      this.globalErrorShowTypeValue = 'Dialog'
    }
    const autoUploadErrorLog = this.debugSettingDataPreferences.getSync('autoUploadErrorLog', true)
    this.autoUploadErrorLog = autoUploadErrorLog as boolean
    const showMemoryLevelChange = this.debugSettingDataPreferences.getSync('showMemoryLevelChange', false)
    this.showMemoryLevelChange = showMemoryLevelChange as boolean
    const lowBatteryCapacityLevel = this.debugSettingDataPreferences.getSync('lowBatteryCapacityLevel', 4)
    this.lowBatteryCapacityLevelIndex = (lowBatteryCapacityLevel as number) - 1
    if (lowBatteryCapacityLevel === 1) {
      this.lowBatteryCapacityLevelValue = '满'
    }
    if (lowBatteryCapacityLevel === 2) {
      this.lowBatteryCapacityLevelValue = '高'
    }
    if (lowBatteryCapacityLevel === 3) {
      this.lowBatteryCapacityLevelValue = '正常'
    }
    if (lowBatteryCapacityLevel === 4) {
      this.lowBatteryCapacityLevelValue = '低'
    }
    if (lowBatteryCapacityLevel === 5) {
      this.lowBatteryCapacityLevelValue = '告警'
    }
    if (lowBatteryCapacityLevel === 6) {
      this.lowBatteryCapacityLevelValue = '极低'
    }
    if (lowBatteryCapacityLevel === 7) {
      this.lowBatteryCapacityLevelValue = '关机'
    }
    const autoReportHighLatency = this.debugSettingDataPreferences.getSync('autoReportHighLatency', true)
    this.autoReportHighLatency = autoReportHighLatency as boolean
    const showNetAvailableStatusChange = this.debugSettingDataPreferences.getSync('showNetAvailableStatusChange', false)
    this.showNetAvailableStatusChange = showNetAvailableStatusChange as boolean
    const showNetBlockStatusChange = this.debugSettingDataPreferences.getSync('showNetBlockStatusChange', false)
    this.showNetBlockStatusChange = showNetBlockStatusChange as boolean
    const showNetLost = this.debugSettingDataPreferences.getSync('showNetLost', false)
    this.showNetLost = showNetLost as boolean
    const showNetCapabilitiesChange = this.debugSettingDataPreferences.getSync('showNetCapabilitiesChange', false)
    this.showNetCapabilitiesChange = showNetCapabilitiesChange as boolean
    const showNetQosChange = this.debugSettingDataPreferences.getSync('showNetQosChange', false)
    this.showNetQosChange = showNetQosChange as boolean
    const showNetSceneChange = this.debugSettingDataPreferences.getSync('showNetSceneChange', false)
    this.showNetSceneChange = showNetSceneChange as boolean
    const highLatencyThreshold = this.debugSettingDataPreferences.getSync('highLatencyThreshold', 200)
    this.highLatencyThreshold = String(highLatencyThreshold)
    const allService = this.commonSettingDataPreferences.getSync('allService', true)
    this.allService = allService as boolean
    if (!allService) {
      this.autoUploadErrorLog = false
    }
  }

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Text('基础')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              Row() {
                Text('故障展示方式')
                  .fontWeight('medium')
                Blank()
                Select([
                  { value: 'Toast' },
                  { value: 'Dialog' }
                ])
                  .selected($$this.globalErrorShowTypeIndex)
                  .value($$this.globalErrorShowTypeValue)
                  .onSelect((index: number) => {
                    this.debugSettingDataPreferences.putSync('globalErrorShowType', index)
                    this.debugSettingDataPreferences.flushSync()
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
                Text('自动上传故障日志')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: $$this.autoUploadErrorLog
                })
                  .enabled(this.allService)
                  .onChange((isOn: boolean) => {
                    this.debugSettingDataPreferences.putSync('autoUploadErrorLog', isOn)
                    this.debugSettingDataPreferences.flushSync()
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
                Text('故障日志')
                  .fontWeight('medium')
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
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'Faultlog'
                })
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('内存占用级别变化时弹窗')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: $$this.showMemoryLevelChange
                })
                  .onChange((isOn: boolean) => {
                    this.debugSettingDataPreferences.putSync('showMemoryLevelChange', isOn)
                    this.debugSettingDataPreferences.flushSync()
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
                Text('电池电量低阈值')
                  .fontWeight('medium')
                Blank()
                Select([
                  { value: '满' },
                  { value: '高' },
                  { value: '正常' },
                  { value: '低' },
                  { value: '告警' },
                  { value: '极低' },
                  { value: '关机' }
                ])
                  .selected($$this.lowBatteryCapacityLevelIndex)
                  .value($$this.lowBatteryCapacityLevelValue)
                  .onSelect((index: number) => {
                    this.debugSettingDataPreferences.putSync('lowBatteryCapacityLevel', index + 1)
                    this.debugSettingDataPreferences.flushSync()
                  })
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
          Column() {
            Text('应用恢复')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              Row() {
                Text('重启当前进程')
                  .fontWeight('medium')
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
              .onClick(() => {
                appRecovery.restartApp()
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('保存当前状态')
                  .fontWeight('medium')
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
              .onClick(() => {
                const res = appRecovery.saveAppState()
                if (res) {
                  promptAction.showToast({
                    message: '保存成功'
                  })
                }
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('设置')
                  .fontWeight('medium')
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
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'Recoverysetting'
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
            Text('网络')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              Row() {
                Text('可用状态变化时弹窗')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: $$this.showNetAvailableStatusChange
                })
                  .onChange((isOn: boolean) => {
                    this.debugSettingDataPreferences.putSync('showNetAvailableStatusChange', isOn)
                    this.debugSettingDataPreferences.flushSync()
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
                Text('阻塞状态变化时弹窗')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: $$this.showNetBlockStatusChange
                })
                  .onChange((isOn: boolean) => {
                    this.debugSettingDataPreferences.putSync('showNetBlockStatusChange', isOn)
                    this.debugSettingDataPreferences.flushSync()
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
                Text('丢失时弹窗')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: $$this.showNetLost
                })
                  .onChange((isOn: boolean) => {
                    this.debugSettingDataPreferences.putSync('showNetLost', isOn)
                    this.debugSettingDataPreferences.flushSync()
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
                Text('能力变化时弹窗')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: $$this.showNetCapabilitiesChange
                })
                  .onChange((isOn: boolean) => {
                    this.debugSettingDataPreferences.putSync('showNetCapabilitiesChange', isOn)
                    this.debugSettingDataPreferences.flushSync()
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
                Text('质量变化时弹窗')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: $$this.showNetQosChange
                })
                  .onChange((isOn: boolean) => {
                    this.debugSettingDataPreferences.putSync('showNetQosChange', isOn)
                    this.debugSettingDataPreferences.flushSync()
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
                Text('场景变化时弹窗')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: $$this.showNetSceneChange
                })
                  .onChange((isOn: boolean) => {
                    this.debugSettingDataPreferences.putSync('showNetSceneChange', isOn)
                    this.debugSettingDataPreferences.flushSync()
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
                Text('高时延时自动反馈传输体验')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: $$this.autoReportHighLatency
                })
                  .onChange((isOn: boolean) => {
                    this.debugSettingDataPreferences.putSync('autoReportHighLatency', isOn)
                    this.debugSettingDataPreferences.flushSync()
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
                Text('时延达到')
                  .fontWeight('medium')
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                TextInput({
                  text: $$this.highLatencyThreshold
                })
                  .type(InputType.Number)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .maxLength(4)
                  .width('25%')
                  .onSubmit((enterKey: EnterKeyType, event: SubmitEvent) => {
                    this.debugSettingDataPreferences.putSync('highLatencyThreshold', Number(event.text))
                    this.debugSettingDataPreferences.flushSync()
                    promptAction.showToast({
                      message: '设置成功'
                    })
                  })
                Text('ms 时判定为高时延')
                  .fontWeight('medium')
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
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
                Text('反馈传输体验')
                  .fontWeight('medium')
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
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'ReportQoe'
                })
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('测试')
                  .fontWeight('medium')
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
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'Networktest'
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
            Text('应用')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              Row() {
                Text('清除所有数据并退出')
                  .fontColor($r('sys.color.warning'))
                  .fontWeight('medium')
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
                const data = await promptAction.showDialog({
                  title: '提示',
                  message: '此操作将清除应用全部数据，同时撤销应用向用户申请的权限。确定清除？',
                  buttons: [
                    {
                      text: '取消',
                      color: $r('sys.color.font_primary')
                    },
                    {
                      text: '清除',
                      color: $r('sys.color.warning')
                    }
                  ]
                })
                if (data.index === 1) {
                  const applicationContext = this.context.getApplicationContext()
                  applicationContext.clearUpApplicationData()
                }
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('终止所有进程并退出')
                  .fontColor($r('sys.color.warning'))
                  .fontWeight('medium')
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
                const data = await promptAction.showActionMenu({
                  title: '是否清除页面堆栈？',
                  buttons: [
                    {
                      text: '是',
                      color: $r('sys.color.font_primary')
                    },
                    {
                      text: '否',
                      color: $r('sys.color.font_primary')
                    }
                  ]
                })
                if (data.index === 0) {
                  const applicationContext = this.context.getApplicationContext()
                  applicationContext.killAllProcesses(true)
                }
                if (data.index === 1) {
                  const applicationContext = this.context.getApplicationContext()
                  applicationContext.killAllProcesses(false)
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

        ListItem() {
          Button('恢复默认设置')
            .align(Alignment.Center)
            .onClick(async () => {
              const data = await promptAction.showDialog({
                title: '提示',
                message: '此操作将恢复全部调试设置为默认。确定恢复？',
                buttons: [
                  {
                    text: '取消',
                    color: $r('sys.color.font_primary')
                  },
                  {
                    text: '恢复',
                    color: $r('sys.color.font_emphasize')
                  }
                ]
              })
              if (data.index === 1) {
                this.debugSettingDataPreferences.clearSync()
                this.debugSettingDataPreferences.flushSync()
                promptAction.showToast({
                  message: '恢复成功'
                })
                this.getSetting()
              }
            })
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })
        .width('100%')

        ListItem() {
          Column() {
            Text('应用程序信息')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              ForEach(this.applicationInfoArray, (item: Item, index: number) => {
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
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('HAP 信息')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              ForEach(this.hapModuleInfoArray, (item: Item, index: number) => {
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
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('Ability 信息')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              ForEach(this.abilityInfoArray, (item: Item, index: number) => {
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
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('应用包信息')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              ForEach(this.bundleInfoArray, (item: Item, index: number) => {
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
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('设备信息')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              ForEach(this.deviceInfoArray, (item: Item, index: number) => {
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
                left: 12
              })
            Column() {
              ForEach(this.systemInfoArray, (item: Item, index: number) => {
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
                left: 12
              })
            Column() {
              ForEach(this.displayInfoArray, (item: Item, index: number) => {
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
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        if (this.windowInfoArray.length > 0) {
          ListItem() {
            Column() {
              Text('窗口信息')
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .fontWeight('medium')
                .margin({
                  bottom: 6,
                  left: 12
                })
              Column() {
                ForEach(this.windowInfoArray, (item: Item, index: number) => {
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
              .padding($r('sys.float.ohos_id_corner_radius_mark'))
            }
            .alignItems(HorizontalAlign.Start)
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_l')
          })
        }

        ListItem() {
          Column() {
            Text('电量信息')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              ForEach(this.batteryInfoArray, (item: Item, index: number) => {
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
                left: 12
              })
            Column() {
              Row() {
                Text('是否处于活动状态')
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
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('是否进入待机低功耗续航模式')
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
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('电源模式')
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
          Column() {
            Text('热管理信息')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              Row() {
                Text('热档位')
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
          Column() {
            Text('系统负载信息')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              Row() {
                Text('系统负载融合档位')
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
          Column() {
            Text('网络信息')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              ForEach(this.networkInfoArray, (item: Item, index: number) => {
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
                left: 12
              })
            Column() {
              Row() {
                Text('辅助功能')
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
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('触摸浏览模式')
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
          Column() {
            Text('存储空间信息')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              ForEach(this.storageStatisticsInfoArray, (item: Item, index: number) => {
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
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('进程信息')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              ForEach(this.processInfoArray, (item: Item, index: number) => {
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
    .onReady(async (context: NavDestinationContext) => {
      this.getSetting()
      this.pageInfos = context.pathStack
      const isRunningInStabilityTest = await appManager.isRunningInStabilityTest()
      this.applicationInfoArray.push({
        name: '当前是否处于稳定性测试场景',
        value: isRunningInStabilityTest ? '是' : '否'
      })
      const isRamConstrainedDevice = await appManager.isRamConstrainedDevice()
      this.applicationInfoArray.push({
        name: '是否为 ram 受限设备',
        value: isRamConstrainedDevice ? '是' : '否'
      })
      const memorySize = await appManager.getAppMemorySize()
      this.applicationInfoArray.push({
        name: '可用内存',
        value: String(memorySize) + ' MB'
      })
      const bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT |
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_SIGNATURE_INFO)
      this.bundleInfoArray.push({
        name: '名称',
        value: bundleInfo.name
      })
      this.bundleInfoArray.push({
        name: '版本号',
        value: String(bundleInfo.versionCode)
      })
      this.bundleInfoArray.push({
        name: '版本文本描述',
        value: bundleInfo.versionName
      })
      this.bundleInfoArray.push({
        name: '分布式场景下兼容的最低版本',
        value: String(bundleInfo.minCompatibleVersionCode)
      })
      this.bundleInfoArray.push({
        name: '应用运行目标版本',
        value: String(bundleInfo.targetVersion)
      })
      this.bundleInfoArray.push({
        name: '应用 appId',
        value: bundleInfo.signatureInfo.appId
      })
      this.bundleInfoArray.push({
        name: '指纹',
        value: bundleInfo.signatureInfo.fingerprint
      })
      this.bundleInfoArray.push({
        name: '应用唯一标识',
        value: bundleInfo.signatureInfo.appIdentifier
      })
      this.bundleInfoArray.push({
        name: '应用证书公钥',
        value: String(bundleInfo.signatureInfo.certificate)
      })
      this.bundleInfoArray.push({
        name: '安装时间',
        value: String(bundleInfo.installTime)
      })
      this.bundleInfoArray.push({
        name: '更新时间',
        value: String(bundleInfo.updateTime)
      })
      this.bundleInfoArray.push({
        name: '分身索引标识',
        value: String(bundleInfo.appIndex)
      })
      const lastWindow = await window.getLastWindow(this.context)
      this.windowInfoArray = this.windowInfoArray.concat([
        { name: '尺寸左边界', value: String(lastWindow.getWindowProperties().windowRect.left) + ' px' },
        { name: '尺寸上边界', value: String(lastWindow.getWindowProperties().windowRect.top) + ' px' },
        { name: '尺寸宽度', value: String(lastWindow.getWindowProperties().windowRect.width) + ' px' },
        { name: '尺寸高度', value: String(lastWindow.getWindowProperties().windowRect.height) + ' px' },
        {
          name: '可绘制区域尺寸左边界',
          value: String(lastWindow.getWindowProperties().drawableRect.left) + ' px'
        },
        {
          name: '可绘制区域尺寸上边界',
          value: String(lastWindow.getWindowProperties().drawableRect.top) + ' px'
        },
        {
          name: '可绘制区域尺寸宽度',
          value: String(lastWindow.getWindowProperties().drawableRect.width) + ' px'
        },
        {
          name: '可绘制区域尺寸高度',
          value: String(lastWindow.getWindowProperties().drawableRect.height) + ' px'
        },
        {
          name: '类型',
          value: lastWindow.getWindowProperties().type === 0 ? '应用子窗口' :
            lastWindow.getWindowProperties().type === 1 ? '系统告警窗口' :
              lastWindow.getWindowProperties().type === 8 ? '悬浮窗' :
                lastWindow.getWindowProperties().type === 16 ? '模态窗口' :
                  'undefined'
        },
        { name: '是否全屏', value: lastWindow.getWindowProperties().isFullScreen ? '是' : '否' },
        { name: '是否为沉浸式', value: lastWindow.getWindowProperties().isLayoutFullScreen ? '是' : '否' },
        { name: '是否可聚焦', value: lastWindow.getWindowProperties().focusable ? '是' : '否' },
        { name: '是否可触摸', value: lastWindow.getWindowProperties().touchable ? '是' : '否' },
        { name: '屏幕亮度', value: String(lastWindow.getWindowProperties().brightness) },
        { name: '屏幕是否常亮', value: lastWindow.getWindowProperties().isKeepScreenOn ? '是' : '否' },
        { name: '隐私模式', value: lastWindow.getWindowProperties().isPrivacyMode ? '开启' : '关闭' },
        { name: '是否透明', value: lastWindow.getWindowProperties().isTransparent ? '是' : '否' },
        { name: 'ID', value: String(lastWindow.getWindowProperties().id) },
        { name: '所在屏幕 ID', value: String(lastWindow.getWindowProperties().displayId) },
        {
          name: '所在屏幕的系统显示大小缩放系数',
          value: String(lastWindow.getWindowDensityInfo().systemDensity)
        },
        {
          name: '所在屏幕的系统默认显示大小缩放系数',
          value: String(lastWindow.getWindowDensityInfo().defaultDensity)
        },
        { name: '自定义设置的显示大小缩放系数', value: String(lastWindow.getWindowDensityInfo().customDensity) },
        {
          name: '在屏幕上的真实显示区域距离屏幕左上角的 x 坐标',
          value: String(lastWindow.getGlobalRect().left) + ' px'
        },
        {
          name: '在屏幕上的真实显示区域距离屏幕左上角的 y 坐标',
          value: String(lastWindow.getGlobalRect().top) + ' px'
        },
        {
          name: '在屏幕上的真实显示区域宽度',
          value: String(lastWindow.getGlobalRect().width) + ' px'
        },
        {
          name: '在屏幕上的真实显示区域高度',
          value: String(lastWindow.getGlobalRect().height) + ' px'
        },
        {
          name: '系统默认内容规避区域是否可见',
          value: lastWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).visible ? '是' : '否'
        },
        {
          name: '是否已经开启沉浸式布局',
          value: lastWindow.getImmersiveModeEnabledState() ? '是' : '否'
        },
        {
          name: '状态栏背景颜色',
          value: String(lastWindow.getWindowSystemBarProperties().statusBarColor)
        },
        {
          name: '状态栏图标是否为高亮状态',
          value: lastWindow.getWindowSystemBarProperties().isStatusBarLightIcon ? '是' : '否'
        },
        {
          name: '状态栏文字颜色',
          value: String(lastWindow.getWindowSystemBarProperties().statusBarContentColor)
        },
        {
          name: '导航栏背景颜色',
          value: String(lastWindow.getWindowSystemBarProperties().navigationBarColor)
        },
        {
          name: '导航栏图标是否为高亮状态',
          value: lastWindow.getWindowSystemBarProperties().isNavigationBarLightIcon ? '是' : '否'
        },
        {
          name: '导航栏文字颜色',
          value: String(lastWindow.getWindowSystemBarProperties().navigationBarContentColor)
        },
        {
          name: '是否使能状态栏属性变化时动画效果',
          value: lastWindow.getWindowSystemBarProperties().enableStatusBarAnimation ? '是' : '否'
        },
        {
          name: '是否使能导航栏属性变化时动画效果',
          value: lastWindow.getWindowSystemBarProperties().enableNavigationBarAnimation ? '是' : '否'
        },
        {
          name: '显示方向',
          value: lastWindow.getPreferredOrientation() === 0 ? '未定义方向模式，由系统判定' :
            lastWindow.getPreferredOrientation() === 1 ? '竖屏显示模式' :
              lastWindow.getPreferredOrientation() === 2 ? '横屏显示模式' :
                lastWindow.getPreferredOrientation() === 3 ? '反向竖屏显示模式' :
                  lastWindow.getPreferredOrientation() === 4 ? '反向横屏显示模式' :
                    lastWindow.getPreferredOrientation() === 5 ?
                      '跟随传感器自动旋转，可以旋转到竖屏、横屏、反向竖屏、反向横屏四个方向' :
                      lastWindow.getPreferredOrientation() === 6 ?
                        '跟随传感器自动竖向旋转，可以旋转到竖屏、反向竖屏，无法旋转到横屏、反向横屏' :
                        lastWindow.getPreferredOrientation() === 7 ?
                          '跟随传感器自动横向旋转，可以旋转到横屏、反向横屏，无法旋转到竖屏、反向竖屏' :
                          lastWindow.getPreferredOrientation() === 8 ?
                            '跟随传感器自动旋转，可以旋转到竖屏、横屏、反向竖屏、反向横屏四个方向，且受控制中心的旋转开关控制' :
                            lastWindow.getPreferredOrientation() === 9 ?
                              '跟随传感器自动竖向旋转，可以旋转到竖屏、反向竖屏，无法旋转到横屏、反向横屏，且受控制中心的旋转开关控制' :
                              lastWindow.getPreferredOrientation() === 10 ?
                                '跟随传感器自动横向旋转，可以旋转到横屏、反向横屏，无法旋转到竖屏、反向竖屏，且受控制中心的旋转开关控制' :
                                lastWindow.getPreferredOrientation() === 11 ? '锁定模式' :
                                  lastWindow.getPreferredOrientation() === 12 ?
                                    '跟随传感器自动旋转，受控制中心的旋转开关控制，且可旋转方向受系统判定' :
                                    lastWindow.getPreferredOrientation() === 13 ?
                                      '调用时临时旋转到竖屏，之后跟随传感器自动旋转，受控制中心的旋转开关控制，且可旋转方向受系统判定' :
                                      lastWindow.getPreferredOrientation() === 14 ?
                                        '调用时临时旋转到横屏，之后跟随传感器自动旋转，受控制中心的旋转开关控制，且可旋转方向受系统判定' :
                                        lastWindow.getPreferredOrientation() === 15 ?
                                          '调用时临时旋转到反向竖屏，之后跟随传感器自动旋转，受控制中心的旋转开关控制，且可旋转方向受系统判定'
                                          : lastWindow.getPreferredOrientation() === 16 ?
                                          '调用时临时旋转到反向横屏，之后跟随传感器自动旋转，受控制中心的旋转开关控制，且可旋转方向受系统判定' :
                                          lastWindow.getPreferredOrientation() === 17 ? '跟随桌面的旋转模式' :
                                            'undefined'
        },
        { name: '是否已显示', value: lastWindow.isWindowShowing() ? '是' : '否' },
        {
          name: '色域模式',
          value: lastWindow.getWindowColorSpace() === 0 ? '默认 SRGB 色域' :
            lastWindow.getWindowColorSpace() === 1 ? '广色域' :
              'undefined'
        },
        {
          name: '最大宽度',
          value: String(lastWindow.getWindowLimits().maxWidth) + ' px'
        },
        {
          name: '最大高度',
          value: String(lastWindow.getWindowLimits().maxHeight) + ' px'
        },
        {
          name: '最小宽度',
          value: String(lastWindow.getWindowLimits().minWidth) + ' px'
        },
        {
          name: '最小高度',
          value: String(lastWindow.getWindowLimits().minHeight) + ' px'
        },
        {
          name: '模式',
          value: lastWindow.getWindowStatus() === 0 ? '未定义' :
            lastWindow.getWindowStatus() === 1 ? '全屏' :
              lastWindow.getWindowStatus() === 2 ? '最大化' :
                lastWindow.getWindowStatus() === 3 ? '最小化' :
                  lastWindow.getWindowStatus() === 4 ? '自由悬浮形式' :
                    lastWindow.getWindowStatus() === 5 ? '分屏' :
                      'undefined'
        },
        { name: '是否已获焦', value: lastWindow.isFocused() ? '是' : '否' },
        { name: '是否禁用返回手势功能', value: lastWindow.isGestureBackEnabled() ? '是' : '否' }
      ])
      const isWindowSupportWideGamut = await lastWindow.isWindowSupportWideGamut()
      this.windowInfoArray.push({
        name: '是否支持广色域模式',
        value: isWindowSupportWideGamut ? '是' : '否'
      })
      if (deviceInfo.deviceType === '2in1') {
        this.windowInfoArray.push({
          name: '是否已经启用尺寸记忆',
          value: this.commonSettingDataPreferences.getSync('isWindowRectAutoSave', false) ? '是' : '否'
        })
      }
      this.systemLoadValue = await systemLoad.getLevel()
      const storageStatisticsInfo = await storageStatistics.getCurrentBundleStats()
      this.storageStatisticsInfoArray.push({
        name: '应用安装文件',
        value: String(storageStatisticsInfo.appSize) + ' B'
      })
      this.storageStatisticsInfoArray.push({
        name: '应用缓存文件',
        value: String(storageStatisticsInfo.cacheSize) + ' B'
      })
      this.storageStatisticsInfoArray.push({
        name: '应用其他文件',
        value: String(storageStatisticsInfo.dataSize) + ' B'
      })
      try {
        const connectionProperties = connection.getConnectionPropertiesSync(connection.getDefaultNetSync())
        this.networkInfoArray.concat([
          {
            name: '网卡名称',
            value: connectionProperties.interfaceName
          },
          { name: '域名', value: connectionProperties.domains },
          {
            name: '最大传输单元',
            value: String(connectionProperties.mtu)
          }
        ])
        const netCapabilities = connection.getNetCapabilitiesSync(connection.getDefaultNetSync())
        this.networkInfoArray.push({
          name: '上行带宽',
          value: String(netCapabilities.linkUpBandwidthKbps) + ' KB/s'
        })
        this.networkInfoArray.push({
          name: '下行带宽',
          value: String(netCapabilities.linkDownBandwidthKbps) + ' KB/s'
        })
        this.networkInfoArray.push({
          name: '网络类型',
          value: netCapabilities.bearerTypes.includes(0) ? '蜂窝' :
            netCapabilities.bearerTypes.includes(1) ? 'Wi-Fi' :
              netCapabilities.bearerTypes.includes(2) ? '蓝牙' :
                netCapabilities.bearerTypes.includes(3) ? '以太网' :
                  netCapabilities.bearerTypes.includes(4) ? 'VPN' :
                    'undefined'
        })
      } catch (err) {
        promptAction.showToast({
          message: 'js 运行异常，错误码：' + err.code + '，错误信息：' + err.message
        })
      }
      const wifiLinkedInfo = await wifiManager.getLinkedInfo()
      this.networkInfoArray.push({
        name: '热点 SSID',
        value: wifiLinkedInfo.ssid
      })
      this.networkInfoArray.push({
        name: '热点 BSSID',
        value: wifiLinkedInfo.bssid
      })
      this.networkInfoArray.push({
        name: '热点信号强度',
        value: String(wifiLinkedInfo.rssi) + ' dBm'
      })
      this.networkInfoArray.push({
        name: 'WLAN 接入点频段',
        value: wifiLinkedInfo.band === 1 ? '2.4 GHz' :
          wifiLinkedInfo.band === 2 ? '5 Ghz' :
            'undefined'
      })
      this.networkInfoArray.push({
        name: 'WLAN 信号强度',
        value: String(wifiManager.getSignalLevel(wifiLinkedInfo.rssi, wifiLinkedInfo.band))
      })
      this.networkInfoArray.push({
        name: 'WLAN 接入点上行速度',
        value: String(wifiLinkedInfo.linkSpeed) + ' Mbps/s'
      })
      this.networkInfoArray.push({
        name: 'WLAN 接入点下行速度',
        value: String(wifiLinkedInfo.rxLinkSpeed) + ' Mbps/s'
      })
      this.networkInfoArray.push({
        name: '当前支持的最大上行速率',
        value: String(wifiLinkedInfo.maxSupportedTxLinkSpeed) + ' Mbps/s'
      })
      this.networkInfoArray.push({
        name: '当前支持的最大下行速率',
        value: String(wifiLinkedInfo.maxSupportedRxLinkSpeed) + ' Mbps/s'
      })
      this.networkInfoArray.push({
        name: 'WLAN 接入点频率',
        value: String(wifiLinkedInfo.frequency)
      })
      this.networkInfoArray.push({
        name: 'WLAN 接入点是否是隐藏网络',
        value: wifiLinkedInfo.isHidden ? '是' : '否'
      })
      this.networkInfoArray.push({
        name: 'WLAN 接入点是否限制数据量',
        value: wifiLinkedInfo.isRestricted ? '是' : '否'
      })
      this.networkInfoArray.push({
        name: 'MAC 地址类型',
        value: wifiLinkedInfo.macType === 0 ? '随机' :
          wifiLinkedInfo.macType === 1 ? '设备' :
            'undefined'
      })
      this.networkInfoArray.push({
        name: 'MAC 地址',
        value: wifiLinkedInfo.macAddress
      })
      this.networkInfoArray.push({
        name: 'WLAN 连接的 IP 地址',
        value: decimalToDottedIP(wifiLinkedInfo.ipAddress)
      })
      this.networkInfoArray.push({
        name: 'WLAN 连接状态',
        value: wifiLinkedInfo.connState === 0 ? '设备正在搜索可用的 AP' :
          wifiLinkedInfo.connState === 1 ? '正在建立 WLAN 连接' :
            wifiLinkedInfo.connState === 2 ? 'WLAN 连接正在认证中' :
              wifiLinkedInfo.connState === 3 ? '正在获取 WLAN 连接的 IP 地址' :
                wifiLinkedInfo.connState === 4 ? 'WLAN 连接已建立' :
                  wifiLinkedInfo.connState === 5 ? 'WLAN 连接正在断开' :
                    wifiLinkedInfo.connState === 6 ? 'WLAN 连接已断开' :
                      wifiLinkedInfo.connState === 7 ? 'WLAN 连接建立失败' :
                        'undefined'
      })
      this.networkInfoArray.push({
        name: '当前连接热点的信道带宽',
        value: wifiLinkedInfo.channelWidth === 0 ? '20 MHz' :
          wifiLinkedInfo.channelWidth === 1 ? '40 MHz' :
            wifiLinkedInfo.channelWidth === 2 ? '80 MHz' :
              wifiLinkedInfo.channelWidth === 3 ? '160 MHz' :
                wifiLinkedInfo.channelWidth === 4 ? '80 MHz+' :
                  wifiLinkedInfo.channelWidth === 5 ? '无效值' :
                    'undefined'
      })
      this.networkInfoArray.push({
        name: '当前连接热点的 Wi-Fi 标准',
        value: wifiLinkedInfo.wifiStandard === 0 ? '无效' :
          wifiLinkedInfo.wifiStandard === 1 ? '802.11a' :
            wifiLinkedInfo.wifiStandard === 2 ? '802.11b' :
              wifiLinkedInfo.wifiStandard === 3 ? '802.11g' :
                wifiLinkedInfo.wifiStandard === 4 ? '802.11n' :
                  wifiLinkedInfo.wifiStandard === 5 ? '802.11ac' :
                    wifiLinkedInfo.wifiStandard === 6 ? '802.11ax' :
                      wifiLinkedInfo.wifiStandard === 7 ? '802.11ad' :
                        'undefined'
      })
      this.networkInfoArray.push({
        name: '热点支持的最高 Wi-Fi 级别',
        value: wifiLinkedInfo.supportedWifiCategory === 1 ? 'Wifi6 以下' :
          wifiLinkedInfo.supportedWifiCategory === 2 ? 'Wifi6' :
            wifiLinkedInfo.supportedWifiCategory === 3 ? 'Wifi6+' :
              wifiLinkedInfo.supportedWifiCategory === 4 ? 'Wifi7' :
                wifiLinkedInfo.supportedWifiCategory === 5 ? 'Wifi7+' :
                  'undefined'
      })
      this.networkInfoArray.push({
        name: '热点是否支持 hilink',
        value: wifiLinkedInfo.isHiLinkNetwork ? '是' : '否'
      })
      try {
        const isMeteredHotspot = wifiManager.isMeteredHotspot()
        this.networkInfoArray.push({
          name: '设备当前连接的 Wi-Fi 是否是手机热点',
          value: isMeteredHotspot ? '是' : '否'
        })
      } catch (err) {
        promptAction.showToast({
          message: 'js 运行异常，错误码：' + err.code + '，错误信息：' + err.message
        })
      }
      const cellularDataFlowType = await data.getCellularDataFlowType()
      this.networkInfoArray.push({
        name: '蜂窝数据业务的上下行状态',
        value: cellularDataFlowType === 0 ? '没有上行或下行数据' :
          cellularDataFlowType === 1 ? '只有下行数据' :
            cellularDataFlowType === 2 ? '只有上行数据' :
              cellularDataFlowType === 3 ? '有上下行数据' :
                cellularDataFlowType === 4 ? '没有上下行数据，底层链路处于休眠状态' :
                  'undefined'
      })
      const cellularDataState = await data.getCellularDataState()
      this.networkInfoArray.push({
        name: '分组交换域 (PS 域) 的连接状态',
        value: cellularDataState === -1 ? '未知' :
          cellularDataState === 0 ? '断开' :
            cellularDataState === 1 ? '正在连接' :
              cellularDataState === 2 ? '已连接' :
                cellularDataState === 3 ? '被挂起' :
                  'undefined'
      })
    })
  }
}