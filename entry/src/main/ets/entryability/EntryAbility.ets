import {
  AbilityConstant,
  appRecovery,
  bundleManager,
  ConfigurationConstant,
  errorManager,
  UIAbility,
  Want,
  wantConstant
} from '@kit.AbilityKit'
import { appInfoManager, updateManager } from '@kit.AppGalleryKit'
import { preferences, relationalStore } from '@kit.ArkData'
import { promptAction, uiAppearance, window } from '@kit.ArkUI'
import { deviceInfo } from '@kit.BasicServicesKit'
import { fileIo } from '@kit.CoreFileKit'
import { netQuality } from '@kit.NetworkBoostKit'
import { connection } from '@kit.NetworkKit'
import { notificationManager } from '@kit.NotificationKit'
import { hiAppEvent } from '@kit.PerformanceAnalysisKit'
import { systemShare } from '@kit.ShareKit'
import { autoLogin } from '../common/Accesstoken'
import { importCloudBackupInfo, importCloudBackupPassword, importCloudBackupTag } from '../common/Cloudbackupimport'
import { write } from '../common/File'
import openLink from '../common/Openlink'
import request from '../common/Request'
import { autoBackupTable } from '../common/Table'

interface JsErrorObject {
  name: string,
  info: Error
}

export default class EntryAbility extends UIAbility {
  async appInit(want: Want) {
    const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
      name: 'commonSetting'
    })
    const iconMode = commonSettingDataPreferences.getSync('iconMode', 1)
    const colorMode = commonSettingDataPreferences.getSync('colorMode', 0)
    try {
      if (iconMode === 0) {
        if (colorMode === 0) {
          const systemColorMode = uiAppearance.getDarkMode()
          if (systemColorMode === 0) {
            await appInfoManager.selectDynamicIcon('dark_' + deviceInfo.deviceType)
          }
          if (systemColorMode === 1) {
            await appInfoManager.disableDynamicIcon()
          }
        }
        if (colorMode === 1) {
          await appInfoManager.disableDynamicIcon()
        }
        if (colorMode === 2) {
          await appInfoManager.selectDynamicIcon('dark_' + deviceInfo.deviceType)
        }
      }
      if (iconMode === 1) {
        await appInfoManager.disableDynamicIcon()
      }
      if (iconMode === 2) {
        await appInfoManager.selectDynamicIcon('dark_' + deviceInfo.deviceType)
      }
    } catch {
    }
    await notificationManager.setBadgeNumber(0)
    if (want.parameters?.noticeUrl) {
      await openLink(this.context, want.parameters.noticeUrl as string)
    }
    if (want.parameters?.shortcutId === 'newPassword') {
      this.context.eventHub.emit('newPassword')
    }
    if (want.parameters?.shortcutId === 'searchPassword') {
      this.context.eventHub.emit('searchPassword')
    }
    if (want.parameters?.menuHandler === 'clickMenu') {
      const uriList = want.parameters.uriList as string[]
      const fileUri = uriList[0] as string
      this.context.eventHub.emit('wantUri', fileUri)
    }
    if (want.uri) {
      if (want.uri === 'storage:///clearcache') {
        this.context.eventHub.emit('clearData')
      }
      if (want.uri.endsWith('.txt') || want.uri.endsWith('.csv') ||
      want.uri.startsWith('https://www.zhangls2512.cn/product/password')) {
        this.context.eventHub.emit('wantUri', want.uri)
      }
    }
    try {
      const sharedData = await systemShare.getSharedData(want)
      const sharedRecords = sharedData.getRecords()
      if (sharedRecords.length !== 0) {
        this.context.eventHub.emit('wantUri', sharedRecords[0].uri)
      }
    } catch {
    }
  }

  async windowInit(windowStage: window.WindowStage) {
    await windowStage.loadContent('pages/Index')
    const context = this.context
    const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
      name: 'commonSetting'
    })
    if (deviceInfo.deviceType === '2in1') {
      const windowRectAutoSave = commonSettingDataPreferences.getSync('windowRectAutoSave', false) as boolean
      await windowStage.setWindowRectAutoSave(windowRectAutoSave)
      const lastWindow = await window.getLastWindow(this.context)
      const windowTopmost = commonSettingDataPreferences.getSync('windowTopmost', false) as boolean
      await lastWindow.setWindowTopmost(windowTopmost)
    }
    if (!notificationManager.isNotificationEnabledSync()) {
      await notificationManager.requestEnableNotification(this.context)
    }
    const debugSettingDataPreferences = preferences.getPreferencesSync(this.context, {
      name: 'debugSetting'
    })
    const errorLogDir = this.context.filesDir + '/log/error/'
    errorManager.on('error', {
      async onUnhandledException(errMsg) {
        if (debugSettingDataPreferences.getSync('globalErrorShowType', 0) === 0) {
          await promptAction.openToast({
            message: 'js 运行异常：' + errMsg
          })
        }
      },
      async onException(err) {
        const object: JsErrorObject = {
          name: 'JS_ERROR',
          info: {
            name: err.name,
            message: err.message,
            stack: err.stack
          }
        }
        if (debugSettingDataPreferences.getSync('saveErrorLog', true)) {
          await write(errorLogDir + Date.now() + '.txt', JSON.stringify(object))
        }
        if (debugSettingDataPreferences.getSync('globalErrorShowType', 0) === 1) {
          context.eventHub.emit('dialog', 'js 运行异常', '名称：' + err.name + '\n信息：' + err.message)
        }
        if (debugSettingDataPreferences.getSync('autoUploadErrorLog', true) &&
        commonSettingDataPreferences.getSync('allService', true)) {
          if ((debugSettingDataPreferences.getSync('autoUploadErrorLogType', [
            'JS_ERROR',
            'APP_CRASH',
            'APP_FREEZE',
            'APP_KILLED',
            'RESOURCE_OVERLIMIT',
            'ADDRESS_SANITIZER'
          ]) as string[]).includes('JS_ERROR')) {
            const res = await request(context, '/debug/newErrorLog', {
              product: 'password',
              object: object
            })
            if (res !== 'fail') {
              context.eventHub.emit('dialog', '提示',
                '故障日志自动上传成功，故障类型：JS_ERROR。建议您依次进入“我的”>“设置”>“关于”，附带联系方式提交意见反馈或联系人工客服，便于开发者排查、处理问题。')
            }
          }
        }
      }
    })
    errorManager.on('unhandledRejection', async (err: Error) => {
      if (err.message !== 'cancel') {
        const object: JsErrorObject = {
          name: 'JS_ERROR',
          info: {
            name: err.name,
            message: err.message,
            stack: err.stack
          }
        }
        if (debugSettingDataPreferences.getSync('saveErrorLog', true)) {
          await write(errorLogDir + Date.now() + '.txt', JSON.stringify(object))
        }
        if (debugSettingDataPreferences.getSync('globalErrorShowType', 0) === 0) {
          await promptAction.openToast({
            message: 'js 运行异常，错误名称：' + err.name + '，错误信息：' + err.message
          })
        }
        if (debugSettingDataPreferences.getSync('globalErrorShowType', 0) === 1) {
          this.context.eventHub.emit('dialog', 'js 运行异常', '名称：' + err.name + '\n信息：' + err.message)
        }
        if (debugSettingDataPreferences.getSync('autoUploadErrorLog', true) &&
        commonSettingDataPreferences.getSync('allService', true)) {
          if ((debugSettingDataPreferences.getSync('autoUploadErrorLogType', [
            'JS_ERROR',
            'APP_CRASH',
            'APP_FREEZE',
            'APP_KILLED',
            'RESOURCE_OVERLIMIT',
            'ADDRESS_SANITIZER'
          ]) as string[]).includes('JS_ERROR')) {
            const res = await request(context, '/debug/newErrorLog', {
              product: 'password',
              object: object
            })
            if (res !== 'fail') {
              this.context.eventHub.emit('dialog', '提示',
                '故障日志自动上传成功，故障类型：JS_ERROR。建议您依次进入“我的”>“设置”>“关于”，附带联系方式提交意见反馈或联系人工客服，便于开发者排查、处理问题。')
            }
          }
        }
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
        if (debugSettingDataPreferences.getSync('saveErrorLog', true)) {
          const promises = appEventGroups.map(async (item) => {
            await write(errorLogDir + Date.now() + '.txt', JSON.stringify(item))
          })
          await Promise.all(promises)
        }
        if (debugSettingDataPreferences.getSync('autoUploadErrorLog', true) &&
        commonSettingDataPreferences.getSync('allService', true)) {
          const promises = appEventGroups.map(async (item) => {
            if ((debugSettingDataPreferences.getSync('autoUploadErrorLogType', [
              'JS_ERROR',
              'APP_CRASH',
              'APP_FREEZE',
              'APP_KILLED',
              'RESOURCE_OVERLIMIT',
              'ADDRESS_SANITIZER'
            ]) as string[]).includes(item.name)) {
              const res = await request(context, '/debug/newErrorLog', {
                product: 'password',
                object: item
              })
              if (res !== 'fail') {
                this.context.eventHub.emit('dialog', '提示', '故障日志自动上传成功，故障类型：' + item.name +
                  '。建议您依次进入“我的”>“设置”>“关于”，附带联系方式提交意见反馈或联系人工客服，便于开发者排查、处理问题。')
              }
            }
          })
          await Promise.all(promises)
        }
      }
    })
    const netConnection = connection.createNetConnection()
    netConnection.register(() => {
    })
    netConnection.on('netAvailable', async (data) => {
      if (debugSettingDataPreferences.getSync('showNetAvailableStatusChange', false)) {
        await promptAction.openToast({
          message: '网络可用，数据网络句柄：' + data.netId
        })
      }
    })
    netConnection.on('netUnavailable', async () => {
      if (debugSettingDataPreferences.getSync('showNetAvailableStatusChange', false)) {
        await promptAction.openToast({
          message: '网络不可用'
        })
      }
    })
    netConnection.on('netBlockStatusChange', (data) => {
      if (debugSettingDataPreferences.getSync('showNetBlockStatusChange', false)) {
        this.context.eventHub.emit('dialog', '网络阻塞状态变化',
          '数据网络句柄：' + data.netHandle.netId + '\n是否堵塞：' + data.blocked ? '是' : '否')
      }
    })
    netConnection.on('netLost', async (data) => {
      if (debugSettingDataPreferences.getSync('showNetLost', false)) {
        await promptAction.openToast({
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
        this.context.eventHub.emit('dialog', '网络能力变化',
          '数据网络句柄：' + data.netHandle.netId + '\n上行带宽：' + data.netCap.linkUpBandwidthKbps +
            ' KB/s\n下行带宽：' + data.netCap.linkDownBandwidthKbps + ' KB/s\n网络类型：' + netBearType)
      }
    })
    netQuality.on('netQosChange', async (list) => {
      if (list.length > 0) {
        const data = list[0]
        if (debugSettingDataPreferences.getSync('showNetQosChange', false)) {
          const pathType = data.pathType === 0 ? '蜂窝主卡' :
            data.pathType === 1 ? '蜂窝副卡' :
              data.pathType === 2 ? '主 Wi-Fi' :
                data.pathType === 3 ? '副 Wi-Fi' :
                  'undefined'
          this.context.eventHub.emit('dialog', '网络质量变化',
            '数据路径：' + pathType + '\n上行带宽：' + data.linkUpBandwidth + ' bps\n下行带宽：' + data.linkDownBandwidth +
              ' bps\n上行速率：' + data.linkUpRate + ' bps\n下行速率：' + data.linkDownRate + '\nRTT 时延：' + data.rttMs +
              ' ms\n上行发送空口缓冲时延：' + data.linkUpBufferDelayMs + ' ms\n上行发送空口缓冲时延占总缓冲时间的比例：' +
            data.linkUpBufferCongestionPercent + '%')
        }
        if (debugSettingDataPreferences.getSync('autoReportHighLatency', true) &&
          data.rttMs >= debugSettingDataPreferences.getSync('highLatencyThreshold', 200)) {
          netQuality.reportQoe({
            serviceType: 'default',
            qoeType: 'highLatency'
          })
          await promptAction.openToast({
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
          this.context.eventHub.emit('dialog', '网络场景变化',
            '数据路径：' + pathType + '\n场景类型：' + scene + '\n建议的数传策略：' + dataSpeedSimpleAction +
              '\n最近一次的弱信号预测是否有效：' + isLastPredictionValid + '\n预计多长时间进入弱信号：' +
              data.weakSignalPrediction?.startTime + ' s\n预计在弱信号区域停留时长：' +
              data.weakSignalPrediction?.duration + ' s')
        }
      }
    })
    if (debugSettingDataPreferences.getSync('deleteErrorLogBeforeUpdateTimeWhenAppLaunch', true)) {
      const bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT)
      const updateTime = bundleInfo.updateTime
      if (fileIo.accessSync(errorLogDir)) {
        const errorLogFileName = await fileIo.listFile(errorLogDir)
        const errorLogFilePath = errorLogFileName.map(item => errorLogDir + item)
        const promises = errorLogFilePath.map(async (item) => {
          const time = Number(item.replace(errorLogDir, '').replace('.txt', ''))
          if (time < updateTime) {
            await fileIo.unlink(item)
          }
        })
        await Promise.all(promises)
      }
    }
    let netConnected = false
    let currentNetworkBearerType = -1
    const netHandle = connection.getDefaultNetSync()
    if (netHandle.netId !== 0) {
      netConnected = true
      currentNetworkBearerType = connection.getNetCapabilitiesSync(netHandle).bearerTypes[0]
    }
    if (netConnected) {
      const checkVersionUpdate = commonSettingDataPreferences.getSync('checkVersionUpdate', 1)
      if (checkVersionUpdate === 2 || (checkVersionUpdate === 1 && currentNetworkBearerType !== 0)) {
        try {
          const res = await updateManager.checkAppUpdate(this.context)
          if (res.updateAvailable === 1) {
            await updateManager.showUpdateDialog(this.context)
          }
        } catch (err) {
          await promptAction.openToast({
            message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
          })
        }
      }
    }
    await autoLogin(context)
    const cloudbackupSettingDataPreferences = preferences.getPreferencesSync(this.context, {
      name: 'cloudbackupSetting'
    })
    const autoImportTables = cloudbackupSettingDataPreferences.getSync('autoImport', []) as string[]
    if (autoImportTables.includes('password')) {
      const res = await importCloudBackupPassword(context)
      if (res === 'success') {
        this.context.eventHub.emit('refreshPassword')
        await promptAction.openToast({
          message: '自动导入密码云备份成功'
        })
      }
    }
    if (autoImportTables.includes('info')) {
      const res = await importCloudBackupInfo(context)
      if (res === 'success') {
        this.context.eventHub.emit('refreshInfo')
        await promptAction.openToast({
          message: '自动导入常用信息云备份成功'
        })
      }
    }
    if (autoImportTables.includes('tag')) {
      const res = await importCloudBackupTag(context)
      if (res === 'success') {
        this.context.eventHub.emit('refreshTag')
        await promptAction.openToast({
          message: '自动导入标签云备份成功'
        })
      }
    }
  }

  async onCreate(want: Want) {
    const passwordRdbStore = await relationalStore.getRdbStore(this.context, {
      name: 'password',
      securityLevel: 4,
      encrypt: true,
      allowRebuild: true
    })
    await passwordRdbStore.executeSql('CREATE TABLE IF NOT EXISTS password(id INTEGER PRIMARY KEY AUTOINCREMENT,name,info,tag,updateTime,cloudBackupTime)')
    await passwordRdbStore.executeSql('CREATE INDEX IF NOT EXISTS name ON password(name)')
    const infoRdbStore = await relationalStore.getRdbStore(this.context, {
      name: 'info',
      securityLevel: 4,
      encrypt: true,
      allowRebuild: true
    })
    await infoRdbStore.executeSql('CREATE TABLE IF NOT EXISTS info(id INTEGER PRIMARY KEY AUTOINCREMENT,type,value,updateTime,cloudBackupTime,UNIQUE(type,value))')
    await infoRdbStore.executeSql('CREATE INDEX IF NOT EXISTS type ON info(type)')
    const tagRdbStore = await relationalStore.getRdbStore(this.context, {
      name: 'tag',
      securityLevel: 1,
      encrypt: true,
      allowRebuild: true
    })
    await tagRdbStore.executeSql('CREATE TABLE IF NOT EXISTS tag(id INTEGER PRIMARY KEY AUTOINCREMENT,value,color,updateTime,cloudBackupTime,UNIQUE(value,color))')
    await tagRdbStore.executeSql('CREATE INDEX IF NOT EXISTS value ON tag(value)')
    passwordRdbStore.on('dataChange', relationalStore.SubscribeType.SUBSCRIBE_TYPE_REMOTE, async (deviceIds) => {
      const promises = deviceIds.map(async (item) => {
        const tableName = await passwordRdbStore.obtainDistributedTableName(item, 'password')
        const predicates = new relationalStore.RdbPredicates(tableName)
        const resultSet = await passwordRdbStore.query(predicates)
        const idIndex = resultSet.getColumnIndex('id')
        const nameIndex = resultSet.getColumnIndex('name')
        const infoIndex = resultSet.getColumnIndex('info')
        const tagIndex = resultSet.getColumnIndex('tag')
        const updateTimeIndex = resultSet.getColumnIndex('updateTime')
        const cloudBackupTimeIndex = resultSet.getColumnIndex('cloudBackupTime')
        while (resultSet.goToNextRow()) {
          try {
            await passwordRdbStore.insert('password', {
              id: resultSet.getValue(idIndex),
              name: String(resultSet.getValue(nameIndex)),
              info: resultSet.getValue(infoIndex),
              tag: resultSet.getValue(tagIndex),
              updateTime: resultSet.getValue(updateTimeIndex),
              cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex)
            }, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
          } catch (err) {
            if (err.code !== 14800032) {
              await promptAction.openToast({
                message: '发生错误，错误码：' + err.code
              })
            }
            if (err.code === 14800032) {
              await promptAction.openToast({
                message: '导入失败，原因：已存在'
              })
            }
          }
        }
        resultSet.close()
      })
      await Promise.all(promises)
      this.context.eventHub.emit('refreshPassword')
      await autoBackupTable(this.context, 'password')
    })
    infoRdbStore.on('dataChange', relationalStore.SubscribeType.SUBSCRIBE_TYPE_REMOTE, async (deviceIds) => {
      const promises = deviceIds.map(async (item) => {
        const tableName = await infoRdbStore.obtainDistributedTableName(item, 'info')
        const predicates = new relationalStore.RdbPredicates(tableName)
        const resultSet = await infoRdbStore.query(predicates)
        const idIndex = resultSet.getColumnIndex('id')
        const typeIndex = resultSet.getColumnIndex('type')
        const valueIndex = resultSet.getColumnIndex('value')
        const updateTimeIndex = resultSet.getColumnIndex('updateTime')
        const cloudBackupTimeIndex = resultSet.getColumnIndex('cloudBackupTime')
        while (resultSet.goToNextRow()) {
          try {
            await infoRdbStore.insert('info', {
              id: resultSet.getValue(idIndex),
              type: String(resultSet.getValue(typeIndex)),
              value: String(resultSet.getValue(valueIndex)),
              updateTime: resultSet.getValue(updateTimeIndex),
              cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex)
            }, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
          } catch (err) {
            if (err.code !== 14800032) {
              await promptAction.openToast({
                message: '发生错误，错误码：' + err.code
              })
            }
            if (err.code === 14800032) {
              await promptAction.openToast({
                message: '同步失败，原因：已存在'
              })
            }
          }
        }
        resultSet.close()
      })
      await Promise.all(promises)
      this.context.eventHub.emit('refreshInfo')
      await autoBackupTable(this.context, 'info')
    })
    tagRdbStore.on('dataChange', relationalStore.SubscribeType.SUBSCRIBE_TYPE_REMOTE, async (deviceIds) => {
      const promises = deviceIds.map(async (item) => {
        const tableName = await tagRdbStore.obtainDistributedTableName(item, 'tag')
        const predicates = new relationalStore.RdbPredicates(tableName)
        const resultSet = await tagRdbStore.query(predicates)
        const idIndex = resultSet.getColumnIndex('id')
        const valueIndex = resultSet.getColumnIndex('value')
        const colorIndex = resultSet.getColumnIndex('color')
        const updateTimeIndex = resultSet.getColumnIndex('updateTime')
        const cloudBackupTimeIndex = resultSet.getColumnIndex('cloudBackupTime')
        while (resultSet.goToNextRow()) {
          try {
            await tagRdbStore.insert('tag', {
              id: resultSet.getValue(idIndex),
              value: String(resultSet.getValue(valueIndex)),
              color: String(resultSet.getValue(colorIndex)),
              updateTime: resultSet.getValue(updateTimeIndex),
              cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex)
            }, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
          } catch (err) {
            if (err.code !== 14800032) {
              await promptAction.openToast({
                message: '发生错误，错误码：' + err.code
              })
            }
            if (err.code === 14800032) {
              await promptAction.openToast({
                message: '同步失败，原因：已存在'
              })
            }
          }
        }
        resultSet.close()
      })
      await Promise.all(promises)
      this.context.eventHub.emit('refreshTag')
      await autoBackupTable(this.context, 'tag')
    })
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
    const applicationContext = this.context.getApplicationContext()
    const colorMode = commonSettingDataPreferences.getSync('colorMode', 0)
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
    if (deviceInfo.deviceType !== 'tablet') {
      const processCache = debugSettingDataPreferences.getSync('processCache', true) as boolean
      applicationContext.setSupportedProcessCache(processCache)
    }
    await this.appInit(want)
  }

  async onNewWant(want: Want) {
    await this.appInit(want)
  }

  async onWindowStageCreate(windowStage: window.WindowStage) {
    await this.windowInit(windowStage)
  }

  async onWindowStageRestore(windowStage: window.WindowStage) {
    await this.windowInit(windowStage)
  }

  onBackPressed() {
    const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
      name: 'commonSetting'
    })
    const destroyWhenBackPressed = commonSettingDataPreferences.getSync('destroyWhenBackPressed', false)
    if (!destroyWhenBackPressed) {
      return true
    } else {
      return false
    }
  }

  async onContinue(wantParam: Record<string, Object>) {
    try {
      if (wantParam.version !== 39) {
        await promptAction.openToast({
          message: '接续失败，原因：目标端应用版本号与发起端不匹配'
        })
        return AbilityConstant.OnContinueResult.MISMATCH
      }
      const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
        name: 'commonSetting'
      })
      const exitAfterContinue = commonSettingDataPreferences.getSync('exitAfterContinue', true)
      wantParam[wantConstant.Params.SUPPORT_CONTINUE_SOURCE_EXIT_KEY] = exitAfterContinue
      return AbilityConstant.OnContinueResult.AGREE
    } catch {
      return AbilityConstant.OnContinueResult.REJECT
    }
  }

  onCollaborate() {
    const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
      name: 'commonSetting'
    })
    const acceptCollaborate = commonSettingDataPreferences.getSync('acceptCollaborate', true)
    if (!acceptCollaborate) {
      return 1
    } else {
      return 0
    }
  }

  async onMemoryLevel(level: AbilityConstant.MemoryLevel) {
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
      await promptAction.openToast({
        message: '当前内存占用' + memoryLevel
      })
    }
  }
}