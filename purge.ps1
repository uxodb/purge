######### Pad naar bestanden hieronder wijzigen (zonder backslash aan het eind)
$lspath = "\\share\dfs\map"
#########
$logpath = "$lspath\Logfiles\purge.log"
$files = Get-ChildItem $lspath -File
$date = Get-Date
$i = 0;
if ([System.IO.File]::Exists($logpath) -and (Get-Item $logpath).Length/1MB -gt "99") {
    $logcount = [System.IO.Directory]::GetFiles("$lspath\Logfiles\", "purge*").Count
    for ($f=0; $f -lt $logcount; $f++) {} 
    $newLog = "$logpath" + ".$f"
    Rename-Item -Path $logpath -NewName $newLog        
} elseif (![System.IO.File]::Exists($logpath)) {
    New-Item -Path $logpath -ItemType "file" -Force
}
Write-Output "-----------------" | Out-File $logpath -Append
Write-Output (Get-Date -Format "dd/MM/yyyy HH:mm") | Out-File $logpath -Append
Write-Output "-----------------" | Out-File $logpath -Append
foreach ($file in $files) {       
    $verschil = New-TimeSpan -Start $date -End $file.LastWriteTime 
    if ($verschil.Days -lt "-730") {
        $i++
        $filedate = $file.LastWriteTime | Get-Date -Format "dd-MM-yyyy"
        $filesize += $file.Length/1MB          
        rm $file.FullName          
        if (Test-Path $file.FullName) {
            [bool]$delcheck = 0
            Write-Output "$filedate | ERROR | $($file.FullName)" | Out-File $logpath -Append
        } else {
            [bool]$delcheck = 1
            Write-Output "$filedate | Verwijderd | $($file.FullName)" | Out-File $logpath -Append
        }
    } 
}
$filesize =  [math]::Round($filesize,2)
$filecount = [System.IO.Directory]::GetFiles($lspath).Count
if ($i -eq "0") {
    Write-Output "Geen te verwijderen bestanden" | Out-File $logpath -Append
    Write-Output "Totaal aantal bestanden over: $filecount" | Out-File $logpath -Append
} elseif ($i -gt "0" -and $delcheck) {
    Write-Output "Aantal bestanden verwijderd: $i" | Out-File $logpath -Append
    Write-Output "Totaal aantal bestanden over: $filecount" | Out-File $logpath -Append
    Write-Output "Totale grootte verwijderde bestanden: $filesize MB " | Out-File $logpath -Append
} elseif ($i -gt "0" -and !$delcheck) {
    Write-Output "Totaal aantal bestanden over: $filecount" | Out-File $logpath -Append
    Write-Output "Aantal bestanden niet kunnen verwijderen: $i" | Out-File $logpath -Append
}
