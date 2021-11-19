This simple PowerShell Script allow you to calculate the daily change rate

To install the script verify Powershell version is upper than 3.0
```
PS C:\Users\blanchet> $PSVersionTable.PSVersion 
Major  Minor  Build  Revision
-----  -----  -----  --------
5      1      19041  610
```

Installer PowerShell Tool Kit de NetApp :  https://mysupport.netapp.com/site/tools/tool-eula/powershell-toolkit

check PowerShell Tool Kit version 
```
PS C:\Users\blanchet> Get-NaToolkitVersion
Major  Minor  Build  Revision
-----  -----  -----  --------
4      5      0      0
```

Verify if execution Policy is Unrestrected
```
PS C:\Users\blanchet> Get-ExecutionPolicy
Unrestricted
```

Clone the Project
```
git clone 
```

Script help
```
PS C:\Users\blanchet\home\git\odcr> .\Get-DailyChangeRate.ps1 -Help
NAME
        Get-DailyChangeRate

SYNOPSIS
        Calculate the Daily Change Rate of a selected list of volume in  % of volume used and in  KB
        from Clustered ONTAP or 7mode Controllers using Snapshot SnapDelta. Each volume need to have
        a minimum of  one  Daily Snapshot.  Volume without snapshot  will be ignored. You can select
        volume list by Names, and/or Aggregate and/or Vserver for  Clusterd  ONTAP.
        Wihout option Get-DailyChangeRate will select all volumes with snapshots

SYNTAX
        Get-DailyChangeRate -Arguments [-help] [-debug <level>] [options]

        Arguments

        -Name <name>
                Name of the clustered ONTAP or Name of a 7mode controller.

        -HTTP
                Use HTTP instead of HTTPS to establish a connection to clustered ONTAP or 7mode Controller.

        -login <login>


        -Password <Password>


        -Aggregate <Aggr-Name>
                Select volumes belong to the Aggregate <Aggr-Name>.

        -Vserver <SVM-Name>
                Select volumes belong to the Vserver <SVM-Name>.

        -Volume <vol1,vol2,...>
                Select volumes list. Wildcards are permitted: vol1,volB*,volC*.

        -ShowSelectVolList
                Show the selected volume list used to calculate the Daily change rate.

        -UseLastSnapshot
                By default the script used the older snapshot to calculate the daily change rate. With this
                option you can select the last snapshot instead.

        -IgnoreSnapShotOlderThanInDays <Number_of_days>
                Exclude volumes with snapshot older than <Number_of_days>

        -Verbose
                Display more verbose information.

        -Debug <Level>
                Set the debug level 0 1 or 2.
```

Without option the script caclulate the daily change rate of all cluster volumes based on snap delta
```
PS C:\Users\blanchet\home\git\odcr> Get-DailyChangeRate.ps1 -name MCCA -login admin
password: *********
Please wait ............................................
TOTAL number of selected volumes with SnapShot is [44/106]
TOTAL Daily Change Rate Pourcent: [0.0567%] Daily change Rate Size: [939770.63KB]
```

with option -aggr the script caclulate the daily change rate of all volume in the selected Aggregate
```
PS C:\Users\blanchet\home\git\odcr> .\Get-DailyChangeRate.ps1 -name MCCA -login admin -Aggregate dataA1
password: *********
Please wait .....................
TOTAL number of selected volumes with SnapShot is [21/34]
TOTAL Daily Change Rate Pourcent: [0.0702%] Daily change Rate Size: [877702.99KB]
```

With option -vserver the script caclulate the daily change rate of all vserver volumes based on snap delta
```
PS C:\Users\blanchet\home\git\odcr> .\Get-DailyChangeRate.ps1 -name MCCA -login admin -Vserver SAN_SVM_MC
password: *********
Please wait ............
TOTAL number of selected volumes with SnapShot is [12/24]
TOTAL Daily Change Rate Pourcent: [0.1735%] Daily change Rate Size: [356766.93KB]
```

with option -volume the script calculate the daily change rate of a single volume 
```
PS C:\Users\blanchet\home\git\odcr> .\Get-DailyChangeRate.ps1 -name MCCA -login admin -Vserver ESX_PROD -Volume DS_1_NFS
password: *********
Please wait .
TOTAL number of selected volumes with SnapShot is [1/1]
TOTAL Daily Change Rate Pourcent: [0.0475%] Daily change Rate Size: [229291.53KB]
```

The option -ShowSelectVolList you can see all selected volumes  
```
PS C:\Users\blanchet\home\git\odcr> .\Get-DailyChangeRate.ps1 -name MCCA -login admin -Vserver SAN_SVM_MC -ShowSelectVolList
password: *********

Name                      State       TotalSize  Used  Available Dedupe Aggregate                 Vserver
----                      -----       ---------  ----  --------- ------ ---------                 -------
archive_postgre_omasso... online        10,3 GB   14%     8,8 GB  True  dataA1                    SAN_SVM_MC
ATRTESTFC                 online        12,2 GB    0%    12,2 GB  True  dataA2                    SAN_SVM_MC
base_postgre_omasson_vol  online        10,3 GB    2%    10,1 GB  True  dataA1                    SAN_SVM_MC
clone_lun                 online       103,1 GB    0%   103,1 GB False  dataA2                    SAN_SVM_MC
DS_SAN_DEMO_FP            online       105,3 GB   47%    54,9 GB False  dataA2                    SAN_SVM_MC
lun_postgresql_omasson... online        10,3 GB    0%    10,3 GB False  dataA1                    SAN_SVM_MC
lun_postgresql_WAL_oma... online        10,3 GB    0%    10,3 GB False  dataA1                    SAN_SVM_MC
lun_solaris_11_2_vol      online       150,0 GB   66%    49,6 GB False  dataA1                    SAN_SVM_MC
```
