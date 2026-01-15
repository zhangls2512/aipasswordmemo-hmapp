import { util } from '@kit.ArkTS'
import { promptAction } from '@kit.ArkUI'
import { asset } from '@kit.AssetStoreKit'
import { cryptoFramework } from '@kit.CryptoArchitectureKit'
import { huks } from '@kit.UniversalKeystoreKit'

interface EncryptData {
  content: string,
  iv: string
}

export function stringToArray(str: string) {
  return new util.TextEncoder().encodeInto(str)
}

function arrayToString(arr: Uint8Array) {
  return util.TextDecoder.create().decodeToString(arr)
}

function encodeBase64(arr: Uint8Array) {
  return new util.Base64Helper().encodeSync(arr)
}

function encodeBase64ToString(arr: Uint8Array) {
  return new util.Base64Helper().encodeToStringSync(arr)
}

function decodeBase64(arr: Uint8Array | string) {
  return new util.Base64Helper().decodeSync(arr)
}

export function getKey(): string {
  const query: asset.AssetMap = new Map()
  query.set(asset.Tag.ALIAS, stringToArray('key'))
  query.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ALL)
  try {
    const keyres = asset.querySync(query)
    const key = keyres[0].get(asset.Tag.SECRET) as Uint8Array
    return arrayToString(key)
  } catch {
    return ''
  }
}

export async function setRandomKey() {
  const keyGenerator = cryptoFramework.createSymKeyGenerator('AES256')
  const key = keyGenerator.generateSymKeySync().getEncoded().data
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
  await promptAction.openToast({
    message: '导入成功'
  })
}

export async function setCustomKey(key: string) {
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
  await promptAction.openToast({
    message: '导入成功'
  })
}

export async function removeKey() {
  await huks.deleteKeyItem('key', {})
  const query: asset.AssetMap = new Map()
  query.set(asset.Tag.ALIAS, stringToArray('key'))
  asset.removeSync(query)
  await promptAction.openToast({
    message: '删除成功'
  })
}

export async function encrypt(content: string): Promise<EncryptData> {
  const random = cryptoFramework.createRandom()
  random.enableHardwareEntropy()
  const iv = random.generateRandomSync(16).data
  const options: huks.HuksOptions = {
    inData: stringToArray(content),
    properties: [
      {
        tag: huks.HuksTag.HUKS_TAG_PURPOSE,
        value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT
      },
      {
        tag: huks.HuksTag.HUKS_TAG_ALGORITHM,
        value: huks.HuksKeyAlg.HUKS_ALG_AES
      },
      {
        tag: huks.HuksTag.HUKS_TAG_KEY_SIZE,
        value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256
      },
      {
        tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE,
        value: huks.HuksCipherMode.HUKS_MODE_CBC
      },
      {
        tag: huks.HuksTag.HUKS_TAG_PADDING,
        value: huks.HuksKeyPadding.HUKS_PADDING_PKCS7
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
}

export async function decrypt(encryptData: EncryptData): Promise<string> {
  try {
    const options: huks.HuksOptions = {
      inData: decodeBase64(encryptData.content),
      properties: [
        {
          tag: huks.HuksTag.HUKS_TAG_PURPOSE,
          value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT
        },
        {
          tag: huks.HuksTag.HUKS_TAG_ALGORITHM,
          value: huks.HuksKeyAlg.HUKS_ALG_AES
        },
        {
          tag: huks.HuksTag.HUKS_TAG_KEY_SIZE,
          value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256
        },
        {
          tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE,
          value: huks.HuksCipherMode.HUKS_MODE_CBC
        },
        {
          tag: huks.HuksTag.HUKS_TAG_PADDING,
          value: huks.HuksKeyPadding.HUKS_PADDING_PKCS7
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
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return 'fail'
  }
}