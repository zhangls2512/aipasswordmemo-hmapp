import { common } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { getFilterPasswordList, Password } from '../common/Dataget'
import getTotp from '../common/Totp'

interface MfaItem {
  id: number,
  mfa: string
}

@Entry
@ComponentV2
struct Searchpasswordstatusbar {
  @Local passwordArray: Password[] = []
  @Local mfaArray: MfaItem[] = []
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  intervalId = -1

  build() {
    List() {
      ForEach(this.passwordArray, (item: Password, index) => {
        ListItem() {
          Column() {
            Row() {
              if (item.info.find(infoItem => infoItem.type === '图标')) {
                Image(item.info.find(infoItem => infoItem.type === '图标')?.value)
                  .autoResize(true)
                  .copyOption(CopyOptions.LocalDevice)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .width('10%')
                  .onError(async (err) => {
                    await promptAction.openToast({
                      message: '发生错误，错误信息：' + err.message
                    })
                  })
              }
              Column() {
                Text(item.name)
                  .enableAutoSpacing(true)
                  .fontWeight(FontWeight.Bold)
                Row() {
                  Text('MFA')
                    .fontWeight(FontWeight.Medium)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                  Text(this.mfaArray.find(mfaItem => mfaItem.id === item.id)?.mfa)
                    .copyOption(CopyOptions.LocalDevice)
                    .layoutWeight(1)
                }
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .borderRadius(12)
            .padding(12)
          }
          .backgroundColor($r('sys.color.comp_background_primary'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
        .margin({
          top: index === 0 ? 0 : $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
      })
    }
    .padding({
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
    })
    .onAppear(() => {
      this.intervalId = setInterval(async () => {
        const passwordArray = await getFilterPasswordList(this.context, '', [], [])
        this.passwordArray = passwordArray.filter(item => item.info.find(itemb => itemb.type === 'MFA'))
        const mfaArray: MfaItem[] = []
        const promises = this.passwordArray.map(async (item) => {
          const mfaInfo = item.info.find(infoItem => infoItem.type === 'MFA')
          if (mfaInfo) {
            const mfaInfoArray = mfaInfo.value.split('\0')
            const res = await getTotp(mfaInfoArray[0], Number(mfaInfoArray[1]), Number(mfaInfoArray[2]))
            if (res.value !== 'fail') {
              mfaArray.push({
                id: item.id,
                mfa: res.value
              })
            }
            if (res.value === 'fail') {
              clearInterval(this.intervalId)
            }
          }
        })
        await Promise.all(promises)
        this.mfaArray = mfaArray
      }, 500)
    })
    .onDisAppear(() => {
      if (this.intervalId !== -1) {
        clearInterval(this.intervalId)
      }
    })
  }
}