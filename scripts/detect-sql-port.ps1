# Prints the TCP port the SQLEXPRESS instance listens on (default 1433 when it cannot be detected).
try {
    $inst = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -ErrorAction Stop).SQLEXPRESS
    $tcp = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$inst\MSSQLServer\SuperSocketNetLib\Tcp\IPAll" -ErrorAction Stop
    if ($tcp.TcpPort) { ($tcp.TcpPort -split ',')[0] }
    elseif ($tcp.TcpDynamicPorts) { ($tcp.TcpDynamicPorts -split ',')[0] }
    else { '1433' }
} catch { '1433' }
