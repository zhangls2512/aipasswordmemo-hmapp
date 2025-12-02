import { preferences } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { rcp } from '@kit.RemoteCommunicationKit'

interface ErrorResponse {
  errCode: number,
  errMsg: string,
  errFix: string
}

export default async function request(context: Context, path: string, body: rcp.RequestContent) {
  const commonSettingDataPreferences = preferences.getPreferencesSync(context, {
    name: 'commonSetting'
  })
  const allService = commonSettingDataPreferences.getSync('allService', true)
  if (!allService) {
    context.eventHub.emit('dialog', '全量模式未开启',
      '全量模式未开启，无法使用在线功能。如需使用在线功能，请前往“我的”>“设置”>“更多”>“应用服务模式”，开启全量模式。')
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
      context.eventHub.emit('dialog', '接口调用失败',
        '错误码：' + res.errCode + '\n错误信息：' + res.errMsg + '\n修复方法：' + res.errFix)
      return 'fail'
    }
    await promptAction.openToast({
      message: '请求失败，错误码：' + response.statusCode
    })
    return 'fail'
  } catch (err) {
    session.close()
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return 'fail'
  }
}