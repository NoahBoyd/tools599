# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Status: indev

# Purpose:  this will be a script to check that watch598 is working correctly.

 # - This will be a task scheduler running every 1 minutes. It is separate from watch598
 # - it runs once and stops. 
 # - check that file sizes are equal. see  C:\data\script\tools599\ps1-yard\24.cmpfilesize.ps1. log it.
 # - send email upon failure. write marker file saying email was sent. send it only once per n hours. use setting for frequency.
 # - call 24.cmpfilesize.ps1 cmpfilesize598.ps1

 # - once per day start  C:\data\script\tools599\watchcopy598\archivetomonthfolder598.bat
     # if time is greater than 23:35:00 and less than 23:36:00 then start it. see C:\data\script\tools599\ps1-yard\12.run.between.two.times.hours.seconds.ps1



 # - may not need heartbeat.
 # - check that watch598 heartbeat file timestamp string written in the file is changing. log it.

 # - later: restart it.




# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#  SETTINGS  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Get Contents from watch598settings
Get-Content watch598settings.conf | Foreach-Object{
    $var = $_.Split('=')
    New-Variable -Name $var[0] -Value $var[1]
 }

$global:PathToMonitor = "$s_PathToMonitor"

$global:errorEmailFrequencyMinutes = "$errorEmailFrequencyMinutes"

$script:logpath="c:\data\logs\watch598cmmresults"

$script:rundate = (Get-Date).toString("yyyy-MM-dd")

$script:lastErrorEmailSent = "C:\data\logs\watch598cmmresults\LastErrorEmailSent.txt"


$script:errorLogs = 'C:\data\logs\watch598cmmresults\processmonitor598-errorLogs.txt'
$script:debuglogpath = 'C:\data\logs\debug\'
$script:processmonitor598_runlog = 'C:\data\logs\watch598cmmresults\processmonitor598-runlog.txt'

#  SETTINGS end ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# Prep ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

cmd /c mkdir $logpath
cmd /c mkdir $debuglogpath


# Create LastErrorEmailSent if it does not exist (For first run) set content to date 400 days ago
if (!(Test-Path $script:lastErrorEmailSent))
{
   New-Item -path $script:lastErrorEmailSent -type "file" -value ""
   Set-Content -Path $script:lastErrorEmailSent -Value (Get-Date).AddDays(-400)
}

# Create ErrorLogs if it does not exist
if (!(Test-Path $script:errorLogs))
{
   New-Item -path $script:errorLogs -type "file" -value ""
}

# Write current date at run time to processmonitor run log
if (!(Test-Path $script:processmonitor598_runlog))
{
   New-Item -path $script:processmonitor598_runlog -type "file" -value ""
}

Add-Content  -Path $script:processmonitor598_runlog -Value (Get-Date)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#  Main code ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Itterate through folder A looking for files older than 2 minute

# Get all files containing fet from folder A
# $filesForA = Get-ChildItem $global:PathToMonitor -Filter '*fet.txt*' | Where-Object {$f.LastWriteTime -lt (Get-Date).AddMinutes(-2)} | Where-Object {$f.LastWriteTime -gt (Get-Date).AddMinutes(-122)}
$filesForA = Get-ChildItem $global:PathToMonitor -Filter '*fet.txt*' | Where-Object {$_.LastWriteTime -lt (Get-Date).AddMinutes(-2) -and $_.LastWriteTime -ge (Get-Date).AddMinutes(-180)} 
$mts = (Get-Date).toString("yyyyMMdd_HH.mm.ss")
(Get-Date) | Out-File $script:debuglogpath\pm598_$mts.txt -Append
# Check if file > 1 minute old in A is also in general (WORKING I THINK)
if ($filesForA.Length -gt 0) {
    foreach ($f in $filesForA) {
        
        # 2021-08-14 dgleba: i think adding single and double quote fixed it. It may have been not working with file names with spaces in them.
        # $testpath = "'C:\data\cmm\watchedoutput\general\{0}'" -f $f
        # or maybe not. dgleba 2021-08-15_Sun_12.27-PM
        $testpath = "C:\data\cmm\watchedoutput\general\{0}" -f $f
        write-host "dollarf: $f"
        "dollarf: $f"  | Out-File $script:debuglogpath\pm598_$mts.txt -Append
        
        # If file is found in A that is not in General, An error will occur
        if ((Test-Path -Path $testpath -PathType Leaf) -eq $false) {
            $print = "Error Occured at {0} with file {1}" -f (Get-Date), $f
            $print | Out-File $script:errorLogs -Append
            write-host $print
            "$print"  | Out-File $script:debuglogpath\pm598_$mts.txt -Append
             
            # Read lastEmailSend from LastErrorEmailSent.txt and assign it to variable
            $lastEmailSend = [IO.File]::ReadAllText($script:lastErrorEmailSent)
            # Convert lastEmailSend to a date object
            $lastEmailSendDate = [datetime]$lastEmailSend

            # If error is found, and time is greater than lastEmailSendDate + errorEmailFrequencyMinutes, send email and update lastemailsend textfile
            if ((Get-Date) -gt $lastEmailSendDate.AddMinutes([int]$errorEmailFrequencyMinutes)) {
                # If error is detected and time is greater than lastemailsend + errorfrequencyminutes, send email and update file
                send-mailmessage -subject "Warning: error detected by processmonitor_watch598." -body "An error (File $f was not found in General) was detected. Please check it. `n`nRef: this msg from computer: $(gc env:computername)  file: C:\Users\dgleba\Desktop\tools599-main\watchcopy598\processmonitor_watch598" -to @("nboyd@stackpole.com") -dno onFailure -smtpServer MESG06.stackpole.ca -from 'nboyd@stackpole.com'
                Set-Content  -Path $script:lastErrorEmailSent -Value (Get-Date)
                
                $taskName = "Watch598"
                # If task is still running but error occurs
                if (($task=Get-ScheduledTask $taskName).State -eq "Running"){
                    # Stop the current scheduled task
                    Stop-ScheduledTask $taskName

                    Start-Sleep 10

                    # Start new instance of scheduled task
                    Start-ScheduledTask $taskName
                    
                    # If task is Disabled and error occurs
                } elseif (($task=Get-ScheduledTask $taskName).State -eq "Disabled") {
                    # Enable Scheduled Task
                    Enable-ScheduledTask $taskName
                    
                    Start-Sleep 10

                    # Start Scheduled Task
                    Start-ScheduledTask $taskName
                
                    # If task is ready and error occurs
                } elseif (($task=Get-ScheduledTask $taskName).State -eq "Ready") {
                    # Start Scheduled Task
                    Start-ScheduledTask $taskName
                } else {
                    continue
                }
                
                Write-Host ""

            }
        }  Write-Host $filesForA.Length
    }
}



#  run archiving ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



timeout 5
