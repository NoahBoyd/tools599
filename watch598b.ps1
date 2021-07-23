# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Status: works from windows task scheduler

# Purpose:  watch a folder for changes and copy files.

# https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-filesystemwatcher-correctly-part-2



#  SETTINGS  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


$global:interimfolder =  "C:\data\cmm\system\interimfolder"

$global:copyToQCcalc =  "C:\data\cmm\watchedoutput\qccalc"

$global:copyToGeneral = "C:\data\cmm\watchedoutput\general"

$global:logpath="c:\data\logs\watch598cmmresults"

$global:thisNickName = "watch598-b-cmm-ps1"

$global:rundate = (Get-Date).toString("yyyy-MM-dd")


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
      
      # Move files from monitored folder to interim folder
      robocopy $PathToMonitor $interimfolder '*chr.txt*' '*hdr.txt*' '*fet.txt*'  /mov /is /R:3 /W:4 

      # copy files from interim folder to general folder
      robocopy $interimfolder $copyToGeneral '*chr.txt*' '*hdr.txt*' '*fet.txt*'

      # move files from interim folder to qccalc folder
      robocopy $interimfolder $copyToQCcalc '*chr.txt*' '*hdr.txt*' '*fet.txt*' /mov /is /R:3 /W:4 


      #$cmd = 'cmd /c copy  "$FullPath" $copyToQCcalc>>$logpath\$rundate-$(gc env:computername)-$thisNickName--copy-log.txt'
      #Invoke-expression $cmd 
      #$cmd = 'cmd /c copy  "$FullPath" $copyToGeneral'
      #Invoke-expression $cmd 
    }
    'Created' { "CREATED"}
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
  # Register-ObjectEvent -InputObject $FileSystemWatcher -EventName Created -Action $Action -SourceIdentifier FSCreate
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
  # Unregister-Event -SourceIdentifier FSCreate
  # Unregister-Event -SourceIdentifier FSDelete
  # Unregister-Event -SourceIdentifier FSRename
  # remove background jobs
  $handlers | Remove-Job
  # remove filesystemwatcher
  $FileSystemWatcher.EnableRaisingEvents = $false
  $FileSystemWatcher.Dispose()
  "Event Handler disabled."
}
