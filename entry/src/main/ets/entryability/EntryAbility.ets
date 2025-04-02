import { errorManager, UIAbility } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { promptAction, window } from '@kit.ArkUI'

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage) {
    windowStage.loadContent('pages/Index')
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
  }
}