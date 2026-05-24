import { UIExtensionContentSession, Want } from '@kit.AbilityKit'
import { FormEditExtensionAbility } from '@kit.FormKit'
import { write } from '../common/File'

export default class EntryFormEditAbility extends FormEditExtensionAbility {
  async onSessionCreate(want: Want, session: UIExtensionContentSession) {
    await write(this.context.tempDir + '/mfaformeditwantparameters.txt', JSON.stringify(want.parameters))
    session.loadContent('pages/Mfaformedit')
  }
}