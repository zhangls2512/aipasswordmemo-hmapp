import { common, insightIntent, InsightIntentExecutor } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { InfoInput, newInfo, newPassword, newTag, PasswordInput, TagInput } from '../common/Datachange'
import { getFilterPasswordList } from '../common/Dataget'

export default class InsightIntentExecutorImpl extends InsightIntentExecutor {
  async onExecuteInUIAbilityForegroundMode(name: string, param: Record<string, Object>) {
    const context = getContext() as common.UIAbilityContext
    const paramString = JSON.stringify(param)
    let message = 'success'
    if (name === 'NewPassword') {
      const paramJson = JSON.parse(paramString) as PasswordInput
      await newPassword(context, {
        name: paramJson.name ?? '',
        info: paramJson.info ?? [],
        tag: paramJson.tag ?? [],
        cloudBackup: false
      })
      context.eventHub.emit('refreshPassword')
    }
    if (name === 'SearchPassword') {
      const paramJson = JSON.parse(paramString) as PasswordInput
      const res = await getFilterPasswordList(context, paramJson.name ?? '', paramJson.info ?? [], paramJson.tag ?? [])
      return {
        code: 0,
        result: {
          data: res
        }
      } as insightIntent.ExecuteResult
    }
    if (name === 'NewInfo') {
      const paramJson = JSON.parse(paramString) as InfoInput
      message = await newInfo(context, {
        type: paramJson.type ?? '',
        value: paramJson.value ?? '',
        cloudBackup: false
      })
      context.eventHub.emit('refreshInfo')
    }
    if (name === 'NewTag') {
      const paramJson = JSON.parse(paramString) as TagInput
      message = await newTag(context, {
        value: paramJson.value ?? '',
        color: '',
        cloudBackup: false
      })
      context.eventHub.emit('refreshTag')
    }
    if (message === 'success') {
      await promptAction.openToast({
        message: '新增成功'
      })
    }
    if (message === 'fail') {
      await promptAction.openToast({
        message: '新增失败，原因：已存在'
      })
    }
    return {
      code: message === 'success' ? 0 : -1,
      result: {
        message: message
      }
    } as insightIntent.ExecuteResult
  }
}