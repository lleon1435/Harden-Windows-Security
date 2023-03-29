#
# Module manifest for module 'New-ConfigWDAC'
#
# Generated by: HotCakeX
#
# Generated on: 3/11/2023
#

@{

    # Script module or binary module file associated with this manifest.
    RootModule           = 'New-ConfigWDAC.psm1'

    # Version number of this module.
    ModuleVersion        = '0.0.6'

    # Supported PSEditions
    CompatiblePSEditions = @("Desktop", "Core")

    # ID used to uniquely identify this module
    GUID                 = '79920947-efb5-48c1-a567-5b02ebe74793'

    # Author of this module
    Author               = 'HotCakeX'

    # Company or vendor of this module
    CompanyName          = 'SpyNetGirl'

    # Copyright statement for this module
    Copyright            = '(c) 2023'

    # Description of the functionality provided by this module
    Description          = @"

This is an advanced PowerShell module for WDAC (Windows Defender Application Control) and automates a lot of tasks.


🟢 Please see the GitHub page for Full details and everything about the module: https://github.com/HotCakeX/Harden-Windows-Security/wiki/New-ConfigWDAC


🛡️ Here is the list of parameters the module supports


✔️ New-ConfigWDAC [[-Get_BlockRules]]
    
✔️ New-ConfigWDAC [[-Get_DriverBlockRules]]
    
✔️ New-ConfigWDAC [[-Make_AllowMSFT_WithBlockRules]] [-Deployit] [-TestMode] [-RequireEVSigners]
    
✔️ New-ConfigWDAC [[-Deploy_LatestDriverBlockRules]]
    
✔️ New-ConfigWDAC [[-Set_AutoUpdateDriverBlockRules]]
    
✔️ New-ConfigWDAC [[-Make_PolicyFromAuditLogs]] [-Deployit] [-TestMode] [-RequireEVSigners] [-Debugmode]
    
✔️ New-ConfigWDAC [[-Prep_MSFTOnlyAudit]]
    
✔️ New-ConfigWDAC [[-Make_LightPolicy]] [-Deployit] [-TestMode] [-RequireEVSigners]
    
✔️ New-ConfigWDAC [[-ListActivePolicies]]
    
✔️ New-ConfigWDAC [[-VerifyWDACStatus]]
    
✔️ New-ConfigWDAC [[-Sign_Deploy_Policy]] [-CertPath] <String> -PolicyPaths <String[]> [-SignToolPath <String>] -CertCN <String>
    
✔️ New-ConfigWDAC [[-Make_SuppPolicy]] -ScanLocation <String> -SuppPolicyName <String> [-Deployit] -PolicyPaths <String[]>
    
✔️ New-ConfigWDAC [[-RemoveSignedPolicy]] -PolicyPaths <String[]> [-SignToolPath <String>] -CertCN <String>
    
✔️ New-ConfigWDAC [[-RemoveUNsignedPolicy]] [-PolicyIDs <String[]>] [-PolicyNames <String[]>]
    
✔️ New-ConfigWDAC [[-AllowNewApp_AuditEvents]] [-CertPath] <String> -SuppPolicyName <String> -PolicyPaths <String[]> [-SignToolPath <String>] -CertCN <String> [-Debugmode]
    
✔️ New-ConfigWDAC [[-AllowNewApp]] [-CertPath] <String> -SuppPolicyName <String> -PolicyPaths <String[]> [-SignToolPath <String>] -CertCN <String> 



REMARKS
To see the syntax, type: "get-help New-ConfigWDAC"

"@

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion    = '7.3'

    # Name of the PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # ClrVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport    = @("New-ConfigWDAC")

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport      = @("New-ConfigWDAC")

    # Variables to export from this module
    VariablesToExport    = '*'

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport      = @()

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    FileList             = @('New-ConfigWDAC.psm1', 'New-ConfigWDAC.psd1')

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData          = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags       = @('WDAC', 'Windows-Defender-Application-Control', 'Windows', 'Security', 'Microsoft', 'Application-Control', 'MDAC')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/HotCakeX/Harden-Windows-Security/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/HotCakeX/Harden-Windows-Security/wiki/New-ConfigWDAC'

            # A URL to an icon representing this module.
            IconUri    = 'https://raw.githubusercontent.com/HotCakeX/Harden-Windows-Security/main/New-ConfigWDAC/PowerShellGalleryIcon.png'

            # ReleaseNotes of this module
             ReleaseNotes =  @"

## Version
* 0.0.6 Many parameters now output objects instead of strings. Improved some of the logics and fixed an error with Audit event log creation. Also started adding change logs.
* 0.0.5 Added -AllowNewApp and -AllowNewApp_AuditEvents parameters to the module to rebootlessly allow an app.
"@


            # Prerelease string of this module
            # Prerelease = ''

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            # RequireLicenseAcceptance = $false

            # External dependent modules of this module
            # ExternalModuleDependencies = @()

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    HelpInfoURI          = 'https://github.com/HotCakeX/Harden-Windows-Security/wiki/New-ConfigWDAC'

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}

