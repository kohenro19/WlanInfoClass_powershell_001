# 文字コードをUTF-8にする
chcp 65001

$result = netsh wlan show interfaces
$result = $result -replace "There is \d+ interface on the system:\s*", ""
$result = $result -replace "\s*:\s", "="

$filteredText = $result -split "`n" | Where-Object { $_ -match '\S' }
$filteredText | ForEach-Object { Write-Output $_ }

# 空白を削除し、ハッシュテーブルに変換
$map = @{}
$filteredText -split "`n" | ForEach-Object {
    $_ = $_.Trim() # 前後の空白を削除
    if ($_ -match "^(.*?)=(.*)$") {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        $map[$key] = $value
    }
}

# ハッシュテーブルの中身を表示
$map

