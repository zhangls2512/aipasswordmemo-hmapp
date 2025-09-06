import { preferences } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { rcp } from '@kit.RemoteCommunicationKit'

interface ErrorResponse {
  errCode: number
  errMsg: string
  errFix: string
}

export default async function request(path: string, body: rcp.RequestContent, hideDialog?: boolean) {
  const context = getContext()
  const commonSettingDataPreferences = preferences.getPreferencesSync(context, {
    name: 'commonSetting'
  })
  const allService = commonSettingDataPreferences.getSync('allService', true)
  if (!allService) {
    promptAction.showDialog({
      title: '全量模式未开启',
      message: '全量模式未开启，无法使用在线功能。如需使用在线功能，请前往“我的”>“设置”>“应用服务模式”，开启全量模式。',
      buttons: [
        {
          text: '确定',
          color: $r('sys.color.font_emphasize')
        }
      ]
    })
    return 'fail'
  }
  const session = rcp.createSession()
  try {
    const response = await session.post('https://api.zhangls2512.cn' + path, body)
    session.close()
    if (response.statusCode === 200) {
      let body = ''
      if (response.toString()) {
        body = response.toString() as string
      }
      const errCode = JSON.parse(body).errCode as number
      if (errCode === 0) {
        return body
      }
      const res = JSON.parse(body) as ErrorResponse
      if (res.errCode === 3061 && !hideDialog) {
        promptAction.showDialog({
          title: '提示',
          message: '此华为账号未绑定轩铭 2512 统一账号。请您使用其他验证方式 (密码、MFA、邮箱验证码) 登录轩铭 2512 统一账号，依次进入“设置”>“绑定华为账号”，绑定华为账号后即可使用华为账号登录。',
          buttons: [
            {
              text: '确定',
              color: $r('sys.color.font_emphasize')
            }
          ]
        })
        return 'fail'
      }
      promptAction.showDialog({
        title: '接口调用失败',
        message: '错误码：' + res.errCode + '\n错误信息：' + res.errMsg + '\n修复方法：' + res.errFix,
        buttons: [
          {
            text: '确定',
            color: $r('sys.color.font_emphasize')
          }
        ]
      })
      return 'fail'
    }
    promptAction.openToast({
      message: '请求失败，错误码：' + response.statusCode
    })
    return 'fail'
  } catch (err) {
    session.close()
    promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return 'fail'
  }
}