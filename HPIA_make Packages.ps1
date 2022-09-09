<#  Create ConfigMgr packages and programs from HPIA synced drivers
    version 1.0  1-14-2020  John Mercer

Given model table, create SCCM package(s) of downloaded drivers with 3 programs, collections, and advertisements of each.
Package, program, collection, and advertisement parameters set in #common data section
Activity is logged to file at path in $LogFileSCCM
customizations required:
	SITE: for ConfigMgr site code (8 times: lines 44, 48, 49, 87, 88, 89, 198, 295)
	\\server\share for path to server to save downloaded drivers (2 times: line 47, 94)
	Dpserver for name of distribution point server (2 times: lines 256, 257 )


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

#common data
$SourceFolder = '\\server\share\desktop\OSDEPLOYMENT\Drivers\HPDrivers\HPIA_Installed'
$CMPackageFolder = 'SITE:\Package\OS Deployment\Drivers\HP Drivers\HPIA Installed'
$CMCollectionFolder = 'SITE:\DeviceCollection\Software Deployment\HP\driver testing'
$PackageProgramNameImage = 'Imaging - '
$commandlineImage = 'Files\HPImageAssistant.exe /Operation:Analyze /Action:Install /Selection:All /Category:All /Silent /ReportFolder:"C:\Program Files (x86)\HP" /SoftpaqDownloadFolder:"Repository" /BIOSPwdFile:password /debug'
$PackageProgramNamePull  = 'Self Install'
$commandlinePull =  'Files\HPImageAssistant.exe /Operation:Analyze /Action:Install /Selection:All /Category:All /noninteractive /ReportFolder:"C:\Program Files (x86)\HP" /SoftpaqDownloadFolder:"Repository" /BIOSPwdFile:password /debug'
$PackageProgramNamePush  = 'Driver Push'
$commandlinePush =  'Deploy-Application.exe -AllowRebootPassThru'
$PackageManufacturer = 'HP'
$PackageLanguage = 'English'
$PackageDiskSpaceUnit = 'MB'
$PackageDuration = '60'
$PackageRunType = 'Normal'
$PackageRunMode = 'RunWithAdministrativeRights'
$ProgramRunTypeImage = 'WhetherOrNotUserIsLoggedOn'
$ProgramRunTypePull  = 'OnlyWhenUserIsLoggedOn'
$ProgramRunTypePush  = 'WhetherOrNotUserIsLoggedOn'
$MaxProgramNameLength = 50
$PackageUserInteraction = $false
$PackageDriveMode = 'RunWithUnc'
$PackageSupportedOS = Get-CMSupportedPlatform -fast -Name 'All Windows 10 (64-bit) client'
$PackageAfterRunningTypeImage = 'NoActionRequired'
$PackageAfterRunningTypePull  = 'ConfigurationManagerRestartsComputer'
$PackageAfterRunningTypePush  = 'ConfigurationManagerRestartsComputer'
$PackageCategory = 'Drivers'
$PackageSuppressNotification = $true
$PackageEnableTS = $true
$ProgramInteractionImage = $false
$ProgramInteractionPull = $true
$ProgramInteractionPush = $true
$DeployPurposeImage = 'Available'
$DeployPurposePull = 'Available'
$DeployPurposePush = 'Required'
$DeployFastNetworkOption = 'DownloadContentFromDistributionPointAndRunLocally'
$DeploySlowNetworkOption = 'DoNotRunProgram'
$CollectionType = 'Device'
$CollectionLimitingCollectionName = 'All Systems'
$CollectionRefreshType = 'None'
$CollectionBase = 'HPIA '
$CollectionFolder1809 = 'SITE:\DeviceCollection\Software Deployment\HP\HPIA driver deployment\HPIA support 1809'
$CollectionFolder1909 = 'SITE:\DeviceCollection\Software Deployment\HP\HPIA driver deployment\HPIA support 1909'
$CollectionFolder2009 = 'SITE:\DeviceCollection\Software Deployment\HP\HPIA driver deployment\HPIA support 2009'
$CollectionLimitingCollectionName1809 = 'All Windows 10 version 1809'
$CollectionLimitingCollectionName1909 = 'All Windows 10 version 1909'
$CollectionLimitingCollectionName2009 = 'All Windows 10 version 20H2'

New-PSDrive -name Z -PSProvider "FileSystem" -Root "\\server\share\Drivers\HPDrivers" -Persist -Scope Global
$RepositoryPath = "Z:\HPIA_Installed"
$LogFileSCCM = "$RepositoryPath\MakePackage.log"

$HPModelsTable= @( 
#       @{ ProdCode = '83D5'; Model = "HP EliteBook 745 G5";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 745 G5 driver testing"; INC = "All HP 745 G5 Laptops" } #test model only
        @{ ProdCode = '8591'; Model = "HP EliteDesk 880 G5 TWR";   OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 880 G5 driver testing"; INC = "All HP 880 G5 Desktops"}
#       @{ ProdCode = '81C3'; Model = "HP Elite Slice";            OSVER1 = 2009; OSVER2 = 1809; COLL = "HP Slice driver testing"; INC = "All HP Elite Slice" }
 #      @{ ProdCode = '870D'; Model = "HP Elite x2 G8";            OSVER1 = '2009'; OSVER2 = 1809; COLL = "HP x2 G8 driver testing"; INC = "All HP x2 G8" }
<#        @{ ProdCode = '8720'; Model = "HP EliteBook x360 1030 G8"; OSVER1 = 2009; OSVER2 = 1809; COLL = "HP x360 G8 driver testing"; INC = "All HP x360 G8 Laptops" }
        @{ ProdCode = '85B9'; Model = "HP Elite x2 G4";            OSVER1 = 2009; OSVER2 = 1809; COLL = "HP x2 G4 driver testing"; INC = "All HP x2 G4" }
        @{ ProdCode = '880D'; Model = "HP EliteBook 840 G8";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 840 G8 driver testing"; INC = "All HP 840 G8 Laptops"}
        @{ ProdCode = '8846'; Model = "HP EliteBook 850 G8";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 850 G8 driver testing"; INC = "All HP 850 G8 Laptops" }
        @{ ProdCode = '8736'; Model = "HP ZBook Studio G7 Mobile"; OSVER1 = 2009; OSVER2 = 1809; COLL = "HP ZBook Studio G7 driver testing"; INC = "All HP ZBook Studio G7 Laptops" }
        @{ ProdCode = '8783'; Model = "HP ZBook Fury 15 G7"  ;     OSVER1 = 2009; OSVER2 = 1809; COLL = "HP ZBook Fury 15 G7 driver testing"; INC = "All HP ZBook Fury 15/17 G7 Laptops" }
        @{ ProdCode = '8715'; Model = "HP ProDesk 600 G6 DM";      OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G6 driver testing"; INC = "All HP 600 G6 DM Desktops" }
        @{ ProdCode = '8712'; Model = "HP ProDesk 600 G6 MT";      OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G6 driver testing"; INC = "All HP 600 G6 MT Desktops" }
        @{ ProdCode = '8714'; Model = "HP ProDesk 600 G6 SFF";     OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G6 driver testing"; INC = "All HP 600 G6 SFF Desktops" }
        @{ ProdCode = '869D'; Model = "HP ProBook 440 G7"  ;       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 440 G7 driver testing"; INC = "All HP 440 G7 Laptops" }
        @{ ProdCode = '8723'; Model = "HP EliteBook 840 G7"  ;     OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 830 G7 driver testing"; INC = "All HP 840 G7 Laptops" }
        @{ ProdCode = '8724'; Model = "HP EliteBook 850 G7"  ;     OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 850 G7 driver testing"; INC = "All HP 850 G7 Laptops" }
        @{ ProdCode = '81C5'; Model = "HP Z4 G4";                  OSVER1 = 2009; OSVER2 = 1809; COLL = "HP Z4 G4 driver testing"; INC = "All HP Z4 G4 Desktops"  }
        @{ ProdCode = '8589'; Model = "HP EliteBook 735 G6";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 735 G6 driver testing"; INC = "All HP 735 G6 Laptops" } # no devices
        @{ ProdCode = '8584'; Model = "HP EliteBook 745 G6";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 745 G6 driver testing"; INC = "All HP 745 G6 Laptops" }
        @{ ProdCode = '8619'; Model = "HP EliteDesk 705 G5 DM";    OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 705 G5 driver testing"; INC = "All HP 705 G5 Desktops"  }
        @{ ProdCode = '8598'; Model = "HP ProDesk 600 G5 DM";      OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G5 DM driver testing"; INC = "All HP 600 G5 DM Desktops"  }
        @{ ProdCode = '8596'; Model = "HP ProDesk 600 G5 MT";      OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G5 MT driver testing"; INC = "All HP 600 G5 MT Desktops"  }
        @{ ProdCode = '8597'; Model = "HP ProDesk 600 G5 SFF";     OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G5 SFF driver testing"; INC = "All HP 600 G5 SFF Desktops"  }
        @{ ProdCode = '854A'; Model = "HP EliteBook 830 G6";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 830 G6 driver testing"; INC = "All HP 830 G6 Laptops"  }
        @{ ProdCode = '8549'; Model = "HP EliteBook 840 G6";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 840 G6 driver testing"; INC = "All HP 840 G6 Laptops"  }
        @{ ProdCode = '8549'; Model = "HP EliteBook 850 G6";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 8x0 G6 driver testing"; INC = "All HP 850 G6 Laptops"  }
        @{ ProdCode = '856D'; Model = "HP ProBook 640 G5"  ;       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 640 G5 driver testing"; INC = "All HP 640 G5 Laptops"  }
        @{ ProdCode = '860F'; Model = "HP ZBook 15 G6 Mobile";     OSVER1 = 2009; OSVER2 = 1809; COLL = "HP ZBook 15 G6 driver testing"; INC = "All HP ZBook 15/17 G6 Laptops"  }
        @{ ProdCode = '83EF'; Model = "HP ProDesk 600 G4 DM";      OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G4 driver testing"; INC = "All HP 600 G4 DM Desktops"  }
        @{ ProdCode = '83EC'; Model = "HP ProDesk 600 G4 MT";      OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G4 driver testing"; INC = "All HP 600 G4 MT Desktops"  }
        @{ ProdCode = '83EE'; Model = "HP ProDesk 600 G4 SFF";     OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G4 driver testing"; INC = "All HP 600 G4 SFF Desktops"  }
        @{ ProdCode = '83B3'; Model = "HP EliteBook 830 G5";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 8x0 G5 driver testing"; INC = "All HP 830 G5 Laptops"  }
        @{ ProdCode = '83B2'; Model = "HP EliteBook 850 G5";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 850 G5 driver testing"; INC = "All HP 850 G5 Laptops" }
        @{ ProdCode = '83D2'; Model = "HP ProBook 640 G4";         OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 640 G4 driver testing"; INC = "All HP 640 G4 Laptops" }
        @{ ProdCode = '8414'; Model = "HP Elite X2 1013 G3";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP x2 1013 G3 driver testing"; INC = "All HP x2 1013 G3"  }
        @{ ProdCode = '842A'; Model = "HP ZBook 15 G5 Mobile";     OSVER1 = 2009; OSVER2 = 1809; COLL = "HP ZBook 15 G5 driver testing"; INC = "All HP ZBook 15/17 G5 Laptops"  }
        @{ ProdCode = '83B2'; Model = "HP ZBook 15U G5 Mobile";    OSVER1 = 2009; OSVER2 = 1809; COLL = "HP ZBook 15u G5 driver testing"; INC = "All HP ZBook 15u/17u G5 Laptops"  }
        @{ ProdCode = '8438'; Model = "HP EliteBook X360 1030 G3"; OSVER1 = 2009; OSVER2 = 1809; COLL = "HP x360 G3 driver testing"; INC = "All HP x360 1030 G3"  }
        @{ ProdCode = '829E'; Model = "HP ProDesk 600 G3 DM";      OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G3 DM driver testing"; INC = "All HP 600 G3 DM Desktops"  }
        @{ ProdCode = '829D'; Model = "HP ProDesk 600 G3 MT";      OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G3 driver testing"; INC = "All HP 600 G3 MT Desktops"  }
        @{ ProdCode = '82B4'; Model = "HP ProDesk 600 G3 SFF";     OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G3 driver testing"; INC = "All HP 600 G3 SFF Desktops"  }
        @{ ProdCode = '835B'; Model = "HP EliteDesk 705 G3 SFF";   OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 705 G3 driver testing"; INC = "All HP 705 G3 Desktops"  }
        @{ ProdCode = '8292'; Model = "HP EliteBook 820 G4";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 820 G4 driver testing"; INC = "All HP 820 G4 Laptops" }
        @{ ProdCode = '828C'; Model = "HP EliteBook 840 G4";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 840 G4 driver testing"; INC = "All HP 840 G4 Laptops" }
        @{ ProdCode = '82AA'; Model = "HP ProBook 640 G3";         OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 640 G3 driver testing"; INC = "All HP 640 G3 Laptops" }
        @{ ProdCode = '80FC'; Model = "HP Elite X2 1012 G1";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP x2 1012 G1 driver testing"; INC = "All HP x2 1012 G1"  }
        @{ ProdCode = '807C'; Model = "HP EliteBook 820 G3";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 8x0 G3 driver testing"; INC = "All HP 820 G3 Laptops"  }
        @{ ProdCode = '8079'; Model = "HP EliteBook 840 G3";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 840 G3 driver testing"; INC = "All HP 840 G3 Laptops"  }
        @{ ProdCode = '80FD'; Model = "HP ProBook 640 G2";         OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 640 G2 driver testing"; INC = "All HP 640 G2 Laptops" }
        @{ ProdCode = '8079'; Model = "HP ZBook 15U G3 Mobile";    OSVER1 = 2009; OSVER2 = 1809; COLL = "HP ZBook 15u G3 driver testing"; INC = "All HP ZBook 15u/17u G3 Laptops"  }
        @{ ProdCode = '80D4'; Model = "HP ZBook Studio G3 Mobile"; OSVER1 = 2009; OSVER2 = 1809; COLL = "HP ZBook Studio G3 driver testing"; INC = "All HP ZBook Studio G3 Laptops" }
        @{ ProdCode = '8169'; Model = "HP ProDesk 600 G2 DM";      OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G2 driver testing"; INC = "All HP 600 G2 DM Desktops"  }
        @{ ProdCode = '805D'; Model = "HP ProDesk 600 G2 MT";      OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G2 driver testing"; INC = "All HP 600 G2 MT Desktops"  }
        @{ ProdCode = '805D'; Model = "HP ProDesk 600 G2 SFF";     OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 600 G2 driver testing"; INC = "All HP 600 G2 SFF Desktops"  }
        @{ ProdCode = '2253'; Model = "HP ZBook 15 G2 Mobile";     OSVER1 = 1809; OSVER2 = 1803; COLL = "HP ZBook 15 G2 driver testing"; INC = "All HP ZBook 15 G2 Laptops"  }
        @{ ProdCode = '2255'; Model = "HP ZBook 17 G2 Mobile";     OSVER1 = 1809; OSVER2 = 1803; COLL = "HP ZBook 15 G2 driver testing"; INC = "All HP ZBook 17 G2 Laptops"  }
##        @{ ProdCode = '3397'; Model = "HP Compaq Elite 8300 SFF"; OSVER1 = 1809; COLL = " }
##        @{ ProdCode = '18DF'; Model = "HP EliteBook FOLIO 9470M"; OSVER1 = 1809; COLL = " }
##        @{ ProdCode = '1494'; Model = "HP Compaq Elite 8200 CMT"; OSVER1 = 1909; OSVER2 = 1809; COLL = " }
##        @{ ProdCode = '1495'; Model = "HP Compaq Elite 8200 SFF"; OSVER1 = 1909; OSVER2 = 1809; COLL = " }
##        @{ ProdCode = '3646'; Model = "HP Compaq Elite 8000 SFF"; OSVER1 = 1909; OSVER2 = 1809; COLL = " }
##        @{ ProdCode = '3031'; Model = "HP Compaq Elite 7900 SFF"; OSVER1 = 1909; OSVER2 = 1809; COLL = " }
##        @{ ProdCode = '212B'; Model = "HP Z440 Workstation";      OSVER1 = 1909; OSVER2 = 1809; COLL = "HP Z440 driver testing"; INC = "All HP Z440 Desktops"  }
        @{ ProdCode = '158B'; Model = "HP Z820 Workstation";       OSVER1 = 1809; OSVER2 = 1803; COLL = "HP Z820 driver testing"; INC = "All HP Z820 Desktops"  }  #no devices
        @{ ProdCode = '21D0'; Model = "HP ProDesk 600 G1 DM";      OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 600 G1 driver testing"; INC = "All HP 600 G1 DM Desktops"  }
        @{ ProdCode = '18E7'; Model = "HP ProDesk 600 G1 SFF";     OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 600 G1 driver testing"; INC = "All HP 600 G1 SFF Desktops"  }
        @{ ProdCode = '1993'; Model = "HP ProBook 640 G1";         OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 640 G1 driver testing"; INC = "All HP 640 G1 Laptops"  }
        @{ ProdCode = '225A'; Model = "HP EliteBook 820 G2";       OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 820 G2 driver testing"; INC = "All HP 820 G2 Laptops"  }
        @{ ProdCode = '2216'; Model = "HP EliteBook 840 G2";       OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 840 G2 driver testing"; INC = "All HP 840 G2 Laptops"  }
##        @{ ProdCode = '1850'; Model = "HP Compaq Pro 6305";        OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 6305 driver testing"; INC = "All HP 6305 MT Desktops"  }
##        @{ ProdCode = '1850'; Model = "HP Compaq Pro 6305 SFF";    OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 6305 driver testing"; INC = "All HP 6305 SFF Desktops"  }
        @{ ProdCode = '1992'; Model = "HP ProBook 645 G1";         OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 645 G1 driver testing"; INC = "All HP 645 G1 Laptops"  }
        @{ ProdCode = '1991'; Model = "HP EliteBook 820 G1";       OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 820 G1 driver testing"; INC = "All HP 820 G1 Laptops"  }
        @{ ProdCode = '198F'; Model = "HP EliteBook 840 G1";       OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 840 G1 driver testing"; INC = "All HP 840 G1 Laptops"  }
        @{ ProdCode = '1909'; Model = "HP ZBook 15 G1 Mobile";     OSVER1 = 1809; OSVER2 = 1803; COLL = "HP ZBook 15 G1 driver testing"; INC = "All HP ZBook 15/17 G1 Laptops"  }
        @{ ProdCode = '22DA'; Model = "HP EliteBook FOLIO 9480M";  OSVER1 = 1809; OSVER2 = 1803; COLL = "HP Folio 9480M driver testing"; INC = "All HP 9480m Laptops" }
        @{ ProdCode = '2215'; Model = "HP EliteDesk 705 G1";       OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 705 G1 driver testing"; INC = "All HP 705 G1 Desktops"  }
#>
)

Log -Message "----------------------------------------------------------------------------" -LogFile $LogFileSCCM

#loop for models here
foreach ($Model in $HPModelsTable) 
{

    #item data
    #$Packagefolder = 'HP EliteBook 840 G2'  #read from table
    #$Packagefolder = 'HP ELITEBOOK X360 1030 G3'  #read from table
    $PackageFolder = $($Model.Model)
    Log -Message "Processing for model $Packagefolder" -LogFile $LogFileSCCM
    $PackageName = $Packagefolder + ' HPIA Drivers'
    Set-Location C:
    #$PackageVersion = '1/8/2020'  #read this from activity log?
    $PackageVersion = ((Get-ChildItem $SourceFolder\$Packagefolder\Files\repository\.repository\activity.log).LastWriteTime).ToShortDateString()
    Log -Message "     Detected date:  $PackageVersion" -LogFile $LogFileSCCM
    #$PackageDiskSpaceRequirement = '1480' #read this from Repository folder?
    $PackageDiskSpaceRequirement = [math]::Round((Get-ChildItem $SourceFolder\$Packagefolder\Files\repository | Measure-Object -Property length -s).sum/1mb)
    Log -Message "     Detected size:  $PackageDiskSpaceRequirement MB" -LogFile $LogFileSCCM
    Set-Location SITE:
    $PackageProgramNameImage  = 'Imaging - ' + $PackageName
    if ($PackageProgramNameImage.Length -ge $MaxProgramNameLength){$PackageProgramNameImage=$PackageProgramNameImage.Substring(0,$MaxProgramNameLength)}
    #$TestCollectionName = 'HP 8x0 G7 SSM driver testing'  #read from table
    $TestCollectionName = $($Model.COLL)
    Log -Message "     Given collection name:   $TestCollectionName" -LogFile $LogFileSCCM


    $getpackage = Get-CMPackage -name $PackageName -fast
    if ($getpackage -eq $null)
        {#package does not exist
        Log -Message "Package does not exist." -LogFile $LogFileSCCM

        #create package
        $Newpackage = New-CMPackage -Name $PackageName -Manufacturer $PackageManufacturer -Version $PackageVersion -Language $PackageLanguage -Path $SourceFolder\$Packagefolder
        $PackageID = $newpackage.PackageID
        Log -Message "Package created:  $PackageName" -LogFile $LogFileSCCM
        #move package
        Move-CMObject -FolderPath $CMPackageFolder -ObjectId $packageID
        Log -Message "Package moved to $CMPackageFolder" -LogFile $LogFileSCCM

        #create Image Program
        $NewProgram = New-CMProgram -PackageId $PackageID -StandardProgramName $PackageProgramNameImage -CommandLine $commandlineImage `
        -RunType $PackageRunType -DiskSpaceRequirement $PackageDiskSpaceRequirement -DiskSpaceUnit $PackageDiskSpaceUnit -Duration $PackageDuration `
        -AddSupportedOperatingSystemPlatform $PackageSupportedOS -ProgramRunType $ProgramRunTypeImage -RunMode $PackageRunMode -DriveMode $PackageDriveMode `
        -UserInteraction $ProgramInteractionImage
        Log -Message "Program created:  $PackageProgramNameImage" -LogFile $LogFileSCCM

        #set additional program parameters
        $updateProgram = Set-CMProgram -PackageId $PackageID -ProgramName $PackageProgramNameImage -StandardProgram -AfterRunningType $PackageAfterRunningTypeImage `
        -Category $PackageCategory -SuppressProgramNotification $PackageSuppressNotification -EnableTaskSequence $PackageEnableTS 
        Log -Message "Additional program parameters set for $PackageProgramNameImage." -LogFile $LogFileSCCM

        #create pull program
        $NewProgram = New-CMProgram -PackageId $PackageID -StandardProgramName $PackageProgramNamePull -CommandLine $commandlinePull `
        -RunType $PackageRunType -DiskSpaceRequirement $PackageDiskSpaceRequirement -DiskSpaceUnit $PackageDiskSpaceUnit -Duration $PackageDuration `
        -AddSupportedOperatingSystemPlatform $PackageSupportedOS -ProgramRunType $ProgramRunTypePull -RunMode $PackageRunMode -DriveMode $PackageDriveMode `
        -UserInteraction $ProgramInteractionPull
        Log -Message "Program created:  $PackageProgramNamePull" -LogFile $LogFileSCCM

        #set additional program parameters
        $updateProgram = Set-CMProgram -PackageId $PackageID -ProgramName $PackageProgramNamePull -StandardProgram -AfterRunningType $PackageAfterRunningTypePull `
        -Category $PackageCategory -SuppressProgramNotification $PackageSuppressNotification 
        Log -Message "Additional program parameters set for $PackageProgramNamePull." -LogFile $LogFileSCCM

        #create push program
        $NewProgram = New-CMProgram -PackageId $PackageID -StandardProgramName $PackageProgramNamePush -CommandLine $commandlinePush `
        -RunType $PackageRunType -DiskSpaceRequirement $PackageDiskSpaceRequirement -DiskSpaceUnit $PackageDiskSpaceUnit -Duration $PackageDuration `
        -AddSupportedOperatingSystemPlatform $PackageSupportedOS -ProgramRunType $ProgramRunTypePush -RunMode $PackageRunMode -DriveMode $PackageDriveMode `
        -UserInteraction $ProgramInteractionPush
        Log -Message "Program created:  $PackageProgramNamePush" -LogFile $LogFileSCCM

        #set additional program parameters
        $updateProgram = Set-CMProgram -PackageId $PackageID -ProgramName $PackageProgramNamePush -StandardProgram -AfterRunningType $PackageAfterRunningTypePush `
        -Category $PackageCategory -SuppressProgramNotification $PackageSuppressNotification 
        Log -Message "Additional program parameters set for $PackageProgramNamePush." -LogFile $LogFileSCCM

        #Replicate
        Start-CMContentDistribution -PackageId $PackageID -DistributionPointName 'DPserver'
        Start-CMContentDistribution -PackageId $PackageID -DistributionPointName 'DPserver'
        Log -Message "Replication started." -LogFile $LogFileSCCM

        #create test collection (if needed)
        $CollectionID = $null
        $CollectionID = (Get-CMCollection -Name $TestCollectionName).CollectionID
        if ($CollectionID -ne $null)
            {#collection found
            Log -Message "     Detected collection ID:  $CollectionID" -LogFile $LogFileSCCM
            }
        else
            {#collection not found, make one
            Log -Message "Collection not found, creating one." -LogFile $LogFileSCCM
            $newCollection = New-CMCollection -CollectionType $CollectionType -Name $TestCollectionName -LimitingCollectionName $CollectionLimitingCollectionName -RefreshType $CollectionRefreshType
            Log -Message "Collection $TestCollectionName created." -LogFile $LogFileSCCM
            Log -Message "*** You will need to populate collection rules and evaluation cycle. ***" -LogFile $LogFileSCCM -Type 2
            $CollectionID = $newCollection.CollectionID
            Move-CMObject -FolderPath $CMCollectionFolder -ObjectId $CollectionID
            Log -Message "Collection moved to $CMCollectionFolder" -LogFile $LogFileSCCM
            }

        #deploy to test collection
        $newDeploy = New-CMPackageDeployment -StandardProgram -PackageId $PackageID -ProgramName $PackageProgramNamePull -DeployPurpose $DeployPurposeImage -CollectionId $CollectionID `
        -AvailableDateTime (Get-Date) -FastNetworkOption $DeployFastNetworkOption -SlowNetworkOption $DeploySlowNetworkOption
        Log -Message "Deployment created to collection $TestCollectionName" -LogFile $LogFileSCCM

        #create push/pull collection (if needed)
        Log -Message "Creating push/pull collection." -LogFile $LogFileSCCM
        $CollectionNamePushPull = $CollectionBase + $PackageFolder
        $CollectionID = $null
        $CollectionID = (Get-CMCollection -Name $CollectionNamePushPull).CollectionID
        if ($CollectionID -ne $null)
            {#collection found
            Log -Message "     Detected collection ID:  $CollectionID" -LogFile $LogFileSCCM
            }
        else
            {#collection not found, make one
            $CollectionLimitingPushPull = 'All HPIA support ' + $Model.OSVER1
            $CollectionPathPushPull = 'SITE:\DeviceCollection\Software Deployment\HP\HPIA driver deployment\HPIA support ' + $Model.OSVER1
            $newCollection = New-CMCollection -CollectionType $CollectionType -Name $CollectionNamePushPull -LimitingCollectionName $CollectionLimitingpushpull -RefreshType $CollectionRefreshType
            $CollectionID = $newCollection.CollectionID
            $include = $($Model.INC)
            log -Message "Collection created.  ID = $CollectionID" -LogFile $LogFileSCCM
            Move-CMObject -FolderPath $CollectionPathPushPull -ObjectId $CollectionID
            Log -Message "Collection moved to $CollectionPathPushPull" -LogFile $LogFileSCCM
            Add-CMDeviceCollectionIncludeMembershipRule -CollectionId $CollectionID -IncludeCollectionName $include
            log -Message "Added inclusion rule for collection $include." -LogFile $LogFileSCCM
            }

        # deployment PULL to push/pull collection
        $newDeploy = New-CMPackageDeployment -StandardProgram -PackageId $PackageID -ProgramName $PackageProgramNamePull -DeployPurpose $DeployPurposePull -CollectionId $CollectionID `
        -AvailableDateTime (Get-Date) -FastNetworkOption $DeployFastNetworkOption -SlowNetworkOption $DeploySlowNetworkOption
        Log -Message "Pull deployment created to collection $CollectionBase $PackageFolder" -LogFile $LogFileSCCM
        
        # deployment PUSH to push/pull collection
<#        $newDeploy = New-CMPackageDeployment -StandardProgram -PackageId $PackageID -ProgramName $PackageProgramNamePush -DeployPurpose $DeployPurposePush -CollectionId $CollectionID `
        -AvailableDateTime (Get-Date) -FastNetworkOption $DeployFastNetworkOption -SlowNetworkOption $DeploySlowNetworkOption
        Log -Message "Push deployment created to collection $CollectionBase $PackageFolder" -LogFile $LogFileSCCM
#>

        }
    Else
        {#package already exists, just update content
        $packageID = $getpackage.PackageID
        Log -Message "Package for model $Packagefolder already exists with PackageID:  $packageID" -LogFile $LogFileSCCM
        Log -Message " Updating version to $PackageVersion" -LogFile $LogFileSCCM
        set-CMPackage -Id $packageID -Version $PackageVersion
        Log -Message "Starting replication for Model $Packagefolder." -LogFile $LogFileSCCM
		Update-CMDistributionPoint -PackageId $packageID
        }

    Log -Message "Model $Packagefolder complete." -LogFile $LogFileSCCM

} # end loop
Log -Message "----------------------------------------------------------------------------" -LogFile $LogFileSCCM
Remove-PSDrive -Name Z
Set-Location C: