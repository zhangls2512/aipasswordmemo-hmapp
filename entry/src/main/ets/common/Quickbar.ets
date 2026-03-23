import { quickBarManager } from '@kit.DeskTopExtensionKit'
import { getPasswordList } from './Dataget'

interface QuickBarPasswordItem {
  taskId: number,
  passwordId: number
}

export async function getQuickBarPasswordIdList(context: Context) {
  try {
    const customCategories = await quickBarManager.getCustomCategories(context)
    const passwordCustomCategory = customCategories.find(item => item.categoryName === '常用密码')
    if (passwordCustomCategory) {
      try {
        const passwordTasks = await quickBarManager.getTasksFromCategory(context, passwordCustomCategory.categoryId)
        return passwordTasks.map(item => {
          const parameters = item.taskInfo.parameters
          if (parameters) {
            return Number(parameters.find(item => item.key === 'passwordId')?.value)
          }
          return -1
        }).filter(item => item !== -1)
      } catch {
        return []
      }
    } else {
      return []
    }
  } catch {
    return []
  }
}

export async function setQuickBarPassword(context: Context, passwordId: number, passwordName: string) {
  try {
    await quickBarManager.addCustomCategory(context, '常用密码')
  } catch {
  }
  const customCategories = await quickBarManager.getCustomCategories(context)
  const passwordCustomCategory = customCategories.find(item => item.categoryName === '常用密码')
  if (passwordCustomCategory) {
    try {
      const passwordTaskArray = await quickBarManager.getTasksFromCategory(context, passwordCustomCategory.categoryId)
      const passwordTasks = passwordTaskArray.map((item): QuickBarPasswordItem => {
        const parameters = item.taskInfo.parameters
        if (parameters) {
          return {
            taskId: item.taskId,
            passwordId: Number(parameters.find(item => item.key === 'passwordId')?.value)
          }
        }
        return {
          taskId: -1,
          passwordId: -1
        }
      }).filter(item => item.passwordId !== -1)
      const passwordTask = passwordTasks.find(item => item.passwordId === passwordId)
      if (!passwordTask) {
        await quickBarManager.addQuickTask(context, passwordCustomCategory.categoryId, {
          taskName: passwordName,
          abilityName: 'EntryAbility',
          parameters: [
            {
              key: 'action',
              value: 'passwordInfo'
            },
            {
              key: 'passwordId',
              value: String(passwordId)
            }
          ]
        })
      }
      if (passwordTask) {
        await quickBarManager.updateQuickTask(context, {
          taskId: passwordTask.taskId,
          categoryId: passwordCustomCategory.categoryId,
          taskInfo: {
            taskName: passwordName,
            abilityName: 'EntryAbility',
            parameters: [
              {
                key: 'action',
                value: 'passwordInfo'
              },
              {
                key: 'passwordId',
                value: String(passwordId)
              }
            ]
          }
        })
      }
    } catch {
      await quickBarManager.addQuickTask(context, passwordCustomCategory.categoryId, {
        taskName: passwordName,
        abilityName: 'EntryAbility',
        parameters: [
          {
            key: 'action',
            value: 'passwordInfo'
          },
          {
            key: 'passwordId',
            value: String(passwordId)
          }
        ]
      })
    }
  }
}

export async function deleteQuickBarPassword(context: Context, passwordId: number) {
  try {
    const customCategories = await quickBarManager.getCustomCategories(context)
    const passwordCustomCategory = customCategories.find(item => item.categoryName === '常用密码')
    if (passwordCustomCategory) {
      const passwordTasks = await quickBarManager.getTasksFromCategory(context, passwordCustomCategory.categoryId)
      const promises = passwordTasks.map(async (item) => {
        const parameters = item.taskInfo.parameters
        if (parameters) {
          if (parameters.find(item => item.key === 'passwordId')?.value === String(passwordId)) {
            await quickBarManager.deleteQuickTask(context, item.taskId)
          }
        }
      })
      await Promise.all(promises)
      const passwordIds = await getQuickBarPasswordIdList(context)
      if (passwordIds.length === 0) {
        await quickBarManager.deleteCustomCategory(context, passwordCustomCategory.categoryId)
      }
    }
  } catch {
  }
}

export async function syncQuickBarPassword(context: Context) {
  const passwordIds = await getQuickBarPasswordIdList(context)
  const passwords = await getPasswordList(context)
  const promises = passwordIds.map(async (item) => {
    const password = passwords.find(passwordItem => passwordItem.id === item)
    if (!password) {
      await deleteQuickBarPassword(context, item)
    }
    if (password) {
      await setQuickBarPassword(context, item, password.name)
    }
  })
  await Promise.all(promises)
}