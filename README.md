# lxsshost
    Configures a Windows local host to allow multiple LX subsystems to be more easily accessible by a 
    single user.
    
# Desciption
    This enables multiple LX subsystems (LXSS) to be more easily accessible by a single user. Each user 
    account can host a unique LX subsystem. Multiple LX subsystems can natively co-exist on a single host
    by creating a separate user account for each LX subsystem.
    
    These functions provide a standard framework which these accounts are created to provide easier access
    to these separate LX subsystem by using what is built into Windows.
    
# Getting started
    Download master.ps1 and run the following in an elevated PowerShell console:
```powershell
Import-Module C:\path\to\master.ps1 -Global
```
    
    (Optional)
    Run the following function to create the local group and create the configuration files:
```powershell
Initialize-LXSSHost -Verbose
```
    This is not required to use the New-LXSubsystem function but future code may be written assuming this
    has been ran and there does exist some group by which to filter LXSS user accounts.
    
# Creating a new LX subsystem
    Run the following function to create a new LX subsystem:
```powershell
New-LXSubsystem
```
    
## Details on what this is doing:
    
    Each local LXSS user account is created with the same password and standardize naming convention. Using the 
    same password and standardized account name syntax, credentials are then stored and passed within 
    subsequent functions to run the bash.exe as the separate user.
    
    It also hides each account from the Windows logon screen and enables the ability to re-direct the
    the LXSS account profiles. I can confirm I am currently redirecting these account profiles
    to a separate drive entirely.
    
  ! WARNING: Because it made it easier for me, I automatically also add every LXSS user
    to the Administrators group. Might be a security concern for some, but all my testing
    has always had the LXSS accounts users in this group.
    
# Accessing another LX subsystem
    The following function invokes bash.exe under the context of the user account specified in -Name.
    Just to be fancy, the -Name parameter options is defined at runtime and will update, based on account 
    membership of Linux Subsystems group.
```powershell
Enter-BashSession
```
        
    If need-be, the following function will open up Windows cmd prompt as the LX subsystem account to enter
    in credentials if not stored:
```powershell
Start-LXSubsystemCommand
```
   
# Caveats
    The host setup involves creating json files that I hope to eventually take as the 
    default input values for subsequent functions. I hope to create a separate default user profile to be used for
    the LXSS user accounts. I was thinking maybe to use a shared user profile directory with a separately defined 
    location only the user AppData folder where the LX subsystem exists.
    
    Anyway, please enjoy and please feel free to share, contribute, or report bugs found.
    
# Author
    Victor Pham
    victorvpham@gmail.com
    Last updated 2017-06-18
    
# Version:
    0.0.1.0 - Created.
