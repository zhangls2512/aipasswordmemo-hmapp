import { util } from '@kit.ArkTS'

function getNumber(data: number, start: number, end: number) {
  const binarystring = data.toString(2).padStart(8, '0')
  const resultstring = binarystring.substring(start, end + 1)
  return parseInt(resultstring, 2)
}

export default function getPublicKey(inputData: Uint8Array): string {
  let publicKey = ''
  const data = Array.from(inputData)
  let offset = 0
  let pendingParseKeyCount = getNumber(data[offset], 3, 7)
  while (pendingParseKeyCount > 0) {
    offset++
    offset += getNumber(data[offset], 3, 7)
    offset++
    const valueType = getNumber(data[offset], 0, 2)
    if (valueType === 2) {
      let valueValueLength = getNumber(data[offset], 3, 7)
      if (valueValueLength == 24) {
        offset++
        valueValueLength = data[offset]
      }
      if (valueValueLength == 25) {
        offset++
        let lengthstring = data[offset].toString(2).padStart(8, '0')
        offset++
        lengthstring += data[offset].toString(2).padStart(8, '0')
        valueValueLength = parseInt(lengthstring, 2)
      }
      if (valueValueLength == 26) {
        let lengthstring = ''
        for (let i = 0; i < 4; i++) {
          offset++
          lengthstring += data[offset].toString(2).padStart(8, '0')
        }
        valueValueLength = parseInt(lengthstring, 2)
      }
      if (valueValueLength == 27) {
        let lengthstring = ''
        for (let i = 0; i < 8; i++) {
          offset++
          lengthstring += data[offset].toString(2).padStart(8, '0')
        }
        valueValueLength = parseInt(lengthstring, 2)
      }
      const authData: number[] = []
      for (let i = 1; i <= valueValueLength; i++) {
        offset++
        authData.push(data[offset])
      }
      const credentialIdLength =
        parseInt(authData[53].toString(2).padStart(8, '0') + authData[54].toString(2).padStart(8, '0'), 2)
      const cosePublicKey: number[] = []
      for (let i = 55 + credentialIdLength; i < authData.length; i++) {
        cosePublicKey.push(authData[i])
      }
      const publickeyx: number[] = []
      for (let i = 10; i < 42; i++) {
        publickeyx.push(cosePublicKey[i])
      }
      const publickeyy: number[] = []
      for (let i = 45; i < 77; i++) {
        publickeyy.push(cosePublicKey[i])
      }
      const derPublicKeyHeader =
        [48, 89, 48, 19, 6, 7, 42, 134, 72, 206, 61, 2, 1, 6, 8, 42, 134, 72, 206, 61, 3, 1, 7, 3, 66, 0, 4]
      publicKey = new util.Base64Helper().encodeToStringSync(new Uint8Array(derPublicKeyHeader.concat(publickeyx)
        .concat(publickeyy)), util.Type.BASIC_URL_SAFE)
    }
    if (valueType === 3) {
      offset += getNumber(data[offset], 3, 7)
    }
    if (valueType === 5) {
      let pendingParseKeyCounta = getNumber(data[offset], 3, 7)
      while (pendingParseKeyCounta > 0) {
        offset++
        offset += getNumber(data[offset], 3, 7)
        offset++
        const valueTypea = getNumber(data[offset], 0, 2)
        if (valueTypea === 2) {
          let valueValueLength = getNumber(data[offset], 3, 7)
          if (valueValueLength == 24) {
            offset++
            valueValueLength = data[offset]
          }
          if (valueValueLength == 25) {
            offset++
            let lengthstring = data[offset].toString(2).padStart(8, '0')
            offset++
            lengthstring += data[offset].toString(2).padStart(8, '0')
            valueValueLength = parseInt(lengthstring, 2)
          }
          if (valueValueLength == 26) {
            let lengthstring = ''
            for (let i = 0; i < 4; i++) {
              offset++
              lengthstring += data[offset].toString(2).padStart(8, '0')
            }
            valueValueLength = parseInt(lengthstring, 2)
          }
          if (valueValueLength == 27) {
            let lengthstring = ''
            for (let i = 0; i < 8; i++) {
              offset++
              lengthstring += data[offset].toString(2).padStart(8, '0')
            }
            valueValueLength = parseInt(lengthstring, 2)
          }
          offset += valueValueLength
        }
        if (valueTypea === 3) {
          offset += getNumber(data[offset], 3, 7)
        }
        if (valueTypea === 4) {
          let pendingParseItemCount = getNumber(data[offset], 3, 7)
          while (pendingParseItemCount > 0) {
            offset++
            let itemLength = getNumber(data[offset], 3, 7)
            if (itemLength == 24) {
              offset++
              itemLength = data[offset]
            }
            if (itemLength == 25) {
              offset++
              let lengthstring = data[offset].toString(2).padStart(8, '0')
              offset++
              lengthstring += data[offset].toString(2).padStart(8, '0')
              itemLength = parseInt(lengthstring, 2)
            }
            if (itemLength == 26) {
              let lengthstring = ''
              for (let i = 0; i < 4; i++) {
                offset++
                lengthstring += data[offset].toString(2).padStart(8, '0')
              }
              itemLength = parseInt(lengthstring, 2)
            }
            if (itemLength == 27) {
              let lengthstring = ''
              for (let i = 0; i < 8; i++) {
                offset++
                lengthstring += data[offset].toString(2).padStart(8, '0')
              }
              itemLength = parseInt(lengthstring, 2)
            }
            offset += itemLength
            pendingParseItemCount--
          }
        }
        pendingParseKeyCounta--
      }
    }
    pendingParseKeyCount--
  }
  return publicKey
}