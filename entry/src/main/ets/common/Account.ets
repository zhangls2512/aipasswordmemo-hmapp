import { authentication } from '@kit.AccountKit'
import { util } from '@kit.ArkTS'
import { promptAction } from '@kit.ArkUI'
import { appAccount } from '@kit.BasicServicesKit'
import { netBoost } from '@kit.NetworkBoostKit'
import { fido2 } from '@kit.OnlineAuthenticationKit'
import { getFlushPreference } from './Preference'
import request from './Request'

interface AccountInfo {
  uid: string,
  email: string,
  endDate: number
}

export async function setAccount(accessToken: string, accountInfo: AccountInfo) {
  const appAccountManager = appAccount.createAppAccountManager()
  try {
    await appAccountManager.createAccount('default', {
      customData: {
        uid: accountInfo.uid,
        email: accountInfo.email,
        endDate: String(accountInfo.endDate)
      }
    })
    await appAccountManager.setCredential('default', 'accessToken', accessToken)
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
  }
}

export async function getAccountAccessToken() {
  const appAccountManager = appAccount.createAppAccountManager()
  try {
    const endDate = Number(appAccountManager.getCustomDataSync('default', 'endDate'))
    if (endDate < Date.now() && endDate !== 0) {
      await removeAccount()
      await promptAction.openToast({
        message: '登录态过期，请重新登录'
      })
      return ''
    }
    const accessToken = await appAccountManager.getCredential('default', 'accessToken')
    return accessToken
  } catch {
    return ''
  }
}

export async function getAccountInfo(): Promise<AccountInfo> {
  const appAccountManager = appAccount.createAppAccountManager()
  try {
    const endDate = Number(appAccountManager.getCustomDataSync('default', 'endDate'))
    if (endDate < Date.now()) {
      await removeAccount()
      await promptAction.openToast({
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

export async function removeAccount() {
  const accessToken = await getAccountAccessToken()
  if (accessToken) {
    const appAccountManager = appAccount.createAppAccountManager()
    await appAccountManager.removeAccount('default')
  }
}

export async function autoLogin(context: Context) {
  const accessToken = await getAccountAccessToken()
  if (!accessToken) {
    const autoLoginByHuaweiAccount = getFlushPreference(context, 'commonSetting', 'autoLoginByHuaweiAccount', false)
    const autoLoginByPasskey = getFlushPreference(context, 'commonSetting', 'autoLoginByPasskey', false)
    try {
      if (autoLoginByHuaweiAccount && !autoLoginByPasskey) {
        const loginRequest = new authentication.HuaweiIDProvider().createLoginWithHuaweiIDRequest()
        loginRequest.forceLogin = false
        const controller = new authentication.AuthenticationController()
        const authenticationResponse: authentication.LoginWithHuaweiIDResponse =
          await controller.executeRequest(loginRequest)
        netBoost.setSceneDesc({
          scene: 'login',
          sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
        })
        const loginResponse = await request(context, '/account/getAccessToken', {
          verifyType: 'huaweiaipasswordmemoapp',
          verifyCode: authenticationResponse.data?.authorizationCode
        })
        netBoost.setSceneDesc({
          scene: 'login',
          sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
        })
        if (loginResponse !== 'fail') {
          const accessToken = JSON.parse(loginResponse).accessToken as string
          const uid = JSON.parse(loginResponse).uid as string
          const email = JSON.parse(loginResponse).email as string
          const endDate = JSON.parse(loginResponse).endDate as number
          await setAccount(accessToken, {
            uid: uid,
            email: email,
            endDate: endDate
          })
          await promptAction.openToast({
            message: '华为账号静默登录成功'
          })
          context.eventHub.emit('refreshMe')
        }
      }
      if (autoLoginByPasskey && !autoLoginByHuaweiAccount) {
        const publicKeyAssertionCredential = await fido2.authenticate(context, {
          publicKey: {
            challenge: new util.TextEncoder().encodeInto(String(Date.now()).slice(0, -5) + '00000'),
            timeout: 100000,
            rpId: 'www.zhangls2512.cn'
          }
        })
        netBoost.setSceneDesc({
          scene: 'login',
          sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
        })
        const loginResponse = await request(context, '/account/getAccessToken', {
          verifyType: 'passkey',
          credentialId: new util.Base64Helper().encodeToStringSync(publicKeyAssertionCredential.rawId,
            util.Type.BASIC_URL_SAFE),
          authenticatorData: new util.Base64Helper().encodeToStringSync(publicKeyAssertionCredential.response.authenticatorData,
            util.Type.BASIC_URL_SAFE),
          clientDataJSON: new util.Base64Helper().encodeToStringSync(publicKeyAssertionCredential.response.clientDataJson,
            util.Type.BASIC_URL_SAFE),
          signature: new util.Base64Helper().encodeToStringSync(publicKeyAssertionCredential.response.signature,
            util.Type.BASIC_URL_SAFE)
        })
        netBoost.setSceneDesc({
          scene: 'login',
          sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
        })
        if (loginResponse !== 'fail') {
          const accessToken = JSON.parse(loginResponse).accessToken as string
          const uid = JSON.parse(loginResponse).uid as string
          const email = JSON.parse(loginResponse).email as string
          const endDate = JSON.parse(loginResponse).endDate as number
          await setAccount(accessToken, {
            uid: uid,
            email: email,
            endDate: endDate
          })
          await promptAction.openToast({
            message: '通行密钥静默登录成功'
          })
          context.eventHub.emit('refreshMe')
        }
      }
    } catch (err) {
      if (err.code !== 1021300004) {
        await promptAction.openToast({
          message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
        })
      }
    }
  }
}