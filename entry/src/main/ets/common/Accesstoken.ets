import { util } from '@kit.ArkTS'
import { asset } from '@kit.AssetStoreKit'

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

export function get() {
  const query: asset.AssetMap = new Map()
  query.set(asset.Tag.ALIAS, stringToArray('accessToken'))
  query.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ALL)
  try {
    const res: asset.AssetMap[] = asset.querySync(query)
    const accessToken: Uint8Array = res[0].get(asset.Tag.SECRET) as Uint8Array
    return arrayToString(accessToken)
  } catch {
    return ''
  }
}

export function set(accessToken: string) {
  const query: asset.AssetMap = new Map()
  query.set(asset.Tag.SECRET, stringToArray(accessToken))
  query.set(asset.Tag.ALIAS, stringToArray('accessToken'))
  query.set(asset.Tag.CONFLICT_RESOLUTION, asset.ConflictResolution.OVERWRITE)
  asset.addSync(query)
}

export function remove() {
  const query: asset.AssetMap = new Map()
  query.set(asset.Tag.ALIAS, stringToArray('accessToken'))
  asset.removeSync(query)
}