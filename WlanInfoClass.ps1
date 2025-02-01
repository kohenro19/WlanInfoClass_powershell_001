# WLANのステータス情報を取得し、ハッシュテーブルに格納するクラス
class WlanInfoClass {
    # WLAN情報を格納するハッシュテーブル
    [hashtable]$wlanInfo

    # コンストラクタ
    WlanInfoClass() {
        # ハッシュテーブルを初期化
        $this.wlanInfo = @{}

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
    }

    # ハッシュテーブル（WLAN情報）を取得するメソッド
    [hashtable] getWlanInfo() {
        return $this.WlanInfo
    }

    [void]confirmIfTargetAP([string]$enterWlanInfo) {
        If($enterWlanInfo -eq $this.WlanInfo["AP BSSID"]){
            Write-Host "OK" 
        }else{
            Write-Host "NG" 
        }     
    }
}

# クラスをインスタンス化し、WLAN情報を取得
$wlaninfo = [WlanInfoClass]::new()

$enterWlanInfo = Read-Host "Please enter the MAC address of the target AP" 
$wlaninfo.confirmIfTargetAP($enterWlanInfo)
