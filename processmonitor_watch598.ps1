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


$script:logpath="c:\data\logs\watch598cmmresults"

$script:rundate = (Get-Date).toString("yyyy-MM-dd")

# Current time - 1 minute
$timetocheck = (Get-Date).AddMinutes(-1)


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

        if ((Test-Path -Path $testpath -PathType Leaf) -eq $false) {
            
            Write-Host 'File doesnt exist in General (Send Email)'
        }  
    }
}


# I will let it run without checking right now.


#  run archiving ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



