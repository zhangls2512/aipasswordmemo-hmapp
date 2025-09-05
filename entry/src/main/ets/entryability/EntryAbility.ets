import { AbilityConstant, appRecovery, ConfigurationConstant, errorManager, UIAbility, Want } from '@kit.AbilityKit'
import { updateManager } from '@kit.AppGalleryKit'
import { preferences, relationalStore } from '@kit.ArkData'
import { uri, util } from '@kit.ArkTS'
import { promptAction, window } from '@kit.ArkUI'
import { deviceInfo } from '@kit.BasicServicesKit'
import { wifiManager } from '@kit.ConnectivityKit'
import { netQuality } from '@kit.NetworkBoostKit'
import { connection } from '@kit.NetworkKit'
import { notificationManager } from '@kit.NotificationKit'
import { hiAppEvent } from '@kit.PerformanceAnalysisKit'
import fs from '@ohos.file.fs'
import { check, get, getAccountInfo } from '../common/Accesstoken'
import { decrypt, getKey } from '../common/Crypto'
import { getPasswordMaxId, PasswordInfoItem } from '../common/Dataget'
import { importInfo, importPassword, importTag, InfoInItem, PasswordInItem, TagInItem } from '../common/Dataimport'
import getDeviceToken from '../common/Devicetoken'
import request from '../common/Request'
import { InfoCloudBackup, Item, PasswordCloudBackup, TagCloudBackup } from '../pages/Cloudbackupimport'
import { PasswordOutItem } from '../pages/DataInOut'

export default class EntryAbility extends UIAbility {
  storage = new LocalStorage()

  parseCsvLine(line: string) {
    const result: string[] = []
    let inQuotes = false
    let currentField = ''
    for (let i = 0; i < line.length; i++) {
      const char = line[i]
      if (char === '"') {
        if (inQuotes && line[i + 1] === '"') {
          currentField += '"'
          i++
        } else {
          inQuotes = !inQuotes
        }
      } else if (char === ',' && !inQuotes) {
        result.push(currentField)
        currentField = ''
      } else {
        currentField += char
      }
    }
    result.push(currentField)
    return result
  }

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    const accessToken = await get()
    const accountInfo = await getAccountInfo()
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
    if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
      this.context.restoreWindowStage(this.storage)
    }
    if (notificationManager.isNotificationEnabledSync()) {
      notificationManager.setBadgeNumber(0)
    }
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
    const observer: errorManager.ErrorObserver = {
      onUnhandledException(errMsg) {
        if (debugSettingDataPreferences.getSync('globalErrorShowType', 0) === 0) {
          promptAction.showToast({
            message: 'js 运行异常：' + errMsg
          })
        }
      },
      onException(err) {
        if (debugSettingDataPreferences.getSync('globalErrorShowType', 0) === 1) {
          let message = '名称：' + err.name + '\n消息：' + err.message
          if (typeof (err.stack) === 'string') {
            message = message + '\n错误堆栈信息：' + err.stack
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
    }
    errorManager.on('error', observer)
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
          if (!fs.accessSync(errorLogDir)) {
            fs.mkdirSync(errorLogDir, true)
          }
          appEventGroups.forEach((item) => {
            const file = fs.openSync(this.context.filesDir + '/log/error/' + Date.now() + '.txt',
              fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
            fs.writeSync(file.fd, JSON.stringify(item))
            fs.closeSync(file)
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
                promptAction.showToast({
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
        promptAction.showToast({
          message: '网络可用，数据网络句柄：' + data.netId
        })
      }
    })
    netConnection.on('netUnavailable', () => {
      if (debugSettingDataPreferences.getSync('showNetAvailableStatusChange', false)) {
        promptAction.showToast({
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
        promptAction.showToast({
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
          promptAction.showToast({
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
      promptAction.showToast({
        message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
      })
    }
    if (accessToken && getKey()) {
      const cloudbackupSettingDataPreferences = preferences.getPreferencesSync(this.context, {
        name: 'cloudbackupSetting'
      })
      const autoImportTables = cloudbackupSettingDataPreferences.getSync('autoImport', []) as string[]
      if (autoImportTables.includes('password')) {
        promptAction.showToast({
          message: '导入密码云备份中'
        })
        const countres = await request('/password/getBackupCount', {
          accessToken: accessToken
        })
        if (countres !== 'fail') {
          const total = JSON.parse(countres).count.password as number
          for (let i = 0; i < total; i += 50) {
            const listres = await request('/password/getBackupList', {
              accessToken: accessToken,
              type: 'password',
              skip: i,
              count: 50
            })
            if (listres !== 'fail') {
              const listarray = JSON.parse(listres).data as Item[]
              const array: PasswordInItem[] = []
              const promises = listarray.map(async (item) => {
                const itemstring = await decrypt({
                  content: item.content,
                  iv: item.iv
                })
                if (itemstring !== 'fail') {
                  const itemobject = JSON.parse(itemstring) as PasswordCloudBackup
                  let cloudBackupTime = itemobject.cloudBackupTime
                  if (typeof (cloudBackupTime) === 'number') {
                    cloudBackupTime = JSON.stringify([{
                      uid: accountInfo.uid,
                      time: itemobject.cloudBackupTime
                    }])
                  }
                  array.push({
                    id: item.id,
                    name: itemobject.name,
                    info: itemobject.info,
                    tag: itemobject.tag,
                    updateTime: itemobject.updateTime,
                    cloudBackupTime: cloudBackupTime
                  })
                }
              })
              await Promise.all(promises)
              await importPassword(JSON.stringify(array), 0)
            }
          }
          promptAction.showToast({
            message: '导入密码云备份成功'
          })
        }
      }
      if (autoImportTables.includes('info')) {
        promptAction.showToast({
          message: '导入常用信息云备份中'
        })
        const countres = await request('/password/getBackupCount', {
          accessToken: accessToken
        })
        if (countres !== 'fail') {
          const total = JSON.parse(countres).count.info as number
          for (let i = 0; i < total; i += 50) {
            const listres = await request('/password/getBackupList', {
              accessToken: accessToken,
              type: 'info',
              skip: i,
              count: 50
            })
            if (listres !== 'fail') {
              const listarray = JSON.parse(listres).data as Item[]
              const array: InfoInItem[] = []
              const promises = listarray.map(async (item) => {
                const itemstring = await decrypt({
                  content: item.content,
                  iv: item.iv
                })
                if (itemstring !== 'fail') {
                  const itemobject = JSON.parse(itemstring) as InfoCloudBackup
                  let cloudBackupTime = itemobject.cloudBackupTime
                  if (typeof (cloudBackupTime) === 'number') {
                    cloudBackupTime = JSON.stringify([{
                      uid: accountInfo.uid,
                      time: itemobject.cloudBackupTime
                    }])
                  }
                  array.push({
                    id: item.id,
                    type: itemobject.type,
                    value: itemobject.value,
                    updateTime: itemobject.updateTime,
                    cloudBackupTime: cloudBackupTime
                  })
                }
              })
              await Promise.all(promises)
              await importInfo(JSON.stringify(array), 0)
            }
          }
          promptAction.showToast({
            message: '导入常用信息云备份成功'
          })
        }
      }
      if (autoImportTables.includes('tag')) {
        promptAction.showToast({
          message: '导入标签云备份中'
        })
        const countres = await request('/password/getBackupCount', {
          accessToken: accessToken
        })
        if (countres !== 'fail') {
          const total = JSON.parse(countres).count.tag as number
          for (let i = 0; i < total; i += 50) {
            const listres = await request('/password/getBackupList', {
              accessToken: accessToken,
              type: 'tag',
              skip: i,
              count: 50
            })
            if (listres !== 'fail') {
              const listarray = JSON.parse(listres).data as Item[]
              const array: TagInItem[] = []
              const promises = listarray.map(async (item) => {
                const itemstring = await decrypt({
                  content: item.content,
                  iv: item.iv
                })
                if (itemstring !== 'fail') {
                  const itemobject = JSON.parse(itemstring) as TagCloudBackup
                  let cloudBackupTime = itemobject.cloudBackupTime
                  if (typeof (cloudBackupTime) === 'number') {
                    cloudBackupTime = JSON.stringify([{
                      uid: accountInfo.uid,
                      time: itemobject.cloudBackupTime
                    }])
                  }
                  array.push({
                    id: item.id,
                    value: itemobject.value,
                    color: itemobject.color,
                    updateTime: itemobject.updateTime,
                    cloudBackupTime: cloudBackupTime
                  })
                }
              })
              await Promise.all(promises)
              await importInfo(JSON.stringify(array), 0)
            }
          }
          promptAction.showToast({
            message: '导入标签云备份成功'
          })
        }
      }
    }
    if (want.parameters?.shortcutId) {
      const shortcutDataPreferences = preferences.getPreferencesSync(this.context, {
        name: 'shortcut'
      })
      shortcutDataPreferences.putSync('shortcutId', want.parameters?.shortcutId)
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
      const file = fs.openSync(filePath)
      const size = fs.statSync(file.fd).size
      const filebuffer = new ArrayBuffer(size)
      fs.readSync(file.fd, filebuffer)
      const decoder = util.TextDecoder.create()
      const filestring = decoder.decodeToString(new Uint8Array(filebuffer))
      fs.closeSync(file)
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
      }
      if (filePath.endsWith('.csv')) {
        const lines = filestring.split('\n').filter(line => line.trim() !== '')
        const result: PasswordOutItem[] = []
        const maxId = await getPasswordMaxId()
        let idCounter = maxId + 1
        const firstLine = this.parseCsvLine(lines[0])
        const columnCount = firstLine.length
        const nameIndex = firstLine.findIndex(item => item === '名称')
        if (nameIndex === -1) {
          promptAction.showToast({
            message: '导入失败，原因：无名称列'
          })
        } else {
          const infoColumnsIndex: number[] = []
          for (let i = 0; i < columnCount; i++) {
            if (i !== nameIndex) {
              infoColumnsIndex.push(i)
            }
          }
          for (let i = 1; i < lines.length; i++) {
            const line = lines[i]
            const parsedLine = this.parseCsvLine(line)
            const name = parsedLine[nameIndex]
            const info: PasswordInfoItem[] = []
            infoColumnsIndex.forEach(item => {
              if (firstLine[item] && parsedLine[item] && firstLine[item] !== '图标' && firstLine[item] !== 'MFA') {
                info.push({ type: firstLine[item], value: parsedLine[item] })
              }
            })
            if (name && info.length > 0) {
              result.push({
                id: idCounter++,
                name: name,
                info,
                tag: [],
                updateTime: Date.now(),
                cloudBackupTime: JSON.stringify([])
              })
            }
          }
          await importPassword(JSON.stringify(result), 0)
          this.context.eventHub.emit('refreshPassword')
        }
      }
      promptAction.showToast({
        message: '导入成功'
      })
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
                promptAction.showToast({
                  message: '邀请码使用成功'
                })
              }
            }
          } else {
            promptAction.showToast({
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
              promptAction.showToast({
                message: '兑换码使用成功'
              })
            }
          } else {
            promptAction.showToast({
              message: '兑换码使用失败，原因：未登录账号'
            })
          }
        }
      }
    }
  }

  async onWindowStageCreate(windowStage: window.WindowStage) {
    if (deviceInfo.deviceType === '2in1') {
      const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
        name: 'commonSetting'
      })
      const windowRectAutoSave = commonSettingDataPreferences.getSync('windowRectAutoSave', false) as boolean
      await windowStage.setWindowRectAutoSave(windowRectAutoSave)
    }
    windowStage.loadContent('pages/Index')
    if (!notificationManager.isNotificationEnabledSync()) {
      notificationManager.requestEnableNotification(this.context)
    }
  }

  onContinue(wantParam: Record<string, Object>) {
    if (wantParam.version !== 14) {
      return AbilityConstant.OnContinueResult.MISMATCH
    }
    return AbilityConstant.OnContinueResult.AGREE
  }

  async onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam) {
    const accessToken = await get()
    if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
      this.context.restoreWindowStage(this.storage)
    }
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
      const file = fs.openSync(filePath)
      const size = fs.statSync(file.fd).size
      const filebuffer = new ArrayBuffer(size)
      fs.readSync(file.fd, filebuffer)
      const decoder = util.TextDecoder.create()
      const filestring = decoder.decodeToString(new Uint8Array(filebuffer))
      fs.closeSync(file)
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
      }
      if (filePath.endsWith('.csv')) {
        const lines = filestring.split('\n').filter(line => line.trim() !== '')
        const result: PasswordOutItem[] = []
        const maxId = await getPasswordMaxId()
        let idCounter = maxId + 1
        const firstLine = this.parseCsvLine(lines[0])
        const columnCount = firstLine.length
        const nameIndex = firstLine.findIndex(item => item === '名称')
        if (nameIndex === -1) {
          promptAction.showToast({
            message: '导入失败，原因：无名称列'
          })
        } else {
          const infoColumnsIndex: number[] = []
          for (let i = 0; i < columnCount; i++) {
            if (i !== nameIndex) {
              infoColumnsIndex.push(i)
            }
          }
          for (let i = 1; i < lines.length; i++) {
            const line = lines[i]
            const parsedLine = this.parseCsvLine(line)
            const name = parsedLine[nameIndex]
            const info: PasswordInfoItem[] = []
            infoColumnsIndex.forEach(item => {
              if (firstLine[item] && parsedLine[item] && firstLine[item] !== '图标' && firstLine[item] !== 'MFA') {
                info.push({ type: firstLine[item], value: parsedLine[item] })
              }
            })
            if (name && info.length > 0) {
              result.push({
                id: idCounter++,
                name: name,
                info,
                tag: [],
                updateTime: Date.now(),
                cloudBackupTime: JSON.stringify([])
              })
            }
          }
          await importPassword(JSON.stringify(result), 0)
          this.context.eventHub.emit('refreshPassword')
        }
      }
      promptAction.showToast({
        message: '导入成功'
      })
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
                promptAction.showToast({
                  message: '邀请码使用成功'
                })
              }
            }
          } else {
            promptAction.showToast({
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
              promptAction.showToast({
                message: '兑换码使用成功'
              })
            }
          } else {
            promptAction.showToast({
              message: '兑换码使用失败，原因：未登录账号'
            })
          }
        }
      }
    }
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
      promptAction.showToast({
        message: '当前内存占用' + memoryLevel
      })
    }
  }
}