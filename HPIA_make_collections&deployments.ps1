<# John Mercer
Make collections for HPIA deployment
for each selected model based on a parent/limiting collection
create mandatory deployment of correct package for model
with four deployment times
assumes package and "Driver Push" program already created

Given model table and pre-defined grouping collections, create SCCM deployment collections and advertisements to push drivers
Activity is logged to file at path in $LogFileSCCM
customizations required:
	SITE: for ConfigMgr site code (3 times: lines 47, 51, 52)
	\\server\share for path to server to save downloaded drivers (2 times: lines 50, 72)
	For each deployment run, modify lines 62-68 as appropriate
	
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
$CMCollectionFolder = 'SITE:\DeviceCollection\Software Deployment\HP\driver pushes'
$PackageProgramNamePush  = 'Driver Push'
$DeployPurposePush = 'Required'
$DeployFastNetworkOption = 'DownloadContentFromDistributionPointAndRunLocally'
$DeploySlowNetworkOption = 'DoNotRunProgram'
$DeployBehaviorPush = 'RerunIfFailedPreviousAttempt'
$CollectionType = 'Device'
$CollectionRefreshType = 'None'
$CollectionBase = 'HPIA '
# make sure to edit all the following lines as appropriate
$CollectionLimitingCollectionName = 'HPIA push 14'
$CollectionDescriptor = 'push20'
$DeploymentTime1 = '10/05/2021 2:00:00 PM' #mm/dd/yyyy
$DeploymentTime2 = '' # or '' to default to 24 hours after previous time
$DeploymentTime3 = '' # or '' to default to 24 hours after previous time
$DeploymentTime4 = '' # or '' to default to 24 hours after previous time
$DeploymentTime5 = '' # or '' to default to 24 hours after previous time


#connect to package source
New-PSDrive -name Z -PSProvider "FileSystem" -Root "\\server\share\Drivers\HPDrivers" -Persist -Scope Global
$RepositoryPath = "Z:\HPIA_Installed"
$LogFileSCCM = "$RepositoryPath\deployPackage.log"

$HPModelsTable= @( 
#        @{ ProdCode = '83D5'; Model = "HP EliteBook 745 G5";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 745 G5 driver $CollectionDescriptor"; INC = "All HP 745 G5 Laptops" } #test model only
        @{ ProdCode = '8720'; Model = "HP EliteBook x360 1030 G8"; OSVER1 = 2009; OSVER2 = 1809; COLL = "HP x360 G8 driver $CollectionDescriptor"; INC = "All HP x360 G8 Laptops" }
        @{ ProdCode = '85B9'; Model = "HP Elite x2 G4";            OSVER1 = 2009; OSVER2 = 1809; COLL = "HP x2 G4 driver $CollectionDescriptor"; INC = "All HP x2 G4" }
        @{ ProdCode = '880D'; Model = "HP EliteBook 840 G8";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 840 G8 driver $CollectionDescriptor"; INC = "All HP 840 G8 Laptops"}
        @{ ProdCode = '8846'; Model = "HP EliteBook 850 G8";       OSVER1 = 2009; OSVER2 = 1809; COLL = "HP 850 G8 driver $CollectionDescriptor"; INC = "All HP 850 G8 Laptops" }
        @{ ProdCode = '8736'; Model = "HP ZBook Studio G7 Mobile"; OSVER1 = 2009; OSVER2 = 1809; COLL = "HP ZBook Studio G7 driver $CollectionDescriptor"; INC = "All HP ZBook Studio G7 Laptops" }
        @{ ProdCode = '8783'; Model = "HP ZBook Fury 15 G7"  ;     OSVER1 = 1909; OSVER2 = 1809; COLL = "HP ZBook Fury 15 G7 driver $CollectionDescriptor"; INC = "All HP ZBook Fury 15/17 G7 Laptops" }
        @{ ProdCode = '8715'; Model = "HP ProDesk 600 G6 DM";      OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G6 DM driver $CollectionDescriptor"; INC = "All HP 600 G6 DM Desktops" }
        @{ ProdCode = '8712'; Model = "HP ProDesk 600 G6 MT";      OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G6 MT driver $CollectionDescriptor"; INC = "All HP 600 G6 MT Desktops" }
        @{ ProdCode = '8714'; Model = "HP ProDesk 600 G6 SFF";     OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G6 SFF driver $CollectionDescriptor"; INC = "All HP 600 G6 SFF Desktops" }
        @{ ProdCode = '869D'; Model = "HP ProBook 440 G7"  ;       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 440 G7 driver $CollectionDescriptor"; INC = "All HP 440 G7 Laptops" }
        @{ ProdCode = '8723'; Model = "HP EliteBook 840 G7"  ;     OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 840 G7 driver $CollectionDescriptor"; INC = "All HP 840 G7 Laptops" }
        @{ ProdCode = '8724'; Model = "HP EliteBook 850 G7"  ;     OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 850 G7 driver $CollectionDescriptor"; INC = "All HP 850 G7 Laptops" }
#        @{ ProdCode = '8589'; Model = "HP EliteBook 735 G6";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 735 G6 driver $CollectionDescriptor"; INC = "All HP 735 G6 Laptops" } # no devices
        @{ ProdCode = '8619'; Model = "HP EliteDesk 705 G5 DM";    OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 705 G5 driver $CollectionDescriptor"; INC = "All HP 705 G5 Desktops"  }
        @{ ProdCode = '8584'; Model = "HP EliteBook 745 G6";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 745 G6 driver $CollectionDescriptor"; INC = "All HP 745 G6 Laptops" }
        @{ ProdCode = '8598'; Model = "HP ProDesk 600 G5 DM";      OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G5 DM driver $CollectionDescriptor"; INC = "All HP 600 G5 DM Desktops"  }
        @{ ProdCode = '8596'; Model = "HP ProDesk 600 G5 MT";      OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G5 MT driver $CollectionDescriptor"; INC = "All HP 600 G5 MT Desktops"  }
        @{ ProdCode = '8597'; Model = "HP ProDesk 600 G5 SFF";     OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G5 SFF driver $CollectionDescriptor"; INC = "All HP 600 G5 SFF Desktops"  }
        @{ ProdCode = '854A'; Model = "HP EliteBook 830 G6";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 830 G6 driver $CollectionDescriptor"; INC = "All HP 830 G6 Laptops"  }
        @{ ProdCode = '8549'; Model = "HP EliteBook 840 G6";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 840 G6 driver $CollectionDescriptor"; INC = "All HP 840 G6 Laptops"  }
        @{ ProdCode = '8549'; Model = "HP EliteBook 850 G6";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 850 G6 driver $CollectionDescriptor"; INC = "All HP 850 G6 Laptops"  }
        @{ ProdCode = '856D'; Model = "HP ProBook 640 G5"  ;       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 640 G5 driver $CollectionDescriptor"; INC = "All HP 640 G5 Laptops"  }
        @{ ProdCode = '85B9'; Model = "HP Elite x2 G4";            OSVER1 = 1909; OSVER2 = 1809; COLL = "HP x2 G4 driver $CollectionDescriptor"; INC = "All HP x2 G4"  }
        @{ ProdCode = '860F'; Model = "HP ZBook 15 G6 Mobile";     OSVER1 = 1909; OSVER2 = 1809; COLL = "HP ZBook 15 G6 driver $CollectionDescriptor"; INC = "All HP ZBook 15/17 G6 Laptops"  }
        @{ ProdCode = '83EF'; Model = "HP ProDesk 600 G4 DM";      OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G4 DM driver $CollectionDescriptor"; INC = "All HP 600 G4 DM Desktops"  }
        @{ ProdCode = '83EC'; Model = "HP ProDesk 600 G4 MT";      OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G4 MT driver $CollectionDescriptor"; INC = "All HP 600 G4 MT Desktops"  }
        @{ ProdCode = '83EE'; Model = "HP ProDesk 600 G4 SFF";     OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G4 SFF driver $CollectionDescriptor"; INC = "All HP 600 G4 SFF Desktops"  }
        @{ ProdCode = '83B3'; Model = "HP EliteBook 830 G5";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 830 G5 driver $CollectionDescriptor"; INC = "All HP 830 G5 Laptops"  }
        @{ ProdCode = '83B2'; Model = "HP EliteBook 850 G5";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 850 G5 driver $CollectionDescriptor"; INC = "All HP 850 G5 Laptops" }
        @{ ProdCode = '83D2'; Model = "HP ProBook 640 G4";         OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 640 G4 driver $CollectionDescriptor"; INC = "All HP 640 G4 Laptops" }
        @{ ProdCode = '8414'; Model = "HP Elite X2 1013 G3";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP x2 1013 G3 driver $CollectionDescriptor"; INC = "All HP x2 1013 G3"  }
        @{ ProdCode = '842A'; Model = "HP ZBook 15 G5 Mobile";     OSVER1 = 1909; OSVER2 = 1809; COLL = "HP ZBook 15 G5 driver $CollectionDescriptor"; INC = "All HP ZBook 15/17 G5 Laptops"  }
        @{ ProdCode = '83B2'; Model = "HP ZBook 15U G5 Mobile";    OSVER1 = 1909; OSVER2 = 1809; COLL = "HP ZBook 15u G5 driver $CollectionDescriptor"; INC = "All HP ZBook 15u/17u G5 Laptops"  }
        @{ ProdCode = '8438'; Model = "HP EliteBook X360 1030 G3"; OSVER1 = 1909; OSVER2 = 1809; COLL = "HP x360 G3 driver $CollectionDescriptor"; INC = "All HP x360 1030 G3"  }
        @{ ProdCode = '81C5'; Model = "HP Z4 G4";                  OSVER1 = 1909; OSVER2 = 1809; COLL = "HP Z4 G4 driver $CollectionDescriptor"; INC = "All HP Z4 G4 Desktops"  }
        @{ ProdCode = '829E'; Model = "HP ProDesk 600 G3 DM";      OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G3 DM driver $CollectionDescriptor"; INC = "All HP 600 G3 DM Desktops"  }
#>        @{ ProdCode = '829D'; Model = "HP ProDesk 600 G3 MT";      OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G3 MT driver $CollectionDescriptor"; INC = "All HP 600 G3 MT Desktops"  }
        @{ ProdCode = '82B4'; Model = "HP ProDesk 600 G3 SFF";     OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G3 SFF driver $CollectionDescriptor"; INC = "All HP 600 G3 SFF Desktops"  }
        @{ ProdCode = '835B'; Model = "HP EliteDesk 705 G3 SFF";   OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 705 G3 driver $CollectionDescriptor"; INC = "All HP 705 G3 Desktops"  }
        @{ ProdCode = '8292'; Model = "HP EliteBook 820 G4";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 820 G4 driver $CollectionDescriptor"; INC = "All HP 820 G4 Laptops" }
        @{ ProdCode = '828C'; Model = "HP EliteBook 840 G4";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 840 G4 driver $CollectionDescriptor"; INC = "All HP 840 G4 Laptops" }
        @{ ProdCode = '82AA'; Model = "HP ProBook 640 G3";         OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 640 G3 driver $CollectionDescriptor"; INC = "All HP 640 G3 Laptops" }
        @{ ProdCode = '80FC'; Model = "HP Elite X2 1012 G1";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP x2 1012 G1 driver $CollectionDescriptor"; INC = "All HP x2 1012 G1"  }
        @{ ProdCode = '807C'; Model = "HP EliteBook 820 G3";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 820 G3 driver $CollectionDescriptor"; INC = "All HP 820 G3 Laptops"  }
        @{ ProdCode = '8079'; Model = "HP EliteBook 840 G3";       OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 840 G3 driver $CollectionDescriptor"; INC = "All HP 840 G3 Laptops"  }
        @{ ProdCode = '80FD'; Model = "HP ProBook 640 G2";         OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 640 G2 driver $CollectionDescriptor"; INC = "All HP 640 G2 Laptops" }
        @{ ProdCode = '8079'; Model = "HP ZBook 15U G3 Mobile";    OSVER1 = 1909; OSVER2 = 1809; COLL = "HP ZBook 15u G3 driver $CollectionDescriptor"; INC = "All HP ZBook 15u/17u G3 Laptops"  }
        @{ ProdCode = '80D4'; Model = "HP ZBook Studio G3 Mobile"; OSVER1 = 1909; OSVER2 = 1809; COLL = "HP ZBook Studio G3 driver $CollectionDescriptor"; INC = "All HP ZBook Studio G3 Laptops" }
##        @{ ProdCode = '1850'; Model = "HP Compaq Pro 6305";        OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 6305 driver $CollectionDescriptor"; INC = "All HP 6305 MT Desktops"  }
##        @{ ProdCode = '1850'; Model = "HP Compaq Pro 6305 SFF";    OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 6305 driver $CollectionDescriptor"; INC = "All HP 6305 SFF Desktops"  }
##        @{ ProdCode = '3397'; Model = "HP Compaq Elite 8300 SFF"; OSVER1 = 1809; COLL = " }
##        @{ ProdCode = '18DF'; Model = "HP EliteBook FOLIO 9470M"; OSVER1 = 1809; COLL = " }
##        @{ ProdCode = '1494'; Model = "HP Compaq Elite 8200 CMT"; OSVER1 = 1909; OSVER2 = 1809; COLL = " }
##        @{ ProdCode = '1495'; Model = "HP Compaq Elite 8200 SFF"; OSVER1 = 1909; OSVER2 = 1809; COLL = " }
##        @{ ProdCode = '3646'; Model = "HP Compaq Elite 8000 SFF"; OSVER1 = 1909; OSVER2 = 1809; COLL = " }
##        @{ ProdCode = '3031'; Model = "HP Compaq Elite 7900 SFF"; OSVER1 = 1909; OSVER2 = 1809; COLL = " }
##        @{ ProdCode = '212B'; Model = "HP Z440 Workstation";      OSVER1 = 1909; OSVER2 = 1809; COLL = "HP Z440 driver $CollectionDescriptor"; INC = "All HP Z440 Desktops"  }
##        @{ ProdCode = '158B'; Model = "HP Z820 Workstation";       OSVER1 = 1809; OSVER2 = 1803; COLL = "HP Z820 driver $CollectionDescriptor"; INC = "All HP Z820 Desktops"  }  #no devices
        @{ ProdCode = '8169'; Model = "HP ProDesk 600 G2 DM";      OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G2 DM driver $CollectionDescriptor"; INC = "All HP 600 G2 DM Desktops"  }
        @{ ProdCode = '805D'; Model = "HP ProDesk 600 G2 MT";      OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G2 MT driver $CollectionDescriptor"; INC = "All HP 600 G2 MT Desktops"  }
        @{ ProdCode = '805D'; Model = "HP ProDesk 600 G2 SFF";     OSVER1 = 1909; OSVER2 = 1809; COLL = "HP 600 G2 SFF driver $CollectionDescriptor"; INC = "All HP 600 G2 SFF Desktops"  }
        @{ ProdCode = '21D0'; Model = "HP ProDesk 600 G1 DM";      OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 600 G1 DM driver $CollectionDescriptor"; INC = "All HP 600 G1 DM Desktops"  }
        @{ ProdCode = '18E7'; Model = "HP ProDesk 600 G1 SFF";     OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 600 G1 SFF driver $CollectionDescriptor"; INC = "All HP 600 G1 SFF Desktops"  }
        @{ ProdCode = '1993'; Model = "HP ProBook 640 G1";         OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 640 G1 driver $CollectionDescriptor"; INC = "All HP 640 G1 Laptops"  }
        @{ ProdCode = '225A'; Model = "HP EliteBook 820 G2";       OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 820 G2 driver $CollectionDescriptor"; INC = "All HP 820 G2 Laptops"  }
        @{ ProdCode = '2216'; Model = "HP EliteBook 840 G2";       OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 840 G2 driver $CollectionDescriptor"; INC = "All HP 840 G2 Laptops"  }
        @{ ProdCode = '2253'; Model = "HP ZBook 15 G2 Mobile";     OSVER1 = 1809; OSVER2 = 1803; COLL = "HP ZBook 15 G2 driver $CollectionDescriptor"; INC = "All HP ZBook 15 G2 Laptops"  }
        @{ ProdCode = '2255'; Model = "HP ZBook 17 G2 Mobile";     OSVER1 = 1809; OSVER2 = 1803; COLL = "HP ZBook 15 G2 driver $CollectionDescriptor"; INC = "All HP ZBook 17 G2 Laptops"  }
        @{ ProdCode = '1992'; Model = "HP ProBook 645 G1";         OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 645 G1 driver $CollectionDescriptor"; INC = "All HP 645 G1 Laptops"  }
        @{ ProdCode = '1991'; Model = "HP EliteBook 820 G1";       OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 820 G1 driver $CollectionDescriptor"; INC = "All HP 820 G1 Laptops"  }
        @{ ProdCode = '198F'; Model = "HP EliteBook 840 G1";       OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 840 G1 driver $CollectionDescriptor"; INC = "All HP 840 G1 Laptops"  }
        @{ ProdCode = '1909'; Model = "HP ZBook 15 G1 Mobile";     OSVER1 = 1809; OSVER2 = 1803; COLL = "HP ZBook 15 G1 driver $CollectionDescriptor"; INC = "All HP ZBook 15/17 G1 Laptops"  }
        @{ ProdCode = '22DA'; Model = "HP EliteBook FOLIO 9480M";  OSVER1 = 1809; OSVER2 = 1803; COLL = "HP Folio 9480M driver $CollectionDescriptor"; INC = "All HP 9480m Laptops" }
        @{ ProdCode = '2215'; Model = "HP EliteDesk 705 G1";       OSVER1 = 1809; OSVER2 = 1803; COLL = "HP 705 G1 driver $CollectionDescriptor"; INC = "All HP 705 G1 Desktops"  }
#>
)
#loop for models here
foreach ($Model in $HPModelsTable) 
{
    #get package
    $PackageFolder = $($Model.Model)
    Log -Message "Processing for model $Packagefolder" -LogFile $LogFileSCCM
    # variable name is $TestCollection, but it is the deployment collection
    $TestCollectionName = $($Model.COLL)
    Log -Message "     Given collection name:   $TestCollectionName" -LogFile $LogFileSCCM
    $TestCollectionInclude = $($Model.INC)
    Log -Message "     Include collection name:   $TestCollectionInclude" -LogFile $LogFileSCCM


    $PackageName = $Packagefolder + ' HPIA Drivers'
    $getpackage = Get-CMPackage -name $PackageName -fast
    if ($getpackage -eq $null)
        {#package does not exist
        Log -Message "Package does not exist." -LogFile $LogFileSCCM
        }
    Else
        {#package exists
        $packageID = $getpackage.PackageID
        Log -Message "Package for model $Packagefolder exists with PackageID:  $packageID." -LogFile $LogFileSCCM
        
        #create test collection (if needed)
        $CollectionID = (Get-CMCollection -Name $TestCollectionName).CollectionID
        if ($CollectionID -ne $null)
            {#collection found
            Log -Message "     Detected collection ID:  $CollectionID." -LogFile $LogFileSCCM
            }
        else
            {#collection not found, make one
            Log -Message "Collection not found, creating one." -LogFile $LogFileSCCM
            $newCollection = New-CMCollection -CollectionType $CollectionType -Name $TestCollectionName -LimitingCollectionName $CollectionLimitingCollectionName -RefreshType $CollectionRefreshType
            Log -Message "Collection $TestCollectionName created." -LogFile $LogFileSCCM
#            Log -Message "*** You will need to populate collection rules and evaluation cycle. ***" -LogFile $LogFileSCCM -Type 2
            $CollectionID = $newCollection.CollectionID
            Move-CMObject -FolderPath $CMCollectionFolder -ObjectId $CollectionID
            Log -Message "Collection moved to $CMCollectionFolder." -LogFile $LogFileSCCM
            }

        #check for existing include collection rule
        $includeds = (Get-CMDeviceCollectionIncludeMembershipRule -CollectionId $CollectionID)
        $includedfound = $false
        foreach ($included in $includeds)
        {
            Log -Message "Found inclusion rule for $included ." -LogFile $LogFileSCCM
            if ($included.rulename -eq $TestCollectionInclude)
            {
                Log -Message "Already has rule to include collection $TestCollectionInclude." -LogFile $LogFileSCCM
                $includedfound = $true
            } #test inclusion rule names
        } #loop for existing included rules
        if (!$includedfound)
        {
            #Make include rule using $TestCollectionInclude
            Add-CMDeviceCollectionIncludeMembershipRule -CollectionId $CollectionID -IncludeCollectionName $TestCollectionInclude
            Log -Message "Added rule to include collection $TestCollectionInclude." -LogFile $LogFileSCCM
        } #inclusion rule not found
            
        #trigger collection membership update
        Invoke-CMCollectionUpdate -CollectionId $CollectionID
        Log -Message "Updated collection $TestCollectionName." -LogFile $LogFileSCCM

        #add 5 deployment times
        [datetime]$time1 = $DeploymentTime1
        if ($DeploymentTime2 -eq '')
            {[datetime]$time2 = $time1.addhours(24)}
        else
            {[datetime]$time2 = $DeploymentTime2}
        if ($DeploymentTime3 -eq '')
            {[datetime]$time3 = $time2.addhours(24)}
        else
            {[datetime]$time3 = $DeploymentTime3}
        if ($DeploymentTime4 -eq '')
            {[datetime]$time4 = $time3.addhours(24)}
        else
            {[datetime]$time4 = $DeploymentTime4}
        if ($DeploymentTime5 -eq '')
            {[datetime]$time5 = $time4.addhours(24)}
        else
            {[datetime]$time5 = $DeploymentTime5}

        $DeploySchedule1 = New-CMSchedule -start $time1 -Nonrecurring
        $DeploySchedule2 = New-CMSchedule -start $time2 -Nonrecurring
        $DeploySchedule3 = New-CMSchedule -start $time3 -Nonrecurring
        $DeploySchedule4 = New-CMSchedule -start $time4 -Nonrecurring
        $DeploySchedule5 = New-CMSchedule -start $time5 -Nonrecurring
        $deployschedule = @()
        $deployschedule += $DeploySchedule1
        $deployschedule += $DeploySchedule2
        $deployschedule += $DeploySchedule3
        $deployschedule += $DeploySchedule4
        $deployschedule += $DeploySchedule5

        
        #make push advertisement
        $newDeploy = New-CMPackageDeployment -StandardProgram -PackageId $PackageID -ProgramName $PackageProgramNamePush -DeployPurpose $DeployPurposePush -CollectionId $CollectionID `
        -AvailableDateTime (Get-Date) -FastNetworkOption $DeployFastNetworkOption -SlowNetworkOption $DeploySlowNetworkOption -RerunBehavior $DeployBehaviorPush `
        -Schedule $DeploySchedule -RunFromSoftwareCenter $true

        Log -Message "Push deployment created to collection $CollectionBase $PackageFolder." -LogFile $LogFileSCCM
        
        } #package exist
    Log -Message "Model $Packagefolder complete." -LogFile $LogFileSCCM

} # end loop for model

Log -Message "----------------------------------------------------------------------------" -LogFile $LogFileSCCM
Remove-PSDrive -Name Z
Set-Location C:
