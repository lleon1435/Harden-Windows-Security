# Stop operation as soon as there is an error anywhere, unless explicitly specified otherwise
$ErrorActionPreference = 'Stop'
if (-NOT ([System.Environment]::OSVersion.Version -ge '10.0.22621')) { Write-Error -Message "You're not using Windows 11 22H2, exitting..." }


# Get the path to SignTool
function Get-SignTool {
    param(    
        [parameter(Mandatory = $false)][System.String]$SignToolExePath
    )
    
    # If Sign tool path was provided by user, return it, validation already happened in the parameter ValidateScript
    if ($SignToolExePath) {
        return $SignToolExePath
    }
    # If Sign tool path wasn't provided by user, detect it automatically and then validate it here
    else {
        if ($Env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
            if ( Test-Path -Path "C:\Program Files (x86)\Windows Kits\*\bin\*\x64\signtool.exe") {
                $SignToolExePath = "C:\Program Files (x86)\Windows Kits\*\bin\*\x64\signtool.exe" 
            }
            else {
                Write-Error -Message "signtool.exe couldn't be found"
            }
        }
        elseif ($Env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
            if (Test-Path -Path "C:\Program Files (x86)\Windows Kits\*\bin\*\arm64\signtool.exe") {
                $SignToolExePath = "C:\Program Files (x86)\Windows Kits\*\bin\*\arm64\signtool.exe"
            }
            # If sign tool path was neither provided by user nor detected on the system, stop the operation and throw error
            else {
                Write-Error -Message "signtool.exe couldn't be found"
            }
        }
        # Setting the minimum version of SignTool that is allowed to be executed
        [System.Version]$WindowsSdkVersion = '10.0.22621.755'
        [System.Boolean]$GreenFlag1 = (((get-item -Path $SignToolExePath).VersionInfo).ProductVersionRaw -ge $WindowsSdkVersion)
        [System.Boolean]$GreenFlag2 = (((get-item -Path $SignToolExePath).VersionInfo).FileVersionRaw -ge $WindowsSdkVersion)
        [System.Boolean]$GreenFlag3 = ((get-item -Path $SignToolExePath).VersionInfo).CompanyName -eq 'Microsoft Corporation'
        [System.Boolean]$GreenFlag4 = ((Get-AuthenticodeSignature -FilePath $SignToolExePath).Status -eq 'Valid')
        [System.Boolean]$GreenFlag5 = ((Get-AuthenticodeSignature -FilePath $SignToolExePath).StatusMessage -eq 'Signature verified.')
        # If any of the 5 checks above fails, the operation stops
        if (!$GreenFlag1 -or !$GreenFlag2 -or !$GreenFlag3 -or !$GreenFlag4 -or !$GreenFlag5) {
            Write-Error -Message "The SignTool executable was found but couldn't be verified. Please download the latest Windows SDK to get the newest SignTool executable. Official download link: http://aka.ms/WinSDK"        
        }
        return $SignToolExePath        
    }        
}



# Make sure the latest version of the module is installed and if not, automatically update it, clean up any old versions
function Update-self {
    $currentversion = (Test-modulemanifest "$psscriptroot\WDACConfig.psd1").Version.ToString()
    try {
        $latestversion = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/HotCakeX/Harden-Windows-Security/main/WDACConfig/version.txt"
    }
    catch {
        Write-Error -Message "Couldn't verify if the latest version of the module is installed, please check your Internet connection. You can optionally bypass the online check by using -SkipVersionCheck parameter."
    }
    if (-NOT ($currentversion -eq $latestversion)) {
        Write-Host "The currently installed module's version is $currentversion while the latest version is $latestversion - Auto Updating the module now and will run your command after that 💓"
        Remove-Module -Name WDACConfig -Force
        # Do this if the module was installed properly using Install-moodule cmdlet
        try {
            Uninstall-Module -Name WDACConfig -AllVersions -Force -ErrorAction Stop
            Install-Module -Name WDACConfig -RequiredVersion $latestversion -Force              
            Import-Module -Name WDACConfig -RequiredVersion $latestversion -Force -Global
        }
        # Do this if module files/folder was just copied to Documents folder and not properly installed - Should rarely happen
        catch {
            Install-Module -Name WDACConfig -RequiredVersion $latestversion -Force
            Import-Module -Name WDACConfig -RequiredVersion $latestversion -Force -Global
        }            
    }
}



# Increase Code Integrity Operational Event Logs size from the default 1MB to user defined size
function Set-LogSize {
    [CmdletBinding()]
    param ([System.Int64]$LogSize)        
    $logName = 'Microsoft-Windows-CodeIntegrity/Operational'
    $log = New-Object System.Diagnostics.Eventing.Reader.EventLogConfiguration $logName
    $log.MaximumSizeInBytes = $LogSize
    $log.IsEnabled = $true
    $log.SaveChanges()
}



# function that takes 2 arrays, one contains file paths and the other contains folder paths. It checks them and shows file paths
# that are not in any of the folder paths. Performs this check recursively too so works if the filepath is in a sub-directory of a folder path
function Test-FilePath {
    param (
        [Parameter(Mandatory = $true)]
        [System.String[]]$FilePath,
        [Parameter(Mandatory = $true)]
        [System.String[]]$DirectoryPath
    )

    # Loop through each file path
    foreach ($file in $FilePath) {
        # Check if the file path is valid
        if (Test-Path $file -PathType 'Leaf') {
            # Get the full path of the file
            $FileFullPath = Resolve-Path $file

            # Initialize a variable to store the result
            $Result = $false

            # Loop through each directory path
            foreach ($directory in $DirectoryPath) {
                # Check if the directory path is valid
                if (Test-Path $directory -PathType 'Container') {
                    # Get the full path of the directory
                    $DirectoryFullPath = Resolve-Path $directory

                    # Check if the file path starts with the directory path
                    if ($FileFullPath -like "$DirectoryFullPath\*") {
                        # The file is inside the directory or its sub-directories
                        $Result = $true
                        break # Exit the inner loop
                    }
                }
                else {
                    # The directory path is not valid
                    Write-Warning "The directory path '$directory' is not valid."
                }
            }

            # Output the file path if it is not inside any of the directory paths
            if (-not $Result) {
                Write-Output $FileFullPath
            }
        }
        else {
            # The file path is not valid
            Write-Warning "The file path '$file' is not valid."
        }
    }
}



# Script block that lists every \Device\Harddiskvolume - https://superuser.com/questions/1058217/list-every-device-harddiskvolume
# These are DriveLetter mappings
$DirveLettersGlobalRootFixScriptBlock = {
    $signature = @'
[DllImport("kernel32.dll", SetLastError=true)]
[return: MarshalAs(UnmanagedType.Bool)]
public static extern bool GetVolumePathNamesForVolumeNameW([MarshalAs(UnmanagedType.LPWStr)] string lpszVolumeName,
[MarshalAs(UnmanagedType.LPWStr)] [Out] StringBuilder lpszVolumeNamePaths, uint cchBuferLength, 
ref UInt32 lpcchReturnLength);

[DllImport("kernel32.dll", SetLastError = true)]
public static extern IntPtr FindFirstVolume([Out] StringBuilder lpszVolumeName,
uint cchBufferLength);

[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool FindNextVolume(IntPtr hFindVolume, [Out] StringBuilder lpszVolumeName, uint cchBufferLength);

[DllImport("kernel32.dll", SetLastError = true)]
public static extern uint QueryDosDevice(string lpDeviceName, StringBuilder lpTargetPath, int ucchMax);

'@;
    Add-Type -ErrorAction SilentlyContinue -MemberDefinition $signature -Name Win32Utils -Namespace PInvoke -Using PInvoke, System.Text;

    [UInt32] $lpcchReturnLength = 0;
    [UInt32] $Max = 65535
    $sbVolumeName = New-Object System.Text.StringBuilder($Max, $Max)
    $sbPathName = New-Object System.Text.StringBuilder($Max, $Max)
    $sbMountPoint = New-Object System.Text.StringBuilder($Max, $Max)
    [IntPtr] $volumeHandle = [PInvoke.Win32Utils]::FindFirstVolume($sbVolumeName, $Max)
    do {
        $volume = $sbVolumeName.toString()
        $unused = [PInvoke.Win32Utils]::GetVolumePathNamesForVolumeNameW($volume, $sbMountPoint, $Max, [Ref] $lpcchReturnLength);
        $ReturnLength = [PInvoke.Win32Utils]::QueryDosDevice($volume.Substring(4, $volume.Length - 1 - 4), $sbPathName, [UInt32] $Max);
        if ($ReturnLength) {
            $DriveMapping = @{
                DriveLetter = $sbMountPoint.toString()
                VolumeName  = $volume
                DevicePath  = $sbPathName.ToString()
            }
            Write-Output (New-Object PSObject -Property $DriveMapping)
        }
        else {
            Write-Output "No mountpoint found for: " + $volume
        } 
    } while ([PInvoke.Win32Utils]::FindNextVolume([IntPtr] $volumeHandle, $sbVolumeName, $Max));
}



### Function to separately capture FileHashes of deleted files and FilePaths of available files from Event Viewer Audit Logs ####
Function Get-AuditEventLogsProcessing {
    param ($Date)

    $DirveLettersGlobalRootFix = Invoke-Command -ScriptBlock $DirveLettersGlobalRootFixScriptBlock

    # Defining a custom object to store and finally return it as results
    $AuditEventLogsProcessingResults = [PSCustomObject]@{
        # Defining object properties as arrays
        AvailableFilesPaths = @()
        DeletedFileHashes   = @()
    }
                      
    # Event Viewer Code Integrity logs scan
    foreach ($event in Get-WinEvent -FilterHashtable @{LogName = 'Microsoft-Windows-CodeIntegrity/Operational'; ID = 3076 } -ErrorAction SilentlyContinue | Where-Object { $_.TimeCreated -ge $Date } ) {
        $xml = [xml]$event.toxml()
        $xml.event.eventdata.data |
        ForEach-Object { $hash = @{} } { $hash[$_.name] = $_.'#text' } { [pscustomobject]$hash } |
        ForEach-Object {
            if ($_.'File Name' -match ($pattern = '\\Device\\HarddiskVolume(\d+)\\(.*)$')) {
                $hardDiskVolumeNumber = $Matches[1]
                $remainingPath = $Matches[2]
                $getletter = $DirveLettersGlobalRootFix | Where-Object { $_.devicepath -eq "\Device\HarddiskVolume$hardDiskVolumeNumber" }
                $usablePath = "$($getletter.DriveLetter)$remainingPath"
                $_.'File Name' = $_.'File Name' -replace $pattern, $usablePath
            } # Check if file is currently on the disk
            if (Test-Path $_.'File Name') {
                $AuditEventLogsProcessingResults.AvailableFilesPaths += $_.'File Name' 
            } # If file is not currently on the disk, extract its hashes from event log
            elseif (-NOT (Test-Path $_.'File Name')) {
                $AuditEventLogsProcessingResults.DeletedFileHashes += $_ | Select-Object FileVersion, 'File Name', PolicyGUID, 'SHA256 Hash', 'SHA256 Flat Hash', 'SHA1 Hash', 'SHA1 Flat Hash'
            }
        }
    }
    # return the results as an object
    return $AuditEventLogsProcessingResults
}



# Creates a policy file and requires 2 parameters to supply the file rules and rule references
function New-EmptyPolicy {
    param (
        $RulesContent,
        $RuleRefsContent
    )    
    $EmptyPolicy = @"
<?xml version="1.0" encoding="utf-8"?>
<SiPolicy xmlns="urn:schemas-microsoft-com:sipolicy" PolicyType="Base Policy">
<VersionEx>10.0.0.0</VersionEx>
<PlatformID>{2E07F7E4-194C-4D20-B7C9-6F44A6C5A234}</PlatformID>
<Rules>
<Rule>
<Option>Enabled:Unsigned System Integrity Policy</Option>
</Rule>
<Rule>
<Option>Enabled:Audit Mode</Option>
</Rule>
<Rule>
<Option>Enabled:Advanced Boot Options Menu</Option>
</Rule>
<Rule>
<Option>Required:Enforce Store Applications</Option>
</Rule>
</Rules>
<!--EKUS-->
<EKUs />
<!--File Rules-->
<FileRules>
$RulesContent
</FileRules>
<!--Signers-->
<Signers />
<!--Driver Signing Scenarios-->
<SigningScenarios>
<SigningScenario Value="131" ID="ID_SIGNINGSCENARIO_DRIVERS_1" FriendlyName="Auto generated policy on $(Get-Date -Format 'MM-dd-yyyy')">
<ProductSigners />
</SigningScenario>
<SigningScenario Value="12" ID="ID_SIGNINGSCENARIO_WINDOWS" FriendlyName="Auto generated policy on $(Get-Date -Format 'MM-dd-yyyy')">
<ProductSigners>
<FileRulesRef>
$RuleRefsContent
</FileRulesRef>
</ProductSigners>
</SigningScenario>
</SigningScenarios>
<UpdatePolicySigners />
<CiSigners />
<HvciOptions>0</HvciOptions>
<BasePolicyID>{B163125F-E30A-43FC-ABEC-E30B4EE88FA8}</BasePolicyID>
<PolicyID>{B163125F-E30A-43FC-ABEC-E30B4EE88FA8}</PolicyID>
</SiPolicy>
"@
    return $EmptyPolicy
}



# Gets the latest Microsoft Recommended block rules, removes its allow all rules and sets HVCI to strict
$GetBlockRulesSCRIPTBLOCK = {             
    $MicrosoftRecommendeDriverBlockRules = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/MicrosoftDocs/windows-itpro-docs/public/windows/security/threat-protection/windows-defender-application-control/microsoft-recommended-block-rules.md"
    $MicrosoftRecommendeDriverBlockRules -match "(?s)(?<=``````xml).*(?=``````)" | Out-Null
    $Rules = $Matches[0]

    $Rules = $Rules -replace '<Allow\sID="ID_ALLOW_A_1"\sFriendlyName="Allow\sKernel\sDrivers"\sFileName="\*".*/>', ''
    $Rules = $Rules -replace '<Allow\sID="ID_ALLOW_A_2"\sFriendlyName="Allow\sUser\smode\scomponents"\sFileName="\*".*/>', ''
    $Rules = $Rules -replace '<FileRuleRef\sRuleID="ID_ALLOW_A_1".*/>', ''
    $Rules = $Rules -replace '<FileRuleRef\sRuleID="ID_ALLOW_A_2".*/>', ''

    $Rules | Out-File '.\Microsoft recommended block rules TEMP.xml'
    # Removing empty lines from policy file
    Get-Content '.\Microsoft recommended block rules TEMP.xml' | Where-Object { $_.trim() -ne "" } | Out-File '.\Microsoft recommended block rules.xml'                
    Remove-Item '.\Microsoft recommended block rules TEMP.xml' -Force
    Set-RuleOption -FilePath '.\Microsoft recommended block rules.xml' -Option 3 -Delete
    Set-HVCIOptions -Strict -FilePath '.\Microsoft recommended block rules.xml'
    [PSCustomObject]@{
        PolicyFile = 'Microsoft recommended block rules.xml'
    }
}



# Creates a policy file that has 2 Allow all rules, for Kernel drivers and User-mode binaries, to be merged with Deny base policies
function New-AllowAllPolicy {  
    $AllowAllPolicy = @"
<?xml version="1.0" encoding="utf-8"?>
<SiPolicy xmlns="urn:schemas-microsoft-com:sipolicy" PolicyType="Base Policy">
<VersionEx>10.0.0.0</VersionEx>
<PlatformID>{2E07F7E4-194C-4D20-B7C9-6F44A6C5A234}</PlatformID>
<Rules>
<Rule>
<Option>Enabled:Unsigned System Integrity Policy</Option>
</Rule>
</Rules>
<!--EKUS-->
<EKUs />
<!--File Rules-->
<FileRules>
<Allow ID="ID_ALLOW_A_1" FriendlyName="Allow Kernel Drivers" FileName="*" />
<Allow ID="ID_ALLOW_A_2" FriendlyName="Allow User mode components" FileName="*" />
</FileRules>
<!--Signers-->
<Signers />
  <SigningScenarios>
    <SigningScenario Value="131" ID="ID_SIGNINGSCENARIO_DRIVERS_1" FriendlyName="Driver Signing Scenarios">
      <ProductSigners>
        <FileRulesRef>
          <FileRuleRef RuleID="ID_ALLOW_A_1" />
        </FileRulesRef>
      </ProductSigners>
    </SigningScenario>
    <SigningScenario Value="12" ID="ID_SIGNINGSCENARIO_WINDOWS" FriendlyName="User Mode Signing Scenarios">
      <ProductSigners>
        <FileRulesRef>
          <FileRuleRef RuleID="ID_ALLOW_A_2" />          
        </FileRulesRef>
      </ProductSigners>
    </SigningScenario>
  </SigningScenarios>
<UpdatePolicySigners />
<CiSigners />
<HvciOptions>0</HvciOptions>
<BasePolicyID>{B163125F-E30A-43FC-ABEC-E30B4EE88FA8}</BasePolicyID>
<PolicyID>{B163125F-E30A-43FC-ABEC-E30B4EE88FA8}</PolicyID>
</SiPolicy>
"@
    return $AllowAllPolicy
}

