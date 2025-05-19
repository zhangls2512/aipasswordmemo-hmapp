import { common, ConfigurationConstant } from '@kit.AbilityKit'
import { updateManager } from '@kit.AppGalleryKit'
import { preferences, relationalStore } from '@kit.ArkData'
import { EntityType, textProcessing } from '@kit.NaturalLanguageKit'
import { get, remove } from './Accesstoken'
import getCloudServiceStatus from './Cloudservice'
import { newInfo } from './Datachange'
import { checkPermission } from './Permission'
import request from './Request'
import { backupTable, recoveryTable } from './Table'

export default async function parseContent(content: string): Promise<string[]> {
  const array: string[] = []
  const context = getContext() as common.UIAbilityContext
  const commonSettingDataPreferences = preferences.getPreferencesSync(context, {
    name: 'commonSetting'
  })
  const dataSettingDataPreferences = preferences.getPreferencesSync(context, {
    name: 'dataSetting'
  })
  if (content.includes('好')) {
    array.push('请说出需要我帮您执行的具体操作，例如“设置深色模式”。')
  }
  if (content.includes('重启')) {
    const applicationContext = context.getApplicationContext()
    applicationContext.restartApp({
      bundleName: 'com.zhangxm.aipasswordmemo',
      abilityName: 'EntryAbility'
    })
  }
  if (content.includes('退出应用')) {
    context.terminateSelf()
  }
  if (content.includes('登录') && !content.includes('退出登录')) {
    if (!get()) {
      array.push('登录需要您手动操作。您可以依次进入“我的”>“登录”登录账号。')
    }
    if (get()) {
      array.push('您已登录。')
    }
  }
  if (content.includes('退出登录')) {
    if (!get()) {
      array.push('未登录账号，无法退出登录。')
    }
    if (get()) {
      remove()
      const loginDataPreferences = preferences.getPreferencesSync(context, {
        name: 'login'
      })
      loginDataPreferences.deleteSync('endDate')
      array.push('已退出登录。')
    }
  }
  if (content.includes('浅色')) {
    const applicationContext = context.getApplicationContext()
    applicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT)
    commonSettingDataPreferences.putSync('colorMode', 1)
    commonSettingDataPreferences.flushSync()
    array.push('已设置为浅色模式。')
  }
  if (content.includes('深色')) {
    const applicationContext = context.getApplicationContext()
    applicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK)
    commonSettingDataPreferences.putSync('colorMode', 2)
    commonSettingDataPreferences.flushSync()
    array.push('已设置为深色模式。')
  }
  if (content.includes('检查更新')) {
    try {
      const res = await updateManager.checkAppUpdate(context)
      const hasUpdate = res.updateAvailable
      if (hasUpdate === 0) {
        array.push('已是最新版本。')
      }
      if (hasUpdate === 1) {
        updateManager.showUpdateDialog(context)
        array.push('有新版本，您可在弹窗中更新。')
      }
    } catch {
      array.push('很抱歉，检查更新失败。')
    }
  }
  if (content.includes('开启密码同步')) {
    const onTables = dataSettingDataPreferences.getSync('onTables', []) as string[]
    if (onTables.includes('password')) {
      array.push('密码同步已开启。')
    }
    if (!onTables.includes('password')) {
      const res = await checkPermission('ohos.permission.DISTRIBUTED_DATASYNC')
      if (!res) {
        array.push('很抱歉，因您未授权，无法开启密码同步。')
      }
      if (res) {
        const rdbStore = await relationalStore.getRdbStore(context, {
          name: 'password',
          securityLevel: 4,
          encrypt: true,
          allowRebuild: true
        })
        await rdbStore.setDistributedTables(['password'])
        const newOnTables = [...onTables, 'password']
        dataSettingDataPreferences.putSync('onTables', newOnTables)
        dataSettingDataPreferences.flushSync()
        array.push('已开启密码同步。')
      }
    }
  }
  if (content.includes('开启常用信息同步')) {
    const onTables = dataSettingDataPreferences.getSync('onTables', []) as string[]
    if (onTables.includes('info')) {
      array.push('常用信息同步已开启。')
    }
    if (!onTables.includes('info')) {
      const res = await checkPermission('ohos.permission.DISTRIBUTED_DATASYNC')
      if (!res) {
        array.push('很抱歉，因您未授权，无法开启常用信息同步。')
      }
      if (res) {
        const rdbStore = await relationalStore.getRdbStore(context, {
          name: 'info',
          securityLevel: 4,
          encrypt: true,
          allowRebuild: true
        })
        await rdbStore.setDistributedTables(['info'])
        const newOnTables = [...onTables, 'info']
        dataSettingDataPreferences.putSync('onTables', newOnTables)
        dataSettingDataPreferences.flushSync()
        array.push('已开启常用信息同步。')
      }
    }
  }
  if (content.includes('开启标签同步')) {
    const onTables = dataSettingDataPreferences.getSync('onTables', []) as string[]
    if (onTables.includes('tag')) {
      array.push('标签同步已开启。')
    }
    if (!onTables.includes('tag')) {
      const res = await checkPermission('ohos.permission.DISTRIBUTED_DATASYNC')
      if (!res) {
        array.push('很抱歉，因您未授权，无法开启标签同步。')
      }
      if (res) {
        const rdbStore = await relationalStore.getRdbStore(context, {
          name: 'tag',
          securityLevel: 1,
          encrypt: true,
          allowRebuild: true
        })
        await rdbStore.setDistributedTables(['tag'])
        const newOnTables = [...onTables, 'tag']
        dataSettingDataPreferences.putSync('onTables', newOnTables)
        dataSettingDataPreferences.flushSync()
        array.push('已开启标签同步。')
      }
    }
  }
  if (content.includes('开启密码自动同步')) {
    const autoSyncTables = dataSettingDataPreferences.getSync('autoSyncTables', []) as string[]
    if (autoSyncTables.includes('password')) {
      array.push('密码自动同步已开启。')
    }
    if (!autoSyncTables.includes('password')) {
      const onTables = dataSettingDataPreferences.getSync('onTables', []) as string[]
      if (!onTables.includes('password')) {
        const res = await checkPermission('ohos.permission.DISTRIBUTED_DATASYNC')
        if (!res) {
          array.push('很抱歉，因您未授权，无法开启密码自动同步。')
        }
        if (res) {
          const rdbStore = await relationalStore.getRdbStore(context, {
            name: 'password',
            securityLevel: 4,
            encrypt: true,
            allowRebuild: true
          })
          await rdbStore.setDistributedTables(['password'])
          const newOnTables = [...onTables, 'password']
          dataSettingDataPreferences.putSync('onTables', newOnTables)
          dataSettingDataPreferences.flushSync()
          const newAutoSyncTables = [...autoSyncTables, 'password']
          dataSettingDataPreferences.putSync('autoSyncTables', newAutoSyncTables)
          dataSettingDataPreferences.flushSync()
          array.push('已开启密码自动同步。')
        }
      }
      if (onTables.includes('password')) {
        const newAutoSyncTables = [...autoSyncTables, 'password']
        dataSettingDataPreferences.putSync('autoSyncTables', newAutoSyncTables)
        dataSettingDataPreferences.flushSync()
        array.push('已开启密码自动同步。')
      }
    }
  }
  if (content.includes('开启常用信息自动同步')) {
    const autoSyncTables = dataSettingDataPreferences.getSync('autoSyncTables', []) as string[]
    if (autoSyncTables.includes('info')) {
      array.push('常用信息自动同步已开启。')
    }
    if (!autoSyncTables.includes('info')) {
      const onTables = dataSettingDataPreferences.getSync('onTables', []) as string[]
      if (!onTables.includes('info')) {
        const res = await checkPermission('ohos.permission.DISTRIBUTED_DATASYNC')
        if (!res) {
          array.push('很抱歉，因您未授权，无法开启常用信息自动同步。')
        }
        if (res) {
          const rdbStore = await relationalStore.getRdbStore(context, {
            name: 'info',
            securityLevel: 4,
            encrypt: true,
            allowRebuild: true
          })
          await rdbStore.setDistributedTables(['info'])
          const newOnTables = [...onTables, 'info']
          dataSettingDataPreferences.putSync('onTables', newOnTables)
          dataSettingDataPreferences.flushSync()
          const newAutoSyncTables = [...autoSyncTables, 'info']
          dataSettingDataPreferences.putSync('autoSyncTables', newAutoSyncTables)
          dataSettingDataPreferences.flushSync()
          array.push('已开启常用信息自动同步。')
        }
      }
      if (onTables.includes('info')) {
        const newAutoSyncTables = [...autoSyncTables, 'info']
        dataSettingDataPreferences.putSync('autoSyncTables', newAutoSyncTables)
        dataSettingDataPreferences.flushSync()
        array.push('已开启常用信息自动同步。')
      }
    }
  }
  if (content.includes('开启标签自动同步')) {
    const autoSyncTables = dataSettingDataPreferences.getSync('autoSyncTables', []) as string[]
    if (autoSyncTables.includes('tag')) {
      array.push('标签自动同步已开启。')
    }
    if (!autoSyncTables.includes('tag')) {
      const onTables = dataSettingDataPreferences.getSync('onTables', []) as string[]
      if (!onTables.includes('tag')) {
        const res = await checkPermission('ohos.permission.DISTRIBUTED_DATASYNC')
        if (!res) {
          array.push('很抱歉，因您未授权，无法开启标签自动同步。')
        }
        if (res) {
          const rdbStore = await relationalStore.getRdbStore(context, {
            name: 'tag',
            securityLevel: 1,
            encrypt: true,
            allowRebuild: true
          })
          await rdbStore.setDistributedTables(['tag'])
          const newOnTables = [...onTables, 'tag']
          dataSettingDataPreferences.putSync('onTables', newOnTables)
          dataSettingDataPreferences.flushSync()
          const newAutoSyncTables = [...autoSyncTables, 'tag']
          dataSettingDataPreferences.putSync('autoSyncTables', newAutoSyncTables)
          dataSettingDataPreferences.flushSync()
          array.push('已开启标签自动同步。')
        }
      }
      if (onTables.includes('tag')) {
        const newAutoSyncTables = [...autoSyncTables, 'tag']
        dataSettingDataPreferences.putSync('autoSyncTables', newAutoSyncTables)
        dataSettingDataPreferences.flushSync()
        array.push('已开启标签自动同步。')
      }
    }
  }
  if (content.includes('关闭密码自动同步')) {
    const autoSyncTables = dataSettingDataPreferences.getSync('autoSyncTables', []) as string[]
    if (!autoSyncTables.includes('password')) {
      array.push('密码自动同步已关闭。')
    }
    if (autoSyncTables.includes('password')) {
      const newAutoSyncTables = autoSyncTables.filter(item => item !== 'password')
      dataSettingDataPreferences.putSync('autoSyncTables', newAutoSyncTables)
      dataSettingDataPreferences.flushSync()
      array.push('已关闭密码自动同步。')
    }
  }
  if (content.includes('关闭常用信息自动同步')) {
    const autoSyncTables = dataSettingDataPreferences.getSync('autoSyncTables', []) as string[]
    if (!autoSyncTables.includes('info')) {
      array.push('常用信息自动同步已关闭。')
    }
    if (autoSyncTables.includes('info')) {
      const newAutoSyncTables = autoSyncTables.filter(item => item !== 'info')
      dataSettingDataPreferences.putSync('autoSyncTables', newAutoSyncTables)
      dataSettingDataPreferences.flushSync()
      array.push('已关闭常用信息自动同步。')
    }
  }
  if (content.includes('关闭标签自动同步')) {
    const autoSyncTables = dataSettingDataPreferences.getSync('autoSyncTables', []) as string[]
    if (!autoSyncTables.includes('tag')) {
      array.push('标签自动同步已关闭。')
    }
    if (autoSyncTables.includes('tag')) {
      const newAutoSyncTables = autoSyncTables.filter(item => item !== 'tag')
      dataSettingDataPreferences.putSync('autoSyncTables', newAutoSyncTables)
      dataSettingDataPreferences.flushSync()
      array.push('已关闭标签自动同步。')
    }
  }
  if (content.includes('开启密码自动备份')) {
    const autoBackupTables = dataSettingDataPreferences.getSync('autoBackupTables', []) as string[]
    if (autoBackupTables.includes('password')) {
      array.push('密码自动备份已开启。')
    }
    if (!autoBackupTables.includes('password')) {
      const newAutoBackupTables = [...autoBackupTables, 'password']
      dataSettingDataPreferences.putSync('autoBackupTables', newAutoBackupTables)
      dataSettingDataPreferences.flushSync()
      array.push('已开启密码自动备份。')
    }
  }
  if (content.includes('开启常用信息自动备份')) {
    const autoBackupTables = dataSettingDataPreferences.getSync('autoBackupTables', []) as string[]
    if (autoBackupTables.includes('info')) {
      array.push('常用信息自动备份已开启。')
    }
    if (!autoBackupTables.includes('info')) {
      const newAutoBackupTables = [...autoBackupTables, 'info']
      dataSettingDataPreferences.putSync('autoBackupTables', newAutoBackupTables)
      dataSettingDataPreferences.flushSync()
      array.push('已开启常用信息自动备份。')
    }
  }
  if (content.includes('开启标签自动备份')) {
    const autoBackupTables = dataSettingDataPreferences.getSync('autoBackupTables', []) as string[]
    if (autoBackupTables.includes('tag')) {
      array.push('标签自动备份已开启。')
    }
    if (!autoBackupTables.includes('tag')) {
      const newAutoBackupTables = [...autoBackupTables, 'tag']
      dataSettingDataPreferences.putSync('autoBackupTables', newAutoBackupTables)
      dataSettingDataPreferences.flushSync()
      array.push('已开启标签自动备份。')
    }
  }
  if (content.includes('关闭密码自动备份')) {
    const autoBackupTables = dataSettingDataPreferences.getSync('autoBackupTables', []) as string[]
    if (!autoBackupTables.includes('password')) {
      array.push('密码自动备份已关闭。')
    }
    if (autoBackupTables.includes('password')) {
      const newAutoBackupTables = autoBackupTables.filter(item => item !== 'password')
      dataSettingDataPreferences.putSync('autoBackupTables', newAutoBackupTables)
      dataSettingDataPreferences.flushSync()
      array.push('已关闭密码自动备份。')
    }
  }
  if (content.includes('关闭常用信息自动备份')) {
    const autoBackupTables = dataSettingDataPreferences.getSync('autoBackupTables', []) as string[]
    if (!autoBackupTables.includes('info')) {
      array.push('常用信息自动备份已关闭。')
    }
    if (autoBackupTables.includes('info')) {
      const newAutoBackupTables = autoBackupTables.filter(item => item !== 'info')
      dataSettingDataPreferences.putSync('autoBackupTables', newAutoBackupTables)
      dataSettingDataPreferences.flushSync()
      array.push('已关闭常用信息自动备份。')
    }
  }
  if (content.includes('关闭标签自动备份')) {
    const autoBackupTables = dataSettingDataPreferences.getSync('autoBackupTables', []) as string[]
    if (!autoBackupTables.includes('tag')) {
      array.push('标签自动备份已关闭。')
    }
    if (autoBackupTables.includes('tag')) {
      const newAutoBackupTables = autoBackupTables.filter(item => item !== 'tag')
      dataSettingDataPreferences.putSync('autoBackupTables', newAutoBackupTables)
      dataSettingDataPreferences.flushSync()
      array.push('已关闭标签自动备份。')
    }
  }
  if (content.includes('备份密码')) {
    await backupTable('password')
    array.push('密码已备份。')
  }
  if (content.includes('备份常用信息')) {
    await backupTable('info')
    array.push('常用信息已备份。')
  }
  if (content.includes('备份标签')) {
    await backupTable('tag')
    array.push('标签已备份。')
  }
  if (content.includes('恢复密码')) {
    const isBackupTables = dataSettingDataPreferences.getSync('isBackupTables', []) as string[]
    if (!isBackupTables.includes('password')) {
      array.push('很抱歉，密码未备份，无法恢复。')
    }
    if (isBackupTables.includes('password')) {
      recoveryTable('password')
      array.push('密码已恢复。')
    }
  }
  if (content.includes('恢复常用信息')) {
    const isBackupTables = dataSettingDataPreferences.getSync('isBackupTables', []) as string[]
    if (!isBackupTables.includes('info')) {
      array.push('很抱歉，常用信息未备份，无法恢复。')
    }
    if (isBackupTables.includes('info')) {
      recoveryTable('info')
      array.push('常用信息已恢复。')
    }
  }
  if (content.includes('恢复标签')) {
    const isBackupTables = dataSettingDataPreferences.getSync('isBackupTables', []) as string[]
    if (!isBackupTables.includes('tag')) {
      array.push('很抱歉，标签未备份，无法恢复。')
    }
    if (isBackupTables.includes('tag')) {
      recoveryTable('tag')
      array.push('标签已恢复。')
    }
  }
  if (content.includes('新增常用信息')) {
    const entity = await textProcessing.getEntity(content, {
      entityTypes: [
        EntityType.EMAIL,
        EntityType.NAME,
        EntityType.PHONE_NO,
        EntityType.URL,
        EntityType.ID_NO
      ]
    })
    entity.forEach((item) => {
      if (item.type === EntityType.EMAIL) {
        newInfo({
          type: '邮箱',
          value: item.text,
          cloudBackup: false
        })
        array.push('已新增常用信息：邮箱 ' + item.text + '。')
      }
      if (item.type === EntityType.NAME) {
        newInfo({
          type: '姓名',
          value: item.text,
          cloudBackup: false
        })
        array.push('已新增常用信息：姓名 ' + item.text + '。')
      }
      if (item.type === EntityType.PHONE_NO) {
        newInfo({
          type: '手机号',
          value: item.text,
          cloudBackup: false
        })
        array.push('已新增常用信息：手机号 ' + item.text + '。')
      }
      if (item.type === EntityType.URL) {
        newInfo({
          type: 'URL',
          value: item.text,
          cloudBackup: false
        })
        array.push('已新增常用信息：URL ' + item.text + '。')
      }
      if (item.type === EntityType.ID_NO) {
        newInfo({
          type: '身份证号',
          value: item.text,
          cloudBackup: false
        })
        array.push('已新增常用信息：身份证号 ' + item.text + '。')
      }
    })
  }
  if (content.includes('开通云服务') && !content.includes('取消开通云服务')) {
    const res = await getCloudServiceStatus()
    if (!res) {
      const accessToken = get()
      if (!accessToken) {
        array.push('未登录账号，无法开通云服务。您可以依次进入“我的”>“登录”登录账号。')
      }
      if (accessToken) {
        const result = await request('/account/openService', {
          accessToken: get(),
          service: 'password'
        })
        if (result !== 'fail') {
          array.push('已开通云服务。')
        }
        if (result === 'fail') {
          array.push('很抱歉，开通云服务失败。您可以重试或手动操作。给您带来的不便敬请谅解。')
        }
      }
    }
    if (res) {
      array.push('账号云服务已开通。')
    }
  }
  if (content.includes('取消开通云服务')) {
    const res = await getCloudServiceStatus()
    if (!res) {
      array.push('未登录账号或账号未开通云服务，无法取消开通云服务。')
    }
    if (res) {
      const result = await request('/account/closeService', {
        accessToken: get(),
        service: 'password'
      })
      if (result !== 'fail') {
        array.push('已取消开通云服务。')
      }
      if (result === 'fail') {
        array.push('很抱歉，取消开通云服务失败。您可以重试或手动操作。给您带来的不便敬请谅解。')
      }
    }
  }
  if (array.length === 0) {
    array.push('我的技能正在不断增加中，目前还不会执行此操作，换一个试试呢，例如“设置深色模式”。')
  }
  return array
}