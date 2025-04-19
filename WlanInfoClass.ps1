# WLAN�̃X�e�[�^�X�����擾���A�n�b�V���e�[�u���Ɋi�[����N���X
class WlanInfoClass {
    # WLAN�����i�[����n�b�V���e�[�u��
    [hashtable]$wlanInfo
    [string[]]$matchedLineWithSSID

    # �R���X�g���N�^
    WlanInfoClass() {
        # �n�b�V���e�[�u����������
        $this.wlanInfo = @{}
        $this.matchedLineWithSSID = @()

        # `netsh wlan show interfaces` �R�}���h�����s���āAWi-Fi�C���^�[�t�F�[�X�����擾
        $originalWlanInfo = netsh wlan show interfaces

        # "There is X interface on the system:" �̕������폜�iX�͐��l�j
        $modifiedWlanInfo = $originalWlanInfo -replace "There is \d+ interface on the system:\s*", ""

        # "���ږ� : �l" �̌`���� "���ږ�=�l" �ɕϊ��i�󔒂��폜�j
        $modifiedWlanInfo = $modifiedWlanInfo -replace "\s*:\s", "="

        # �󔒍s���폜���A�f�[�^�̂���s�������擾
        $modifiedWlanInfo = $modifiedWlanInfo -split "`n" | Where-Object { $_ -match '\S' }

        # �t�B���^�����O�����e�s������
        $modifiedWlanInfo | ForEach-Object {
            # �s�̑O��̋󔒂��폜
            $_ = $_.Trim()

            # "�L�[=�l" �̌`���Ɉ�v���邩�`�F�b�N
            if ($_ -match "^(.*?)=(.*)$") {
                # �L�[�ƒl���擾���A���ꂼ��̑O��̋󔒂��폜
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()

                # �n�b�V���e�[�u���ɒǉ�
                $this.wlanInfo[$key] = $value
            }
        }

        # �A�N�Z�X�|�C���g�̈ꗗ��ǂݎ��
        $apTable = Import-Csv -Path "apTable.csv"

        # Country = Japan �̍s���� Name ���������o��
        $this.matchedLineWithSSID = $apTable | Where-Object { $_.SSID -eq $this.wlaninfo["SSID"] }

        # ���ʕ\��
        $this.matchedLineWithSSID
    }

    getMatchedLineWithSSID() {
        # 1�s�����o���i�����1�����Ȃ��O��j
        $line = $this.matchedLineWithSSID

        # ��������I�u�W�F�N�g�ɕϊ�
        # 1. @{...} ������
        $clean = $line -replace '^@{', '' -replace '}$', ''

        # 2. ; ��؂�����s�ɁiConvertFrom-StringData���j
        $formatted = $clean -replace '; ', "`n"

        # 3. ��������n�b�V���e�[�u���ɕϊ�
        $ht = $formatted | ConvertFrom-StringData

        # 4. GATEWAY��Ԃ�
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
                if ($output -match "���� = (\d+)ms") {
                    $rtt = [int]$matches[1]
                    if ($rtt -ge 300) {
                        $status = "NG"
                    } else {
                        $status = "OK"
                    }
                    "$timestamp $gateway $status - ��������: $rtt ms" | Out-File -Append $logFile
                } elseif ($output -match "�v�����^�C���A�E�g") {
                    "$timestamp $gateway NG - �����Ȃ��i�^�C���A�E�g�j" | Out-File -Append $logFile
                } else {
                    "$timestamp $gateway NG - ���̑��̃G���[" | Out-File -Append $logFile
                }
            # }
            Start-Sleep -Seconds 1
}


    }
}

# �N���X���C���X�^���X�����AWLAN�����擾
$wlaninfo = [WlanInfoClass]::new()

$wlaninfo.getMatchedLineWithSSID()