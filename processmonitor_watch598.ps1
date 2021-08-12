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

# Create LastErrorEmailSent if it does not exist (For first run)
if (!(Test-Path "C:\data\logs\watch598cmmresults\LastErrorEmailSent.txt"))
{
   New-Item -path "C:\data\logs\watch598cmmresults\LastErrorEmailSent.txt" -type "file" -value ""
}
else
{
  Write-Host ""
}

# Get Contents from watch598settings
Get-Content watch598settings.conf | Foreach-Object{
    $var = $_.Split('=')
    New-Variable -Name $var[0] -Value $var[1]
 }

$global:errorEmailFrequencyMinutes = "$errorEmailFrequencyMinutes"

# Get last email send time from file

# Get last email sent datetime from text file
#$lastEmailSend = [IO.File]::ReadAllText("C:\data\logs\watch598cmmresults\LastErrorEmailSent.txt")

# Convert date string from text file to date object (Will not run if erroremail has never been sent)
#if ($lastEmailSend -ne ""){
    #$lastEmailSendDate = [datetime]$lastEmailSend
#}


$script:logpath="c:\data\logs\watch598cmmresults"

$script:rundate = (Get-Date).toString("yyyy-MM-dd")

# Current time - 1 minute
#$timetocheck = (Get-Date).AddMinutes(-1)


#  SETTINGS end ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# Prep ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#  Main code ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Itterate through folder A looking for files older than 1 minute

# Get all files containing fet from folder A
$filesForA = Get-ChildItem 'C:\data\cmm\results from calypso\' -Filter '*fet.txt*' | Where-Object {$f.LastWriteTime -lt (Get-Date).AddMinutes(-1)}

#$fileForGeneral = Get-ChildItem 'C:\data\cmm\watchedoutput\general\' -Filter '*fet.txt*' | Where-Object {$f.LastWriteTime -lt (Get-Date).AddMinutes(-1)}

# Check if file > 1 minute old in A is also in general (WORKING I THINK)
if ($filesForA.Length -gt 0) {
    foreach ($f in $filesForA) {

        $testpath = 'C:\data\cmm\watchedoutput\general\{0}' -f $f

        # If file is found in A that is not in General, An error will occur
        if ((Test-Path -Path $testpath -PathType Leaf) -eq $false) {
            $print = "Error Occured at {0}" -f (Get-Date)
            $print | Out-File 'C:\data\logs\watch598cmmresults\errorLogs.txt' -Append
            
            # Read lastEmailSend from LastErrorEmailSent.txt and assign it to variable
            $lastEmailSend = [IO.File]::ReadAllText("C:\data\logs\watch598cmmresults\LastErrorEmailSent.txt")
            # If LastErrorEmailSent.txt is not empty (not the first time being run) convert lastEmailSend to a date object
            if ($lastEmailSend -ne ""){
                $lastEmailSendDate = [datetime]$lastEmailSend
            }

            # First time error occurs, email will be sent and lastemailsend will be updated in textfile
            if ($lastEmailSend -eq "") {
                #send-mailmessage -subject "Warning: error detected by processmonitor_watch598." -body "An error (LastEmailSent File is Blank) was detected by machine $(gc env:computername). Please check it. `n`nRef: this msg from computer: xxx  file:   C:\data\script\tools599\watchcopy598\processmonitor_watch598" -to @("dgleba@stackpole.com") -dno onFailure -smtpServer MESG01.stackpole.ca -from 'dgleba@stackpole.com'
                Set-Content  -Path "C:\data\logs\watch598cmmresults\LastErrorEmailSent.txt" -Value (Get-Date)
            } 
            # If error is found, and time is greater than lastEmailSendDate + errorEmailFrequencyMinutes, send email and update lastemailsend textfile
            elseif ((Get-Date) -gt $lastEmailSendDate.AddMinutes([int]$errorEmailFrequencyMinutes)) {
                # If error is detected and time is greater than lastemailsend + errorfrequencyminutes, send email and update file
                send-mailmessage -subject "Warning: error detected by processmonitor_watch598." -body "An error (File $f was not found in General) was detected  by machine $(gc env:computername). Please check it. `n`nRef: this msg from C:\Users\dgleba\Desktop\tools599-main\watchcopy598\processmonitor_watch598" -to @("nboyd@stackpole.com") -dno onFailure -smtpServer MESG01.stackpole.ca -from 'nboyd@stackpole.com'
                Set-Content  -Path "C:\data\logs\watch598cmmresults\LastErrorEmailSent.txt" -Value (Get-Date)
            }
        }  
    }
}


# I will let it run without checking right now.


#  run archiving ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



timeout 30

