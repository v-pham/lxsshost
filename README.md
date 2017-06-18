# lxsshost
  Configures a Windows local host to allow multiple LX subsystems to be more easily accessible by a single 
  user.
    
## Description
  This enables multiple LX subsystems (LXSS) to be more easily accessible by a single user. Each user 
  account can host a unique LX subsystem. Multiple LX subsystems can natively co-exist on a single host by 
  creating a separate user account for each LX subsystem.
    
  These functions provide a standard framework which user accounts can be created to provide easier access
  to these separate LX subsystem by using what is built into Windows.
    
## Getting started
  Download master.ps1 and run the following in an elevated PowerShell console:
```powershell
Import-Module C:\path\to\master.ps1 -Global
```
    
##### (Optional) Setup the local host
  Run the following function to create the local group and create the configuration files:
```powershell
Initialize-LXSSHost -Verbose
```
##### Note
    This is not required to use the New-LXSubsystem function but future code may be written assuming 
    this has been ran.
    
## Creating a new LX subsystem
  Run the following function to create a new LX subsystem:
```powershell
New-LXSubsystem -Name ubuntu -LXSSRoot "C:\.lxss" -Password "Change2day!" -AsPlainText -SetLXSSPassword
```
##### Note
    Subsequent new LX subsystems can be created with -Password (and everything after) omitted which will set
    the user password to the same password set with the -SetLXSSPassword parameter.
    
### Details on what this is doing:
    
    - A user account is created, -SetLXSSPassword exports the credentials to a text file (converted from a secure 
    string).
    - Invokes Windows command prompt (and exits) to create the user profile in the directory specified by LXSSRoot.
      * This can allow you to redirect the LX subsystem to a drive other than the system drive.
    - The user account is set to be hidden from the Windows logon screen
    
##### Warning
    I also add every LXSS user to the Administrators group. Might be a security concern for some but 
    all my testing has always had the LXSS created accounts users in this group.
    
## Accessing the LX subsystems
  The following function invokes bash.exe under the context of the user account specified in -Name. The -Name 
  parameter options is defined at runtime and will update (listing members of the "Linux Subsystems", if it exists).
```powershell
Enter-BashSession -Name ubuntu
```

## Interacting with the LX subsystems from Windows
  The following starts a Windows prompt in the context of the LXSS user account:
```powershell
Start-LXSubsystemCommand -Name ubuntu
```
   
## Final Notes
  The host setup involves creating json files that I hope to eventually take as the default input values 
  for subsequent functions. And I'd like to create a separate default user profile for the LXSS user accounts 
  or use a shared user profile directory with a separately defined location for the user AppData folder 
  where the LX subsystem exists.
    
  Please enjoy and feel free to share, contribute, or report bugs found.
    
## Author
    Victor Pham
    Last updated 2017-06-18
    
#### Version:
    0.0.1.0 - Created.
