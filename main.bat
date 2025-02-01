REM バッチファイルの実行時にコマンドの出力を非表示にする
@echo off

REM PowerShellスクリプト verifyWlan.ps1 を実行
REM -NoProfile: ユーザーのプロファイルを読み込まずに実行し、処理を高速化
REM -ExecutionPolicy Unrestricted: 実行ポリシーを無制限に設定し、スクリプトの実行を許可
powershell -NoProfile -ExecutionPolicy Unrestricted .\verifyWlan.ps1

REM ユーザーがキーを押すまで一時停止（メッセージなし）
pause > nul

REM スクリプトを終了
exit
