#Author: Connor Ruggles
#Date: July 5, 2016
#Last Modified: July 5, 2016


#set up variables
$EmailTo = "alertemail@domain.com"
$EmailFrom = "email@domain.com"
$logPathToday = "\\server\pathtoday"
$logPathOld = "\\server\pathold"

#gets all log files from current day's scans
$logs = Get-ChildItem $logPathToday

ForEach($log in $logs)
{
    #writes name of log to screen
    Write-Host $log
    #gets last 5 lines of log file
    $lastFive = Get-Content -Path $logPathToday\$log | Select-Object -last 5
    
    #checks if log is empty (scan didn't start correctly)
    If($log.Length -eq 0)
    {
        Move-Item -Destination $logPathOld -Path $logPathToday\$log -Force
        Continue
    }
    #checks if scan did not finish correctly/stopped prematurely
    If(($lastFive -contains "Quick Scanning") -or ($lastFive -contains "Could not open"))
    {
        Move-Item -Destination $logPathOld -Path $logPathToday\$log -Force
        Continue
    }
    #checks again if scan did not finish correctly/stopped prematurely
    If($lastFive -notcontains "Ending Sophos Anti-Virus.")
    {
        Move-Item -Destination $logPathOld -Path $logPathToday\$log -Force
        Continue
    }
    #checks if it finish correctly
    If($lastFive -contains "Ending Sophos Anti-Virus.")
    {
        If($lastFive -contains "No viruses were discovered.")
        {
            #if scan did not detect anything, moves the log to the old folder
            Move-Item -Destination $logPathOld -Path $logPathToday\$log -Force
        }
        else
        {
            #otherwise, sends an email with the log file attached saying something is wrong
            #then moves the log to the old folder
            $EmailSubject = "A virus has been discovered."
            $EmailBody = "A virus has been discovered on a managed computer. Read through $log (attached to this email) for more details."
            Send-MailMessage -To $EmailTo -From $EmailFrom -Subject $EmailSubject -Body $EmailBody -SmtpServer smtp.domain.com -Attachments $logPathToday\$log
            Move-Item -Destination $logPathOld -Path $logPathToday\$log -Force
        }
    }
    else
    {
        $EmailSubject = "A virus has been discovered."
        $EmailBody = "A virus has been discovered on a managed computer. Read through $log (attached to this email) for more details."
        Send-MailMessage -To $EmailTo -From $EmailFrom -Subject $EmailSubject -Body $EmailBody -SmtpServer smtp.domain.com -Attachments $logPathToday\$log
        Move-Item -Destination $logPathOld -Path $logPathToday\$log -Force
    }

    #failsafe in case a file did not get moved during one of the other checks
    Move-Item -Destination $logPathOld -Path $logPathToday\$log -Force

}
