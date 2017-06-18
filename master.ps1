<#
.Synopsis
    Configures local host to allow multiple LX subsystems to be more easily accessible by
    a single user.

.DESCRIPTION
    This enables multiple LX subsystems (LXSS) to be more easily accessible by a single user.
    Each user account can host a unique LX subsystem. Multiple LX subsystems can already
    exist by creating separate local user account for each LX subsystem.

    To help make other LXSS be more easily accessible to a single user, each local user account
    is created with the same password and standardize naming convention. Using the same password
    and standardized account name syntax, credentials could then be seamlessly passed
    within subsequent functions to run the bash.exe executable, allowing access to different LXSS
    installed under the context of different users.

    It also sets each user account as a special account so it is not seen at the Windows 
    sign-on screen and enables the ability to temporarily the default ProfilesDirectory
    for the LXSS accounts so it could be re-directed.

  ! WARNING: Because it made it easier for me, I automatically also add every LXSS user
    to the Administrators group. Might be a security concern for some, but all my testing
    has always had these users in this group. 

.INPUTS
    The host setup involves creating json files that I hope to eventually take as the 
    default input values for subsequent functions.

.NOTES
    General notes:
      Built and tested with the LXSS accounts all members of the Administrators group on
      a non-domain joined computer.

             Author: Victor Pham
    DateLastUpdated: 2017-06-18
            Version:
             0.0.1.0 - Created.
#>

<# 

    LX SUBSYSTEM SETUP: Functions related to creating the initial accounts to host LX subsystems. 
    (The commands underneath each function are available aliases to the PowerShell function)

    * Initialize-LXSSHost: Creates new local group and conf files (for future use).

    * New-LXSubsystem: Open Windows cmd as LX account to install or uninstall the LXSS.
       lxss-new

    LX SUBSYSTEM ACCESS: Functions to access the LX subsystems or the Windows command prompt to manage those systems
    (The commands underneath each function are available aliases to the PowerShell function)

    * Start-LXSubsystemCommand: Open Windows cmd as LX account to install or uninstall the LXSS.
       lxss-cmd
       lxss-sudosh
    
    * Enter-BashSession: Invoke the bash.exe as a separate user account (allowing you to access that account's LXSS)
       lxss-start
       lxss-sh
#>

##### LX SUBSYSTEM SETUP

function Initialized-LXSSHost {
    New-LocalGroup -Description "Accounts created to host Linux subsystems." -Name "Linux Subsystems"
    New-Item -Path $env:USERPROFILE -Name ".lxssconf" -ItemType Directory
    New-Item -Path "$env:USERPROFILE\.lxssconf" -Name "host.json" -ItemType File
    New-Item -Path "$env:USERPROFILE\.lxssconf" -Name "lxss.json" -ItemType File
    New-Item -Path "$env:USERPROFILE\.lxssconf" -Name "lxssuser.json" -ItemType File
}

<#
.Synopsis
   Creates new account to provide a userspace to host a new LX subsystem.

.DESCRIPTION
   Creates a new local account to host a new LX subsystem. A default group can be specified to which
   the new account will be added.
   
   The -LXSSRoot parameter is where the user profile for this account will be set. It does so by temporarily
   changing the default ProfilesDirectory location within the registry, then invokes command to set its user 
   profile directory there, then changing the ProfilesDirectory location back to original value.

   It also hides this account from the Windows logon screen by setting it as a "SpecialAccount". Setting the
   related -SpecialAccount parameter to $FALSE will disable this, and have the account be just like any other.

.EXAMPLE
   New-LXSubsystem -Name ubuntu -Tag "lxss-" -LXSSRoot "C:\.lxss" -Password "RandomCharsHurr1" -AsPlainText -SetLXSSPassword -Verbose

   This creates a new local user account "lxss-ubuntu" with its password being "RandomCharsHurr1". The user profile for this account would
   be re-located to C:\.lxss\ubuntu (note the absence of the "lxss-tag").
   
   "RandomCharsHurr1" would also be stored as a converted secure string under the running user's profile and be automatically passed to
   when running the LXSS access function Enter-BashSession. 
#>
function New-LXSubsystem {
    [CmdletBinding()]
    [Alias('lxss-new')]
    param(
    [Parameter(Mandatory=$true,
               ValueFromPipeline=$true,
               ValueFromPipelineByPropertyName=$true,
               Position=0)]
        [string]$Name,
    [Parameter(ValueFromPipelineByPropertyName=$true,
               Position=1)]
    [AllowEmptyString()]
        [string]$Tag="",
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateSet("Prefix","Suffix","Custom")]
        [string]$TagType="Prefix",
    [Parameter()]
        [boolean]$IncludeUserProfileTag=$false,
    [Parameter(Mandatory=$false,
               ValueFromPipelineByPropertyName=$true,
               Position=2)]
    [AllowEmptyString()]
        [string]$Description="Account created to host separate Linux subsystem",
    [Parameter(ValueFromPipelineByPropertyName=$true,
               Position=3)]
    [AllowEmptyString()]
        [string]$LXSSRoot=$null,
    [Parameter(Mandatory=$true,
               ValueFromPipelineByPropertyName=$true)]
        [string[]]$LXSSLocalGroupList=@("Administrators","Linux Subsystems"),
    [Parameter(Mandatory=$true,
               ValueFromPipelineByPropertyName=$true,
               ParameterSetName='SetPassword',
               Position=4)]
    [AllowEmptyString()]
        $Password=$null,
    [Parameter(Mandatory=$false,
               ValueFromPipelineByPropertyName=$true,
               ParameterSetName='SetPassword')]
    [switch]$AsPlainText,
    [Parameter(Mandatory=$false,
               ValueFromPipelineByPropertyName=$true,
               ParameterSetName='SetPassword')]
    [switch]$NullPassword,
    [Parameter(Mandatory=$false,
               ValueFromPipelineByPropertyName=$true,
               ParameterSetName='SetPassword')]
    [switch]$SetLXSSPassword=$false,
    [Parameter(Mandatory=$true,
               ValueFromPipelineByPropertyName=$true,
               ParameterSetName='Default')]
    [switch]$LXSSPassword,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [boolean]$SpecialAccount=$true
    )
    
    begin{

    if(!(Test-Path -Path "$env:USERPROFILE\.lxssconf")){ New-Item -Path $env:USERPROFILE -Name ".lxssconf" -ItemType Directory -Force }
    $LXSSConfUser = "$env:USERPROFILE\.lxssconf"

    switch($PSCmdlet.ParameterSetName)
    {
        "SetPassword" { 
            if($Password -eq $null -and !$NullPassword.IsPresent){ Write-Error "Specify a password or include the -NullPassword parameter." -ErrorAction Stop }
            elseif($Password -eq $null -and $NullPassword.IsPresent){ $SecureString = New-Object securestring }
            elseif($Password -is [securestring]){ [securestring]$SecureString = $Password }
            elseif($Password -is [string] -and !$AsPlainText.IsPresent){ Write-Error "Plain text passwords must be include the -AsPlainText parameter." -ErrorAction Stop }
            elseif($Password -is [string] -and $AsPlainText.IsPresent){ [securestring]$SecureString = ($Password.ToString() | ConvertTo-SecureString -AsPlainText -Force)}
            else{ Write-Error "Unknown error related to specifying password." -ErrorAction Stop }

            if($SetLXSSPassword.IsPresent -and $Password -ne $null){
                $SecureString | ConvertFrom-SecureString | Out-File "$LXSSConfUser\lxsspasswd.PSSecureString" -Force
                Write-Verbose -Message "LXSS credentials stored: $LXSSConfUser\lxsspasswd.PSSecureString"
            }
        }
        Default { 
            if(Test-Path -Path "$LXSSConfUser\lxsspasswd.PSSecureString")
            {
                [securestring]$SecureString = Get-Content "$LXSSConfUser\lxsspasswd.PSSecureString" | ConvertTo-SecureString
            }
            else{ Write-Error "No stored LXSS credentials found. A password must be specified." -ErrorAction Stop }
        }
    }

    <#
        Because the account name will differ based on tagging preferences, the LXSS account name is stored in several versions.
        References to the LXSS account name should conform to the following within this function (and all other functions):
            $LXSSUsername    - Refers to the credential username
            $LXSSProfileName - Refers to the account name as referenced in the user profile directory (it could be tagged or untagged)
    #>

    switch($TagType)
    {
        "Custom" { 
            [string]$LXSSUsername = $Name
            if($IncludeUserProfileTag){ [string]$LXSSProfileName = $LXSSUsername }
            else{ [string]$LXSSProfileName = "$($LXSSUsername -replace "$Tag")" }

        }
        "Prefix" { 
            [string]$LXSSUsername = $Tag + $Name
            if($IncludeUserProfileTag){ [string]$LXSSProfileName = $LXSSUsername }
            else{ [string]$LXSSProfileName = ($LXSSUsername -replace "$Tag") }
        }
        "Suffix" { 
            [string]$LXSSUsername = $Name + $Tag
            if($IncludeUserProfileTag){ [string]$LXSSProfileName = $LXSSUsername }
            else{ [string]$LXSSProfileName = ($LXSSUsername -replace "$Tag") }
        }
    }
    
    [array]$CheckNewUsername = @()
    [array]$CheckNewUsername = Get-LocalUser | ? { $_.Name -like "$LXSSUsername" }
    if($CheckNewUsername.Count -gt 0){ Write-Error "The specified username already exists." -ErrorAction Stop; return }

    [string[]]$ValidLocalGroupList = @()
    [string[]]$LocalGroups = Get-LocalGroup | foreach { $_.Name }
    foreach($LXSSGroup in $LXSSGroupList){
        if($LocalGroups.Contains("$LXSSGroup")){ $ValidLocalGroupList += $LXSSGroup }
    }

    if($LXSSRoot -eq $null){ [string]$LXSSRoot = $(Split-Path $env:USERPROFILE -Parent) }
    }

    process{

    $LXSSCredential = New-Object pscredential @("$LXSSProfileName",$SecureString)
    try {
        $LXSSUser = New-LocalUser -Name "$LXSSProfileName" -Description "$Description" -AccountNeverExpires -Password $SecureString -ErrorAction Stop 
        Write-Verbose -Message "New LXSS account created: $LXSSProfileName"
    }
    catch { return $Error[0] }

    foreach($LXSSGroup in $ValidLocalGroupList){
        Add-LocalGroupMember -Group $LXSSGroup -Member $LXSSUser
        Write-Verbose -Message "New LXSS account added to LXSS group: $LXSSGroup"
    }

    [string]$CurrentProfilesDirectory = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" -Name ProfilesDirectory
    if(!($CurrentProfilesDirectory -like $LXSSRoot)){
        [string]$UsersProfiles = "_UsersProfilesDirectory"
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" -Name "$UsersProfiles" -PropertyType String -Value "$CurrentProfilesDirectory" -Force | Out-Null
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" -Name ProfilesDirectory -PropertyType String -Value "$LXSSRoot" -Force | Out-Null
        Write-Verbose "Temporarily setting default ProfilesDirectory to LXSSRoot path: $LXSSRoot."
    }

    Start-Process powershell -Credential $LXSSCredential -ArgumentList @("-command return $env:USERPROFILE") -WindowStyle Minimized -Wait
    [string]$LXSSSID = Get-WmiObject Win32_UserAccount | ? { $_.Name -like "$LXSSProfileName" } | foreach { $_.SID }
    [string]$LXSSProfilePath =  Get-WmiObject Win32_UserProfile | ? { $_.SID -like "$LXSSSID" } | foreach { $_.LocalPath }
    if(Test-Path $LXSSProfilePath){ 
        Write-Verbose "New LXSS account profile created: $LXSSProfilePath."
    }
    else{ Write-Error "Unable to verify new LXSS account profile created: $LXSSProfilePath" }

    if(!$IncludeUserProfileTag)
    {
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" -Name ProfilesDirectory -PropertyType String -Value "$CurrentProfilesDirectory" -Force | Out-Null
        Write-Verbose "Default ProfilesDirectory value restored."
        Rename-LocalUser -Name "$LXSSProfileName" -NewName $LXSSUsername
    }
    Write-Verbose "New LXSS user account finalized: $LXSSUsername."
        
    if($SpecialAccount){
        [string]$SpecialAccounts = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList"
		if (!(Test-Path "$SpecialAccounts")) { New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts" -Name UserList -ItemType Directory -Force | Out-Null }
        New-ItemProperty -Path $SpecialAccounts -Name $LXSSUsername -PropertyType Dword -Value 0 -Force | Out-Null
        Write-Verbose "Disabled LXSS user account from appearing as option at Windows logon screen."
    }
    }
}

##### LX SUBSYSTEM ACCESS

function Start-LXSubsystemCommand {
    [cmdletbinding()]
    [alias('lxss-cmd', 'lxss-sudosh')]
    param (
    )
    dynamicparam
    {
        $DynamicParameters = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $Attribute = New-Object System.Management.Automation.ParameterAttribute
        $Attribute.Mandatory = $true
        $Attribute.Position = 0
        $AttributeCollection.Add($Attribute)
        $SetArray = Get-LocalGroupMember "Linux Subsystems" | foreach { Split-Path $_.Name -Leaf }
        $AttributeCollection.Add((New-Object System.Management.Automation.ValidateSetAttribute($SetArray)))
        $Name = New-Object System.Management.Automation.RuntimeDefinedParameter('Name', [string], $AttributeCollection)
        $DynamicParameters.Add('Name', $Name)
        
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $Attribute.Mandatory = $false
        $AttributeCollection.Add($Attribute)
        $RunAs = New-Object System.Management.Automation.RuntimeDefinedParameter ('RunAs', [switch], $AttributeCollection)
        $DynamicParameters.Add('RunAs', $RunAs)

        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $Attribute.Mandatory = $false
        $AttributeCollection.Add($Attribute)
        $PersistCurrentWindow = New-Object System.Management.Automation.RuntimeDefinedParameter ('PersistCurrentWindow', [switch], $AttributeCollection)
        $DynamicParameters.Add('PersistCurrentWindow', $PersistCurrentWindow)
        $DynamicParameters
    }
    process
    {
        $RunningUser = $env:USERPROFILE
        if ($Name -like 'CurrentUser')
        {
            switch ($RunAs.IsPresent)
            {
                $true   { Start-Process cmd -ArgumentList @("/k","/s","pushd `"$env:USERPROFILE`"") -Verb RunAs }
                default { Start-Process cmd }
            }
            return
        }
        
        if ($RunAs.IsPresent)
        {
            Start-Process powershell -Verb RunAs -ArgumentList @("-command cmd") -WindowStyle Hidden
        }
        else
        {
            $StoredLXSSCredentials = "$env:USERPROFILE\.lxssconf\lxsspasswd.PSSecureString"
            if (Test-Path $StoredLXSSCredentials)
            {
                [pscredential]$LXSSCredentials = New-Object pscredential "$env:COMPUTERNAME\$Name", $(Get-Content "$StoredLXSSCredentials" | ConvertTo-SecureString)
            }
            else { $LXSSCredentials = Get-Credential }
            Start-Process cmd -ArgumentList @("/k","/s","pushd %USERPROFILE%") -Credential $LXSSCredentials
        }
    }
    end
    {
        if (!$PersistCurrentWindow) { exit }
    }
}

function Enter-BashSession
{
    [cmdletbinding()]
    [alias('lxss-start','lxss-sh','Enter-LinuxSubsystem')]
    param (
    )
    dynamicparam
    {
        $DynamicParameters = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $Attribute = New-Object System.Management.Automation.ParameterAttribute
        $Attribute.Mandatory = $true
        $Attribute.Position = 0
        $AttributeCollection.Add($Attribute)
        $SetArray = Get-LocalGroupMember "Administrators" | foreach { Split-Path $_.Name -Leaf }
        $SetArray += "CurrentUser"
        $AttributeCollection.Add((New-Object System.Management.Automation.ValidateSetAttribute($SetArray)))
        $Name = New-Object System.Management.Automation.RuntimeDefinedParameter('Name', [string], $AttributeCollection)
        $DynamicParameters.Add('Name', $Name)
        
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $Attribute.Mandatory = $false
        $AttributeCollection.Add($Attribute)
        $RunAs = New-Object System.Management.Automation.RuntimeDefinedParameter ('RunAs', [switch], $AttributeCollection)
        $DynamicParameters.Add('RunAs', $RunAs)

        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $Attribute.Mandatory = $false
        $AttributeCollection.Add($Attribute)
        $PersistCurrentWindow = New-Object System.Management.Automation.RuntimeDefinedParameter ('PersistCurrentWindow', [switch], $AttributeCollection)
        $DynamicParameters.Add('PersistCurrentWindow', $PersistCurrentWindow)
        $DynamicParameters
    }
    
    process
    {
        if ($Name -like 'CurrentUser')
        {
            switch ($RunAs.IsPresent)
            {
                $true { Start-Process bash -ArgumentList @('~') -Verb RunAs }
                default { Start-Process bash -ArgumentList @("~") }
            }
            return
        }
        
        if ($RunAs.IsPresent)
        {
            Start-Process powershell -Verb RunAs -ArgumentList @("-command Enter-BashSession -Name $Name") -WindowStyle Hidden
        }
        else
        {
            $StoredLXSSCredentials = "$env:USERPROFILE\.lxssconf\lxsspasswd.PSSecureString"
            if (Test-Path $StoredLXSSCredentials)
            {
                [pscredential]$LXSSCredentials = New-Object pscredential "$env:COMPUTERNAME\$Name", $(Get-Content "$StoredLXSSCredentials" | ConvertTo-SecureString)
            }
            else { $LXSSCredentials = Get-Credential }
            Start-Process bash -ArgumentList '~' -Credential $LXSSCredentials
        }
    }
    end
    {
        if (!$PersistCurrentWindow) { exit }
    }
}
