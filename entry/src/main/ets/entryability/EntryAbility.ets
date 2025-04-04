import { ConfigurationConstant, errorManager, UIAbility } from '@kit.AbilityKit'
import { updateManager } from '@kit.AppGalleryKit'
import { preferences } from '@kit.ArkData'
import { promptAction, window } from '@kit.ArkUI'
import { BusinessError } from '@kit.BasicServicesKit'
import { wifiManager } from '@kit.ConnectivityKit'
import { connection } from '@kit.NetworkKit'
import { netQuality } from '@kit.NetworkBoostKit'
import { hiAppEvent } from '@kit.PerformanceAnalysisKit'
import { httpRequest } from '../common/Request'

export default class EntryAbility extends UIAbility {
  async onWindowStageCreate(windowStage: window.WindowStage) {
    windowStage.loadContent('pages/Index')
    const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
      name: 'commonSetting'
    })
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
          let message: string = '名称：' + err.name + '\n消息：' + err.message
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
      name: "watcher",
      appEventFilters: [
        {
          domain: hiAppEvent.domain.OS,
          eventTypes: [1]
        }
      ],
      onReceive: async (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
        if (debugSettingDataPreferences.getSync('autoUploadErrorLog', true)) {
          const promises = appEventGroups.map(async (item) => {
            const res = await httpRequest('/debug/newErrorLog', {
              key: 'RaGvhiCmYP8aPZ-QmmDgBQvwkfkp9TXEVCWEn8fPjshs9GyUCooG_kq7N8bHBRcT',
              object: item
            })
            if (res !== 'fail') {
              promptAction.showToast({
                message: '故障日志自动上传成功，故障类型：' + item.name
              })
            }
          })
          await Promise.all(promises)
        }
      }
    })
    const netConnection: connection.NetConnection = connection.createNetConnection()
    netConnection.register(() => {
    })
    netConnection.on('netAvailable', (data: connection.NetHandle) => {
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
    netConnection.on('netBlockStatusChange', (data: connection.NetBlockStatusInfo) => {
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
    netConnection.on('netLost', (data: connection.NetHandle) => {
      if (debugSettingDataPreferences.getSync('showNetLost', false)) {
        promptAction.showToast({
          message: '网络丢失，数据网络句柄：' + data.netId
        })
      }
    })
    netConnection.on('netCapabilitiesChange', (data: connection.NetCapabilityInfo) => {
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
    netQuality.on('netQosChange', (list: Array<netQuality.NetworkQos>) => {
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
          try {
            netQuality.reportQoe({
              serviceType: 'default',
              qoeType: 'highLatency'
            })
            promptAction.showToast({
              message: '自动反馈网络高时延传输体验成功'
            })
          } catch (err) {
            promptAction.showToast({
              message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
              (err as BusinessError).message
            })
          }
        }
      }
    })
    netQuality.on('netSceneChange', (list: Array<netQuality.NetworkScene>) => {
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
    const checkVersionUpdate = commonSettingDataPreferences.getSync('checkVersionUpdate', 1)
    if (checkVersionUpdate === 1) {
      const wifiLinkedInfo = await wifiManager.getLinkedInfo()
      if (wifiLinkedInfo.connState === 4) {
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
  }
}