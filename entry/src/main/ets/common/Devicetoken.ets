import { promptAction } from '@kit.ArkUI'
import { deviceCertificate } from '@kit.DeviceSecurityKit'

export default async function get(): Promise<string> {
  try {
    const deviceToken = await deviceCertificate.getDeviceToken()
    return deviceToken
  } catch (err) {
    promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return ''
  }
}