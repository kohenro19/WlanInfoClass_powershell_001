# WLANのステータス情報を取得し、ハッシュテーブルに格納するクラス
class WlanInfoClass {
    # WLAN情報を格納するハッシュテーブル
    [hashtable]$wlanInfo
    [string[]]$matchedLineWithSSID

    # コンストラクタ
    WlanInfoClass() {
        try {
            # 文字化け対策
            [Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding('utf-8')

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

            # 登録済みのアクセスポイントの一覧を読み取る
            $apTable = Import-Csv -Path "apTable.csv"

            # Country = Japan の行から Name だけを取り出す
            $this.matchedLineWithSSID = $apTable | Where-Object { $_.SSID -eq $this.wlaninfo["SSID"] }
            if (-not $this.matchedLineWithSSID) {
                throw "SSID が一致するアクセスポイントが見つかりません"
            }
    
        } catch {
            throw "GATEWAYが適切に設定されていないか、またはネットワークがつながっていません。"
        }
    
    }
    [void]excutePingToGateway() {
        # 1行を取り出す（今回は1つしかない前提）
        $lineExtractedFromSSID = $this.matchedLineWithSSID

        # 文字列をオブジェクトに変換
        # 1. @{...} を除去
        $lineExtractedFromSSID = $lineExtractedFromSSID -replace '^@{', '' -replace '}$', ''

        # 2. ; 区切りを改行に（ConvertFrom-StringData風）
        $lineExtractedFromSSID = $lineExtractedFromSSID -replace '; ', "`n"

        # 3. 文字列をハッシュテーブルに変換
        $lineExtractedFromSSID = $lineExtractedFromSSID | ConvertFrom-StringData

        # 4. GATEWAYを返す
        $gateway = $lineExtractedFromSSID["GATEWAY"]
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logFile = "ping_result-$gateway.txt"
        $connectedSSID = $this.wlanInfo["SSID"] 
        $connectedBSSID = $this.wlaninfo["AP BSSID"]
        $count = 10

        "############################################" | Out-File -Append $logFile
        "$connectedSSID　のSSIDに接続しています。" | Out-File -Append $logFile
        "$connectedBSSID　のAPに接続しています。" | Out-File -Append $logFile
        "############################################" | Out-File -Append $logFile

        for ($i = 1; $i -le $count; $i++) {
            $pingResult = Test-Connection $gateway -Count 1
            $status = $pingResult.Status
            $latency = $pingResult.Latency

            if ($status -eq "Success") {
                if ($latency -ge 10) {
                    # Write-Host "NG"
                    "$timestamp $gateway  NG - 応答あるが遅い - 応答時間: $latency ms" | Out-File -Append $logFile
                } else {
                    # Write-Host "OK"
                    "$timestamp $gateway $status - 応答時間: $latency ms" | Out-File -Append $logFile
                }
                "$timestamp $gateway $status - 応答時間: $latency ms" | Out-File -Append $logFile
            } elseif ($status -eq "TimedOut") {
                "$timestamp $gateway NG - 応答なし（タイムアウト）" | Out-File -Append $logFile
            } else {
                "$timestamp $gateway NG - その他のエラー" | Out-File -Append $logFile
            }
            Start-Sleep -Seconds 1
        }
    }
}

# クラスをインスタンス化し、WLAN情報を取得
$wlaninfo = [WlanInfoClass]::new()

# GATEWAYに対してpingを実行する
$wlaninfo.excutePingToGateway()