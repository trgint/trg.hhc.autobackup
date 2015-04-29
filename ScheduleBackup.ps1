$xmlfile = "TaskConfig.xml"
$url = "https://bitbucket.org/trginternational/trg.hhc.autobackup/raw/master/$xmlfile"

Write-Host -ForegroundColor Green "Downloading TaskConfig xml template"
if ($PSVersionTable.PSVersion -ge (new-object 'Version' 3,0))
{
    #Powershell version 3 and above support Invoke-WebRequest
    Invoke-WebRequest ("https://bitbucket.org/trginternational/trg.hhc.autobackup/raw/master/$xmlfile") -OutFile $xmlfile
} else {
    (New-Object System.IO.StreamReader((New-Object System.Net.WebClient).OpenRead($url))).ReadToEnd() | Out-File $xmlfile 
}

Write-Host -ForegroundColor Green "Please provide credentials under which the backup task should run"
$creds = Get-Credential

if ($creds -ne $null)
{
    #refer to https://msdn.microsoft.com/en-us/library/windows/desktop/bb736357(v=vs.85).aspx
    schtasks /Create /XML $xmlfile /RU $creds.UserName /RP $creds.GetNetworkCredential().Password /TN "SunSystems Auto backup"
} else {
    Write-Host -ForegroundColor Red "No credentials supplied - aborting."
}
