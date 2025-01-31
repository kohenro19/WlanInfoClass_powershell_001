# 文字コードをUTF-8に設定（コマンドプロンプトやPowerShellの文字化け対策）
# chcp 65001

# WLANのステータス情報を取得し、ハッシュテーブルに格納するクラス
class VerifyWlanStatus {
    # WLAN情報を格納するハッシュテーブル
    [hashtable]$map

    # コンストラクタ
    VerifyWlanStatus() {
        # ハッシュテーブルを初期化
        $this.map = @{}

        # `netsh wlan show interfaces` コマンドを実行して、Wi-Fiインターフェース情報を取得
        $getWlanStatus = netsh wlan show interfaces

        # "There is X interface on the system:" の部分を削除（Xは数値）
        $result = $getWlanStatus -replace "There is \d+ interface on the system:\s*", ""

        # "項目名 : 値" の形式を "項目名=値" に変換（空白を削除）
        $result = $result -replace "\s*:\s", "="

        # 空白行を削除し、データのある行だけを取得
        $filteredText = $result -split "`n" | Where-Object { $_ -match '\S' }

        # フィルタリングした各行を処理
        $filteredText | ForEach-Object {
            # 行の前後の空白を削除
            $_ = $_.Trim()

            # "キー=値" の形式に一致するかチェック
            if ($_ -match "^(.*?)=(.*)$") {
                # キーと値を取得し、それぞれの前後の空白を削除
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()

                # ハッシュテーブルに追加
                $this.map[$key] = $value
            }
        }
    }

    # ハッシュテーブル（WLAN情報）を取得するメソッド
    [hashtable] GetMap() {
        return $this.map
    }

    [void]CheckAP([string]$mac) {
        If($mac -eq $this.map["AP BSSID"]){
            Write-Host "OK" 
        }else{
            Write-Host "NG" 
        }     
    }
}

# クラスをインスタンス化し、WLAN情報を取得
$networkMap = [VerifyWlanStatus]::new()

$mac = Read-Host "Please enter the MAC address of the target AP" 
$networkMap.CheckAP($mac)
