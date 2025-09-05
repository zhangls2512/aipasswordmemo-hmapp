import { common } from '@kit.AbilityKit'
import { authentication } from '@kit.AccountKit'
import { preferences } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { appAccount } from '@kit.BasicServicesKit'
import request from './Request'

export interface AccountInfo {
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

export async function get(): Promise<string> {
  const appAccountManager = appAccount.createAppAccountManager()
  try {
    const endDate = Number(appAccountManager.getCustomDataSync('default', 'endDate'))
    if (endDate < Date.now() && endDate !== 0) {
      await appAccountManager.removeAccount('default')
      promptAction.showToast({
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
      promptAction.showToast({
        message: '登录已到期，请重新登录'
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
  const accessToken = await get()
  if (!accessToken) {
    const context = getContext() as common.UIAbilityContext
    const commonSettingDataPreferences = preferences.getPreferencesSync(context, {
      name: 'commonSetting'
    })
    const autoLoginByHuaweiAccount = commonSettingDataPreferences.getSync('autoLoginByHuaweiAccount', false)
    if (autoLoginByHuaweiAccount) {
      const loginRequest = new authentication.HuaweiIDProvider().createLoginWithHuaweiIDRequest()
      loginRequest.forceLogin = false
      try {
        const controller = new authentication.AuthenticationController()
        const resa: authentication.LoginWithHuaweiIDResponse = await controller.executeRequest(loginRequest)
        const res = await request('/account/getAccessToken', {
          verifyType: 'huaweiaipasswordmemoapp',
          verifyCode: resa.data?.authorizationCode
        }, true)
        if (res !== 'fail') {
          const accessToken = JSON.parse(res).accessToken as string
          const uid = JSON.parse(res).uid as string
          const email = JSON.parse(res).email as string
          const endDate = JSON.parse(res).endDate as number
          set(accessToken, {
            uid: uid,
            email: email,
            endDate: endDate
          })
          promptAction.showToast({
            message: '华为账号静默登录成功'
          })
        }
      } catch (err) {
        promptAction.showToast({
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