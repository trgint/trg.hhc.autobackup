﻿#SunSystems 4.3.3 Auto-backup script written by 'Vincent De Smet <vincent.desmet@trginternational.com>'
#last update 21/04/2015
#this script requires 7z to be installed in the Program Files directory

#script parameters
[xml]$config = Get-Content ".\config.xml"
$sunPath       = $config.settings.sunDir     #location of SUN32.EXE folder (will be used as working directory)
$backupPath    = $config.settings.backupDir  #target folder for off-site backups (full path will be created if it does not exist)
#array of e-mail contacts to be notified when SunSystems backups are outdated:
$emailTo       = $config.settings.contacts.contact | %{ $_.GetAttribute("email")} 

#Script variables
$sunBackupPath     = Join-Path -Path $sunPath -ChildPath '_back' #backup folder under sunPath
$fileName          = "$(Get-Date -Format 'yyyyMMdd').zip" #$() is evaluated within string to output year-month-date.zip
$minZipFileDate    = (Get-Date).AddDays(-7)               #minimum date of zipfiles to keep, older files will be deleted
$minSunBackupDate  = (Get-Date).AddDays(-1)               #minimum date of Sun backup files,  for alert

#Additional email parameters for when Sun backup fails
$emailFrom     = '{0} <donotreply@hilton.com>' -f $env:COMPUTERNAME
$emailSubject  = 'Outdated SunSystems Backups'
$emailbody     = @"
Please note that the latest SunSystems Backup files are from {0}.
This date should be greater than $minSunBackupDate, it seems the backup procedure is failing.

Consider reviewing the Backup Operator password in SunSystems User Manager and in the T:\STANDARD.MDF macro definition for "FB".

Contact TRGHelp@trginternational.com if you are not sure what to do.

This is an automated e-mail from the SunBackup.ps1 script, please do not reply to this email.
For more information about this script refer to https://github.com/trgint/trg.hhc.autobackup
"@

$PSEmailServer = 'smtpmail.hilton.com' #this sets the default smtp server, port defaults to 25

#ensure backup path exists, -Force creates the full path if it does not exist
New-Item -ItemType Directory -Force -Path $backupPath

#ensure 7-zip is installed, raise an error if 7z is not installed
$7z = "$env:ProgramFiles\7-Zip\7z.exe"
if (-not (Test-Path $7z)) {throw "$7z is required"}

#function used to measure maximum LastWriteTime required as Measure-Object does not work with DateTime
function Measure-Latest([String] $Property = $null, [Switch] $Earliest) {
    BEGIN { $value = $null }
    PROCESS {
        if($Property){
            $TestObject = $_.$Property
        }else{
            $TestObject = $_
        }

        if($Earliest){
            $Logic = $TestObject -lt $value
        }else{
            $Logic = $TestObject -gt $value
        }

        if (($TestObject -ne $null) -and (($value -eq $null) -or ($Logic))) {
            $value = $TestObject
        }
    }
    END { $value }
}

#function used to lookup airport information
function Get-AirportInformation
{
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]
        $AirportCode
    )
    try
    {
        $wsdl = 'http://www.webservicex.net/airport.asmx?WSDL'
        $proxy = New-WebServiceProxy -Uri $wsdl -Namespace proxy -Class ip
        [xml]$rtn = $proxy.getAirportInformationByAirportCode($AirportCode)

        $rtn.NewDataSet.Table[0] | Select-Object -Property cityOrAirportName , Country
    }catch
    {
        Write-Warning "Error Occured: $_"
        Write-Host "Airport Code not found"
    }
}

Write-Host -ForegroundColor Green "Starting SunSystems file backup macro..."
#run sun32 with backup macro & pass through the Process Id
$p = Start-Process SUN32.EXE -WorkingDirectory $sunPath -ArgumentList @('STANDARD.MDF,,FB') -PassThru
#wait for the process to complete, specify a timeout to ensure rest of the script executes even if SUN32.EXE hangs
Wait-Process -Id $p.Id -Timeout (New-TimeSpan -Hours 2).TotalSeconds
if(!$p.HasExited)
{
	#forcefully kill SUN32.exe
    taskkill /T /F /PID $p.Id
}

#ensure backup ran by testing age of backup files
$sunBackupDate = Get-ChildItem $sunBackupPath -Recurse -Filter '*.bak' | Measure-Latest -property LastWriteTime
if($sunBackupDate -gt $minSunBackupDate) {
    #sun backup files are dated greater than the minimum date and are thus up to date
    #proceed with compression and cleanup
    
    Write-Host -ForegroundColor Green "Compressing SunSystems backups..."
    #zip all bak files -r = Recursively - Ampersand calls program referenced in string variable
    & $7z a -tzip `
        (Join-Path -Path $backupPath -ChildPath $fileName) `
        (Join-Path -Path $sunBackupPath -ChildPath '*.bak') `
        -r -mx7 -mmt
    
    #uncomment below lines to delete SUN backups after 7z successfully zipped them
    ##this has not been tested with the LastWriteTime check...
    #if ($LastExitCode -le 1) { 
    #    Remove-Item -Recurse (Join-Path -Path $sunBackupPath -ChildPath '*.bak') -ErrorAction SilentlyContinue
    #}
    
    Write-Host -ForegroundColor Green "Removing zip files older than $minZipFileDate..." 
    #clean up old backup archives
    Get-ChildItem $backupPath -ErrorAction SilentlyContinue | `
        ? {$_.Extension -eq '.zip' -and $_.LastWriteTime -lt $minZipFileDate} | `
        Remove-Item
}else {
    #sun backup files are older than the minimum date, send an e-mail alert!
    Write-Host -ForegroundColor Red "SunSystems Backup (*.bak) files are older than $minSunBackupDate, sending email... "

    #if first 3 characters of Server Name matches a valid airport code, tag this airport information at end of emailBody
    $AirportInformation = Get-AirportInformation -AirportCode $env:COMPUTERNAME.Substring(0,3)
    if ($AirportInformation -ne $null)
    {
        $emailBody = $emailBody + ("`n`nNote: {0} indicates this property is located near following airport: {1} ({2})" -f $env:COMPUTERNAME, $AirportInformation.cityOrAirportName, $AirportInformation.Country)
    }else {
        $emailBody = $emailBody + ("`n`nNote: airport information could not be retrieved for {0}" -f $env:COMPUTERNAME)
    }

    #add sunBackupDate to $emailBody & send email
    Send-Mailmessage -priority High `
        -from $emailFrom `
        -to $emailTo `
        -subject $emailSubject `
        -body ($emailBody -f $sunBackupDate)
}

Write-Host -ForegroundColor Green "Done." 
#exit

