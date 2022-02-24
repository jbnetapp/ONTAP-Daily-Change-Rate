#############################################################################################
# SnapDelta list PowerShell script  v0.6.1
# Jerome.Blanchet@NetApp.com
#
Param (
	[int32]$Debug = 0 ,
	[switch]$Help,
	[string]$Vserver,
	[string]$Name,
	[string]$login,
	[string]$password,
	[string[]]$Volume,
	[string]$Aggregate,
	[switch]$HTTP,
	[switch]$ShowSelectVolList,
	[switch]$UseLastSnapshot,
	[string]$IgnoreSnapShotOlderThanInDays,
	[switch]$Verbose,
	[Int32]$NaErrorAction = 0,
	[Int32]$NcErrorAction = 0
)

#############################################################################################
filter Skip-Null { $_|?{ $_ -ne $null } }
$RELEASE="0.2"
$global:CDOT = $True

#############################################################################################
Function set_debug_level ($debug_level) {
switch ( $debug_level ) {
        '0'     {
                $global:DebugPreference = "SilentlyContinue"
		$global:NaErrorAction = 0 
		$global:NcErrorAction = 0 
                }
        '1'     {
                Write-Host "Set Debug to Continue"
                $global:DebugPreference = "Continue"
		$global:NaErrorAction = 1 
		$global:NcErrorAction = 1 
                }
        '2'     {
                Write-Host "Set Debug to Inquire"
                $global:DebugPreference = "Inquire"
		$global:NaErrorAction = 1 
		$global:NcErrorAction = 1 
                }
        'show'  {
                Write-Host "DebugPreference: [${global:DebugPreference}]"
                }

        default {
                Write-Host "Set Debug to Default"
                $global:DebugPreference = "SilentlyContinue"
                }
        }
}

#############################################################################################
Function clean_exit ([int]$code) {
	exit $code 
}
#############################################################################################
Function Write-Help ([int]$code) {
	Write-Host "NAME"
	Write-Host "`tGet-DailyChangeRate`n"
	Write-Host "SYNOPSIS"
	Write-Host "`tCalculate the Daily Change Rate of a selected list of volume in  % of volume used and in  KB"
	Write-Host "`tfrom Clustered ONTAP or 7mode Controllers using Snapshot SnapDelta. Each volume need to have"
	Write-Host "`ta minimum of  one  Daily Snapshot.  Volume without snapshot  will be ignored. You can select"
	Write-Host "`tvolume list by Names, and/or Aggregate and/or Vserver for  Clusterd  ONTAP."
	Write-Host "`tWihout option Get-DailyChangeRate will select all volumes with snapshots`n"
	Write-Host "SYNTAX"
	Write-Host "`tGet-DailyChangeRate -Arguments [-help] [-debug <level>] [options]`n"
	Write-Host "`tArguments`n"
	Write-Host "`t-Name <name>"
	Write-Host "`t`tName of the clustered ONTAP or Name of a 7mode controller.`n"
	Write-Host "`t-HTTP"
	Write-Host "`t`tUse HTTP instead of HTTPS to establish a connection to clustered ONTAP or 7mode Controller.`n"
	Write-Host "`t-login <login>"
	Write-Host "`t`t`n"
	Write-Host "`t-Password <Password>"
	Write-Host "`t`t`n"
	Write-Host "`t-Aggregate <Aggr-Name>"
	Write-Host "`t`tSelect volumes belong to the Aggregate <Aggr-Name>.`n"
	Write-Host "`t-Vserver <SVM-Name>"
	Write-Host "`t`tSelect volumes belong to the Vserver <SVM-Name>.`n"
	Write-Host "`t-Volume <vol1,vol2,...>"
	Write-Host "`t`tSelect volumes list. Wildcards are permitted: vol1,volB*,volC*.`n"
	Write-Host "`t-ShowSelectVolList"
	Write-Host "`t`tShow the selected volume list used to calculate the Daily change rate.`n"
	Write-Host "`t-UseLastSnapshot"
	Write-Host "`t`tBy default the script used the older snapshot to calculate the daily change rate. With this "
	Write-Host "`t`toption you can select the last snapshot instead.`n"
	Write-Host "`t-IgnoreSnapShotOlderThanInDays <Number_of_days>"
	Write-Host "`t`tExclude volumes with snapshot older than <Number_of_days>`n"
	Write-Host "`t-Verbose"
	Write-Host "`t`tDisplay more verbose information.`n"
	Write-Host "`t-Debug <Level>"
	Write-Host "`t`tSet the debug level 0 1 or 2.`n"
	clean_exit $code
}

#############################################################################################
Function Connect-NetApp (
	        [string]$myName,
	        [System.Management.Automation.PSCredential]$myCred) {
Try {
	$global:CDOT = $True
	if ( $HTTP ) { $NC=Connect-NcController $Name -Credential $cred -HTTP  -ErrorAction $NaErrorAction -ErrorVariable NaErrorVar }
	else 	     { $NC=Connect-NcController $Name -Credential $cred -HTTPS -ErrorAction $NaErrorAction -ErrorVariable NaErrorVar }
	if ( $? -ne $True ) {
		$global:CDOT = $False
		if ( $HTTP )  { $NA=Connect-NaController $Name -Credential $cred -HTTP -ErrorAction $NaErrorAction -ErrorVariable NaErrorVar }
		else          { $NA=Connect-NaController $Name -Credential $cred -HTTPS -ErrorAction $NaErrorAction -ErrorVariable NaErrorVar }
		if ( $? -ne $True ) { throw "ERROR: Connect failed [$NaErrorVar]" }
	}
	return $NA
}  catch  {
	$ErrorMessage = $_.Exception.Message
	clean_exit $code
}
}
#############################################################################################
Function Connect-NetApp (
	        [string]$myName,
	        [System.Management.Automation.PSCredential]$myCred) {
Try {
	$global:CDOT = $True
	if ( $HTTP ) { $NC=Connect-NcController $Name -Credential $cred -HTTP  -ErrorAction $NaErrorAction -ErrorVariable NaErrorVar }
	else 	     { $NC=Connect-NcController $Name -Credential $cred -HTTPS -ErrorAction $NaErrorAction -ErrorVariable NaErrorVar }
	if ( $? -ne $True ) {
		$global:CDOT = $False
		if ( $HTTP )  { $NA=Connect-NaController $Name -Credential $cred -HTTP -ErrorAction $NaErrorAction -ErrorVariable NaErrorVar }
		else          { $NA=Connect-NaController $Name -Credential $cred -HTTPS -ErrorAction $NaErrorAction -ErrorVariable NaErrorVar }
		if ( $? -ne $True ) { throw "ERROR: Connect failed [$NaErrorVar]" }
	}
	return $NA
}  catch  {
	$ErrorMessage = $_.Exception.Message
	$FailedItem = $_.Exception.ItemName
	$Type = $_.Exception.GetType().FullName
	$CategoryInfo = $_.CategoryInfo
	$ErrorDetails = $_.ErrorDetails
	$Exception = $_.Exception
	$FullyQualifiedErrorId = $_.FullyQualifiedErrorId
	$InvocationInfo = $_.InvocationInfo
	$PipelineIterationInfo = $_.PipelineIterationInfo
	$ScriptStackTrace = $_.ScriptStackTrace
	$TargetObject = $_.TargetObject
	Write-Error  "Trap Error: [$ErrorMessage]"
	Write-Debug  "Trap Item: [$FailedItem]"
	Write-Debug  "Trap Type: [$Type]"
	Write-Debug  "Trap CategoryInfo: [$CategoryInfo]"
	Write-Debug  "Trap ErrorDetails: [$ErrorDetails]"
	Write-Debug  "Trap Exception: [$Exception]"
	Write-Debug  "Trap FullyQualifiedErrorId: [$FullyQualifiedErrorId]"
	Write-Debug  "Trap InvocationInfo: [$InvocationInfo]"
	Write-Debug  "Trap PipelineIterationInfo: [$PipelineIterationInfo]"
	Write-Debug  "Trap ScriptStackTrace: [$ScriptStackTrace]"
	Write-Debug  "Trap TargetObject: [$TargetObject]"
	return $false
}
}
#############################################################################################
# MAIN
#############################################################################################

if ( $IgnoreSnapShotOlderThanInDays -eq "" ) {
	$DateCur = Get-Date
	$DateUnix = Get-Date -Date "01/01/1970"
	$IgnoreSnapShotOlderThanInDays = (New-TimeSpan -Start $DateUnix -End $DateCur).TotalDays
}

if ( $Help ) { Write-Help }

if ( $Debug -gt 0 )    { set_debug_level 0 }
set_debug_level $Debug

if ( $Name -eq "" ) {  
	$Name = Read-host "Controller Name" 
} 
if ( $login -eq "" ) {  
	$login = Read-host "login" 
} 
if ( $password -eq "" ) { 
	$cpassword = Read-host "password" -AsSecureString 
} else {
	$cpassword = ConvertTo-SecureString $password -AsPlainText -Force
}
#############################################################################################

$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $login,$cpassword
if ( ( $NetApp=Connect-NetApp -myName $Name -MyCred $cred ) -eq $false ) {
	Write-Host "ERROR: Connection to $Name failed"
	clean_exit 1
}

Write-Debug "CDOT check [$CDOT]"


if ( $global:CDOT -eq $True ) {
	$Template = Get-NcVol -Template
	if ( $Aggregate -ne "" ) {
		Write-Debug "Template Aggregate [$Aggregate]"
		$Template.Aggregate = $Aggregate
	}

	if ( $Vserver -ne "" ) {
		Write-Debug "Template Vserver [$Vserver]"
		$Template.Vserver = $Vserver
	}
	if ( $volume.Length -ne 0 ) {
		Write-Debug "Template Volume [$Vserver]"
		$Template.Name=[system.String]::Join(",", $volume)
	}	
	if ( $ShowSelectVolList ) {
		Get-NcVol  -Query $Template
		clean_exit 1
	}
	$VolList = Get-NcVol  -Query $Template
	if ( $? -ne $True ) {
		Write-Error "Get-NaVol failed"
		clean_exit 1
	}

} else {
	# Get Volume List 
	Write-Debug "Get-NaVol [$Volume] [$Aggregate]"
	if ( $Aggregate -ne "" ) {
		if ( $ShowSelectVolList ) {
			Get-NaVol $Volume -Aggregate $Aggregate
			clean_exit 1
		}
		$VolList = Get-NaVol $Volume -Aggregate $Aggregate
	} else {
		if ( $ShowSelectVolList ) {
			Get-NaVol $Volume
			clean_exit 1
		}
		$VolList = Get-NaVol $Volume
	}
	if ( $? -ne $True ) {
		Write-Error "Get-NaVol failed"
		clean_exit 1
	}

}

$VolListCount=$VolList.Count
$TotalUsedKB = 0
$TotalRateKBH= 0
$TotalRateKBD= 0
$VolCount=0
if ( $Verbose ) { Write-Host "Verbose" } else { write-host -NoNewline "Please wait " }
foreach ( $Vol in ( $VolList | Skip-Null ) ) {
	if ( $Vol.State -eq "online" ) {
		if ( $global:CDOT -eq $True ) {
			if ( $Vol.VolumeStateAttributes.IsNodeRoot -eq $True ) {
				if ($Verbose) { Write-Host "Volume: $Vol SnapShot:[$SelectedSnap] is Node Root Volume ignore it" }
				$SelectedSnapList = $null
			} else {
				if ( ( $Vol.VolumeIdAttributes.StyleExtended -eq "flexgroup" ) -or ( $Vol.VolumeIdAttributes.StyleExtended -eq "flexgroup_constituent" ) ) {
					Write-Warning "Warning: $Vol is a Flexgroup or Flexgroup constituent and it is not Supported by Snap Delta. Ignore volume $Vol"
					$SelectedSnapList = $null
				} else {
					$SelectedSnapList=Get-NcSnapshot $Vol -vserver $Vol.vserver 
				}
			}
		} else { 
			$SelectedSnapList=Get-NaSnapshot $Vol 
		}

		if ( $UseLastSnapshot ) { $SelectedSnap = $SelectedSnapList | Sort-Object AccessTimeDT | Select-Object -Last 1 }
		else { $SelectedSnap = $SelectedSnapList | Sort-Object AccessTimeDT -Descending | Where-Object {$_.AccessTimeDT -gt (Get-Date).AddDays(-$IgnoreSnapshotOlderThanInDays)} | Select-Object -Last 1  }
		
		if ( $SelectedSnap -ne $null ) {
			$SelectedSnapDate=$SelectedSnap.Created
			if ( $Verbose ) { Write-Host -NoNewline "Volume: $Vol SnapShot:[$SelectedSnap] " } else { write-host -NoNewline "." }
			if ( $global:CDOT -eq $True ) { $SnapDelta=Get-NcSnapshotDelta -Volume $Vol -SnapName1 $SelectedSnap -VserverContext $Vol.vserver }
			else { $SnapDelta=Get-NaSnapshotDelta -Volume $Vol -SnapName1 $SelectedSnap }
			$VolRateKBH=[math]::Round(($SnapDelta.ConsumedSize/1024)/$SnapDelta.ElapsedTimeTS.TotalHours,2)
			$VolRateKBD=[math]::Round(($SnapDelta.ConsumedSize/1024)/$SnapDelta.ElapsedTimeTS.TotalDays,2)
			if ( $global:CDOT -eq $True ) { $VolUsedKB=[math]::Round($Vol.VolumeSpaceAttributes.SizeUsed/1024,2) }
			else { $VolUsedKB=[math]::Round($Vol.SizeUsed/1024,2) }
			$VolHourlyChangePCT=[math]::Round($VolRateKBH/$VolUsedKB*100,2)
			$VolDailyChangePCT=[math]::Round($VolRateKBD/$VolUsedKB*100,2)
			$TotalUsedKB+=$VolUsedKB
			$TotalRateKBH+=$VolRateKBH
			$TotalRateKBD+=$VolRateKBD
			$VolCount++
			if ( $Verbose ) { Write-Host "Daily Change Rate:[$VolDailyChangePCT%] [${VolRateKBD}KB] TOTAL[${TotalRateKBD}KB]" }
			Write-Debug "Vol  Name  = [$Vol]"
			Write-Debug "VolUsedKB  = [$VolUsedKB]"
			Write-Debug "Snap Name  = [$SelectedSnap]"
			Write-Debug "Snap Date  = [$SelectedSnapDate]"
			Write-Debug "VolRateKBH = [$VolRateKBH]"
			Write-Debug "VolRateKBD = [$VolRateKBD]"
			Write-Debug "VolHourlyChangePCT       = [$VolHourlyChangePCT%]"
			Write-Debug "VolDailyChangePCT        = [$VolDailyChangePCT%]" 
			Write-Debug "IgnoreSnapShotOlderThan  = [$IgnoreSnapshotOlderThanInDays]"
			#
			Write-Debug "TotalUsedKB  = [$TotalUsedKB]"
			Write-Debug "TotalRateKBH = [$TotalRateKBH]"
			Write-Debug "TotalRateKBD = [$TotalRateKBD]"
		}
	}
}

if ( $TotalUsedKB -eq 0 ) {
	Write-host "No SnapShot found"
	clean_exit 1
}

$TotalHourlyChangePCT=[math]::Round($TotalRateKBH/$TotalUsedKB*100,4)
$TotalDailyChangePCT=[math]::Round($TotalRateKBD/$TotalUsedKB*100,4)

Write-host
Write-Host "TOTAL number of selected volumes with SnapShot is [$VolCount/$VolListCount]"
Write-Host "TOTAL Daily Change Rate Pourcent: [$TotalDailyChangePCT%] Daily change Rate Size: [${TotalRateKBD}KB]"
Write-Debug "TotalHourlyChangePCT  = [$TotalHourlyChangePCT%]"
Write-Debug "TotalDailyChangePCT  = [$TotalDailyChangePCT%]"
