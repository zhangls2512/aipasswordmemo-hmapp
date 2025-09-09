import { AbilityConstant, appRecovery, ConfigurationConstant, errorManager, UIAbility, Want } from '@kit.AbilityKit'
import { updateManager } from '@kit.AppGalleryKit'
import { preferences, relationalStore } from '@kit.ArkData'
import { uri } from '@kit.ArkTS'
import { promptAction, window } from '@kit.ArkUI'
import { deviceInfo } from '@kit.BasicServicesKit'
import { wifiManager } from '@kit.ConnectivityKit'
import { fileIo } from '@kit.CoreFileKit'
import { netQuality } from '@kit.NetworkBoostKit'
import { connection } from '@kit.NetworkKit'
import { notificationManager } from '@kit.NotificationKit'
import { hiAppEvent } from '@kit.PerformanceAnalysisKit'
import { check, get } from '../common/Accesstoken'
import { importCloudBackupInfo, importCloudBackupPassword, importCloudBackupTag } from '../common/Cloudbackimport'
import { importCsvPassword } from '../common/Csv'
import { importInfo, importPassword, importTag } from '../common/Dataimport'
import getDeviceToken from '../common/Devicetoken'
import { read } from '../common/File'
import request from '../common/Request'

export default class EntryAbility extends UIAbility {
  async appInit(want: Want) {
    const accessToken = await get()
    if (notificationManager.isNotificationEnabledSync()) {
      notificationManager.setBadgeNumber(0)
    }
    if (want.parameters?.shortcutId === 'newPassword') {
      this.context.eventHub.emit('newPassword')
    }
    if (want.parameters?.shortcutId === 'searchPassword') {
      this.context.eventHub.emit('searchPassword')
    }
    if (want.parameters?.menuHandler === 'clickMenu') {
      const uriList = want.parameters.uriList as string[]
      const filePath = uriList[0] as string
      const filestring = read(filePath)
      if (filePath.endsWith('.txt')) {
        const data = await promptAction.showActionMenu({
          title: '选择导入类型',
          buttons: [
            {
              text: '密码',
              color: $r('sys.color.font_primary')
            },
            {
              text: '常用信息',
              color: $r('sys.color.font_primary')
            },
            {
              text: '标签',
              color: $r('sys.color.font_primary')
            }
          ]
        })
        if (data.index === 0) {
          await importPassword(filestring, 0)
          this.context.eventHub.emit('refreshPassword')
        }
        if (data.index === 1) {
          await importInfo(filestring, 0)
          this.context.eventHub.emit('refreshInfo')
        }
        if (data.index === 2) {
          await importTag(filestring, 0)
          this.context.eventHub.emit('refreshTag')
        }
        promptAction.openToast({
          message: '导入成功'
        })
      }
      if (filePath.endsWith('.csv')) {
        await importCsvPassword(filestring)
        this.context.eventHub.emit('refreshPassword')
      }
    }
    if (want.uri) {
      if (want.uri === 'storage:///clearcache') {
        promptAction.showDialog({
          title: '提示',
          message: '请前往“我的”>“设置”>“其他”>“清理数据”清理数据。',
          buttons: [
            {
              text: '确定',
              color: $r('sys.color.font_emphasize')
            }
          ]
        })
      }
      if (want.uri.startsWith('https://www.zhangls2512.cn/product/password')) {
        const urires = new uri.URI(want.uri)
        const invitationCode = urires.getQueryValue('invitationcode')
        const vipCode = urires.getQueryValue('vipcode')
        if (invitationCode) {
          if (accessToken) {
            const deviceToken = await getDeviceToken()
            if (deviceToken) {
              const res = await request('/product/useInvitationcode', {
                accessToken: accessToken,
                deviceToken: deviceToken,
                product: 'password',
                invitationcode: invitationCode
              })
              if (res !== 'fail') {
                promptAction.openToast({
                  message: '邀请码使用成功'
                })
              }
            }
          } else {
            promptAction.openToast({
              message: '邀请码使用失败，原因：未登录账号'
            })
          }
        }
        if (vipCode) {
          if (accessToken) {
            const res = await request('/product/useVipcode', {
              accessToken: accessToken,
              vipcode: vipCode
            })
            if (res !== 'fail') {
              promptAction.openToast({
                message: '兑换码使用成功'
              })
            }
          } else {
            promptAction.openToast({
              message: '兑换码使用失败，原因：未登录账号'
            })
          }
        }
      }
    }
  }

  async windowInit(windowStage: window.WindowStage) {
    const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
      name: 'commonSetting'
    })
    if (deviceInfo.deviceType === '2in1') {
      const windowRectAutoSave = commonSettingDataPreferences.getSync('windowRectAutoSave', false) as boolean
      await windowStage.setWindowRectAutoSave(windowRectAutoSave)
    }
    await windowStage.loadContent('pages/Index')
    const lastWindow = await window.getLastWindow(this.context)
    const windowTopmost = commonSettingDataPreferences.getSync('windowTopmost', false) as boolean
    await lastWindow.setWindowTopmost(windowTopmost)
    if (!notificationManager.isNotificationEnabledSync()) {
      notificationManager.requestEnableNotification(this.context)
    }
  }

  async onCreate(want: Want) {
    const passwordRdbStore = await relationalStore.getRdbStore(this.context, {
      name: 'password',
      securityLevel: 4,
      encrypt: true,
      allowRebuild: true
    })
    passwordRdbStore.executeSql('CREATE TABLE IF NOT EXISTS password (id INTEGER PRIMARY KEY AUTOINCREMENT, name, info, tag, updateTime, cloudBackupTime)')
    const infoRdbStore = await relationalStore.getRdbStore(this.context, {
      name: 'info',
      securityLevel: 4,
      encrypt: true,
      allowRebuild: true
    })
    infoRdbStore.executeSql('CREATE TABLE IF NOT EXISTS info (id INTEGER PRIMARY KEY AUTOINCREMENT, type, value, updateTime, cloudBackupTime)')
    const tagRdbStore = await relationalStore.getRdbStore(this.context, {
      name: 'tag',
      securityLevel: 1,
      encrypt: true,
      allowRebuild: true
    })
    tagRdbStore.executeSql('CREATE TABLE IF NOT EXISTS tag (id INTEGER PRIMARY KEY AUTOINCREMENT, value, color, updateTime, cloudBackupTime)')
    appRecovery.enableAppRecovery(appRecovery.RestartFlag.RESTART_WHEN_APP_FREEZE)
    const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
      name: 'commonSetting'
    })
    const allowContinue = commonSettingDataPreferences.getSync('allowContinue', true)
    if (!allowContinue) {
      await this.context.setMissionContinueState(AbilityConstant.ContinueState.INACTIVE)
    }
    if (allowContinue) {
      await this.context.setMissionContinueState(AbilityConstant.ContinueState.ACTIVE)
    }
    const allowRestore = commonSettingDataPreferences.getSync('allowRestore', true) as boolean
    this.context.setRestoreEnabled(allowRestore)
    const colorMode = commonSettingDataPreferences.getSync('colorMode', 0)
    const applicationContext = this.context.getApplicationContext()
    if (colorMode === 0) {
      applicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
    }
    if (colorMode === 1) {
      applicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT)
    }
    if (colorMode === 2) {
      applicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK)
    }
    const debugSettingDataPreferences = preferences.getPreferencesSync(this.context, {
      name: 'debugSetting'
    })
    const processCache = debugSettingDataPreferences.getSync('processCache', true) as boolean
    applicationContext.setSupportedProcessCache(processCache)
    const globalErrorShowType = debugSettingDataPreferences.getSync('globalErrorShowType', 0)
    errorManager.on('error', {
      onUnhandledException(errMsg) {
        if (globalErrorShowType === 0) {
          promptAction.openToast({
            message: 'js 运行异常：' + errMsg
          })
        }
      },
      onException(err) {
        if (globalErrorShowType === 1) {
          let message = '名称：' + err.name + '\n信息：' + err.message
          if (typeof (err.stack) === 'string') {
            message = message + '\n堆栈：' + err.stack
          }
          promptAction.showDialog({
            title: 'js 运行异常',
            message: message,
            buttons: [
              {
                text: '确定',
                color: $r('sys.color.font_emphasize')
              }
            ]
          })
        }
      }
    })
    errorManager.on('unhandledRejection', (err: Error) => {
      if (globalErrorShowType === 0) {
        promptAction.openToast({
          message: 'js 运行异常，错误名称：' + err.name + '，错误信息：' + err.message + '，错误堆栈：' + err.stack
        })
      }
      if (globalErrorShowType === 1) {
        let message = '名称：' + err.name + '\n信息：' + err.message
        if (typeof (err.stack) === 'string') {
          message = message + '\n堆栈：' + err.stack
        }
        promptAction.showDialog({
          title: 'js 运行异常',
          message: message,
          buttons: [
            {
              text: '确定',
              color: $r('sys.color.font_emphasize')
            }
          ]
        })
      }
    })
    hiAppEvent.addWatcher({
      name: 'watcher',
      appEventFilters: [
        {
          domain: hiAppEvent.domain.OS,
          eventTypes: [hiAppEvent.EventType.FAULT]
        }
      ],
      onReceive: async (domain, appEventGroups) => {
        const autoUploadErrorLogType = debugSettingDataPreferences.getSync('autoUploadErrorLogType', [
          'APP_CRASH',
          'APP_FREEZE',
          'APP_KILLED',
          'APP_LAUNCH',
          'RESOURCE_OVERLIMIT',
          'ADDRESS_SANITIZER',
          'MAIN_THREAD_JANK',
          'SCROLL_JANK',
          'CPU_USAGE_HIGH',
          'BATTERY_USAGE'
        ]) as string[]
        if (debugSettingDataPreferences.getSync('saveErrorLog', true)) {
          const errorLogDir = this.context.filesDir + '/log/error'
          if (!fileIo.accessSync(errorLogDir)) {
            fileIo.mkdirSync(errorLogDir, true)
          }
          appEventGroups.forEach((item) => {
            const file = fileIo.openSync(this.context.filesDir + '/log/error/' + Date.now() + '.txt',
              fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE)
            fileIo.writeSync(file.fd, JSON.stringify(item))
            fileIo.closeSync(file)
          })
        }
        if (debugSettingDataPreferences.getSync('autoUploadErrorLog', true) &&
        commonSettingDataPreferences.getSync('allService', true)) {
          appEventGroups.map(async (item) => {
            if (autoUploadErrorLogType.includes(item.name)) {
              const res = await request('/debug/newErrorLog', {
                key: 'RaGvhiCmYP8aPZ-QmmDgBQvwkfkp9TXEVCWEn8fPjshs9GyUCooG_kq7N8bHBRcT',
                object: item
              })
              if (res !== 'fail') {
                promptAction.openToast({
                  message: '故障日志自动上传成功，故障类型：' + item.name
                })
              }
            }
          })
        }
      }
    })
    const netConnection: connection.NetConnection = connection.createNetConnection()
    netConnection.register(() => {
    })
    netConnection.on('netAvailable', (data) => {
      if (debugSettingDataPreferences.getSync('showNetAvailableStatusChange', false)) {
        promptAction.openToast({
          message: '网络可用，数据网络句柄：' + data.netId
        })
      }
    })
    netConnection.on('netUnavailable', () => {
      if (debugSettingDataPreferences.getSync('showNetAvailableStatusChange', false)) {
        promptAction.openToast({
          message: '网络不可用'
        })
      }
    })
    netConnection.on('netBlockStatusChange', (data) => {
      if (debugSettingDataPreferences.getSync('showNetBlockStatusChange', false)) {
        promptAction.showDialog({
          title: '网络阻塞状态变化',
          message: '数据网络句柄：' + data.netHandle.netId + '\n是否堵塞：' + data.blocked ? '是' : '否',
          buttons: [
            {
              text: '确定',
              color: $r('sys.color.font_emphasize')
            }
          ]
        })
      }
    })
    netConnection.on('netLost', (data) => {
      if (debugSettingDataPreferences.getSync('showNetLost', false)) {
        promptAction.openToast({
          message: '网络丢失，数据网络句柄：' + data.netId
        })
      }
    })
    netConnection.on('netCapabilitiesChange', (data) => {
      if (debugSettingDataPreferences.getSync('showNetCapabilitiesChange', false)) {
        const netBearType = data.netCap.bearerTypes.includes(0) ? '蜂窝' :
          data.netCap.bearerTypes.includes(1) ? 'Wi-Fi' :
            data.netCap.bearerTypes.includes(2) ? '蓝牙' :
              data.netCap.bearerTypes.includes(3) ? '以太网' :
                data.netCap.bearerTypes.includes(4) ? 'VPN' :
                  'undefined'
        promptAction.showDialog({
          title: '网络能力变化',
          message: '数据网络句柄：' + data.netHandle.netId + '\n上行带宽：' + data.netCap.linkUpBandwidthKbps +
            ' KB/s\n下行带宽：' + data.netCap.linkDownBandwidthKbps + ' KB/s\n网络类型：' + netBearType,
          buttons: [
            {
              text: '确定',
              color: $r('sys.color.font_emphasize')
            }
          ]
        })
      }
    })
    netQuality.on('netQosChange', (list) => {
      if (list.length > 0) {
        const data = list[0]
        if (debugSettingDataPreferences.getSync('showNetQosChange', false)) {
          const pathType = data.pathType === 0 ? '蜂窝主卡' :
            data.pathType === 1 ? '蜂窝副卡' :
              data.pathType === 2 ? '主 Wi-Fi' :
                data.pathType === 3 ? '副 Wi-Fi' :
                  'undefined'
          promptAction.showDialog({
            title: '网络质量变化',
            message: '数据路径：' + pathType + '\n上行带宽：' + data.linkUpBandwidth +
              ' bps\n下行带宽：' + data.linkDownBandwidth + ' bps\n上行速率：' + data.linkUpRate +
              ' bps\n下行速率：' + data.linkDownRate + '\nRTT 时延：' + data.rttMs + ' ms\n上行发送空口缓冲时延：' +
            data.linkUpBufferDelayMs + ' ms\n上行发送空口缓冲时延占总缓冲时间的比例：' +
            data.linkUpBufferCongestionPercent + '%',
            buttons: [
              {
                text: '确定',
                color: $r('sys.color.font_emphasize')
              }
            ]
          })
        }
        if (debugSettingDataPreferences.getSync('autoReportHighLatency', true) &&
          data.rttMs >= debugSettingDataPreferences.getSync('highLatencyThreshold', 200)) {
          netQuality.reportQoe({
            serviceType: 'default',
            qoeType: 'highLatency'
          })
          promptAction.openToast({
            message: '自动反馈网络高时延传输体验成功'
          })
        }
      }
    })
    netQuality.on('netSceneChange', (list) => {
      if (list.length > 0) {
        const data = list[0]
        if (debugSettingDataPreferences.getSync('showNetSceneChange', false)) {
          const pathType = data.pathType === 0 ? '蜂窝主卡' :
            data.pathType === 1 ? '蜂窝副卡' :
              data.pathType === 2 ? '主 Wi-Fi' :
                data.pathType === 3 ? '副 Wi-Fi' :
                  'undefined'
          const scene = data.scene === 'normal' ? '正常' :
            data.scene === 'congestion' ? '拥塞' :
              data.scene === 'frequentHandover' ? '小区切换频繁' :
                data.scene === 'weakSignal' ? '弱信号' :
                  'undefined'
          const dataSpeedSimpleAction = data.recommendedAction === 'doCaching' ? '做缓存动作' :
            data.recommendedAction === 'suspendData' ? '停止发包' :
              data.recommendedAction === 'decreaseData' ? '降低发包速率' :
                data.recommendedAction === 'increaseData' ? '增加发包速率' :
                  data.recommendedAction === 'keepData' ? '保持当前发包速率' :
                    'undefined'
          const isLastPredictionValid = data.weakSignalPrediction?.isLastPredictionValid ? '是' : '否'
          promptAction.showDialog({
            title: '网络质量变化',
            message: '数据路径：' + pathType + '\n场景类型：' + scene +
              '\n建议的数传策略：' + dataSpeedSimpleAction + '\n最近一次的弱信号预测是否有效：' + isLastPredictionValid +
              '\n预计多长时间进入弱信号：' + data.weakSignalPrediction?.startTime + ' s\n预计在弱信号区域停留时长：' +
              data.weakSignalPrediction?.duration +
              ' s',
            buttons: [
              {
                text: '确定',
                color: $r('sys.color.font_emphasize')
              }
            ]
          })
        }
      }
    })
    await check()
    const checkVersionUpdate = commonSettingDataPreferences.getSync('checkVersionUpdate', 1)
    try {
      if (checkVersionUpdate === 1) {
        if (wifiManager.isConnected()) {
          const res = await updateManager.checkAppUpdate(this.context)
          if (res.updateAvailable === 1) {
            updateManager.showUpdateDialog(this.context)
          }
        }
      }
      if (checkVersionUpdate === 2) {
        const res = await updateManager.checkAppUpdate(this.context)
        if (res.updateAvailable === 1) {
          updateManager.showUpdateDialog(this.context)
        }
      }
    } catch (err) {
      promptAction.openToast({
        message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
      })
    }
    const cloudbackupSettingDataPreferences = preferences.getPreferencesSync(this.context, {
      name: 'cloudbackupSetting'
    })
    const autoImportTables = cloudbackupSettingDataPreferences.getSync('autoImport', []) as string[]
    if (autoImportTables.includes('password')) {
      await importCloudBackupPassword()
      this.context.eventHub.emit('refreshPassword')
      promptAction.openToast({
        message: '自动导入密码云备份成功'
      })
    }
    if (autoImportTables.includes('info')) {
      await importCloudBackupInfo()
      this.context.eventHub.emit('refreshInfo')
      promptAction.openToast({
        message: '自动导入常用信息云备份成功'
      })
    }
    if (autoImportTables.includes('tag')) {
      await importCloudBackupTag()
      this.context.eventHub.emit('refreshTag')
      promptAction.openToast({
        message: '自动导入标签云备份成功'
      })
    }
    this.appInit(want)
  }

  onNewWant(want: Want) {
    this.appInit(want)
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    this.windowInit(windowStage)
  }

  onWindowStageRestore(windowStage: window.WindowStage) {
    this.windowInit(windowStage)
  }

  onBackPressed() {
    const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
      name: 'commonSetting'
    })
    const destroyWhenBackPressed = commonSettingDataPreferences.getSync('destroyWhenBackPressed', false) as boolean
    if (!destroyWhenBackPressed) {
      return true
    } else {
      return false
    }
  }

  onContinue(wantParam: Record<string, Object>) {
    if (wantParam.version !== 14) {
      promptAction.openToast({
        message: '接续失败，原因：目标端应用版本号与发起端不匹配'
      })
      return AbilityConstant.OnContinueResult.MISMATCH
    }
    return AbilityConstant.OnContinueResult.AGREE
  }

  onCollaborate() {
    const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
      name: 'commonSetting'
    })
    const acceptCollaborate = commonSettingDataPreferences.getSync('acceptCollaborate', true) as boolean
    if (acceptCollaborate) {
      return 0
    } else {
      return 1
    }
  }

  onMemoryLevel(level: AbilityConstant.MemoryLevel) {
    const debugSettingDataPreferences = preferences.getPreferencesSync(this.context, {
      name: 'debugSetting'
    })
    const showMemoryLevelChange = debugSettingDataPreferences.getSync('showMemoryLevelChange', false)
    if (showMemoryLevelChange) {
      let memoryLevel = ''
      if (level === 0) {
        memoryLevel = '适中'
      }
      if (level === 1) {
        memoryLevel = '低'
      }
      if (level === 2) {
        memoryLevel = '高'
      }
      promptAction.openToast({
        message: '当前内存占用' + memoryLevel
      })
    }
  }
}