# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Status: works from windows task scheduler

# Purpose:  watch a folder for changes and copy files.

# https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-filesystemwatcher-correctly-part-2



#  SETTINGS  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


$global:interimfolder =  "C:\data\cmm\system\interimfolder"

$global:copyToQCcalc =  "C:\data\cmm\watchedoutput\qccalc"

$global:copyToGeneral = "C:\data\cmm\watchedoutput\general"

$global:copyToLitmus = "C:\data\cmm\watchedoutput\litmus"

$global:copyToA2 = "C:\data\cmm\A2"

$global:logpath="c:\data\logs\watch598cmmresults"

$global:thisNickName = "watch598-b-cmm-ps1"

$global:rundate = (Get-Date).toString("yyyy-MM-dd")

$count = 0


#  SETTINGS end ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



# settings-from-file ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# get path to monitor from settings file..
Get-Content watch598settings.conf | Foreach-Object{
   $var = $_.Split('=')
   New-Variable -Name $var[0] -Value $var[1]
}

$global:PathToMonitor = "$s_PathToMonitor"

#$global:watch_file_filter = $s_watch_file_filter

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



# Prep ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


cmd /c mkdir $PathToMonitor
cmd /c mkdir $interimfolder
cmd /c mkdir $copyToQCcalc
cmd /c mkdir $copyToGeneral
cmd /c mkdir $global:copyToLitmus
cmd /c mkdir $global:copyToA2
cmd /c mkdir $logpath

# save process id to file. Could use this to check later that is still running.
$tsdhms = (Get-Date).toString("yyyy-MM-dd_HH.mm.ss")

$carg = "echo {0}, {1}>>{2}\{3}_{4}_pid__log.txt" -f $pid, $tsdhms, $logpath,$(gc env:computername), $thisNickName
cmd /c $carg

$carg = "echo {0}>{1}\{2}_{3}_pid.txt" -f $pid, $logpath,$(gc env:computername), $thisNickName
cmd /c $carg

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#  Main code ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# on startup, handle chr,fet,hdr files in folder A





$FileSystemWatcher = New-Object System.IO.FileSystemWatcher
$FileSystemWatcher.Path  = "$PathToMonitor"
#$FileSystemWatcher.Filter  = $watch_file_filter
$FileSystemWatcher.IncludeSubdirectories = $false

# make sure the watcher emits events
$FileSystemWatcher.EnableRaisingEvents = $true

# define the code that should execute when a file change is detected
$Action = {
  $details = $event.SourceEventArgs
  $Name = $details.Name
  $FullPath = $details.FullPath
  $OldFullPath = $details.OldFullPath
  $OldName = $details.OldName
  $ChangeType = $details.ChangeType
  $Timestamp = $event.TimeGenerated

  $cmd = "cmd /c echo $FullPath, $ChangeType, $Timestamp>>$logpath\$(gc env:computername)-$thisNickName--run-log.txt"
  Invoke-expression $cmd
  # Write-Host ""
  # Write-Host $cmd
  
  # $carg = "echo {0}, {1}, {2}>>{3}\{4}_{5}_run-log.txt" -f $FullPath, $ChangeType, $Timestamp, $logpath, $(gc env:computername), $thisNickName
  # cmd /c $carg
  # Write-Host ""
  # Write-Host $carg


  $text = "{0} was {1} at {2} " -f $FullPath, $ChangeType, $Timestamp
  Write-Host ""
  Write-Host $text -ForegroundColor Green
  
  # copy the files to both locations..
  
  Write-Host "wf: $watch_file_filter"
  Write-Host $Name
  
  # #debug..
  # Write-Host "$cmd"

  # you can also execute code based on change type here
  switch ($ChangeType)
    {
    'Changed' {

    # Wait 10 seconds after file is changed to move files
    Start-Sleep -Seconds 10
    # Copy files from A to A2
    "DATA FROM A" | Out-File 'C:\data\logs\watch598cmmresults\testlogs.txt' -Append

    gci $PathToMonitor | measure Length -s | Out-File 'C:\data\logs\watch598cmmresults\testlogs.txt' -Append # Print A Details
    robocopy $PathToMonitor $copyToA2 '*chr.txt*' '*hdr.txt*' '*fet.txt*'
    $print = "File COPIED From A to A2 at {0}" -f (Get-Date)
    $print | Out-File 'C:\data\logs\watch598cmmresults\testlogs.txt' -Append
    Start-Sleep 2
    # Move files from A2 to interim folder
    "DATA FROM A2" | Out-File 'C:\data\logs\watch598cmmresults\testlogs.txt' -Append

    gci $copyToA2 | measure Length -s | Out-File 'C:\data\logs\watch598cmmresults\testlogs.txt' -Append # Print A2 Details
    robocopy $copyToA2 $interimfolder '*chr.txt*' '*hdr.txt*' '*fet.txt*'  /mov /is /R:3 /W:4
    $print = "File MOVED From A2 to Interim at {0}" -f (Get-Date)
    $print | Out-File 'C:\data\logs\watch598cmmresults\testlogs.txt' -Append
    Start-Sleep 2
    # Copy Files from B to E
    "DATA FROM B BEFORE COPY TO E" | Out-File 'C:\data\logs\watch598cmmresults\testlogs.txt' -Append

    gci $interimfolder | measure Length -s | Out-File 'C:\data\logs\watch598cmmresults\testlogs.txt' -Append # Print B Details
    robocopy $interimfolder $copyToLitmus '*chr.txt*' '*hdr.txt*' '*fet.txt*'
    $print = "File COPIED From B to E at {0}" -f (Get-Date)
    $print | Out-File 'C:\data\logs\watch598cmmresults\testlogs.txt' -Append
    Start-Sleep 2
    # copy files from interim folder to general folder
    "DATA FROM B AFTER COPY TO E AND BEFORE COPY TO C" | Out-File 'C:\data\logs\watch598cmmresults\testlogs.txt' -Append

    gci $interimfolder | measure Length -s | Out-File 'C:\data\logs\watch598cmmresults\testlogs.txt' -Append # Print B Details
    robocopy $interimfolder $copyToGeneral '*chr.txt*' '*hdr.txt*' '*fet.txt*'
    $print = "File Copied From B to General at {0}" -f (Get-Date)
    $print | Out-File 'C:\data\logs\watch598cmmresults\testlogs.txt' -Append
    Start-Sleep 2

    # move files from interim folder to qccalc folder
    robocopy $interimfolder $copyToQCcalc '*chr.txt*' '*hdr.txt*' '*fet.txt*' /mov /is /R:3 /W:4
    "DATA FROM D AFTER FILES MOVE FROM B" | Out-File 'C:\data\logs\watch598cmmresults\testlogs.txt' -Append

    gci $copyToQCcalc | measure Length -s | Out-File 'C:\data\logs\watch598cmmresults\testlogs.txt' -Append # Print D Details
    $print = "File MOVED From B to D at {0}" -f (Get-Date)
    $print | Out-File 'C:\data\logs\watch598cmmresults\testlogs.txt' -Append
    "DATA FROM E AT END OF SCRIPT" | Out-File 'C:\data\logs\watch598cmmresults\testlogs.txt' -Append

    gci $copyToLitmus | measure Length -s | Out-File 'C:\data\logs\watch598cmmresults\testlogs.txt' -Append # Print E Details


      #$cmd = 'cmd /c copy  "$FullPath" $copyToQCcalc>>$logpath\$rundate-$(gc env:computername)-$thisNickName--copy-log.txt'
      #Invoke-expression $cmd 
      #$cmd = 'cmd /c copy  "$FullPath" $copyToGeneral'
      #Invoke-expression $cmd 
    }
    'Created' { 
      # Write file created to logs
      $print = "FILE CREATED AT {0}" -f (Get-Date)
      $print | Out-File 'C:\data\logs\watch598cmmresults\testlogs.txt' -Append
      $count += 1
      # Start writeinfinitly.py writing to file
      if ($count -eq 3) {
        #$path = 'C:\Users\nboyd\Desktop\tools599-main\watchcopy598'
        #$file = 'writeinfinitly.py'
        # Start filevalidator after waiting 10 seconds
        #$cmd = $path+"\\"+$file  # This line of code will create the concatenate the path and file
        #Start-Process $cmd  # This line will execute the cmd
        Start-Sleep 10
        $script = $PSScriptRoot+"\filevalidator.ps1"
        & $script
        $count = 0
      }
    }
    'Deleted' { "DELETED"
    # uncomment the below to mimick a time intensive handler
    <#
    Write-Host "Deletion Handler Start" -ForegroundColor Gray
    Start-Sleep -Seconds 4    
    Write-Host "Deletion Handler End" -ForegroundColor Gray
    #>
   }
     'Renamed' { 
      # this executes only when a file was renamed
      $text = "File {0} was renamed to {1}" -f $OldName, $Name
      Write-Host $text -ForegroundColor Yellow
    }
    default { Write-Host $_ -ForegroundColor Red -BackgroundColor White }
  }
}


# add event handlers
$handlers = . {
  Register-ObjectEvent -InputObject $FileSystemWatcher -EventName Changed -Action $Action -SourceIdentifier FSChange
   Register-ObjectEvent -InputObject $FileSystemWatcher -EventName Created -Action $Action -SourceIdentifier FSCreate
  # Register-ObjectEvent -InputObject $FileSystemWatcher -EventName Deleted -Action $Action -SourceIdentifier FSDelete
  # Register-ObjectEvent -InputObject $FileSystemWatcher -EventName Renamed -Action $Action -SourceIdentifier FSRename
}

Write-Host "Watching for changes to $PathToMonitor, file filter:  $watch_file_filter" 

try
{
  do
  {
  # -Timeout 3 is wait 3 seconds in loop.
    Wait-Event -Timeout 3
    Write-Host "." -NoNewline
  } while ($true)
}
finally
{
  # this gets executed when user presses CTRL+C
  # remove the event handlers
  Unregister-Event -SourceIdentifier FSChange
   Unregister-Event -SourceIdentifier FSCreate
  # Unregister-Event -SourceIdentifier FSDelete
  # Unregister-Event -SourceIdentifier FSRename
  # remove background jobs
  $handlers | Remove-Job
  # remove filesystemwatcher
  $FileSystemWatcher.EnableRaisingEvents = $false
  $FileSystemWatcher.Dispose()
  "Event Handler disabled."
}