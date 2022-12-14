<# John Mercer
Given model table and deployment keyword, find deployment status and summarize it
Activity is logged to file at path in $LogFileSCCM
Output is in c:\temp\deployment_summary.txt and screen
customizations required:
	SITE: for ConfigMgr site code (1 time: line 42)
	\\​server\share for path to server to save downloaded drivers (1 times: line 50)
	For each deployment run, modify line 45 ($keywords) as appropriate
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

Set-Location SITE:
$packageID = ""
$PackageProgramNamePush  = 'Driver Push'
$keywords = "*push09","*push10"
$successcodes = "10008","10040"
$inprogresscodes = "10002","10005","10022","10035","10037","10073","10061"
$errorcodes = "10053", "10057","10070","10045","10021","10054","10003"
$unknowncodes = "0", "10034"
New-PSDrive -name Z -PSProvider "FileSystem" -Root "\\server\share\Drivers\HPDrivers" -Persist -Scope Global
$RepositoryPath = "Z:\HPIA_Installed"
$LogFileSCCM = "$RepositoryPath\deploymentstatus.log"

$HPModelsTable= @( 
#        @{ ProdCode = '83D5'; Model = "HP EliteBook 745 G5";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 745 G5 driver pilot3c"; INC = "All HP 745 G5 Laptops" } #test model only
        @{ ProdCode = '8720'; Model = "HP EliteBook x360 1030 G8"; OSVER1 = 2009; OSVER2 = 1809; COLL = "HP x360 G8 driver $CollectionDescriptor"; INC = "All HP x360 G8 Laptops" }
        @{ ProdCode = '85B9'; Model = "HP Elite x2 G4";            OSVER1 = 2009; OSVER2 = 1809; COLL = "HP x2 G4 driver $CollectionDescriptor"; INC = "All HP x2 G4" }
        @{ ProdCode = '880D'; Model = "HP EliteBook 840 G8";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 840 G8 driver $CollectionDescriptor"; INC = "All HP 840 G8 Laptops"}
        @{ ProdCode = '8846'; Model = "HP EliteBook 850 G8";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 850 G8 driver $CollectionDescriptor"; INC = "All HP 850 G8 Laptops" }
        @{ ProdCode = '8736'; Model = "HP ZBook Studio G7 Mobile"; OSVER1 = 2009; OSVER2 = 1809; COLL = "HP ZBook Studio G7 driver $CollectionDescriptor"; INC = "All HP ZBook Studio G7 Laptops" }
        @{ ProdCode = '8783'; Model = "HP ZBook Fury 15 G7"  ;     OSVER1 = 1909; OSVER2 = 1809; COLL = "HP ZBook Fury 15 G7 driver $CollectionDescriptor"; INC = "All HP ZBook Fury 15/17 G7 Laptops" }
        @{ ProdCode = '8715'; Model = "HP ProDesk 600 G6 DM";      OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G6 DM driver $CollectionDescriptor"; INC = "All HP 600 G6 DM Desktops" }
        @{ ProdCode = '8712'; Model = "HP ProDesk 600 G6 MT";      OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G6 MT driver $CollectionDescriptor"; INC = "All HP 600 G6 MT Desktops" }
        @{ ProdCode = '8714'; Model = "HP ProDesk 600 G6 SFF";     OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G6 SFF driver $CollectionDescriptor"; INC = "All HP 600 G6 SFF Desktops" }
        @{ ProdCode = '869D'; Model = "HP ProBook 440 G7"  ;       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 440 G7 driver pilot3c"; INC = "All HP 440 G7 Laptops" }
        @{ ProdCode = '8723'; Model = "HP EliteBook 840 G7"  ;     OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 840 G7 driver pilot3c"; INC = "All HP 840 G7 Laptops" }
        @{ ProdCode = '8724'; Model = "HP EliteBook 850 G7"  ;     OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 850 G7 driver pilot3c"; INC = "All HP 850 G7 Laptops" }
#        @{ ProdCode = '8589'; Model = "HP EliteBook 735 G6";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 735 G6 driver pilot3c"; INC = "All HP 735 G6 Laptops" } # no devices
        @{ ProdCode = '8619'; Model = "HP EliteDesk 705 G5 DM";    OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 705 G5 driver pilot3c"; INC = "All HP 705 G5 Desktops"  }
        @{ ProdCode = '8584'; Model = "HP EliteBook 745 G6";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 745 G6 driver pilot3c"; INC = "All HP 745 G6 Laptops" }
        @{ ProdCode = '8598'; Model = "HP ProDesk 600 G5 DM";      OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G5 DM driver pilot3c"; INC = "All HP 600 G5 DM Desktops"  }
        @{ ProdCode = '8596'; Model = "HP ProDesk 600 G5 MT";      OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G5 MT driver pilot3c"; INC = "All HP 600 G5 MT Desktops"  }
        @{ ProdCode = '8597'; Model = "HP ProDesk 600 G5 SFF";     OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G5 SFF driver pilot3c"; INC = "All HP 600 G5 SFF Desktops"  }
        @{ ProdCode = '854A'; Model = "HP EliteBook 830 G6";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 830 G6 driver pilot3c"; INC = "All HP 830 G6 Laptops"  }
        @{ ProdCode = '8549'; Model = "HP EliteBook 840 G6";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 840 G6 driver pilot3c"; INC = "All HP 840 G6 Laptops"  }
        @{ ProdCode = '8549'; Model = "HP EliteBook 850 G6";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 850 G6 driver pilot3c"; INC = "All HP 850 G6 Laptops"  }
        @{ ProdCode = '856D'; Model = "HP ProBook 640 G5"  ;       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 640 G5 driver pilot3c"; INC = "All HP 640 G5 Laptops"  }
        @{ ProdCode = '85B9'; Model = "HP Elite x2 G4";            OSVER1 = 1909; OSVER2 = 1809; COLL = "HP x2 G4 driver pilot3c"; INC = "All HP x2 G4"  }
        @{ ProdCode = '860F'; Model = "HP ZBook 15 G6 Mobile";     OSVER1 = 1909; OSVER2 = 1809; COLL = "HP ZBook 15 G6 driver pilot3c"; INC = "All HP ZBook 15/17 G6 Laptops"  }
        @{ ProdCode = '83EF'; Model = "HP ProDesk 600 G4 DM";      OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G4 driver pilot3c"; INC = "All HP 600 G4 DM Desktops"  }
        @{ ProdCode = '83EC'; Model = "HP ProDesk 600 G4 MT";      OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G4 driver pilot3c"; INC = "All HP 600 G4 MT Desktops"  }
        @{ ProdCode = '83EE'; Model = "HP ProDesk 600 G4 SFF";     OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G4 driver pilot3c"; INC = "All HP 600 G4 SFF Desktops"  }
        @{ ProdCode = '83B3'; Model = "HP EliteBook 830 G5";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 830 G5 driver pilot3c"; INC = "All HP 830 G5 Laptops"  }
        @{ ProdCode = '83B2'; Model = "HP EliteBook 850 G5";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 850 G5 driver pilot3c"; INC = "All HP 850 G5 Laptops" }
        @{ ProdCode = '83D2'; Model = "HP ProBook 640 G4";         OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 640 G4 driver pilot3c"; INC = "All HP 640 G4 Laptops" }
        @{ ProdCode = '8414'; Model = "HP Elite X2 1013 G3";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP x2 1013 G3 driver pilot3c"; INC = "All HP x2 1013 G3"  }
        @{ ProdCode = '842A'; Model = "HP ZBook 15 G5 Mobile";     OSVER1 = 1909; OSVER2 = 1809; COLL = "HP ZBook 15 G5 driver pilot3c"; INC = "All HP ZBook 15/17 G5 Laptops"  }
        @{ ProdCode = '83B2'; Model = "HP ZBook 15U G5 Mobile";    OSVER1 = 1909; OSVER2 = 1809; COLL = "HP ZBook 15u G5 driver pilot3c"; INC = "All HP ZBook 15u/17u G5 Laptops"  }
        @{ ProdCode = '8438'; Model = "HP EliteBook X360 1030 G3"; OSVER1 = 1909; OSVER2 = 1809; COLL = "HP x360 G3 driver pilot3c"; INC = "All HP x360 1030 G3"  }
        @{ ProdCode = '81C5'; Model = "HP Z4 G4";                  OSVER1 = 1909; OSVER2 = 1809; COLL = "HP Z4 G4 driver pilot3c"; INC = "All HP Z4 G4 Desktops"  }
        @{ ProdCode = '829E'; Model = "HP ProDesk 600 G3 DM";      OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G3 DM driver pilot3c"; INC = "All HP 600 G3 DM Desktops"  }
        @{ ProdCode = '829D'; Model = "HP ProDesk 600 G3 MT";      OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G3 driver pilot3c"; INC = "All HP 600 G3 MT Desktops"  }
        @{ ProdCode = '82B4'; Model = "HP ProDesk 600 G3 SFF";     OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G3 driver pilot3c"; INC = "All HP 600 G3 SFF Desktops"  }
        @{ ProdCode = '835B'; Model = "HP EliteDesk 705 G3 SFF";   OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 705 G3 driver pilot3c"; INC = "All HP 705 G3 Desktops"  }
        @{ ProdCode = '8292'; Model = "HP EliteBook 820 G4";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 820 G4 driver pilot3c"; INC = "All HP 820 G4 Laptops" }
        @{ ProdCode = '828C'; Model = "HP EliteBook 840 G4";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 840 G4 driver pilot3c"; INC = "All HP 840 G4 Laptops" }
        @{ ProdCode = '82AA'; Model = "HP ProBook 640 G3";         OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 640 G3 driver pilot3c"; INC = "All HP 640 G3 Laptops" }
        @{ ProdCode = '80FC'; Model = "HP Elite X2 1012 G1";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP x2 1012 G1 driver pilot3c"; INC = "All HP x2 1012 G1"  }
        @{ ProdCode = '807C'; Model = "HP EliteBook 820 G3";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 820 G3 driver pilot3c"; INC = "All HP 820 G3 Laptops"  }
        @{ ProdCode = '8079'; Model = "HP EliteBook 840 G3";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 840 G3 driver pilot3c"; INC = "All HP 840 G3 Laptops"  }
        @{ ProdCode = '80FD'; Model = "HP ProBook 640 G2";         OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 640 G2 driver pilot3c"; INC = "All HP 640 G2 Laptops" }
        @{ ProdCode = '8079'; Model = "HP ZBook 15U G3 Mobile";    OSVER1 = 1909; OSVER2 = 1809; COLL = "HP ZBook 15u G3 driver pilot3c"; INC = "All HP ZBook 15u/17u G3 Laptops"  }
        @{ ProdCode = '80D4'; Model = "HP ZBook Studio G3 Mobile"; OSVER1 = 1909; OSVER2 = 1809; COLL = "HP ZBook Studio G3 driver pilot3c"; INC = "All HP ZBook Studio G3 Laptops" }
##        @{ ProdCode = '1850'; Model = "HP Compaq Pro 6305";        OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 6305 driver pilot3c"; INC = "All HP 6305 MT Desktops"  }
##        @{ ProdCode = '1850'; Model = "HP Compaq Pro 6305 SFF";    OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 6305 driver pilot3c"; INC = "All HP 6305 SFF Desktops"  }
##        @{ ProdCode = '3397'; Model = "HP Compaq Elite 8300 SFF"; OSVER1 = 1809; COLL = " }
##        @{ ProdCode = '18DF'; Model = "HP EliteBook FOLIO 9470M"; OSVER1 = 1809; COLL = " }
##        @{ ProdCode = '1494'; Model = "HP Compaq Elite 8200 CMT"; OSVER1 = 1909; OSVER2 = 1809; COLL = " }
##        @{ ProdCode = '1495'; Model = "HP Compaq Elite 8200 SFF"; OSVER1 = 1909; OSVER2 = 1809; COLL = " }
##        @{ ProdCode = '3646'; Model = "HP Compaq Elite 8000 SFF"; OSVER1 = 1909; OSVER2 = 1809; COLL = " }
##        @{ ProdCode = '3031'; Model = "HP Compaq Elite 7900 SFF"; OSVER1 = 1909; OSVER2 = 1809; COLL = " }
##        @{ ProdCode = '212B'; Model = "HP Z440 Workstation";      OSVER1 = 1909; OSVER2 = 1809; COLL = "HP Z440 driver pilot3c"; INC = "All HP Z440 Desktops"  }
##        @{ ProdCode = '158B'; Model = "HP Z820 Workstation";       OSVER1 = 1809; OSVER2 = 1803; COLL = "HP Z820 driver pilot3c"; INC = "All HP Z820 Desktops"  }  #no devices
        @{ ProdCode = '8169'; Model = "HP ProDesk 600 G2 DM";      OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G2 driver pilot3c"; INC = "All HP 600 G2 DM Desktops"  }
        @{ ProdCode = '805D'; Model = "HP ProDesk 600 G2 MT";      OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G2 driver pilot3c"; INC = "All HP 600 G2 MT Desktops"  }
        @{ ProdCode = '805D'; Model = "HP ProDesk 600 G2 SFF";     OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G2 driver pilot3c"; INC = "All HP 600 G2 SFF Desktops"  }
        @{ ProdCode = '21D0'; Model = "HP ProDesk 600 G1 DM";      OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 600 G1 driver pilot3c"; INC = "All HP 600 G1 DM Desktops"  }
        @{ ProdCode = '18E7'; Model = "HP ProDesk 600 G1 SFF";     OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 600 G1 driver pilot3c"; INC = "All HP 600 G1 SFF Desktops"  }
        @{ ProdCode = '1993'; Model = "HP ProBook 640 G1";         OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 640 G1 driver pilot3c"; INC = "All HP 640 G1 Laptops"  }
        @{ ProdCode = '225A'; Model = "HP EliteBook 820 G2";       OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 820 G2 driver pilot3c"; INC = "All HP 820 G2 Laptops"  }
        @{ ProdCode = '2216'; Model = "HP EliteBook 840 G2";       OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 840 G2 driver pilot3c"; INC = "All HP 840 G2 Laptops"  }
        @{ ProdCode = '2253'; Model = "HP ZBook 15 G2 Mobile";     OSVER1 = 1809; OSVER2 = 1803; COLL = "HP ZBook 15 G2 driver pilot3c"; INC = "All HP ZBook 15 G2 Laptops"  }
        @{ ProdCode = '2255'; Model = "HP ZBook 17 G2 Mobile";     OSVER1 = 1809; OSVER2 = 1803; COLL = "HP ZBook 15 G2 driver pilot3c"; INC = "All HP ZBook 17 G2 Laptops"  }
        @{ ProdCode = '1992'; Model = "HP ProBook 645 G1";         OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 645 G1 driver pilot3c"; INC = "All HP 645 G1 Laptops"  }
        @{ ProdCode = '1991'; Model = "HP EliteBook 820 G1";       OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 820 G1 driver pilot3c"; INC = "All HP 820 G1 Laptops"  }
        @{ ProdCode = '198F'; Model = "HP EliteBook 840 G1";       OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 840 G1 driver pilot3c"; INC = "All HP 840 G1 Laptops"  }
        @{ ProdCode = '1909'; Model = "HP ZBook 15 G1 Mobile";     OSVER1 = 1809; OSVER2 = 1803; COLL = "HP ZBook 15 G1 driver pilot3c"; INC = "All HP ZBook 15/17 G1 Laptops"  }
        @{ ProdCode = '22DA'; Model = "HP EliteBook FOLIO 9480M";  OSVER1 = 1809; OSVER2 = 1803; COLL = "HP Folio 9480M driver pilot3c"; INC = "All HP 9480m Laptops" }
        @{ ProdCode = '2215'; Model = "HP EliteDesk 705 G1";       OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 705 G1 driver pilot3c"; INC = "All HP 705 G1 Desktops"  }
#>
)

#timestamp the output file
"" | out-file c:\temp\deployment_summary.txt -Append
"$(get-date)" | out-file c:\temp\deployment_summary.txt -Append
"" | out-file c:\temp\deployment_summary.txt -Append

foreach ($keyword in $keywords)
{
    $successcount = 0
    $inprogresscount = 0
    $defercount = 0
    $errorcount = 0
    $unknowncount = 0
    $now = get-date -Format 'dd-MM-yyyy HH:mm:ss'
    log -Message "$now" -LogFile $LogFileSCCM
    log -message "Deployment status for keyword $keyword" -LogFile $LogFileSCCM
    write-host  $now
    write-host  "Deployment status for keyword $keyword"
    #loop for models here
    foreach ($Model in $HPModelsTable) 
    {
        #get package
        $PackageFolder = $($Model.Model)
        log -Message "checking on model $PackageFolder" -LogFile $LogFileSCCM

        $PackageName = $Packagefolder + ' HPIA Drivers'
        $getpackage = Get-CMPackage -name $PackageName -fast
        $packageID = $getpackage.PackageID

        #get advertisements
        $ads = get-cmpackagedeployment -PackageId $packageID -ProgramName $PackageProgramNamePush
        #write-host 'CollectionName', 'Assets', 'MessageID', 'MessageDescription'

        foreach ($ad in $ads)
            {
            if ($ad.AdvertisementName -like $keyword)
                {
                $adname = $ad.AdvertisementName
                #log -Message "found advertisement $adName" -LogFile $LogFileSCCM
                $adstatus = get-cmpackagedeploymentstatus -DeploymentId $ad.AdvertisementID -StatusType Any
                foreach ($status in $adstatus)
                    {
                    #write-host $status.CollectionName, $status.Assets, $status.MessageID, $status.MessageDescription
                    if ($status.MessageID -in $successcodes)
                        {$successcount = $successcount + $status.Assets
                        #write-host "success count   "$successcount
                        }
                    if ($status.MessageID -in $inprogresscodes)
                        {$inprogresscount = $inprogresscount + $status.Assets
                        #write-host "in progress count"$inprogresscount
                        }
                    if ($status.MessageID -in $errorcodes)
                        {$errorcount = $errorcount + $status.Assets
                        #write-host "error count     "$errorcount
                        }
                    if ($status.MessageID -in $unknowncodes)
                        {$unknowncount = $unknowncount + $status.Assets
                        #write-host "unknown count     "$unknowncount
                        }
                    if ($status.MessageID -notin $successcodes + $inprogresscodes + $errorcodes + $unknowncodes + "10006")
                        {write-host "*** new status found $status.CollectionName, $status.MessageID, $status.MessageDescription"}

                    if ($status.MessageID -eq "10006") #check App Deployment Toolkit status code
                        {
                        $details = get-cmdeploymentstatusdetails -InputObject $status
                        foreach ($detail in $details)
                            {
                            #write-host $detail.StatusDescription, $detail.devicename
                            if ($detail.StatusDescription -eq "60012")
                                {$defercount += 1}
                            elseif ($detail.StatusDescription -eq "256")
                                {$successcount += 1}
                            else
                                {$errorcount += 1}
                            } #for each detail
                        } #app deployment toolkit codes
                    } #for each status
                } #ad name like keyword
            } #for each ad
        } #for each model
    <#
    write-host "success count     "$successcount
    write-host "in progress count "$inprogresscount
    write-host "defer count       "$defercount
    write-host "error count       "$errorcount
    write-host "unknown count     "$unknowncount
    #>
    write-output "`t $keyword `t $now `t $successcount `t $inprogresscount `t $defercount `t $errorcount `t $unknowncount" | out-file c:\temp\deployment_summary.txt -Append
    
    write-host "excel             "$now `t $successcount `t $inprogresscount `t $defercount `t $errorcount `t $unknowncount
    log -Message "success count     $successcount" -LogFile $LogFileSCCM
    log -Message "in progress count $inprogresscount" -LogFile $LogFileSCCM
    log -Message "defer count       $defercount" -LogFile $LogFileSCCM
    log -Message "error count       $errorcount" -LogFile $LogFileSCCM
    log -Message "unknown count     $unknowncount" -LogFile $LogFileSCCM
}
Remove-PSDrive -Name Z
Set-Location C: