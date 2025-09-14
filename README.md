## SolsDroid Termux上で動作するSol's RNGのAndroid用通知マクロです。
[BloxstrapRPC]ログをワイヤレスデバッグを使用して監視、Discord Webhookにjson形式で送信します。
- Aura装備通知
- Biome変更通知
- 設定したプライベートサーバーのURLを送信


- 動作環境 Android11以降のPlayStore、またはF-droidのTermux
 - git (cloneに使用)
 - python3
 - android-tools (adb)
をインストールする必要があるため、以下のコマンドを実行してください。
'''
pkg update && pkg upgrade -y && pkg install git python python-dev clang make -y && pkg install android-tools -y && git clone https://github.com/TomatoKyou/SolsDroid.git && cd SolsDroid && pip install --upgrade pip && pip install requests
'''
## 初回設定
Android標準設定で、あなたのメーカーの説明にしたがってビルド番号を複数回クリックし開発者向けオプションを解放してください。
開発者向けオプションを開き、スクロールして”ワイヤレスデバッグ”をクリックしてください（On/Offではなく文字をクリック）
フローティングウィンドウ、もしくは画面分割で設定とTermuxを同時に表示してください。
設定で”ペア設定コードによるデバイスのペア設定”をタップ後、Termuxにて”cd SolsDroid”を実行、adb pair localhost:下に表示されているIPアドレスに:でつながっているポート番号　を実行してください。
（例）表示されたIPが192.168.2.119:46285の場合、adb pair localhost:46285 をTermuxと設定を同時に表示しながら実行してください。
Enter your pairing code:が表示されたら、Wifiペア設定コードに書いてある6桁の数字を入力してください。
設定のウィンドウが消え、ペア設定済みのデバイスに新しいデバイスが追加された場合成功です。
失敗した場合：
フローティングウィンドウ、画面分割でTermuxと設定を同時に表示していることを確認してください。
ワイヤレスデバッグを一度OFF、再度ONにしてもう一度ペア設定を試みてください。

## マクロのセットアップ
shellが~/SolsDroid $であることを確認して、bash setup.shを実行してください。
一時的に設定に移動して、ペアリング用のポートではなく（ここ強調）ワイヤレスデバッグをタップしたときに表示される”IPアドレスとポート”に表示されているポートを覚えるかメモを取り
Enter your adb wireless debug port (from Android settings):に入力してEnterを押してください。
adb devicesを実行して、List of devices attached以外に何も表示されなかった場合は、ワイヤレスデバッグを一度オフ、再度ONにしてbash setup.shを実行、新しく発行されたポートを入力してください。
adb devicesを実行してemulator-5554（環境によって変わる可能性があります）が表示されたら成功です。
（注意）この手順は2回以上失敗する可能性があります。原因はおそらくadbそのものにあるため、修正ができません; ;
この手順は端末を再起動後、もしくは時間が経過してadb devicesを実行しても何も表示されなかった場合再度行う必要があります。

マクロを起動
bash run.shを実行して Enter Discord Webhook URL:　に使用するWebhookのURLを入力、 Robloxを起動してプライベートサーバーのURLをコピー、そのままプライベートサーバーに参加してください。
完全にゲームが起動したら素早くTermuxの画面に切り替えて、コピーしたURLをEnter Private Server URL:　にペーストしてEnter、サーバーから切断される前にRobloxに戻ってください。
Discordを確認して正常に動作していれば成功です、Androidがプロセスをメモリ圧迫などの理由で終了したり、ワイヤレスデバッグが切断されることがない限り永続的に動作します。
WebhookやプライベートサーバーURLの設定を完了した以降は、SolsRNGを完全に起動した後、素早くTermuxに移動してbash run.shを実行してサーバーから切断される前にRobloxに戻ってください。
まれにadbがクラッシュして、bash run.shを実行してから最初のログ読み取りの段階でPythonスクリプトが終了されることがありますが、bash run.shを再実行してください。これもADBによる問題のため修正ができません; ;
Discordにメッセージが送信されていれば、その後クラッシュすることはありません（おそらく）

## 注意点
ワイヤレスデバッグはセキュリティリスクがあります！ 公共Wifiでは絶対に有効化しないでください。信頼できる人のみがアクセスするWifiを推奨します。
このプロジェクトは開発初期段階です。Discordで手伝ってくれる人を募集しています。 https://discord.gg/ayuVgCKC98
