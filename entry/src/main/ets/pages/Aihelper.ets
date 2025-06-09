import { preferences } from '@kit.ArkData'
import { util } from '@kit.ArkTS'
import { promptAction } from '@kit.ArkUI'
import { speechRecognizer, textToSpeech } from '@kit.CoreSpeechKit'
import { cryptoFramework } from '@kit.CryptoArchitectureKit'
import parseContent from '../common/Contentparse'
import { checkPermission } from '../common/Permission'

interface Item {
  role: string,
  content: string
}

@ComponentV2
export default struct Aihelper {
  @Local array: Item[] = [
    {
      role: 'AI',
      content: '点击上方“点击开始说话”按钮，说出需要我帮您执行的操作。'
    }
  ]
  @Local isRecording: boolean = false
  @Local isThinking: boolean = false
  @Local allowSpeak: boolean = true
  @Local autoContinueRecording: boolean = false
  context = getContext(this)
  speakSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'speakSetting'
  })

  async speak(text: string) {
    if (!this.allowSpeak) {
      if (!this.autoContinueRecording) {
        this.isRecording = false
      }
      if (this.autoContinueRecording) {
        this.startRecording()
      }
    }
    if (this.allowSpeak) {
      const ttsEngine = await textToSpeech.createEngine({
        language: 'zh-CN',
        online: 1,
        person: 0
      })
      ttsEngine.setListener({
        onStart(requestId: string, response: textToSpeech.StartResponse) {
        },
        onComplete: (requestId: string, response: textToSpeech.CompleteResponse) => {
          if (response.type === 1) {
            ttsEngine.stop()
            ttsEngine.shutdown()
            if (!this.autoContinueRecording) {
              this.isRecording = false
            }
            if (this.autoContinueRecording) {
              this.startRecording()
            }
          }
        },
        onStop(requestId: string, response: textToSpeech.StopResponse) {
        },
        onData(requestId: string, audio: ArrayBuffer, response: textToSpeech.SynthesisResponse) {
        },
        onError(requestId: string, errorCode: number, errorMessage: string) {
          promptAction.showToast({
            message: '发生错误，错误码：' + errorCode + '，错误信息：' + errorMessage
          })
        }
      })
      const random = cryptoFramework.createRandom()
      const requestIdArray = random.generateRandomSync(16).data
      const textDecoder = util.TextDecoder.create('utf-8', {
        ignoreBOM: true
      })
      const requestIdString = textDecoder.decodeToString(requestIdArray, {
        stream: false
      })
      ttsEngine.speak(text, {
        requestId: requestIdString
      })
    }
  }

  async startRecording() {
    const permission = await checkPermission('ohos.permission.MICROPHONE')
    if (permission) {
      const asrEngine = await speechRecognizer.createEngine({
        language: 'zh-CN',
        online: 1
      })
      const index = this.array.length
      asrEngine.setListener({
        onStart(sessionId: string, eventMessage: string) {
        },
        onEvent(sessionId: string, eventCode: number, eventMessage: string) {
        },
        onResult: (sessionId: string, result: speechRecognizer.SpeechRecognitionResult) => {
          this.array[index] = {
            role: '我',
            content: result.result
          }
        },
        onComplete: async (sessionId: string, eventMessage: string) => {
          asrEngine.shutdown()
          this.isThinking = true
          const res = await parseContent(this.array[index].content)
          this.isThinking = false
          this.array = this.array.concat(res.map((item): Item => ({
            role: 'AI',
            content: item
          })))
          this.speak(res.join(''))
        },
        onError(sessionId: string, errorCode: number, errorMessage: string) {
          promptAction.showToast({
            message: '发生错误，错误码：' + errorCode + '，错误信息：' + errorMessage
          })
        }
      })
      this.isRecording = true
      this.array.push({
        role: '我',
        content: '正在录音，请说出需要我帮您执行的操作...'
      })
      asrEngine.startListening({
        sessionId: '0',
        audioInfo: {
          audioType: 'pcm',
          sampleRate: 16000,
          sampleBit: 16,
          soundChannel: 1
        },
        extraParams: {
          'recognitionMode': 0
        }
      })
    }
  }

  build() {
    List() {
      ListItem() {
        Column() {
          Row() {
            Text('语音播报')
              .fontWeight(FontWeight.Medium)
            Blank()
            Toggle({
              type: ToggleType.Switch,
              isOn: $$this.allowSpeak
            })
              .onChange((isOn: boolean) => {
                this.speakSettingDataPreferences.putSync('allowSpeak', isOn)
                this.speakSettingDataPreferences.flushSync()
              })
          }
          .borderRadius(12)
          .padding(12)
          .width('100%')

          Divider()
            .padding({
              left: 12,
              right: 12
            })
          Row() {
            Text('连续对话')
              .fontWeight(FontWeight.Medium)
            Blank()
            Toggle({
              type: ToggleType.Switch,
              isOn: $$this.autoContinueRecording
            })
              .onChange((isOn: boolean) => {
                this.speakSettingDataPreferences.putSync('autoContinueRecording', isOn)
                this.speakSettingDataPreferences.flushSync()
              })
          }
          .borderRadius(12)
          .padding(12)
          .width('100%')
        }
        .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
        .padding($r('sys.float.ohos_id_corner_radius_mark'))
      }
      .margin({
        bottom: $r('sys.float.ohos_id_elements_margin_vertical_m')
      })

      if (!this.isRecording) {
        ListItem() {
          Column() {
            Button('点击开始说话')
              .onClick(() => {
                this.startRecording()
              })
          }
        }
        .width('100%')
        .margin({
          bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
      }

      ForEach(this.array, (item: Item) => {
        ListItem() {
          Text() {
            Span(item.role + '：')
              .fontWeight(FontWeight.Medium)
            Span(item.content)
          }
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
      })
      if (this.isThinking) {
        ListItem() {
          Row() {
            LoadingProgress()
              .height(20)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .width(20)
            Text('AI 助手思考中...')
              .fontColor($r('sys.color.font_secondary'))
          }
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
      }
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_max_padding_start'),
      right: $r('sys.float.ohos_id_max_padding_end')
    })
    .onAppear(() => {
      const allowSpeak = this.speakSettingDataPreferences.getSync('allowSpeak', true)
      this.allowSpeak = allowSpeak as boolean
      const autoContinueRecording = this.speakSettingDataPreferences.getSync('autoContinueRecording', false)
      this.autoContinueRecording = autoContinueRecording as boolean
    })
  }
}