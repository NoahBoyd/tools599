
Write-Host ("SECOND SCRIPT")
function checkFileStatus($filePath)
    {
        write-host (Get-Date) "[ACTION][FILECHECK] Checking if" $filePath "is locked"
        $fileInfo = New-Object System.IO.FileInfo $filePath

        try 
        {
            $fileStream = $fileInfo.Open( [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read )
            write-host (Get-Date) "[ACTION][FILEAVAILABLE]" $filePath
            $print = "[ACTION][FILEAVAILABLE] $filePath NOT LOCKED {0}" -f (Get-Date)
            #$print | Out-File -FilePath 'C:\data\logs\watch598cmmresults\testlogs.txt'
            $print | Out-File 'C:\data\logs\watch598cmmresults\lockedlogs.txt' -Append
            return $true
        }
        catch
        {
            write-host (Get-Date) "[ACTION][FILELOCKED] $filePath is locked"
            $print = "[ACTION][FILELOCKED] $filePath is locked {0}" -f (Get-Date)
            #$print | Out-File -FilePath 'C:\data\logs\watch598cmmresults\testlogs.txt'
            $print | Out-File 'C:\data\logs\watch598cmmresults\lockedlogs.txt' -Append
            return $false
            
        }
    }

#$FileStream = [System.IO.File]::Open("C:\data\cmm\results from calypso\chr.txt.txt",'Open','Write')
#$FileStream.Close()
#$FileStream.Dispose()
    while ($true){

        $filepath = 'C:\data\cmm\results from calypso\chr.txt.txt'
        
        $valid = checkFileStatus -filePath $filepath
        #$valid | Out-File -FilePath 'C:\data\logs\watch598cmmresults\testlogs.txt'
        if ($valid) {
            break
        } elseif ($valid -eq $false) {
            #Start-Sleep 2
            continue
        }
        #IsFileLocked -filePath $filepath
        Start-Sleep -Seconds 1
    }
    