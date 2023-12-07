# open_port.ps1

# 対象ポート (※適宜変更)
$port = 3000
# WSL2のディストリビューション名 (※適宜変更)
$distName = "Ubuntu"

# 引数の一個目が数値だった場合、port番号として解釈する
if ($args[0] -match '^\d+$') {
    $port = [int]$args[0]
}

# "clear" オプションが指定された場合は過去の設定をすべて削除
if ($args[0] -eq "clear") {
    Get-NetFirewallRule -DisplayName "WSL 2 Firewall Unlock" | Remove-NetFirewallRule
    netsh interface portproxy reset
    return
}

if ($args[0] -eq "status") {
    Get-NetFirewallRule | Where-Object { $_.DisplayName -eq "WSL 2 Firewall Unlock" } | FT DisplayName, Name, Enabled
    netsh interface portproxy show v4tov4
    return
}

# Windows Defenderに穴あけ
New-NetFireWallRule -DisplayName "WSL 2 Firewall Unlock" -Direction Outbound -LocalPort $port -Action Allow -Protocol TCP
New-NetFireWallRule -DisplayName 'WSL 2 Firewall Unlock' -Direction Inbound -LocalPort $port -Action Allow -Protocol TCP
# WSL2の現在のIPに対するポートフォワーディング設定
netsh interface portproxy add v4tov4 listenport=$port listenaddress=* connectport=$port connectaddress=(wsl -d $distName -e hostname -I).trim()


# 現在のユーザーが管理者権限を持っていない場合に、スクリプトを管理者権限で再実行するための処理です。
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Administrators")) { Start-Process powershell.exe "-File `"$PSCommandPath`"" -Verb RunAs; exit }

# WSL 2 インスタンスの IP アドレスを取得します。
# bash.exe を使って、ip r コマンドを実行し、結果からIPアドレスを抽出します。
# IP アドレスが取得できない場合、スクリプトは終了します。
$ip = bash.exe -c "ip r |tail -n1|cut -d ' ' -f9"
if ( ! $ip ) {
    echo "The Script Exited, the ip address of WSL 2 cannot be found";
    exit;
}
