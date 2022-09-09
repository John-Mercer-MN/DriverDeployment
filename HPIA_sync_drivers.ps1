<#  Creator @ryandengstrom - ryandengstrom.com
    Used to maintain a softpaq repository for each model specified in the HPModelsTable.
    This Script was created to script maintenance of softpaq repositories, which are used with HP Image Assistant during OSD/IPU task sequences.
    
    REQUIREMENTS:  HP Client Management Script Library
    Download / Installer: https://ftp.hp.com/pub/caps-softpaq/cmit/hp-cmsl.html  
    Docs: https://developers.hp.com/hp-client-management/doc/client-management-script-library
    This script was created using version 1.2.1 (https://ftp.hp.com/pub/caps-softpaq/cmit/release/cmsl/hp-cmsl-1.2.1.exe)

    THANKS:
        HP: Nathan Kofahl (@nkofahl) was very helpful in answering questions about the cmdlets and a place to report bugs.

        Loop Code: The HPModelsTable loop code (and other general code) was taken from Gary Blok's (@gwblok) post on garytown.com.
            https://garytown.com/create-hp-bios-repository-using-powershell

        Logging: The Log function was created by Ryan Ephgrave (@ephingposh)
            https://www.ephingadmin.com/powershell-cmtrace-log-function/


Given model table, create the appropriate folder(s) and download the latest drivers from HP to it
Drivers are downloaded to $RepositoryPath
Summary of downloaded files in drivers.csv within folder
Activity is logged to file at path in $LogFile
customizations required:
    \\server\share for path to server to save downloaded drivers (1 time: line 111)
	Mail.domain.com for name of mail server (1 time: line 245)
	recipient@domain.com for name of email recipient (2 times: line 246, 249)
Template folders that need to be populated before use
	"$($RepositoryPath)\HPIA Base"
	"$($RepositoryPath)\ADTmaster"
#>

function Log {
    Param (
        [Parameter(Mandatory=$false)]
        $Message,

        [Parameter(Mandatory=$false)]
        $ErrorMessage,

        [Parameter(Mandatory=$false)]
        $Component,

        [Parameter(Mandatory=$false)]
        [int]$Type,
       
        [Parameter(Mandatory=$true)]
        $LogFile
    )
<#
Type: 1 = Normal, 2 = Warning (yellow), 3 = Error (red)
#>
    $Time = Get-Date -Format "HH:mm:ss.ffffff"
    $Date = Get-Date -Format "MM-dd-yyyy"

    if ($ErrorMessage -ne $null) {$Type = 3}
    if ($Component -eq $null) {$Component = " "}
    if ($Type -eq $null) {$Type = 1}

    $LogMessage = "<![LOG[$Message $ErrorMessage" + "]LOG]!><time=`"$Time`" date=`"$Date`" component=`"$Component`" context=`"`" type=`"$Type`" thread=`"`" file=`"`">"
    $LogMessage | Out-File -Append -Encoding UTF8 -FilePath $LogFile
}

function Get-IniFile 
{  
    param( [parameter(Mandatory = $true)] [string] $filePath )  
    $anonymous = "NoSection"
    $ini = @{}  
    switch -regex -file $filePath  
    {  
        "^\[(.+)\]$" # Section  
        {  
            $section = $matches[1]  
            $ini[$section] = @{}  
            $CommentCount = 0  
        }  
        "^(;.*)$" # Comment  
        {  
            if (!($section))  
            {  
                $section = $anonymous  
                $ini[$section] = @{}  
            }  
            $value = $matches[1]  
            $CommentCount = $CommentCount + 1  
            $name = "Comment" + $CommentCount  
            $ini[$section][$name] = $value  
        }   
        "(.+?)\s*=\s*(.*)" # Key  
        {  
            if (!($section))  
            {  
                $section = $anonymous  
                $ini[$section] = @{}  
            }  
            $name,$value = $matches[1..2]  
            $ini[$section][$name] = $value  
        }  
    }  
    return $ini  
}  



$OS = "Win10"
$SSMONLY = "ssm"
$Category1 = "bios"
$Category2 = "driver"
$Category3 = "firmware"
$Category4 = "software"
New-PSDrive -name Z -PSProvider "FileSystem" -Root "\\server\share\Drivers\HPDrivers" -Persist -Scope Global
$RepositoryPath = "Z:\HPIA_Installed"

$LogFile = "$RepositoryPath\RepoUpdate.log"
$newmodel = "true"

$HPModelsTable= @( 
#        @{ ProdCode = '83D5'; Model = "HP EliteBook 745 G5";      OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 735 G6 driver testing" } #test model only
       # @{ ProdCode = '81C3'; Model = "HP Elite Slice";           OSVER1 = 2009; OSVER2 = 1809; COLL = "HP Slice driver testing" }
        @{ ProdCode = '8591'; Model = "HP EliteDesk 880 G5 TWR";   OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 880 G5 driver testing" }
#       @{ ProdCode = '8720'; Model = "HP EliteBook x360 1030 G8"; OSVER1 = 2009; OSVER2 = 1809; COLL = "HP x360 G8 driver testing" }
#       @{ ProdCode = '85B9'; Model = "HP Elite x2 G4";            OSVER1 = 2009; OSVER2 = 1809; COLL = "HP x2 G4 driver testing" }
#       @{ ProdCode = '870D'; Model = "HP Elite x2 G8";            OSVER1 = '2009'; OSVER2 = 1809; COLL = "HP x2 G8 driver testing" }
<#        @{ ProdCode = '880D'; Model = "HP EliteBook 840 G8";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 840 G8 driver testing" }
        @{ ProdCode = '8846'; Model = "HP EliteBook 850 G8";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 850 G8 driver testing" }
        @{ ProdCode = '8736'; Model = "HP ZBook Studio G7 Mobile"; OSVER1 = 2009; OSVER2 = 1809; COLL = "HP ZBook Studio G7 driver testing" }
        @{ ProdCode = '8783'; Model = "HP ZBook Fury 15 G7"  ;     OSVER1 = 2009; OSVER2 = 1809; COLL = "HP ZBook Fury 15 G7 driver testing" }
        @{ ProdCode = '8715'; Model = "HP ProDesk 600 G6 DM";      OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G6 driver testing" }
        @{ ProdCode = '8712'; Model = "HP ProDesk 600 G6 MT";      OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G6 driver testing" }
        @{ ProdCode = '8714'; Model = "HP ProDesk 600 G6 SFF";     OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G6 driver testing" }
        @{ ProdCode = '869D'; Model = "HP ProBook 440 G7"  ;       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 440 G7 driver testing" }
        @{ ProdCode = '8723'; Model = "HP EliteBook 840 G7"  ;     OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 840 G7 driver testing" }
        @{ ProdCode = '8724'; Model = "HP EliteBook 850 G7"  ;     OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 850 G7 driver testing" }
        @{ ProdCode = '81C5'; Model = "HP Z4 G4";                  OSVER1 = 2009; OSVER2 = 1809; COLL = "HP Z4 G4 driver testing" }
        @{ ProdCode = '8589'; Model = "HP EliteBook 735 G6";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 735 G6 driver testing" }
        @{ ProdCode = '8584'; Model = "HP EliteBook 745 G6";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 745 G6 driver testing" }
        @{ ProdCode = '8619'; Model = "HP EliteDesk 705 G5 DM";    OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 705 G5 driver testing" }
        @{ ProdCode = '8598'; Model = "HP ProDesk 600 G5 DM";      OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G5 SSM driver testing" }
        @{ ProdCode = '8596'; Model = "HP ProDesk 600 G5 MT";      OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G5 SSM driver testing" }
        @{ ProdCode = '8597'; Model = "HP ProDesk 600 G5 SFF";     OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G5 SSM driver testing" }
        @{ ProdCode = '854A'; Model = "HP EliteBook 830 G6";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 8x0 G6 SSM driver testing" }
        @{ ProdCode = '8549'; Model = "HP EliteBook 840 G6";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 8x0 G6 SSM driver testing" }
        @{ ProdCode = '8549'; Model = "HP EliteBook 850 G6";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 8x0 G6 SSM driver testing" }
        @{ ProdCode = '856D'; Model = "HP ProBook 640 G5"  ;       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 640 G5 SSM driver testing" }
        @{ ProdCode = '860F'; Model = "HP ZBOOK 15 G6 MOBILE";     OSVER1 = 2009; OSVER2 = 1809; COLL = "HP ZBook 15 G6 driver testing" }
        @{ ProdCode = '83EF'; Model = "HP ProDesk 600 G4 DM";      OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G4 SSM driver testing" }
        @{ ProdCode = '83EC'; Model = "HP ProDesk 600 G4 MT";      OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G4 SSM driver testing" }
        @{ ProdCode = '83EE'; Model = "HP ProDesk 600 G4 SFF";     OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G4 SSM driver testing" }
        @{ ProdCode = '83B3'; Model = "HP EliteBook 830 G5";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 8x0 G5 SSM driver testing" }
        @{ ProdCode = '83B2'; Model = "HP EliteBook 850 G5";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 8x0 G5 SSM driver testing" }
        @{ ProdCode = '83D2'; Model = "HP ProBook 640 G4";         OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 640 G4 SSM driver testing" }
        @{ ProdCode = '8414'; Model = "HP ELITE X2 1013 G3";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP x2 1013 G3 driver testing" }
        @{ ProdCode = '842A'; Model = "HP ZBOOK 15 G5 MOBILE";     OSVER1 = 2009; OSVER2 = 1809; COLL = "HP ZBook 15 G5 driver testing" }
        @{ ProdCode = '83B2'; Model = "HP ZBOOK 15U G5 MOBILE";    OSVER1 = 2009; OSVER2 = 1809; COLL = "HP ZBook 15u G5 driver testing" }
        @{ ProdCode = '8438'; Model = "HP ELITEBOOK X360 1030 G3"; OSVER1 = 2009; OSVER2 = 1809; COLL = "HP x360 G3 SSM driver testing" }
        @{ ProdCode = '829E'; Model = "HP ProDesk 600 G3 DM";      OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G3 SSM driver testing" }
        @{ ProdCode = '829D'; Model = "HP ProDesk 600 G3 MT";      OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G3 SSM driver testing" }
        @{ ProdCode = '82B4'; Model = "HP ProDesk 600 G3 SFF";     OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G3 SSM driver testing" }
        @{ ProdCode = '835B'; Model = "HP EliteDesk 705 G3 SFF";   OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 705 G3 SSM driver testing" }
        @{ ProdCode = '8292'; Model = "HP EliteBook 820 G4";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 8x0 G4 SSM driver testing" }
        @{ ProdCode = '828C'; Model = "HP EliteBook 840 G4";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 8x0 G4 SSM driver testing" }
        @{ ProdCode = '82AA'; Model = "HP ProBook 640 G3";         OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 640 G3 SSM driver testing" }
        @{ ProdCode = '80FC'; Model = "HP ELITE X2 1012 G1";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP x2 1012 G1 driver testing" }
        @{ ProdCode = '807C'; Model = "HP EliteBook 820 G3";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 8x0 G3 SSM driver testing" }
        @{ ProdCode = '8079'; Model = "HP EliteBook 840 G3";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 8x0 G3 SSM driver testing" }
        @{ ProdCode = '80FD'; Model = "HP ProBook 640 G2";         OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 640 G2 SSM driver testing" }
        @{ ProdCode = '8079'; Model = "HP ZBOOK 15U G3 MOBILE";    OSVER1 = 2009; OSVER2 = 1809; COLL = "HP ZBook 15u G3 driver testing" }
        @{ ProdCode = '80D4'; Model = "HP ZBOOK STUDIO G3 MOBILE"; OSVER1 = 2009; OSVER2 = 1809; COLL = "HP ZBook Studio G3 driver testing" }
        @{ ProdCode = '8169'; Model = "HP ProDesk 600 G2 DM";      OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G2 SSM driver testing" }
        @{ ProdCode = '805D'; Model = "HP ProDesk 600 G2 MT";      OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G2 SSM driver testing" }
        @{ ProdCode = '805D'; Model = "HP ProDesk 600 G2 SFF";     OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G2 SSM driver testing" }
        @{ ProdCode = '2253'; Model = "HP ZBOOK 15 G2 MOBILE";     OSVER1 = 2009; OSVER2 = 1809; COLL = "HP ZBook 15 G2 driver testing" }
        @{ ProdCode = '2255'; Model = "HP ZBOOK 17 G2 MOBILE";     OSVER1 = 2009; OSVER2 = 1809; COLL = "HP ZBook 15 G2 driver testing" }
##        @{ ProdCode = '3397'; Model = "HP COMPAQ ELITE 8300 SFF";  OSVER1 = 1809; COLL = " }
##        @{ ProdCode = '18DF'; Model = "HP ELITEBOOK FOLIO 9470M";  OSVER1 = 1809; COLL = " }
##        @{ ProdCode = '1494'; Model = "HP COMPAQ ELITE 8200 CMT";  OSVER1 = 2009; OSVER2 = 1809; COLL = " }
##        @{ ProdCode = '1495'; Model = "HP COMPAQ ELITE 8200 SFF";  OSVER1 = 2009; OSVER2 = 1809; COLL = " }
##        @{ ProdCode = '3646'; Model = "HP COMPAQ ELITE 8000 SFF";  OSVER1 = 2009; OSVER2 = 1809; COLL = " }
##        @{ ProdCode = '3031'; Model = "HP COMPAQ ELITE 7900 SFF";  OSVER1 = 2009; OSVER2 = 1809; COLL = " }
##        @{ ProdCode = '212B'; Model = "HP Z440 Workstation";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP Z440 driver testing" }
        @{ ProdCode = '158B'; Model = "HP Z820 Workstation";       OSVER1 = 1809; OSVER2 = 1803; COLL = "HP Z820 driver testing" }
        @{ ProdCode = '21D0'; Model = "HP ProDesk 600 G1 DM";      OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 600 G1 SSM driver testing" }
        @{ ProdCode = '18E7'; Model = "HP ProDesk 600 G1 SFF";     OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 600 G1 SSM driver testing" }
        @{ ProdCode = '1993'; Model = "HP ProBook 640 G1";         OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 640 G1 SSM driver testing" }
        @{ ProdCode = '225A'; Model = "HP EliteBook 820 G2";       OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 8x0 G2 SSM driver testing" }
        @{ ProdCode = '2216'; Model = "HP EliteBook 840 G2";       OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 8x0 G2 SSM driver testing" }
##        @{ ProdCode = '1850'; Model = "HP Compaq Pro 6305";        OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 6305 driver testing" }
##        @{ ProdCode = '1850'; Model = "HP Compaq Pro 6305 SFF";    OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 6305 driver testing" }
        @{ ProdCode = '1992'; Model = "HP ProBook 645 G1";         OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 645 G1 SSM driver testing" }
        @{ ProdCode = '1991'; Model = "HP EliteBook 820 G1";       OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 8x0 G1 SSM driver testing" }
        @{ ProdCode = '198F'; Model = "HP EliteBook 840 G1";       OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 8x0 G1 SSM driver testing" }
        @{ ProdCode = '1909'; Model = "HP ZBOOK 15 G1 MOBILE";     OSVER1 = 1809; OSVER2 = 1803; COLL = "HP ZBook 15 G1 driver testing" }
        @{ ProdCode = '22DA'; Model = "HP ELITEBOOK FOLIO 9480M";  OSVER1 = 1809; OSVER2 = 1803; COLL = "HP Folio 9480M driver testing"}
        @{ ProdCode = '2215'; Model = "HP EliteDesk 705 G1";       OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 705 G1 SSM driver testing" }
#>
       )
if ($newmodel -eq "true") #for logic that was never implemented
    {
    foreach ($Model in $HPModelsTable) 
        {
        Log -Message "----------------------------------------------------------------------------" -LogFile $LogFile
        Log -Message "Checking if repository for model $($Model.Model) aka $($Model.ProdCode) exists" -LogFile $LogFile
        if (Test-Path "$($RepositoryPath)\$($Model.Model)\Files\Repository") { Log -Message "Repository for model $($Model.Model) aka $($Model.ProdCode) already exists" -LogFile $LogFile }
        if (-not (Test-Path "$($RepositoryPath)\$($Model.Model)\Files\Repository")) 
            {
            Log -Message "Repository for $($Model.Model) does not exist, creating now" -LogFile $LogFile
            New-Item -ItemType Directory -Path "$($RepositoryPath)\$($Model.Model)\Files\Repository"
            if (Test-Path "$($RepositoryPath)\$($Model.Model)\Files\Repository")
                {
                Log -Message "$($Model.Model) HPIA folder and repository subfolder successfully created" -LogFile $LogFile
                }
            else
                {
                Log -Message "Failed to create repository subfolder!" -LogFile $LogFile
                Exit
                }
            }
        if (-not (Test-Path "$($RepositoryPath)\$($Model.Model)\Files\Repository\.repository")) 
            {
            Log -Message "Repository not initialized, initializing now" -LogFile $LogFile
            Set-Location -Path "$($RepositoryPath)\$($Model.Model)\Files\Repository"
            Initialize-Repository
            if (Test-Path "$($RepositoryPath)\$($Model.Model)\Files\Repository\.repository") 
                {
                Log -Message "$($Model.Model) repository successfully initialized" -LogFile $LogFile
                }
            else 
                {
                Log -Message "Failed to initialize repository for $($Model.Model)" -LogFile $LogFile
                Exit
                }
            }
        else
            { #necessary when upgrading from 1.3 to 1.4
            Log -Message "Reinitializing now" -LogFile $LogFile
            remove-item "$($RepositoryPath)\$($Model.Model)\Files\Repository\.repository\repository.json"
            Set-Location -Path "$($RepositoryPath)\$($Model.Model)\Files\Repository"
            Initialize-Repository
            }
    
        Log -Message "Set location to $($Model.Model) repository" -LogFile $LogFile
        Set-Location -Path "$($RepositoryPath)\$($Model.Model)\Files\Repository"
      
        Log -Message "Configure notification for $($Model.Model)" -LogFile $LogFile
        Set-RepositoryNotificationConfiguration mail.domain.com
        Add-RepositorySyncFailureRecipient -to recipient@domain.com
        set-repositoryconfiguration -setting OfflineCacheMode -cachevalue enable
        set-repositoryconfiguration -Setting OnRemoteFileNotFound -value LogAndContinue
        Remove-RepositorySyncFailureRecipient -to recipient@domain.com
    
        Log -Message "Remove any existing repository filter for $($Model.Model) repository" -LogFile $LogFile
        Remove-RepositoryFilter -platform $($Model.ProdCode) -yes
    
        Log -Message "Applying repository filter to $($Model.Model) repository ($os $($Model.OSVER1) & $($Model.OSVER2), $Category1, $Category2, and $Category3)" -LogFile $LogFile
        if ($($Model.OSVER1))
            {
            Add-RepositoryFilter -platform $($Model.ProdCode) -os $OS -osver $($Model.OSVER1) -category $Category1
            Add-RepositoryFilter -platform $($Model.ProdCode) -os $OS -osver $($Model.OSVER1) -category $Category2
            Add-RepositoryFilter -platform $($Model.ProdCode) -os $OS -osver $($Model.OSVER1) -category $Category3
            Add-RepositoryFilter -platform $($Model.ProdCode) -os $OS -osver $($Model.OSVER1) -category $Category4
            }
        if ($($Model.OSVER2))
            {
            Add-RepositoryFilter -platform $($Model.ProdCode) -os $OS -osver $($Model.OSVER2) -category $Category1
            Add-RepositoryFilter -platform $($Model.ProdCode) -os $OS -osver $($Model.OSVER2) -category $Category2
            Add-RepositoryFilter -platform $($Model.ProdCode) -os $OS -osver $($Model.OSVER2) -category $Category3
            Add-RepositoryFilter -platform $($Model.ProdCode) -os $OS -osver $($Model.OSVER2) -category $Category4
            }

        Log -Message "Invoking repository sync for $($Model.Model) repository ($os $($Model.OSVER1) & $($Model.OSVER2), $Category1, $Category2, and $Category3)" -LogFile $LogFile
        Invoke-RepositorySync
    
        Log -Message "Invoking repository cleanup for $($Model.Model) repository for $Category1, $Category2, and $Category3" -LogFile $LogFile
        Invoke-RepositoryCleanup

        Log -Message "Confirm HPIA files are up to date for $($Model.Model)" -LogFile $LogFile
        $RobocopySource = "$($RepositoryPath)\HPIA Base"
        $RobocopyDest   = "$($RepositoryPath)\$($Model.Model)\Files"
        $RobocopyArg    = '"'+$RobocopySource+'"'+' "'+$RobocopyDest+'"'+' /E'
        $RobocopyCmd    = "robocopy.exe"
        Start-Process -FilePath $RobocopyCmd -ArgumentList $RobocopyArg -Wait

        Log -Message "Confirm App Deploy Toolkit files are up to date for $($Model.Model)" -LogFile $LogFile
        $RobocopySource = "$($RepositoryPath)\ADTmaster"
        $RobocopyDest   = "$($RepositoryPath)\$($Model.Model)"
        $RobocopyArg    = '"'+$RobocopySource+'"'+' "'+$RobocopyDest+'"'+' /E'
        $RobocopyCmd    = "robocopy.exe"
        Start-Process -FilePath $RobocopyCmd -ArgumentList $RobocopyArg -Wait

        Log -Message "Documenting drivers for $($Model.Model)" -LogFile $LogFile
        #document model repository contents
        $CVApath = "$($RepositoryPath)\$($Model.Model)\Files\Repository"
        $file = 'sp87653.cva'    #sample data
        $resultsfile = "$($RepositoryPath)\$($Model.Model)\drivers.csv"
        remove-item $resultsfile

        #write-host ("file,version,date,systemID,model")
        Add-Content -Path $resultsfile -Value '"File","Title","Version","VendorVersion","Date","Model","2009","1909","Win10"'

        $cvafiles = Get-ChildItem -path $CVApath -name -filter *.cva
        $CVACount = $cvafiles.count
        Log -Message "Drivers found:  $CVACount" -LogFile $LogFile
        foreach ($file in $cvafiles)
            {
            $sp = ($file -split ".cva")[0]
            $CVA = Get-IniFile $file
            $version = $CVA.General.Version
            $vendorversion = $CVA.General.VendorVersion
            $title = $CVA.'Software Title'.US
            $SPdate = $CVA.'CVA File Information'.CVATimeStamp.substring(0,8)
            $spdatebetter = $SPdate.Substring(4,2)+"/"+$SPdate.Substring(6,2)+"/"+$SPdate.Substring(0,4)
            $OS2009 = $cva.'Operating Systems'.Contains('WT64_2009')
            $OS1909 = $cva.'Operating Systems'.Contains('WT64_1909')
            $OS10 = $cva.'Operating Systems'.Contains('WT64')

            $newstreamreader = New-Object System.IO.StreamReader("$CVApath\$file")
            while (($readeachline =$newstreamreader.ReadLine()) -ne $null)
                {
                #Write-Host "$eachlinenumber  $readeachline"

                if ($readeachline -like 'SysId*=*')
                    {
                    #Write-Host $readeachline
                    $sysid = (($readeachline -split "=")[1] -split "0x")[1]
                    #write-host $sysid
                    if ($Model.ProdCode -eq $sysid)
                        {
                        $modelname = $model.Model
                        #write-host ($sp+"     "+$version+"     "+$spdatebetter+"     ") -NoNewline
                        #write-host ($sysid+"     "+$modelname)
                        Add-Content -Path $resultsfile -Value (@($sp, $title, $version, $vendorversion, $spdatebetter, $modelname, $OS2009, $OS1909, $OS10) -join ",")
                        }
                    }
                } # read line
            $newstreamreader.Dispose()
            } #for each cva file
        } #for each model
    } #if new model

Log -Message "----------------------------------------------------------------------------" -LogFile $LogFile
Log -Message "Repository Update Complete" -LogFile $LogFile
Log -Message "----------------------------------------------------------------------------" -LogFile $LogFile
#Set-Location -Path $RepositoryPath
Set-Location C:
Remove-PSDrive -Name Z
