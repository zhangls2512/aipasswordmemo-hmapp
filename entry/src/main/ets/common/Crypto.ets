import { util } from '@kit.ArkTS'
import { promptAction } from '@kit.ArkUI'
import { asset } from '@kit.AssetStoreKit'
import { cryptoFramework } from '@kit.CryptoArchitectureKit'
import { huks } from '@kit.UniversalKeystoreKit'

export interface EncryptData {
  content: string,
  iv: string
}

function stringToArray(str: string): Uint8Array {
  const textEncoder = new util.TextEncoder()
  return textEncoder.encodeInto(str)
}

function arrayToString(arr: Uint8Array): string {
  const textDecoder = util.TextDecoder.create('utf-8', {
    ignoreBOM: true
  })
  return textDecoder.decodeToString(arr, {
    stream: false
  })
}

function encodeBase64(arr: Uint8Array): Uint8Array {
  const base64 = new util.Base64Helper()
  return base64.encodeSync(arr)
}

function encodeBase64ToString(arr: Uint8Array): string {
  const base64 = new util.Base64Helper()
  return base64.encodeToStringSync(arr)
}

function decodeBase64(arr: Uint8Array | string): Uint8Array {
  const base64 = new util.Base64Helper()
  return base64.decodeSync(arr)
}

export function getKey(): string {
  const query: asset.AssetMap = new Map()
  query.set(asset.Tag.ALIAS, stringToArray('key'))
  query.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ALL)
  try {
    const keyres: Array<asset.AssetMap> = asset.querySync(query)
    const key: Uint8Array = keyres[0].get(asset.Tag.SECRET) as Uint8Array
    return arrayToString(key)
  } catch {
    return ''
  }
}

export async function setRandomKey() {
  const keyGenerator = cryptoFramework.createSymKeyGenerator('AES256')
  const keyres = await keyGenerator.generateSymKey()
  const key = keyres.getEncoded().data
  await huks.importKeyItem('key', {
    inData: key,
    properties: [
      {
        tag: huks.HuksTag.HUKS_TAG_ALGORITHM,
        value: huks.HuksKeyAlg.HUKS_ALG_AES
      },
      {
        tag: huks.HuksTag.HUKS_TAG_PURPOSE,
        value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT | huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT
      },
      {
        tag: huks.HuksTag.HUKS_TAG_KEY_SIZE,
        value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256
      }
    ]
  })
  const query: asset.AssetMap = new Map()
  query.set(asset.Tag.SECRET, encodeBase64(key))
  query.set(asset.Tag.ALIAS, stringToArray('key'))
  query.set(asset.Tag.CONFLICT_RESOLUTION, asset.ConflictResolution.OVERWRITE)
  asset.addSync(query)
}

export async function setCustomKey(key: string): Promise<string> {
  try {
    await huks.importKeyItem('key', {
      inData: decodeBase64(stringToArray(key)),
      properties: [
        {
          tag: huks.HuksTag.HUKS_TAG_ALGORITHM,
          value: huks.HuksKeyAlg.HUKS_ALG_AES
        },
        {
          tag: huks.HuksTag.HUKS_TAG_PURPOSE,
          value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT | huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT
        },
        {
          tag: huks.HuksTag.HUKS_TAG_KEY_SIZE,
          value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256
        }
      ]
    })
    const query: asset.AssetMap = new Map()
    query.set(asset.Tag.SECRET, stringToArray(key))
    query.set(asset.Tag.ALIAS, stringToArray('key'))
    query.set(asset.Tag.CONFLICT_RESOLUTION, asset.ConflictResolution.OVERWRITE)
    asset.addSync(query)
    return 'success'
  } catch {
    return 'fail'
  }
}

export async function removeKey(): Promise<string> {
  try {
    await huks.deleteKeyItem('key', {})
    const query: asset.AssetMap = new Map()
    query.set(asset.Tag.ALIAS, stringToArray('key'))
    asset.removeSync(query)
    return 'success'
  } catch {
    return 'fail'
  }
}

export async function encrypt(content: string): Promise<EncryptData | string> {
  const random = cryptoFramework.createRandom()
  const iv = random.generateRandomSync(16).data
  try {
    const options: huks.HuksOptions = {
      inData: stringToArray(content),
      properties: [
        {
          tag: huks.HuksTag.HUKS_TAG_ALGORITHM,
          value: huks.HuksKeyAlg.HUKS_ALG_AES
        },
        {
          tag: huks.HuksTag.HUKS_TAG_PURPOSE,
          value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT
        },
        {
          tag: huks.HuksTag.HUKS_TAG_KEY_SIZE,
          value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256
        },
        {
          tag: huks.HuksTag.HUKS_TAG_PADDING,
          value: huks.HuksKeyPadding.HUKS_PADDING_PKCS7
        },
        {
          tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE,
          value: huks.HuksCipherMode.HUKS_MODE_CBC
        },
        {
          tag: huks.HuksTag.HUKS_TAG_IV,
          value: iv
        }
      ]
    }
    const session = await huks.initSession('key', options)
    const res = await huks.finishSession(session.handle, options)
    return {
      content: encodeBase64ToString(res.outData as Uint8Array),
      iv: encodeBase64ToString(iv)
    }
  } catch (err) {
    promptAction.showDialog({
      title: '加密失败',
      message: JSON.stringify(err),
      buttons: [
        {
          text: '确定',
          color: $r('sys.color.font_emphasize')
        }
      ]
    })
    return 'fail'
  }
}

export async function decrypt(encryptData: EncryptData): Promise<string> {
  try {
    const options: huks.HuksOptions = {
      inData: decodeBase64(encryptData.content),
      properties: [
        {
          tag: huks.HuksTag.HUKS_TAG_ALGORITHM,
          value: huks.HuksKeyAlg.HUKS_ALG_AES
        },
        {
          tag: huks.HuksTag.HUKS_TAG_PURPOSE,
          value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT
        },
        {
          tag: huks.HuksTag.HUKS_TAG_KEY_SIZE,
          value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256
        },
        {
          tag: huks.HuksTag.HUKS_TAG_PADDING,
          value: huks.HuksKeyPadding.HUKS_PADDING_PKCS7
        },
        {
          tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE,
          value: huks.HuksCipherMode.HUKS_MODE_CBC
        },
        {
          tag: huks.HuksTag.HUKS_TAG_IV,
          value: decodeBase64(encryptData.iv)
        }
      ]
    }
    const session = await huks.initSession('key', options)
    const res = await huks.finishSession(session.handle, options)
    return arrayToString(res.outData as Uint8Array)
  } catch (err) {
    promptAction.showDialog({
      title: '解密失败',
      message: JSON.stringify(err),
      buttons: [
        {
          text: '确定',
          color: $r('sys.color.font_emphasize')
        }
      ]
    })
    return 'fail'
  }
}