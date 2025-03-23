import { UIAbility } from '@kit.AbilityKit'
import { window } from '@kit.ArkUI'

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index')
    let windowClass: window.Window = windowStage.getMainWindowSync()
    windowClass.setWindowLayoutFullScreen(true)
    let type = window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR
    let avoidArea = windowClass.getWindowAvoidArea(type)
    let bottomRectHeight = avoidArea.bottomRect.height
    AppStorage.setOrCreate('bottomRectHeight', bottomRectHeight)
    type = window.AvoidAreaType.TYPE_SYSTEM
    avoidArea = windowClass.getWindowAvoidArea(type)
    let topRectHeight = avoidArea.topRect.height
    AppStorage.setOrCreate('topRectHeight', topRectHeight)
    windowClass.on('avoidAreaChange', (data) => {
      if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
        let topRectHeight = data.area.topRect.height
        AppStorage.setOrCreate('topRectHeight', topRectHeight)
      } else if (data.type == window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
        let bottomRectHeight = data.area.bottomRect.height
        AppStorage.setOrCreate('bottomRectHeight', bottomRectHeight)
      }
    })
  }
}