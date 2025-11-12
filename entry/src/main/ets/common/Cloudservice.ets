import { get } from './Accesstoken'
import request from './Request'

export default async function getCloudServiceStatus(context: Context, UIContext: UIContext) {
  const accessToken = await get()
  if (accessToken) {
    const infores = await request(context, UIContext, '/account/getAccountInfo', {
      accessToken: accessToken
    })
    if (infores !== 'fail') {
      const service = JSON.parse(infores).data.service as string[]
      return service.includes('password')
    }
    return false
  }
  return false
}