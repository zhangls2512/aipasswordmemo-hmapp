import { formBindingData, FormExtensionAbility, formProvider } from '@kit.FormKit'
import { getFormMfaList, syncFormMfa } from '../common/Formmfa'
import getTotp from '../common/Totp'

export interface MfaItem {
  name: string,
  value: string
}

interface Message {
  params: MessageParam
}

interface MessageParam {
  action: string
}

export default class EntryFormAbility extends FormExtensionAbility {
  async onFormEvent(formId: string, message: string) {
    const messageObject = JSON.parse(message) as Message
    if (messageObject.params.action === 'refresh') {
      await syncFormMfa(this.context)
      const mfaArray = await getFormMfaList(this.context)
      const result: MfaItem[] = []
      for (let i = 0; i < mfaArray.length; i++) {
        const item = mfaArray[i]
        const mfaInfoArray = item.mfa.split('\0')
        const res = await getTotp(mfaInfoArray[0], Number(mfaInfoArray[1]), Number(mfaInfoArray[2]))
        result.push({
          name: item.passwordName,
          value: res.value
        })
      }
      const formData = formBindingData.createFormBindingData({
        mfaArray: result
      })
      await formProvider.updateForm(formId, formData)
    }
  }
}