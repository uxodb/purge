<#
    .SYNOPSIS
        Deletes files and documents with modify dates of 2> years in the past

    .DESCRIPTION
        This script iterates through all the files in $lspath assessing whether their modification date is at least 2 years in the past
        If this condition is met, the script proceeds to remove these files. 
        The script records its activities in $lspath\Logfiles\ and rotates the logfile when its size surpasses 99MB. 
        Numeral suffixes are added to the out-of-rotation log files in the following format: purge.log.1 with the more recent of logs having
        a higher number.

    .AUTHOR
        uxodb
  
    .DATE
        2019
#>

# Path to files (no trailing backslash)
$lspath = "\\share\dfs\map"

$logpath = "$lspath\Logfiles\purge.log"
$files = Get-ChildItem $lspath -File
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
    if ((get-date).AddYears(-2) -gt $file.LastWriteTime) {
        $i++
        $filedate = $file.LastWriteTime | Get-Date -Format "dd-MM-yyyy"
        $filesize += $file.Length/1MB
        Remove-Item $file.FullName
        if (Test-Path $file.FullName) {
            [bool]$delcheck = 0
            Write-Output "$filedate | ERROR | $($file.FullName)" | Out-File $logpath -Append
        } else {
            [bool]$delcheck = 1
            Write-Output "$filedate | Deleted | $($file.FullName)" | Out-File $logpath -Append
        }
    }
}
$filesize =  [math]::Round($filesize,2)
$filecount = [System.IO.Directory]::GetFiles($lspath).Count
if ($i -eq "0") {
    Write-Output "No files eligible for deletion" | Out-File $logpath -Append
    Write-Output "Amount of files left: $filecount" | Out-File $logpath -Append
} elseif ($i -gt "0" -and $delcheck) {
    Write-Output "Amount of files deleted: $i" | Out-File $logpath -Append
    Write-Output "Amount of files left: $filecount" | Out-File $logpath -Append
    Write-Output "Total size of deleted files: $filesize MB " | Out-File $logpath -Append
} elseif ($i -gt "0" -and !$delcheck) {
    Write-Output "Amount of files left: $filecount" | Out-File $logpath -Append
    Write-Output "Amount of failed deletions: $i" | Out-File $logpath -Append
}
