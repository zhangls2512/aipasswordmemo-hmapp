import { promptAction } from '@kit.ArkUI'
import { BusinessError } from '@kit.BasicServicesKit'
import { rcp } from '@kit.RemoteCommunicationKit'

interface ErrorResponse {
  errCode: number
  errMsg: string
  errFix: string
}

export async function httpRequest(path: string, body: rcp.RequestContent) {
  const session = rcp.createSession()
  try {
    const response = await session.post('https://api.zhangls2512.cn' + path, body)
    session.close()
    if (response.statusCode === 200) {
      let body: string = 'undefined'
      if (response.toString()) {
        body = response.toString() as string
      }
      const errCode = JSON.parse(body).errCode as number
      if (errCode === 0) {
        return body
      } else {
        const res = JSON.parse(body) as ErrorResponse
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
    } else {
      promptAction.showToast({
        message: '请求失败，错误码：' + response.statusCode + '，错误信息：' + response.reasonPhrase
      })
      return 'fail'
    }
  } catch (err) {
    session.close()
    promptAction.showToast({
      message: '发生错误，错误码：' + (err as BusinessError).code + '，错误信息：' +
      (err as BusinessError).message
    })
    return 'fail'
  }
}