import { common } from '@kit.AbilityKit'
import { formBindingData, formProvider } from '@kit.FormKit'
import { read } from '../common/File'
import { FormMfaItem, getFormMfaList, getHasMfaPasswordList, setFormMfa } from '../common/Formmfa'
import getTotp from '../common/Totp'
import { MfaItem } from '../entryformability/EntryFormAbility'

interface MfaFormEditWantParameters {
  cardId: string,
  previewCardId: string
}

@Entry
@ComponentV2
struct Mfaformedit {
  @Local cardId: string = ''
  @Local previewCardId: string = ''
  @Local formMfaArray: FormMfaItem[] = []
  @Local hasMfaPasswordArray: FormMfaItem[] = []
  context = this.getUIContext().getHostContext() as common.UIAbilityContext

  async updateForm() {
    const result: MfaItem[] = []
    for (let i = 0; i < this.formMfaArray.length; i++) {
      const item = this.formMfaArray[i]
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
    await formProvider.updateForm(this.cardId, formData)
    await formProvider.updateForm(this.previewCardId, formData)
  }

  build() {
    List() {
      ListItem() {
        Text('编辑内容实时保存\n点击卡片顶部“刷新”按钮即可获取最新MFA')
          .enableAutoSpacing(true)
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
      }
      .width('100%')

      ForEach(this.formMfaArray, (item: FormMfaItem, index) => {
        ListItem() {
          Row() {
            Text(item.passwordName)
              .enableAutoSpacing(true)
              .layoutWeight(1)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
            if (index !== 0) {
              Image($r('app.media.up'))
                .height(24)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .onClick(async () => {
                  const temp = this.formMfaArray[index]
                  this.formMfaArray[index] = this.formMfaArray[index - 1]
                  this.formMfaArray[index - 1] = temp
                  await setFormMfa(this.context, this.formMfaArray)
                  await this.updateForm()
                })
            }
            if (index !== this.formMfaArray.length - 1) {
              Image($r('app.media.down'))
                .height(24)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .onClick(async () => {
                  const temp = this.formMfaArray[index]
                  this.formMfaArray[index] = this.formMfaArray[index + 1]
                  this.formMfaArray[index + 1] = temp
                  await setFormMfa(this.context, this.formMfaArray)
                  await this.updateForm()
                })
            }
            Image($r('app.media.delete'))
              .height(24)
              .onClick(async () => {
                this.formMfaArray.splice(index, 1)
                await setFormMfa(this.context, this.formMfaArray)
                await this.updateForm()
              })
          }
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
      })
      ForEach(this.hasMfaPasswordArray, (item: FormMfaItem) => {
        if (!this.formMfaArray.some(formItem => formItem.passwordId === item.passwordId)) {
          ListItem() {
            Row() {
              Text(item.passwordName)
                .enableAutoSpacing(true)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Image($r('app.media.add'))
                .height(24)
                .onClick(async () => {
                  this.formMfaArray.push(item)
                  await setFormMfa(this.context, this.formMfaArray)
                  await this.updateForm()
                })
            }
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
        }
      })
    }
    .padding({
      bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      top: $r('sys.float.ohos_id_elements_margin_vertical_m')
    })
    .onAppear(async () => {
      const wantParameters = await read(this.context.tempDir + '/mfaformeditwantparameters.txt')
      if (wantParameters !== 'fail') {
        const parameters = JSON.parse(wantParameters) as MfaFormEditWantParameters
        this.cardId = parameters.cardId
        this.previewCardId = parameters.previewCardId
      }
      this.formMfaArray = await getFormMfaList(this.context)
      this.hasMfaPasswordArray = await getHasMfaPasswordList(this.context)
    })
  }
}