# HelloWorldSwift

$ git clone https://github.com/hiroyuki12/HelloWorldSwift 

Constants.swiftファイルを追加

Xcodeで開き、iPhoneを接続して、実行

## 通信とファイル共有

- ATS（App Transport Security）は標準で有効です。全通信を許可する例外は設定せず、API・画像などの通信にはHTTPSを使用します。外部記事や画像のHTTP URLはATSによって読み込みが制限される場合があります。
- `UIFileSharingEnabled` は `false` です。DocumentsにはSQLiteデータベース、ログ、ダウンロードファイルが保存されるため、Finder／iTunes経由のファイル共有を無効にしています。アプリ内での保存・読み込みは引き続き利用できます。


【swift入門】apiを叩いてTableViewに表示させる
https://fukatsu.tech/api-tableview#api-2

