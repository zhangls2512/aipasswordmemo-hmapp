import { preferences } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { pasteboard } from '@kit.BasicServicesKit'

export async function copy(text: string) {
  const context = getContext()
  const permissionSettingDataPreferences = preferences.getPreferencesSync(context, {
    name: 'permissionSetting'
  })
  const canWritePasteBoard = permissionSettingDataPreferences.getSync('writePasteBoard', false)
  if (canWritePasteBoard) {
    writePasteBoard(text)
  }
  if (!canWritePasteBoard) {
    const data = await promptAction.showDialog({
      title: '允许“轩铭密码智能备忘录”写入剪贴板？',
      message: $r('app.string.WRITE_PASTEBOARD_reason'),
      buttons: [
        {
          text: '禁止',
          color: $r('sys.color.warning')
        },
        {
          text: '允许',
          color: $r('sys.color.font_emphasize')
        }
      ]
    })
    if (data.index === 1) {
      permissionSettingDataPreferences.putSync('writePasteBoard', true)
      permissionSettingDataPreferences.flushSync()
      writePasteBoard(text)
    }
  }
}

async function writePasteBoard(text: string) {
  const pasteData: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text)
  const systemPasteboard = pasteboard.getSystemPasteboard()
  await systemPasteboard.setData(pasteData)
  promptAction.showToast({
    message: '内容已复制到剪贴板'
  })
}