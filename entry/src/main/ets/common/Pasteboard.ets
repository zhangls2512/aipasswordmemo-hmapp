import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { pasteboard } from '@kit.BasicServicesKit'
import Pasteboard from '@ohos.pasteboard'

export async function copy(content: string) {
  const context = getContext() as common.UIAbilityContext
  const commonSettingDataPreferences = preferences.getPreferencesSync(context, {
    name: 'commonSetting'
  })
  const pasteBoardType = commonSettingDataPreferences.getSync('pasteBoardType', 0)
  if (pasteBoardType === 0) {
    const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, content)
    const systemPasteboard = pasteboard.getSystemPasteboard()
    await systemPasteboard.setData(pasteData)
  }
  if (pasteBoardType === 1) {
    const pasteData: Pasteboard.PasteData = Pasteboard.createData(Pasteboard.MIMETYPE_TEXT_PLAIN, content)
    const systemPasteBoard: Pasteboard.SystemPasteboard = Pasteboard.getSystemPasteboard()
    await systemPasteBoard.setData(pasteData)
  }
  promptAction.showToast({
    message: '内容已复制到剪贴板'
  })
}