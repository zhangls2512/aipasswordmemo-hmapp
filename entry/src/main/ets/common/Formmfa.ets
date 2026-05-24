import { fileIo } from '@kit.CoreFileKit'
import { getPasswordInfo, getPasswordList } from './Dataget'
import { read, write } from './File'

export interface FormMfaItem {
  passwordId: number,
  passwordName: string,
  mfa: string
}

export async function getFormMfaList(context: Context) {
  const filePath = context.filesDir + '/formdata/mfa.txt'
  const exist = fileIo.accessSync(filePath)
  if (!exist) {
    return []
  }
  const res = await read(filePath)
  return JSON.parse(res) as FormMfaItem[]
}

export async function setFormMfa(context: Context, list: FormMfaItem[]) {
  await write(context.filesDir + '/formdata/mfa.txt', JSON.stringify(list))
}

export async function syncFormMfa(context: Context) {
  const formMfas = await getFormMfaList(context)
  const deleteSet = new Set<number>()
  for (let i = 0; i < formMfas.length; i++) {
    const item = formMfas[i]
    const res = await getPasswordInfo(context, item.passwordId)
    if (res !== 'fail') {
      const mfaInfo = res.info.find(infoItem => infoItem.type === 'MFA')
      if (!mfaInfo) {
        deleteSet.add(item.passwordId)
      }
      if (mfaInfo) {
        item.passwordName = res.name
        item.mfa = mfaInfo.value
      }
    }
    if (res === 'fail') {
      deleteSet.add(item.passwordId)
    }
  }
  await setFormMfa(context, formMfas.filter(item => !deleteSet.has(item.passwordId)))
}

export async function getHasMfaPasswordList(context: Context) {
  const result: FormMfaItem[] = []
  const res = await getPasswordList(context)
  res.forEach(item => {
    const mfaInfo = item.info.find(infoItem => infoItem.type === 'MFA')
    if (mfaInfo) {
      result.push({
        passwordId: item.id,
        passwordName: item.name,
        mfa: mfaInfo.value
      })
    }
  })
  return result
}