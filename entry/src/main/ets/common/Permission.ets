import { abilityAccessCtrl, bundleManager, common, Permissions } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'

export function getPermission(permission: Permissions): boolean {
  const accessTokenId =
    bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
      .appInfo
      .accessTokenId
  const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager()
  const status: abilityAccessCtrl.GrantStatus = atManager.checkAccessTokenSync(accessTokenId, permission)
  if (status === 0) {
    return true
  }
  return false
}

export async function checkPermission(permission: Permissions): Promise<boolean> {
  const accessTokenId =
    bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
      .appInfo
      .accessTokenId
  const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager()
  const status: abilityAccessCtrl.GrantStatus = atManager.checkAccessTokenSync(accessTokenId, permission)
  if (status === 0) {
    return true
  }
  const context = getContext() as common.UIAbilityContext
  const resa = await atManager.requestPermissionsFromUser(context, [permission])
  const authResulta = resa.authResults[0]
  if (authResulta === 0) {
    return true
  }
  const resb = await atManager.requestPermissionOnSetting(context, [permission])
  const authResultb = resb[0]
  if (authResultb === 0) {
    if (permission === 'ohos.permission.MICROPHONE') {
      const resc = await atManager.requestGlobalSwitch(context, abilityAccessCtrl.SwitchType.MICROPHONE)
      if (resc) {
        return true
      }
      promptAction.showDialog({
        title: '提示',
        message: '请打开全局麦克风开关以使用此功能',
        buttons: [
          {
            text: '确定',
            color: $r('sys.color.font_emphasize')
          }
        ]
      })
      return false
    }
    return true
  }
  promptAction.showDialog({
    title: '提示',
    message: '请允许授权以使用此功能',
    buttons: [
      {
        text: '确定',
        color: $r('sys.color.font_emphasize')
      }
    ]
  })
  return false
}