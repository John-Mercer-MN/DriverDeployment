<# Make new model collections
given a new model name, create the appropriate collections for detection and HPIA deployment
1.  All HP <model> under either All PCs\All Laptops or All PCs\All Desktops (or All PCs\All Tablets)
2.  Query rules for new collection using both full and short names for model
activity is logged in file at path in $LogFileSCCM
customizations required:
    SITE: for ConfigMgr site code (3 times: lines 44, 61, & 62)
    \\server\share for path to server to save downloaded drivers (1 time: line 45)



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
New-PSDrive -name Z -PSProvider "FileSystem" -Root "\\server\share\Drivers\HPDrivers" -Persist -Scope Global
$RepositoryPath = "Z:\HPIA_Installed"
$LogFileSCCM = "$RepositoryPath\MakeCollections.log"

###################################################################
#update next 4 lines per model
$newmodelfullname = 'HP EliteDesk 880 G5 TWR'
$newmodelshortname = '880 G5'
$newmodelChassistype = 'Desktop' # Laptop | Desktop | Tablet
$TestingCollectionName = 'HP 880 G5 driver testing'
###################################################################

$typeplural = $newmodelChassistype+'s'
$CollectionType = 'Device'
$CollectionRefreshType = 'Periodic'
$CollectionLimitingCollectionName = 'All PCs'
$CollectionFolder = 'SITE:\DeviceCollection\All PCs'
$TestingCollectionFolder = 'SITE:\DeviceCollection\Software Deployment\HP\driver testing'
$now = get-date
$daily = New-CMSchedule -DurationInterval Days -DurationCount 0 -RecurInterval Days -RecurCount 1 -Start $now

Log -Message "Processing model $newmodelfullname" -LogFile $LogFileSCCM
Log -Message "Collection for all systems of model $newmodelshortname" -LogFile $LogFileSCCM

$querystring = 'select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COMPUTER_SYSTEM on SMS_G_System_COMPUTER_SYSTEM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COMPUTER_SYSTEM.Model '
$querystring1 = $querystring + 'like "%' + $newmodelshortname + '%"'
$querystring2 = $querystring + '= "' + $newmodelfullname + '"'

$CollectionFolder = $CollectionFolder +'\All ' + $typeplural
$NewCollectionName = 'All HP '+ $newmodelshortname + ' ' + $typeplural

$CollectionID = $null
$CollectionID = (Get-CMCollection -Name $NewCollectionName).CollectionID
if ($CollectionID -ne $null)
    {#collection found
    Log -Message "     Detected collection ID:  $CollectionID" -LogFile $LogFileSCCM
    }
else
    {#collection not found, make one
    Log -Message "Collection not found, creating one." -LogFile $LogFileSCCM
    $newCollection = New-CMCollection -CollectionType $CollectionType -Name $NewCollectionName `
     -LimitingCollectionName $CollectionLimitingCollectionName -RefreshType $CollectionRefreshType -RefreshSchedule $daily
    $CollectionID = $newCollection.CollectionID
    Log -Message "Collection $TestCollectionName created.  ID = $CollectionID" -LogFile $LogFileSCCM
    Move-CMObject -FolderPath $CollectionFolder -ObjectId $CollectionID
    Log -Message "Collection moved to $CollectionFolder" -LogFile $LogFileSCCM
    Add-CMDeviceCollectionQueryMembershipRule -CollectionId $CollectionID -RuleName $newmodelshortname -QueryExpression $querystring1
    log -Message "Query rule $newmodelshortname added." -LogFile $LogFileSCCM
    Add-CMDeviceCollectionQueryMembershipRule -CollectionId $CollectionID -RuleName $newmodelfullname -QueryExpression $querystring2
    log -Message "Query rule $newmodelfullname added." -LogFile $LogFileSCCM
    }
	
if ($TestingCollectionName -ne '')
{
    Log -Message "Collection for testing systems of model $newmodelshortname" -LogFile $LogFileSCCM
    $querystring3 = $querystring1 + ' and SMS_R_System.NetbiosName like "TECLAB%"'

    $CollectionID = $null
    $CollectionID = (Get-CMCollection -Name $TestingCollectionName).CollectionID
    if ($CollectionID -ne $null)
        {#collection found
        Log -Message "     Detected collection ID:  $CollectionID" -LogFile $LogFileSCCM
        $ruleObj = $null
            $ruleObj = Get-CMCollectionQueryMembershipRule -CollectionId $collectionID -RuleName $newmodelshortname
            if ($ruleObj -ne $null)
                {#rule exists using short name
                Log -Message "     Detected rule named:  $newmodelshortname" -LogFile $LogFileSCCM
                }
            else
                {#rule does not exist, make one
                Add-CMDeviceCollectionQueryMembershipRule -CollectionId $CollectionID -RuleName $newmodelshortname -QueryExpression $querystring3
                log -Message "Query rule $newmodelshortname added." -LogFile $LogFileSCCM
                }
        }
    else
        {#collection not found, make one
        Log -Message "Collection not found, creating one." -LogFile $LogFileSCCM
        $newCollection = New-CMCollection -CollectionType $CollectionType -Name $TestingCollectionName `
         -LimitingCollectionName $CollectionLimitingCollectionName -RefreshType $CollectionRefreshType -RefreshSchedule $daily
        $CollectionID = $newCollection.CollectionID
        Log -Message "Collection $TestCollectionName created.  ID = $CollectionID" -LogFile $LogFileSCCM
        Move-CMObject -FolderPath $TestingCollectionFolder -ObjectId $CollectionID
        Log -Message "Collection moved to $TestingCollectionFolder" -LogFile $LogFileSCCM
        Add-CMDeviceCollectionQueryMembershipRule -CollectionId $CollectionID -RuleName $newmodelshortname -QueryExpression $querystring3
        log -Message "Query rule $newmodelshortname added." -LogFile $LogFileSCCM
        }
}

Log -Message "----------------------------------------------------------------------------" -LogFile $LogFileSCCM
Remove-PSDrive -Name Z
