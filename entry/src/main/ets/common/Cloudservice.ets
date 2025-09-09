import { get } from './Accesstoken'
import request from './Request'

export default async function getCloudServiceStatus() {
  const accessToken = await get()
  if (accessToken) {
    const infores = await request('/account/getAccountInfo', {
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