# WLANのステータス情報を取得し、ハッシュテーブルに格納するクラス
class WlanInfoClass {
    # WLAN情報を格納するハッシュテーブル
    [hashtable]$wlanInfo
    [string[]]$matchedLineWithSSID

    # コンストラクタ
    WlanInfoClass() {
        # ハッシュテーブルを初期化
        $this.wlanInfo = @{}
        $this.matchedLineWithSSID = @()

        # `netsh wlan show interfaces` コマンドを実行して、Wi-Fiインターフェース情報を取得
        $originalWlanInfo = netsh wlan show interfaces

        # "There is X interface on the system:" の部分を削除（Xは数値）
        $modifiedWlanInfo = $originalWlanInfo -replace "There is \d+ interface on the system:\s*", ""

        # "項目名 : 値" の形式を "項目名=値" に変換（空白を削除）
        $modifiedWlanInfo = $modifiedWlanInfo -replace "\s*:\s", "="

        # 空白行を削除し、データのある行だけを取得
        $modifiedWlanInfo = $modifiedWlanInfo -split "`n" | Where-Object { $_ -match '\S' }

        # フィルタリングした各行を処理
        $modifiedWlanInfo | ForEach-Object {
            # 行の前後の空白を削除
            $_ = $_.Trim()

            # "キー=値" の形式に一致するかチェック
            if ($_ -match "^(.*?)=(.*)$") {
                # キーと値を取得し、それぞれの前後の空白を削除
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()

                # ハッシュテーブルに追加
                $this.wlanInfo[$key] = $value
            }
        }

        # アクセスポイントの一覧を読み取る
        $apTable = Import-Csv -Path "apTable.csv"

        # Country = Japan の行から Name だけを取り出す
        $this.matchedLineWithSSID = $apTable | Where-Object { $_.SSID -eq $this.wlaninfo["SSID"] }

        # 結果表示
        $this.matchedLineWithSSID
    }

    getMatchedLineWithSSID() {
        # 1行を取り出す（今回は1つしかない前提）
        $line = $this.matchedLineWithSSID

        # 文字列をオブジェクトに変換
        # 1. @{...} を除去
        $clean = $line -replace '^@{', '' -replace '}$', ''

        # 2. ; 区切りを改行に（ConvertFrom-StringData風）
        $formatted = $clean -replace '; ', "`n"

        # 3. 文字列をハッシュテーブルに変換
        $ht = $formatted | ConvertFrom-StringData

        # 4. GATEWAYを返す
        # return $ht["GATEWAY"]
        $gateway = $ht["GATEWAY"]
        # ping $gateway | Out-File -FilePath "ping_${gateway}_result.txt" -Encoding utf8

        $logFile = "ping_result.txt"
        $count = 20

        for ($i = 1; $i -le $count; $i++) {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            # $output = ping.exe -n 1 $gateway
            $output = Test-Connection $gateway -Count 1

            # foreach ($output in $outputs) {
                if ($output -match "時間 = (\d+)ms") {
                    $rtt = [int]$matches[1]
                    if ($rtt -ge 300) {
                        $status = "NG"
                    } else {
                        $status = "OK"
                    }
                    "$timestamp $gateway $status - 応答時間: $rtt ms" | Out-File -Append $logFile
                } elseif ($output -match "要求がタイムアウト") {
                    "$timestamp $gateway NG - 応答なし（タイムアウト）" | Out-File -Append $logFile
                } else {
                    "$timestamp $gateway NG - その他のエラー" | Out-File -Append $logFile
                }
            # }
            Start-Sleep -Seconds 1
}


    }
}

# クラスをインスタンス化し、WLAN情報を取得
$wlaninfo = [WlanInfoClass]::new()

$wlaninfo.getMatchedLineWithSSID()