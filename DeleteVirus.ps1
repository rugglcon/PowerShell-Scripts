#Author: Connor Ruggles
#Date: June 30, 2016
#Last Modified: July 21, 2016


#path where txt docs are sent
$LogPath = "\\amessophos\C$\SAV32Logs\Today";

#counting variable
$script:ScanCount;
$OldScanCount;

#path where report is sent
$ReportPath = "\\regfilesrvr\Departments\Information Technology\Sophos\SophosReports\"

#path where changed table will go after header modification
$ToBeScanned = "\\regfilesrvr\Departments\Information Technology\Sophos\SophosReportsOld\"

#gets each file in the report folder
$ToChange = Get-ChildItem -Path "\\regfilesrvr\Departments\Information Technology\Sophos\SophosReports\"

#loops through to check for a new report every morning
ForEach($newFile in $ToChange)
{
    $oldName
    $name

    $header = "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,ComputerName,22,23,24,25,26"

    #gets contents of the report
    $content = get-content -Path "\\regfilesrvr\Departments\Information Technology\Sophos\SophosReports\TABLE.csv"

    #deletes the report because we have what we need
    Remove-Item -Force -Path "\\regfilesrvr\Departments\Information Technology\Sophos\SophosReports\TABLE.csv"

    #sets the header in a new file
    $header | Set-Content -Path "\\regfilesrvr\Departments\Information Technology\Sophos\SophosReports\newtable.csv"

    #adds the contents of the old report to the new file under the new header
    Add-Content -Path "\\regfilesrvr\Departments\Information Technology\Sophos\SophosReports\newtable.csv" -Value $content

    #gets only the column with the header "ComputerName" since that is all we care about
    $computers = Import-CSV -Path "\\regfilesrvr\Departments\Information Technology\Sophos\SophosReports\newtable.csv" | Select ComputerName
    
    #Moves the new file to a different folder since we are now done with it
    Move-Item -Path "\\regfilesrvr\Departments\Information Technology\Sophos\SophosReports\newtable.csv" -Destination $ToBeScanned -Force

    #loops through each computer name in the list, starting a scan on each
    ForEach($newName in $computers)
    {
        #Stores previous hostname
        $oldName = $name

        #Gets computer name
        $name = $newName.ComputerName

        If($oldName -notmatch $name)
        {
            #gets architecture
            $Arch = (Get-WmiObject Win32_OperatingSystem -computername $name).OSArchitecture 

            #starts scan depending on architecture
            #PLEASE NOTE: IF THE COMPUTER IS NOT ONLINE,
            #THE ARCHITECTURE WILL RETURN EMPTY AND ATTEMPT TO
            #START A SCAN ON THE COMPUTER WITH 32-BIT COMMAND.
            If($Arch -match "64-bit")
            {
                Write-Host "Architecture is 64-bit. Starting Sophos scan on $name";
                $ScanCommand = '"\\$name\C$\Program Files (x86)\Sophos\Sophos Anti-Virus\SAV32CLI.exe" --ignore-could-not-open -nb -nc -di -P="$LogPath\scanlog_$script:ScanCount.txt"';
	            iex "& $ScanCommand";
                Write-Host "Name of log file is scanlog_$script:ScanCount.txt"
                $OldScanCount = $script:ScanCount;
                $script:ScanCount = $script:ScanCount + 1;

                If($script:ScanCount -eq 100)
                {
                   $script:ScanCount = 0;
                } 
            }
            else
            {
	            Write-Host "Architecture is 32-bit. Starting Sophos scan on $name.";
                $ScanCommand = '"\\$name\C$\Program Files\Sophos\Sophos Anti-Virus\SAV32CLI.exe" --ignore-could-not-open -nb -nc -di -P="$LogPath\scanlog_$script:ScanCount.txt"';
                iex "& $ScanCommand";
                Write-Host "Name of log file is scanlog_$script:ScanCount.txt"
                $OldScanCount = $script:ScanCount;
                $script:ScanCount = $script:ScanCount + 1;

                If($script:ScanCount -eq 100)
                {
                   $script:ScanCount = 0;
                }
            }
        }
    }
}