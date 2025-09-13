import { cryptoFramework } from '@kit.CryptoArchitectureKit'

interface Totp {
  value: string,
  secondsRemaining: number
}

function base32Decode(key: string) {
  const BASE32_MAP: Record<string, number> = {
    'A': 0,
    'B': 1,
    'C': 2,
    'D': 3,
    'E': 4,
    'F': 5,
    'G': 6,
    'H': 7,
    'I': 8,
    'J': 9,
    'K': 10,
    'L': 11,
    'M': 12,
    'N': 13,
    'O': 14,
    'P': 15,
    'Q': 16,
    'R': 17,
    'S': 18,
    'T': 19,
    'U': 20,
    'V': 21,
    'W': 22,
    'X': 23,
    'Y': 24,
    'Z': 25,
    '2': 26,
    '3': 27,
    '4': 28,
    '5': 29,
    '6': 30,
    '7': 31
  }
  key = key.replace(/=+$/, '')
  if (key.length === 0) {
    return new Uint8Array(0)
  }
  const padding = key.endsWith('===') ? 2 : key.endsWith('==') ? 1 : 0
  const byteLength = Math.floor((key.length * 5) / 8) - padding
  const array = new Uint8Array(byteLength)
  let bits = 0
  let value = 0
  let index = 0
  for (let i = 0; i < key.length; i++) {
    const c = key[i].toUpperCase()
    value = (value << 5) | BASE32_MAP[c]
    bits += 5
    while (bits >= 8) {
      bits -= 8
      array[index++] = (value >>> bits) & 0xFF
    }
  }
  if (padding > 0) {
    const extraBits = (8 - padding) * 5
    value <<= extraBits
    if (index < array.length) {
      array[index] = (value >>> bits) & 0xFF
    }
  }
  return array
}

function numberToBigEndianUint8Array(num: bigint) {
  const buffer = new ArrayBuffer(8)
  const view = new DataView(buffer)
  for (let i = 0; i < 8; i++) {
    view.setUint8(i, Number((num >> (8n * (7n - BigInt(i)))) & 0xFFn))
  }
  return new Uint8Array(buffer)
}

export default function getTotp(key: string, step: number, digits: number): Totp {
  const keyArray = base32Decode(key)
  const time = Math.floor(Date.now() / 1000 / step)
  const timeArray = numberToBigEndianUint8Array(BigInt(time))
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
  const binary = ((hmac[offset] & 0x7f) << 24) |
    ((hmac[offset + 1] & 0xff) << 16) |
    ((hmac[offset + 2] & 0xff) << 8) |
    (hmac[offset + 3] & 0xff)
  const otp = binary % Math.pow(10, digits)
  return {
    value: otp.toString().padStart(digits, '0'),
    secondsRemaining: Math.ceil(step - (Date.now() / 1000 % step))
  }
}