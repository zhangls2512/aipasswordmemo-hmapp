import { common } from '@kit.AbilityKit'
import { authentication } from '@kit.AccountKit'
import { preferences } from '@kit.ArkData'
import { util } from '@kit.ArkTS'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { appAccount } from '@kit.BasicServicesKit'
import { netBoost } from '@kit.NetworkBoostKit'
import { fido2 } from '@kit.OnlineAuthenticationKit'
import request from './Request'

interface AccountInfo {
  uid: string,
  email: string,
  endDate: number
}

export async function set(accessToken: string, accountInfo: AccountInfo) {
  const appAccountManager = appAccount.createAppAccountManager()
  await appAccountManager.createAccount('default', {
    customData: {
      uid: accountInfo.uid,
      email: accountInfo.email,
      endDate: String(accountInfo.endDate)
    }
  })
  await appAccountManager.setCredential('default', 'accessToken', accessToken)
}

export async function get() {
  const appAccountManager = appAccount.createAppAccountManager()
  try {
    const endDate = Number(appAccountManager.getCustomDataSync('default', 'endDate'))
    if (endDate < Date.now() && endDate !== 0) {
      await appAccountManager.removeAccount('default')
      promptAction.openToast({
        message: '登录态过期，请重新登录'
      })
      return ''
    }
    const res = await appAccountManager.getCredential('default', 'accessToken')
    return res
  } catch {
    return ''
  }
}

export async function getAccountInfo(): Promise<AccountInfo> {
  const appAccountManager = appAccount.createAppAccountManager()
  try {
    const endDate = Number(appAccountManager.getCustomDataSync('default', 'endDate'))
    if (endDate < Date.now() && endDate !== 0) {
      await appAccountManager.removeAccount('default')
      promptAction.openToast({
        message: '登录态过期，请重新登录'
      })
      return {
        uid: '',
        email: '',
        endDate: 0
      }
    }
    return {
      uid: appAccountManager.getCustomDataSync('default', 'uid'),
      email: appAccountManager.getCustomDataSync('default', 'email'),
      endDate: endDate
    }
  } catch {
    return {
      uid: '',
      email: '',
      endDate: 0
    }
  }
}

export async function check() {
  const context = getContext() as common.UIAbilityContext
  const accessToken = await get()
  if (!accessToken) {
    const commonSettingDataPreferences = preferences.getPreferencesSync(context, {
      name: 'commonSetting'
    })
    const autoLoginByHuaweiAccount = commonSettingDataPreferences.getSync('autoLoginByHuaweiAccount', false)
    const autoLoginByPasskey = commonSettingDataPreferences.getSync('autoLoginByPasskey', false)
    if (autoLoginByHuaweiAccount && !autoLoginByPasskey) {
      try {
        const loginRequest = new authentication.HuaweiIDProvider().createLoginWithHuaweiIDRequest()
        loginRequest.forceLogin = false
        const controller = new authentication.AuthenticationController()
        const resa: authentication.LoginWithHuaweiIDResponse = await controller.executeRequest(loginRequest)
        netBoost.setSceneDesc({
          scene: 'login',
          sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
        })
        const res = await request('/account/getAccessToken', {
          verifyType: 'huaweiaipasswordmemoapp',
          verifyCode: resa.data?.authorizationCode
        })
        netBoost.setSceneDesc({
          scene: 'login',
          sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
        })
        if (res !== 'fail') {
          const accessToken = JSON.parse(res).accessToken as string
          const uid = JSON.parse(res).uid as string
          const email = JSON.parse(res).email as string
          const endDate = JSON.parse(res).endDate as number
          await set(accessToken, {
            uid: uid,
            email: email,
            endDate: endDate
          })
          promptAction.openToast({
            message: '华为账号静默登录成功'
          })
        }
      } catch (err) {
        promptAction.openToast({
          message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
        })
      }
    }
    if (autoLoginByPasskey && !autoLoginByHuaweiAccount) {
      try {
        const resa = await fido2.authenticate(context, {
          publicKey: {
            challenge: new util.TextEncoder().encodeInto(String(Date.now()).slice(0, -5) + '00000')
          }
        })
        const dialogControllerProgress = new CustomDialogController({
          builder: LoadingDialog({
            content: '登录中...'
          })
        })
        dialogControllerProgress.open()
        netBoost.setSceneDesc({
          scene: 'login',
          sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
        })
        const resb = await request('/account/getAccessToken', {
          verifyType: 'passkey',
          rawId: new util.Base64Helper().encodeToStringSync(resa.rawId, util.Type.BASIC_URL_SAFE),
          authenticatorData: new util.Base64Helper().encodeToStringSync(resa.response.authenticatorData,
            util.Type.BASIC_URL_SAFE),
          clientDataJSON: new util.Base64Helper().encodeToStringSync(resa.response.clientDataJson,
            util.Type.BASIC_URL_SAFE),
          signature: new util.Base64Helper().encodeToStringSync(resa.response.signature,
            util.Type.BASIC_URL_SAFE)
        })
        netBoost.setSceneDesc({
          scene: 'login',
          sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
        })
        dialogControllerProgress.close()
        if (resb !== 'fail') {
          const accessToken = JSON.parse(resb).accessToken as string
          const uid = JSON.parse(resb).uid as string
          const email = JSON.parse(resb).email as string
          const endDate = JSON.parse(resb).endDate as number
          await set(accessToken, {
            uid: uid,
            email: email,
            endDate: endDate
          })
          promptAction.openToast({
            message: '通行密钥静默登录成功'
          })
        }
      } catch (err) {
        promptAction.openToast({
          message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
        })
      }
    }
  }
}

export async function remove() {
  const accessToken = await get()
  if (accessToken) {
    const appAccountManager = appAccount.createAppAccountManager()
    await appAccountManager.removeAccount('default')
  }
}