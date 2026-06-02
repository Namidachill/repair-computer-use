# repair-computer-use

Windows 版 Codex Desktop の更新後に Computer Use が使えなくなった場合に、原因を確認し、既知の再登録手順で復旧を試すための Codex skill です。

次のような症状を対象にしています。

- Codex Desktop の Settings で `Computer Use plugin is unavailable` と表示される
- Computer Use の設定トグルが消えた
- Computer Use の起動時に `Computer Use native pipe path is unavailable` と表示される
- 修復後に Codex Desktop の左サイドバーが白くなり、フォーカス時だけメニューが見えなくなる

## 安全性

この skill に認証情報、個人用パス、実行ログは含まれていません。

付属スクリプトは最初に読み取り専用の `Inspect` モードで状態を調べます。修復を行う `Repair` モードは、Codex が処理内容を説明し、ユーザーの承認を得てから実行する想定です。

`Repair` モードが行う変更は次の2点です。

1. `%USERPROFILE%\.codex\config.toml` のタイムスタンプ付きバックアップを作る
2. 現在インストールされている Codex Desktop 内の `openai-bundled` marketplace を、公式 CLI の `codex plugin marketplace add` で再登録する

Vault や作業リポジトリのファイルは変更しません。キャッシュ削除、認証情報の変更、実行ファイルの直接起動も行いません。

`Inspect` は `ConfigProblems` も表示します。`%USERPROFILE%\.codex\config.toml` の `[desktop]` ブロック、特に `dictationDictionary` の引用符が壊れている場合、Codex Desktop の UI 設定読み込みが不安定になることがあります。この場合、`Repair` は続行せず、先に設定ファイルを直すか、既知の正常なバックアップへ戻してください。

## 対応環境

- Windows 版 Codex Desktop
- PowerShell
- `codex` コマンドが利用できる環境

この skill は、Codex Desktop の `OpenAI.Codex` Appx package と、同梱されている `openai-bundled` marketplace を利用します。macOS、Linux、WSL 用ではありません。

Codex Desktop の将来の更新で内部構造が変わった場合、修復を中止してエラーを表示することがあります。その場合は無理に処理を続けず、最新版に合わせて内容を見直してください。

## インストール

### Codex 用

このリポジトリ内の `repair-computer-use` フォルダを、次の場所へフォルダごとコピーします。

```text
%USERPROFILE%\.codex\skills\repair-computer-use
```

配置後、Codex Desktop を再起動してください。

### ChatGPT の Skills 画面を使う場合

ChatGPT の Skills 画面からアップロードする場合は、`repair-computer-use` フォルダを ZIP にしてアップロードしてください。

Skills は現時点で製品間を自動同期しません。ChatGPT にアップロードしただけでは Codex Desktop のローカル skill として配置されない場合があります。Codex Desktop で使う場合は、上記のローカル配置を行ってください。

## 使い方

Codex Desktop の新しいチャットで、次のように依頼します。

```text
$repair-computer-use を使って Computer Use が使えない原因を調べて。
```

Codex は最初に `Inspect` モードを実行し、変更を加えずに状態を確認します。

既知の不整合に該当する場合、Codex は `Repair` モードで行う変更、影響範囲、元に戻す方法を説明します。内容を確認してから、実行を承認してください。

修復後は Codex Desktop を再起動し、新しいチャットで Computer Use を確認してください。古いチャットには接続状態が残ることがあります。

## 手動で状態だけ確認する

PowerShell でリポジトリの場所へ移動し、次を実行します。

```powershell
powershell -ExecutionPolicy Bypass -File ".\repair-computer-use\scripts\repair-computer-use.ps1" -Mode Inspect
```

このコマンドは状態を表示するだけで、ファイルを書き換えません。

結果にはユーザーフォルダなどのローカルパスが含まれることがあります。SNS や Issue に貼る場合は、そのまま公開せず、個人情報が含まれていないか確認してください。

## 元に戻す方法

`Repair` モードの出力に表示された `BackupPath` のファイルを使い、バックアップを `%USERPROFILE%\.codex\config.toml` に戻します。

必要に応じて、次のコマンドで再登録した marketplace を取り除けます。

```powershell
codex plugin marketplace remove openai-bundled
```

その後、Codex Desktop を再起動してください。

## 注意点

- 必ず最初に `Inspect` モードを使ってください。
- `Repair` モードは内容を確認してから実行してください。
- 実行ログや `config.toml` を公開しないでください。
- `config.toml` には環境固有の設定が含まれるため、他人と共有しないでください。
- 問題が別原因の場合、この skill で復旧できるとは限りません。
- 復旧しない場合は、Codex Desktop の更新状況を確認し、OpenAI のサポートまたは公式の報告先へ相談してください。

## License

[MIT License](LICENSE)
