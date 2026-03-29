import { promptAction } from '@kit.ArkUI'
import { cryptoFramework } from '@kit.CryptoArchitectureKit'

interface Totp {
  value: string,
  secondsRemaining: number
}

function base32Decode(key: string) {
  const base32Characters =
    ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W',
      'X', 'Y', 'Z', '2', '3', '4', '5', '6', '7']
  const filterKey = key.toUpperCase().split('').filter(item => base32Characters.includes(item))
  let bits = 0
  let value = 0
  const result: number[] = []
  for (let i = 0; i < filterKey.length; i++) {
    const item = filterKey[i]
    value = (value << 5) | base32Characters.indexOf(item)
    bits += 5
    if (bits >= 8) {
      bits -= 8
      result.push((value >>> bits) & 0xff)
    }
  }
  return new Uint8Array(result)
}

export default async function getTotp(key: string, step: number, digits: number): Promise<Totp> {
  try {
    const keyArray = base32Decode(key)
    const time = Math.floor(Date.now() / 1000 / step)
    const buffer = new ArrayBuffer(8)
    const view = new DataView(buffer)
    view.setBigUint64(0, BigInt(time))
    const timeArray = new Uint8Array(buffer)
    const macGenerator = cryptoFramework.createSymKeyGenerator('HMAC')
    const symKey = macGenerator.convertKeySync({
      data: keyArray
    })
    const mac = cryptoFramework.createMac('SHA1')
    mac.initSync(symKey)
    mac.updateSync({
      data: timeArray
    })
    const hmac = mac.doFinalSync().data
    const offset = hmac[hmac.length - 1] & 0xf
    const binary = ((hmac[offset] & 0x7f) << 24) | ((hmac[offset + 1] & 0xff) << 16) |
      ((hmac[offset + 2] & 0xff) << 8) | (hmac[offset + 3] & 0xff)
    const otp = binary % Math.pow(10, digits)
    return {
      value: otp.toString().padStart(digits, '0'),
      secondsRemaining: Math.ceil(step - (Date.now() / 1000 % step))
    }
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return {
      value: 'fail',
      secondsRemaining: -1
    }
  }
}