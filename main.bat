@echo off
rem バッチファイルの実行時にコマンドの出力を非表示にする

rem 標準文字コードをutf-8に設定
chcp 65001 > nul

rem -NoProfile: ユーザーのプロファイルを読み込まずに実行し、処理を高速化
rem -ExecutionPolicy Unrestricted: 実行ポリシーを無制限に設定し、スクリプトの実行を許可
powershell -NoProfile -ExecutionPolicy Unrestricted .\verifyWlan.ps1

rem ユーザーがキーを押すまで一時停止（メッセージなし）
pause > nul

rem スクリプトを終了
exit
