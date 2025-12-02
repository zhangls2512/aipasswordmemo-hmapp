import { getAccountAccessToken } from './Accesstoken'
import request from './Request'

export default async function getCloudServiceStatus(context: Context) {
  const accessToken = await getAccountAccessToken()
  if (accessToken) {
    const accountInfoResponse = await request(context, '/account/getAccountInfo', {
      accessToken: accessToken
    })
    if (accountInfoResponse !== 'fail') {
      const services = JSON.parse(accountInfoResponse).data.service as string[]
      return services.includes('password')
    }
    return false
  }
  return false
}