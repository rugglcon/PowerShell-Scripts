#Author: Connor Ruggles
#Date: June 30, 2016
#Last Modified: July 21, 2016


#path where txt docs are sent
$LogPath = "\\server\path";

#counting variable
$script:ScanCount;
$OldScanCount;

#path where report is sent
$ReportPath = "\\server\reportpath"

#path where changed table will go after header modification
$ToBeScanned = "\\server\oldreportpath"

#gets each file in the report folder
$ToChange = Get-ChildItem -Path $ReportPath

#loops through to check for a new report every morning
ForEach($newFile in $ToChange)
{
    $oldName
    $name

    $header = "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,ComputerName,22,23,24,25,26"

    #gets contents of the report
    $content = get-content -Path $ReportPath\TABLE.csv

    #deletes the report because we have what we need
    Remove-Item -Force -Path $ReportPath\TABLE.csv

    #sets the header in a new file
    $header | Set-Content -Path $ReportPath\newtable.csv

    #adds the contents of the old report to the new file under the new header
    Add-Content -Path $ReportPath\newtable.csv -Value $content

    #gets only the column with the header "ComputerName" since that is all we care about
    $computers = Import-CSV -Path $ReportPath\newtable.csv | Select ComputerName
    
    #Moves the new file to a different folder since we are now done with it
    Move-Item -Path $ReportPath\newtable.csv -Destination $ToBeScanned -Force

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
            try
            {
                $Arch = (Get-WmiObject Win32_OperatingSystem -computername $name).OSArchitecture
            }
            catch
            {
                $Arch = "32-bit"
            } 

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
