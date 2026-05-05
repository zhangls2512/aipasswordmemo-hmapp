import {
  AbilityConstant,
  appRecovery,
  bundleManager,
  ConfigurationConstant,
  contextConstant,
  errorManager,
  UIAbility,
  Want,
  wantConstant
} from '@kit.AbilityKit'
import { appInfoManager, updateManager } from '@kit.AppGalleryKit'
import { relationalStore, uniformTypeDescriptor } from '@kit.ArkData'
import { promptAction, uiAppearance, window } from '@kit.ArkUI'
import { commonEventManager, deviceInfo } from '@kit.BasicServicesKit'
import { fileIo, fileUri } from '@kit.CoreFileKit'
import { statusBarManager } from '@kit.DeskTopExtensionKit'
import { image } from '@kit.ImageKit'
import { netQuality } from '@kit.NetworkBoostKit'
import { connection } from '@kit.NetworkKit'
import { notificationManager } from '@kit.NotificationKit'
import { hiAppEvent } from '@kit.PerformanceAnalysisKit'
import { harmonyShare, systemShare } from '@kit.ShareKit'
import { autoLogin } from '../common/Account'
import { clearNouseData } from '../common/Clearnousedata'
import { importCloudBackupInfo, importCloudBackupPassword, importCloudBackupTag } from '../common/Cloudbackupimport'
import { deleteData } from '../common/Datachange'
import { write } from '../common/File'
import openLink from '../common/Openlink'
import { getFlushPreference, getTempPreference, setTempPreference } from '../common/Preference'
import { autoBackupTable, autoSyncTable } from '../common/Table'

interface JsErrorObject {
  name: string,
  info: Error
}

interface MenuCodeEventData {
  data: EventData
}

interface EventData {
  menuCode: string
}

export default class EntryAbility extends UIAbility {
  async appInit(want: Want) {
    const iconMode = getFlushPreference(this.context, 'commonSetting', 'iconMode', 1)
    const colorMode = getFlushPreference(this.context, 'commonSetting', 'colorMode', 0)
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
    if (want.parameters?.action === 'passwordInfo') {
      this.context.eventHub.emit('passwordInfo', Number(want.parameters.passwordId))
    }
    if (want.parameters?.menuHandler === 'clickMenu1' || want.parameters?.menuHandler === 'clickMenu2' ||
      want.parameters?.menuHandler === 'clickMenu3') {
      const uriList = want.parameters.uriList as string[]
      const fileUri = uriList[0] as string
      this.context.eventHub.emit('wantUri', fileUri)
    }
    if (want.parameters?.linkFeature) {
      const linkFeature = want.parameters.linkFeature
      if (linkFeature === 'AppStorageMgmt') {
        this.context.eventHub.emit('clearData')
      }
      if (linkFeature === 'AppNotificationMgmt') {
        this.context.eventHub.emit('notice')
      }
    }
    if (want.uri && !want.parameters?.linkFeature) {
      this.context.eventHub.emit('wantUri', want.uri)
    }
    try {
      const sharedData = await systemShare.getSharedData(want)
      const sharedRecords = sharedData.getRecords()
      if (sharedRecords.length > 0) {
        this.context.eventHub.emit('wantUri', sharedRecords[0].uri)
      }
    } catch {
    }
    if (deviceInfo.deviceType === '2in1') {
      const lastWindow = await window.getLastWindow(this.context)
      harmonyShare.on('dataReceive', {
        windowId: lastWindow.getWindowProperties().id,
        capabilities: [
          {
            utd: uniformTypeDescriptor.UniformDataType.PLAIN_TEXT,
            maxSupportedCount: 1
          },
          {
            utd: uniformTypeDescriptor.UniformDataType.COMMA_SEPARATED_VALUES_TEXT,
            maxSupportedCount: 1
          },
          {
            utd: uniformTypeDescriptor.UniformDataType.ZIP_ARCHIVE,
            maxSupportedCount: 1
          }
        ]
      }, async (receivableTarget) => {
        await receivableTarget.receive(fileUri.getUriFromPath(this.context.tempDir), {
          onDataReceived: (sharedData) => {
            const sharedRecords = sharedData.getRecords()
            this.context.eventHub.emit('wantUri', sharedRecords[0].uri)
          }
        })
      })
    }
  }

  async windowInit(windowStage: window.WindowStage) {
    await windowStage.getMainWindowSync().setWindowLayoutFullScreen(true)
    await windowStage.loadContent('pages/Index')
    const context = this.context
    if (deviceInfo.deviceType === '2in1') {
      const windowRectAutoSave =
        getFlushPreference(this.context, 'commonSetting', 'windowRectAutoSave', false) as boolean
      await windowStage.setWindowRectAutoSave(windowRectAutoSave)
      const lastWindow = await window.getLastWindow(this.context)
      const windowTopmost = getFlushPreference(this.context, 'commonSetting', 'windowTopmost', false) as boolean
      await lastWindow.setWindowTopmost(windowTopmost)
    }
    if (!notificationManager.isNotificationEnabledSync()) {
      await notificationManager.requestEnableNotification(this.context)
    }
    const errorLogDir = this.context.filesDir + '/log/error/'
    errorManager.on('error', {
      async onUnhandledException(errMsg) {
        if (getFlushPreference(this.context, 'debugSetting', 'globalErrorShowType', 0) === 0) {
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
        if (getFlushPreference(this.context, 'debugSetting', 'saveErrorLog', true)) {
          await write(errorLogDir + Date.now() + '.txt', JSON.stringify(object))
        }
        if (getFlushPreference(this.context, 'debugSetting', 'globalErrorShowType', 0) === 1) {
          context.eventHub.emit('dialog', 'js 运行异常', '名称：' + err.name + '\n信息：' + err.message)
        }
        if (getFlushPreference(this.context, 'debugSetting', 'autoUploadErrorLog', true) &&
          getFlushPreference(this.context, 'commonSetting', 'allService', true)) {
          if ((getFlushPreference(this.context, 'debugSetting', 'autoUploadErrorLogType',
            ['JS_ERROR', 'APP_CRASH']) as string[]).includes('JS_ERROR')) {
            context.eventHub.emit('uploadErrorLog', object.name, JSON.stringify(object))
          }
        }
      }
    })
    errorManager.on('unhandledRejection', async (err: Error) => {
      if (err.message !== 'cancel' && err.message !== 'Default error message') {
        const object: JsErrorObject = {
          name: 'JS_ERROR',
          info: {
            name: err.name,
            message: err.message,
            stack: err.stack
          }
        }
        if (getFlushPreference(this.context, 'debugSetting', 'saveErrorLog', true)) {
          await write(errorLogDir + Date.now() + '.txt', JSON.stringify(object))
        }
        if (getFlushPreference(this.context, 'debugSetting', 'globalErrorShowType', 0) === 0) {
          await promptAction.openToast({
            message: 'js 运行异常，错误名称：' + err.name + '，错误信息：' + err.message
          })
        }
        if (getFlushPreference(this.context, 'debugSetting', 'globalErrorShowType', 0) === 1) {
          this.context.eventHub.emit('dialog', 'js 运行异常', '名称：' + err.name + '\n信息：' + err.message)
        }
        if (getFlushPreference(this.context, 'debugSetting', 'autoUploadErrorLog', true) &&
          getFlushPreference(this.context, 'commonSetting', 'allService', true)) {
          if ((getFlushPreference(this.context, 'debugSetting', 'autoUploadErrorLogType',
            ['JS_ERROR', 'APP_CRASH']) as string[]).includes('JS_ERROR')) {
            this.context.eventHub.emit('uploadErrorLog', object.name, JSON.stringify(object))
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
        if (getFlushPreference(this.context, 'debugSetting', 'saveErrorLog', true)) {
          const promises = appEventGroups.map(async (item) => {
            await write(errorLogDir + Date.now() + '.txt', JSON.stringify(item))
          })
          await Promise.all(promises)
        }
        if (getFlushPreference(this.context, 'debugSetting', 'autoUploadErrorLog', true) &&
          getFlushPreference(this.context, 'commonSetting', 'allService', true)) {
          appEventGroups.forEach(item => {
            if ((getFlushPreference(this.context, 'debugSetting', 'autoUploadErrorLogType',
              ['JS_ERROR', 'APP_CRASH']) as string[]).includes(item.name)) {
              this.context.eventHub.emit('uploadErrorLog', item.name, JSON.stringify(item))
            }
          })
        }
      }
    })
    const netConnection = connection.createNetConnection()
    netConnection.register(() => {
    })
    netConnection.on('netAvailable', async (data) => {
      if (getFlushPreference(this.context, 'debugSetting', 'showNetAvailableStatusChange', false)) {
        await promptAction.openToast({
          message: '网络可用，数据网络句柄：' + data.netId
        })
      }
    })
    netConnection.on('netUnavailable', async () => {
      if (getFlushPreference(this.context, 'debugSetting', 'showNetAvailableStatusChange', false)) {
        await promptAction.openToast({
          message: '网络不可用'
        })
      }
    })
    netConnection.on('netBlockStatusChange', (data) => {
      if (getFlushPreference(this.context, 'debugSetting', 'showNetBlockStatusChange', false)) {
        this.context.eventHub.emit('dialog', '网络阻塞状态变化',
          '数据网络句柄：' + data.netHandle.netId + '\n是否堵塞：' + data.blocked ? '是' : '否')
      }
    })
    netConnection.on('netLost', async (data) => {
      if (getFlushPreference(this.context, 'debugSetting', 'showNetLost', false)) {
        await promptAction.openToast({
          message: '网络丢失，数据网络句柄：' + data.netId
        })
      }
    })
    netConnection.on('netCapabilitiesChange', (data) => {
      if (getFlushPreference(this.context, 'debugSetting', 'showNetCapabilitiesChange', false)) {
        const netBearType = data.netCap.bearerTypes.includes(connection.NetBearType.BEARER_CELLULAR) ? '蜂窝' :
          data.netCap.bearerTypes.includes(connection.NetBearType.BEARER_WIFI) ? 'Wi-Fi' :
            data.netCap.bearerTypes.includes(connection.NetBearType.BEARER_BLUETOOTH) ? '蓝牙' :
              data.netCap.bearerTypes.includes(connection.NetBearType.BEARER_ETHERNET) ? '以太网' :
                data.netCap.bearerTypes.includes(connection.NetBearType.BEARER_VPN) ? 'VPN' : 'undefined'
        this.context.eventHub.emit('dialog', '网络能力变化',
          '数据网络句柄：' + data.netHandle.netId + '\n上行带宽：' + data.netCap.linkUpBandwidthKbps +
            ' KB/s\n下行带宽：' + data.netCap.linkDownBandwidthKbps + ' KB/s\n网络类型：' + netBearType)
      }
    })
    netQuality.on('netQosChange', async (list) => {
      if (list.length > 0) {
        const data = list[0]
        if (getFlushPreference(this.context, 'debugSetting', 'showNetQosChange', false)) {
          const pathType = data.pathType === netQuality.PathType.CELLULAR_PRIMARY ? '蜂窝主卡' :
            data.pathType === netQuality.PathType.CELLULAR_SECONDARY ? '蜂窝副卡' :
              data.pathType === netQuality.PathType.WIFI_PRIMARY ? '主 Wi-Fi' :
                data.pathType === netQuality.PathType.WIFI_SECONDARY ? '副 Wi-Fi' : 'undefined'
          this.context.eventHub.emit('dialog', '网络质量变化',
            '数据路径：' + pathType + '\n上行带宽：' + data.linkUpBandwidth + ' bps\n下行带宽：' + data.linkDownBandwidth +
              ' bps\n上行速率：' + data.linkUpRate + ' bps\n下行速率：' + data.linkDownRate + '\nRTT 时延：' + data.rttMs +
              ' ms\n上行发送空口缓冲时延：' + data.linkUpBufferDelayMs + ' ms\n上行发送空口缓冲时延占总缓冲时间的比例：' +
              data.linkUpBufferCongestionPercent + '%')
        }
        if (getFlushPreference(this.context, 'debugSetting', 'autoReportHighLatency', true) &&
          data.rttMs >= getFlushPreference(this.context, 'debugSetting', 'highLatencyThreshold', 200)) {
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
        if (getFlushPreference(this.context, 'debugSetting', 'showNetSceneChange', false)) {
          const pathType = data.pathType === netQuality.PathType.CELLULAR_PRIMARY ? '蜂窝主卡' :
            data.pathType === netQuality.PathType.CELLULAR_SECONDARY ? '蜂窝副卡' :
              data.pathType === netQuality.PathType.WIFI_PRIMARY ? '主 Wi-Fi' :
                data.pathType === netQuality.PathType.WIFI_SECONDARY ? '副 Wi-Fi' : 'undefined'
          const scene = data.scene === 'normal' ? '正常' :
            data.scene === 'congestion' ? '拥塞' :
              data.scene === 'frequentHandover' ? '小区切换频繁' :
                data.scene === 'weakSignal' ? '弱信号' : 'undefined'
          const dataSpeedSimpleAction = data.recommendedAction === 'doCaching' ? '做缓存动作' :
            data.recommendedAction === 'suspendData' ? '停止发包' :
              data.recommendedAction === 'decreaseData' ? '降低发包速率' :
                data.recommendedAction === 'increaseData' ? '增加发包速率' :
                  data.recommendedAction === 'keepData' ? '保持当前发包速率' : 'undefined'
          const isLastPredictionValid = data.weakSignalPrediction?.isLastPredictionValid ? '是' : '否'
          this.context.eventHub.emit('dialog', '网络场景变化',
            '数据路径：' + pathType + '\n场景类型：' + scene + '\n建议的数传策略：' + dataSpeedSimpleAction +
              '\n最近一次的弱信号预测是否有效：' + isLastPredictionValid + '\n预计多长时间进入弱信号：' +
              data.weakSignalPrediction?.startTime + ' s\n预计在弱信号区域停留时长：' +
              data.weakSignalPrediction?.duration + ' s')
        }
      }
    })
    if (getFlushPreference(this.context, 'debugSetting', 'deleteErrorLogBeforeUpdateTimeWhenAppLaunch', true)) {
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
      const checkVersionUpdate = getFlushPreference(this.context, 'commonSetting', 'checkVersionUpdate', 1)
      if (checkVersionUpdate === 2 ||
        (checkVersionUpdate === 1 && currentNetworkBearerType !== connection.NetBearType.BEARER_CELLULAR)) {
        try {
          const res = await updateManager.checkAppUpdate(this.context)
          if (res.updateAvailable === updateManager.UpdateAvailableCode.LATER_VERSION_EXIST) {
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
    const autoImportTables = getFlushPreference(this.context, 'cloudbackupSetting', 'autoImport', []) as string[]
    if (autoImportTables.includes('password')) {
      const res = await importCloudBackupPassword(context, relationalStore.ConflictResolution.ON_CONFLICT_IGNORE)
      if (res === 'success') {
        this.context.eventHub.emit('refreshPassword')
        await promptAction.openToast({
          message: '自动导入密码云备份成功'
        })
      }
    }
    if (autoImportTables.includes('info')) {
      const res = await importCloudBackupInfo(context, relationalStore.ConflictResolution.ON_CONFLICT_IGNORE)
      if (res === 'success') {
        this.context.eventHub.emit('refreshInfo')
        await promptAction.openToast({
          message: '自动导入常用信息云备份成功'
        })
      }
    }
    if (autoImportTables.includes('tag')) {
      const res = await importCloudBackupTag(context, relationalStore.ConflictResolution.ON_CONFLICT_IGNORE)
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
      securityLevel: relationalStore.SecurityLevel.S4,
      encrypt: true,
      allowRebuild: true
    })
    await passwordRdbStore.executeSql('CREATE TABLE IF NOT EXISTS password(id INTEGER PRIMARY KEY AUTOINCREMENT,name,info,tag,updateTime,cloudBackupTime)')
    await passwordRdbStore.executeSql('CREATE INDEX IF NOT EXISTS name ON password(name)')
    const infoRdbStore = await relationalStore.getRdbStore(this.context, {
      name: 'info',
      securityLevel: relationalStore.SecurityLevel.S4,
      encrypt: true,
      allowRebuild: true
    })
    await infoRdbStore.executeSql('CREATE TABLE IF NOT EXISTS info(id INTEGER PRIMARY KEY AUTOINCREMENT,type,value,updateTime,cloudBackupTime,UNIQUE(type,value))')
    await infoRdbStore.executeSql('CREATE INDEX IF NOT EXISTS type ON info(type)')
    const tagRdbStore = await relationalStore.getRdbStore(this.context, {
      name: 'tag',
      securityLevel: relationalStore.SecurityLevel.S1,
      encrypt: true,
      allowRebuild: true
    })
    await tagRdbStore.executeSql('CREATE TABLE IF NOT EXISTS tag(id INTEGER PRIMARY KEY AUTOINCREMENT,value,color,updateTime,cloudBackupTime,UNIQUE(value,color))')
    await tagRdbStore.executeSql('CREATE INDEX IF NOT EXISTS value ON tag(value)')
    const huaweiCloudSyncRdbStore = await relationalStore.getRdbStore(this.context, {
      name: 'huaweicloudsync',
      securityLevel: relationalStore.SecurityLevel.S3,
      encrypt: true,
      allowRebuild: true
    })
    await huaweiCloudSyncRdbStore.executeSql('CREATE TABLE IF NOT EXISTS password(id TEXT PRIMARY KEY,name TEXT,info TEXT,tag TEXT,updateTime INTEGER,cloudBackupTime TEXT)')
    await huaweiCloudSyncRdbStore.executeSql('CREATE TABLE IF NOT EXISTS info(id TEXT PRIMARY KEY,type TEXT,value TEXT,updateTime INTEGER,cloudBackupTime TEXT)')
    await huaweiCloudSyncRdbStore.executeSql('CREATE TABLE IF NOT EXISTS tag(id TEXT PRIMARY KEY,value TEXT,color TEXT,updateTime INTEGER,cloudBackupTime TEXT)')
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
        const idsa: number[] = []
        while (resultSet.goToNextRow()) {
          idsa.push(resultSet.getValue(idIndex) as number)
          passwordRdbStore.insertSync('password', {
            id: resultSet.getValue(idIndex),
            name: String(resultSet.getValue(nameIndex)),
            info: resultSet.getValue(infoIndex),
            tag: resultSet.getValue(tagIndex),
            updateTime: resultSet.getValue(updateTimeIndex),
            cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex)
          }, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
          huaweiCloudSyncRdbStore.insertSync('password', {
            id: String(resultSet.getValue(idIndex)),
            name: String(resultSet.getValue(nameIndex)),
            info: resultSet.getValue(infoIndex),
            tag: resultSet.getValue(tagIndex),
            updateTime: resultSet.getValue(updateTimeIndex),
            cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex)
          }, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
        }
        const idsb: number[] = []
        const predicatesb = new relationalStore.RdbPredicates('password')
        const resultSetb = await passwordRdbStore.query(predicatesb)
        while (resultSetb.goToNextRow()) {
          idsb.push(resultSetb.getValue(resultSetb.getColumnIndex('id')) as number)
        }
        resultSet.close()
        resultSetb.close()
        const deleteIds = idsb.filter(item => !idsa.includes(item))
        const deletepromises = deleteIds.map(async (item) => {
          await deleteData(this.context, 'password', item)
        })
        await Promise.all(deletepromises)
        await autoSyncTable(this.context, 'password', item)
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
        const idsa: number[] = []
        while (resultSet.goToNextRow()) {
          idsa.push(resultSet.getValue(idIndex) as number)
          infoRdbStore.insertSync('info', {
            id: resultSet.getValue(idIndex),
            type: String(resultSet.getValue(typeIndex)),
            value: String(resultSet.getValue(valueIndex)),
            updateTime: resultSet.getValue(updateTimeIndex),
            cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex)
          }, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
          huaweiCloudSyncRdbStore.insertSync('info', {
            id: String(resultSet.getValue(idIndex)),
            type: String(resultSet.getValue(typeIndex)),
            value: String(resultSet.getValue(valueIndex)),
            updateTime: resultSet.getValue(updateTimeIndex),
            cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex)
          }, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
        }
        const idsb: number[] = []
        const predicatesb = new relationalStore.RdbPredicates('info')
        const resultSetb = await infoRdbStore.query(predicatesb)
        while (resultSetb.goToNextRow()) {
          idsb.push(resultSetb.getValue(resultSetb.getColumnIndex('id')) as number)
        }
        resultSet.close()
        resultSetb.close()
        const deleteIds = idsb.filter(item => !idsa.includes(item))
        const deletepromises = deleteIds.map(async (item) => {
          await deleteData(this.context, 'info', item)
        })
        await Promise.all(deletepromises)
        await autoSyncTable(this.context, 'info', item)
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
        const idsa: number[] = []
        while (resultSet.goToNextRow()) {
          idsa.push(resultSet.getValue(idIndex) as number)
          tagRdbStore.insertSync('tag', {
            id: resultSet.getValue(idIndex),
            value: String(resultSet.getValue(valueIndex)),
            color: String(resultSet.getValue(colorIndex)),
            updateTime: resultSet.getValue(updateTimeIndex),
            cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex)
          }, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
          huaweiCloudSyncRdbStore.insertSync('tag', {
            id: String(resultSet.getValue(idIndex)),
            value: String(resultSet.getValue(valueIndex)),
            color: String(resultSet.getValue(colorIndex)),
            updateTime: resultSet.getValue(updateTimeIndex),
            cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex)
          }, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
        }
        const idsb: number[] = []
        const predicatesb = new relationalStore.RdbPredicates('tag')
        const resultSetb = await tagRdbStore.query(predicatesb)
        while (resultSetb.goToNextRow()) {
          idsb.push(resultSetb.getValue(resultSetb.getColumnIndex('id')) as number)
        }
        resultSet.close()
        resultSetb.close()
        const deleteIds = idsb.filter(item => !idsa.includes(item))
        const deletepromises = deleteIds.map(async (item) => {
          await deleteData(this.context, 'tag', item)
        })
        await Promise.all(deletepromises)
        await autoSyncTable(this.context, 'tag', item)
      })
      await Promise.all(promises)
      this.context.eventHub.emit('refreshTag')
      await autoBackupTable(this.context, 'tag')
    })
    huaweiCloudSyncRdbStore.on('dataChange', relationalStore.SubscribeType.SUBSCRIBE_TYPE_CLOUD_DETAILS,
      (changeInfo: relationalStore.ChangeInfo[]) => {
        changeInfo.forEach(async (item) => {
          const table = item.table
          const huaweiCloudSyncOnTables =
            getFlushPreference(this.context, 'dataSetting', 'huaweiCloudSyncOnTables', []) as string[]
          if (huaweiCloudSyncOnTables.includes(table)) {
            await huaweiCloudSyncRdbStore.cloudSync(relationalStore.SyncMode.SYNC_MODE_TIME_FIRST, [table],
              async (progressDetails) => {
                if (progressDetails.code === relationalStore.ProgressCode.SUCCESS) {
                  if (table === 'password') {
                    const insertedIdArray = item.inserted as string[]
                    const insertpromises = insertedIdArray.map(async (id) => {
                      const predicates = new relationalStore.RdbPredicates('password')
                      predicates.equalTo('id', id)
                      const resultSet = await huaweiCloudSyncRdbStore.query(predicates)
                      const nameIndex = resultSet.getColumnIndex('name')
                      const infoIndex = resultSet.getColumnIndex('info')
                      const tagIndex = resultSet.getColumnIndex('tag')
                      const updateTimeIndex = resultSet.getColumnIndex('updateTime')
                      const cloudBackupTimeIndex = resultSet.getColumnIndex('cloudBackupTime')
                      if (resultSet.goToNextRow()) {
                        passwordRdbStore.insertSync('password', {
                          id: Number(id),
                          name: resultSet.getValue(nameIndex),
                          info: resultSet.getValue(infoIndex),
                          tag: resultSet.getValue(tagIndex),
                          updateTime: resultSet.getValue(updateTimeIndex),
                          cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex)
                        }, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
                      }
                      resultSet.close()
                    })
                    const updatedIdArray = item.updated as string[]
                    const updatepromises = updatedIdArray.map(async (id) => {
                      const predicates = new relationalStore.RdbPredicates('password')
                      predicates.equalTo('id', id)
                      const resultSet = await huaweiCloudSyncRdbStore.query(predicates)
                      const nameIndex = resultSet.getColumnIndex('name')
                      const infoIndex = resultSet.getColumnIndex('info')
                      const tagIndex = resultSet.getColumnIndex('tag')
                      const updateTimeIndex = resultSet.getColumnIndex('updateTime')
                      const cloudBackupTimeIndex = resultSet.getColumnIndex('cloudBackupTime')
                      if (resultSet.goToNextRow()) {
                        const predicatesb = new relationalStore.RdbPredicates('password')
                        predicatesb.equalTo('id', Number(id))
                        passwordRdbStore.updateSync({
                          name: resultSet.getValue(nameIndex),
                          info: resultSet.getValue(infoIndex),
                          tag: resultSet.getValue(tagIndex),
                          updateTime: resultSet.getValue(updateTimeIndex),
                          cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex)
                        }, predicatesb)
                      }
                      resultSet.close()
                    })
                    const deletedIdArray = item.deleted as string[]
                    const deletepromises = deletedIdArray.map(async (id) => {
                      await deleteData(this.context, 'password', Number(id))
                      await huaweiCloudSyncRdbStore.cleanDirtyData(table)
                    })
                    await Promise.all(insertpromises)
                    await Promise.all(updatepromises)
                    await Promise.all(deletepromises)
                    this.context.eventHub.emit('refreshPassword')
                    await autoSyncTable(this.context, table)
                    await autoBackupTable(this.context, table)
                  }
                  if (table === 'info') {
                    const insertedIdArray = item.inserted as string[]
                    const insertpromises = insertedIdArray.map(async (id) => {
                      const predicates = new relationalStore.RdbPredicates('info')
                      predicates.equalTo('id', id)
                      const resultSet = await huaweiCloudSyncRdbStore.query(predicates)
                      const typeIndex = resultSet.getColumnIndex('type')
                      const valueIndex = resultSet.getColumnIndex('value')
                      const updateTimeIndex = resultSet.getColumnIndex('updateTime')
                      const cloudBackupTimeIndex = resultSet.getColumnIndex('cloudBackupTime')
                      if (resultSet.goToNextRow()) {
                        infoRdbStore.insertSync('info', {
                          id: Number(id),
                          type: resultSet.getValue(typeIndex),
                          value: resultSet.getValue(valueIndex),
                          updateTime: resultSet.getValue(updateTimeIndex),
                          cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex)
                        }, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
                      }
                      resultSet.close()
                    })
                    const updatedIdArray = item.updated as string[]
                    const updatepromises = updatedIdArray.map(async (id) => {
                      const predicates = new relationalStore.RdbPredicates('info')
                      predicates.equalTo('id', id)
                      const resultSet = await huaweiCloudSyncRdbStore.query(predicates)
                      const typeIndex = resultSet.getColumnIndex('type')
                      const valueIndex = resultSet.getColumnIndex('value')
                      const updateTimeIndex = resultSet.getColumnIndex('updateTime')
                      const cloudBackupTimeIndex = resultSet.getColumnIndex('cloudBackupTime')
                      if (resultSet.goToNextRow()) {
                        const predicatesb = new relationalStore.RdbPredicates('info')
                        predicatesb.equalTo('id', Number(id))
                        infoRdbStore.updateSync({
                          type: resultSet.getValue(typeIndex),
                          value: resultSet.getValue(valueIndex),
                          updateTime: resultSet.getValue(updateTimeIndex),
                          cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex)
                        }, predicatesb)
                      }
                      resultSet.close()
                    })
                    const deletedIdArray = item.deleted as string[]
                    const deletepromises = deletedIdArray.map(async (id) => {
                      await deleteData(this.context, 'info', Number(id))
                      await huaweiCloudSyncRdbStore.cleanDirtyData(table)
                    })
                    await Promise.all(insertpromises)
                    await Promise.all(updatepromises)
                    await Promise.all(deletepromises)
                    this.context.eventHub.emit('refreshInfo')
                    await autoSyncTable(this.context, table)
                    await autoBackupTable(this.context, table)
                  }
                  if (table === 'tag') {
                    const insertedIdArray = item.inserted as string[]
                    const insertpromises = insertedIdArray.map(async (id) => {
                      const predicates = new relationalStore.RdbPredicates('tag')
                      predicates.equalTo('id', id)
                      const resultSet = await huaweiCloudSyncRdbStore.query(predicates)
                      const valueIndex = resultSet.getColumnIndex('value')
                      const colorIndex = resultSet.getColumnIndex('color')
                      const updateTimeIndex = resultSet.getColumnIndex('updateTime')
                      const cloudBackupTimeIndex = resultSet.getColumnIndex('cloudBackupTime')
                      if (resultSet.goToNextRow()) {
                        tagRdbStore.insertSync('tag', {
                          id: Number(id),
                          value: resultSet.getValue(valueIndex),
                          color: resultSet.getValue(colorIndex),
                          updateTime: resultSet.getValue(updateTimeIndex),
                          cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex)
                        }, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
                      }
                      resultSet.close()
                    })
                    const updatedIdArray = item.updated as string[]
                    const updatepromises = updatedIdArray.map(async (id) => {
                      const predicates = new relationalStore.RdbPredicates('tag')
                      predicates.equalTo('id', id)
                      const resultSet = await huaweiCloudSyncRdbStore.query(predicates)
                      const valueIndex = resultSet.getColumnIndex('value')
                      const colorIndex = resultSet.getColumnIndex('color')
                      const updateTimeIndex = resultSet.getColumnIndex('updateTime')
                      const cloudBackupTimeIndex = resultSet.getColumnIndex('cloudBackupTime')
                      if (resultSet.goToNextRow()) {
                        const predicatesb = new relationalStore.RdbPredicates('tag')
                        predicatesb.equalTo('id', Number(id))
                        tagRdbStore.updateSync({
                          value: resultSet.getValue(valueIndex),
                          color: resultSet.getValue(colorIndex),
                          updateTime: resultSet.getValue(updateTimeIndex),
                          cloudBackupTime: resultSet.getValue(cloudBackupTimeIndex)
                        }, predicatesb)
                      }
                      resultSet.close()
                    })
                    const deletedIdArray = item.deleted as string[]
                    const deletepromises = deletedIdArray.map(async (id) => {
                      await deleteData(this.context, 'tag', Number(id))
                      await huaweiCloudSyncRdbStore.cleanDirtyData(table)
                    })
                    await Promise.all(insertpromises)
                    await Promise.all(updatepromises)
                    await Promise.all(deletepromises)
                    this.context.eventHub.emit('refreshTag')
                    await autoSyncTable(this.context, table)
                    await autoBackupTable(this.context, table)
                  }
                }
              })
          }
        })
      })
    appRecovery.enableAppRecovery(appRecovery.RestartFlag.RESTART_WHEN_APP_FREEZE)
    const allowContinue = getFlushPreference(this.context, 'commonSetting', 'allowContinue', true)
    if (!allowContinue) {
      await this.context.setMissionContinueState(AbilityConstant.ContinueState.INACTIVE)
    }
    if (allowContinue) {
      await this.context.setMissionContinueState(AbilityConstant.ContinueState.ACTIVE)
    }
    const allowRestore = getFlushPreference(this.context, 'commonSetting', 'allowRestore', true) as boolean
    this.context.setRestoreEnabled(allowRestore)
    if (deviceInfo.deviceType === '2in1') {
      statusBarManager.on('statusBarIconClick', async () => {
        await this.context.showAbility()
      })
      statusBarManager.on('rightMenuClick', (data) => {
        const datastring = JSON.stringify(data)
        const eventData = JSON.parse(datastring) as MenuCodeEventData
        this.context.eventHub.emit(eventData.data.menuCode)
      })
      const subscriber = commonEventManager.createSubscriberSync({
        events: ['BACKGROUNDABILITY_EVENT_PREPARETOTERMINATE']
      })
      await commonEventManager.subscribeToEvent(subscriber, async (data) => {
        if (data.event === 'BACKGROUNDABILITY_EVENT_PREPARETOTERMINATE') {
          statusBarManager.removeFromStatusBar(this.context)
          setTempPreference(this.context, 'statusBar', 'exist', false)
          await this.context.terminateSelf()
        }
      })
      const statusBar = getFlushPreference(this.context, 'commonSetting', 'statusBar', false)
      if (statusBar) {
        const blackFileData = this.context.resourceManager.getRawFileContentSync('iconblack.svg')
        const blackImageSource = image.createImageSource(blackFileData.buffer)
        const blackPixelMap = await blackImageSource.createPixelMap()
        await blackImageSource.release()
        const whiteFileData = this.context.resourceManager.getRawFileContentSync('iconwhite.svg')
        const whiteImageSource = image.createImageSource(whiteFileData.buffer)
        const whitePixelMap = await whiteImageSource.createPixelMap()
        await whiteImageSource.release()
        statusBarManager.addToStatusBar(this.context, {
          icons: {
            black: blackPixelMap,
            white: whitePixelMap
          },
          quickOperation: {
            title: '',
            height: 1,
            abilityName: '',
            moduleName: 'entry',
            loadingStatus: true
          }
        })
        await blackPixelMap.release()
        await whitePixelMap.release()
        statusBarManager.updateStatusBarMenu(this.context, [
          [
            {
              title: '打开',
              menuAction: {
                abilityName: 'EntryAbility'
              }
            }
          ],
          [
            {
              title: '新增密码',
              menuAction: {
                abilityName: 'EntryAbility',
                notifyOnly: true,
                menuCode: 'newPassword'
              }
            },
            {
              title: '搜索密码',
              menuAction: {
                abilityName: 'EntryAbility',
                notifyOnly: true,
                menuCode: 'searchPassword'
              }
            }
          ]
        ])
        setTimeout(async () => {
          try {
            await this.context.startAbility({
              bundleName: 'com.zhangxm.aipasswordmemo',
              abilityName: 'BackGroundAbility'
            }, {
              processMode: contextConstant.ProcessMode.NEW_PROCESS_ATTACH_TO_STATUS_BAR_ITEM,
              startupVisibility: contextConstant.StartupVisibility.STARTUP_HIDE
            })
          } catch {
          }
          setTempPreference(this.context, 'statusBar', 'exist', true)
        }, 200)
      }
    }
    const applicationContext = this.context.getApplicationContext()
    const colorMode = getFlushPreference(this.context, 'commonSetting', 'colorMode', 0)
    if (colorMode === 0) {
      applicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
    }
    if (colorMode === 1) {
      applicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT)
    }
    if (colorMode === 2) {
      applicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK)
    }
    if (deviceInfo.deviceType === 'phone') {
      const processCache = getFlushPreference(this.context, 'debugSetting', 'processCache', true) as boolean
      applicationContext.setSupportedProcessCache(processCache)
    }
    await this.appInit(want)
    await clearNouseData(this.context)
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

  async onPrepareToTerminateAsync(): Promise<boolean> {
    const statusBarExist = getTempPreference(this.context, 'statusBar', 'exist', false) as boolean
    if (statusBarExist) {
      await this.context.hideAbility()
    }
    return statusBarExist
  }

  async onConfigurationUpdate() {
    const iconMode = getFlushPreference(this.context, 'commonSetting', 'iconMode', 1)
    const colorMode = getFlushPreference(this.context, 'commonSetting', 'colorMode', 0)
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
  }

  onBackPressed() {
    const destroyWhenBackPressed = getFlushPreference(this.context, 'commonSetting', 'destroyWhenBackPressed', false)
    if (!destroyWhenBackPressed) {
      return true
    } else {
      return false
    }
  }

  async onContinue(wantParam: Record<string, Object>) {
    if (wantParam.version !== 61) {
      await promptAction.openToast({
        message: '接续失败，原因：目标端应用版本号与发起端不匹配'
      })
      return AbilityConstant.OnContinueResult.MISMATCH
    }
    const exitAfterContinue = getFlushPreference(this.context, 'commonSetting', 'exitAfterContinue', true)
    wantParam[wantConstant.Params.SUPPORT_CONTINUE_SOURCE_EXIT_KEY] = exitAfterContinue
    return AbilityConstant.OnContinueResult.AGREE
  }

  onCollaborate() {
    const acceptCollaborate = getFlushPreference(this.context, 'commonSetting', 'acceptCollaborate', true)
    if (!acceptCollaborate) {
      return 1
    } else {
      return 0
    }
  }

  async onMemoryLevel(level: AbilityConstant.MemoryLevel) {
    const showMemoryLevelChange = getFlushPreference(this.context, 'debugSetting', 'showMemoryLevelChange', false)
    if (showMemoryLevelChange) {
      let memoryLevel = ''
      if (level === AbilityConstant.MemoryLevel.MEMORY_LEVEL_MODERATE) {
        memoryLevel = '适中'
      }
      if (level === AbilityConstant.MemoryLevel.MEMORY_LEVEL_LOW) {
        memoryLevel = '低'
      }
      if (level === AbilityConstant.MemoryLevel.MEMORY_LEVEL_CRITICAL) {
        memoryLevel = '高'
      }
      await promptAction.openToast({
        message: '当前内存占用' + memoryLevel
      })
    }
  }
}