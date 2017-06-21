# lxsshost
  Configures a Windows local host to allow multiple LX subsystems to be more easily accessible by a single 
  user.
    
## Description
  This enables multiple LX subsystems (LXSS) to be more easily accessible by a single user. Each user account 
  can host a single LX subsystem. Multiple LX subsystems can natively co-exist on a single Windows host by 
  creating a separate user account for each LX subsystem.
    
  These functions aim to provide a standard framework which local user accounts can be created to provide 
  easier access to separate LX subsystems by using what is already available in Windows.
    
## Getting started
  Download master.ps1 and import the script by running the following in an elevated PowerShell console:
```powershell
Import-Module C:\path\to\master.ps1 -Global
```
    
##### (Optional) Setup the local host
  Run the following function to create the local group and create the configuration files:
```powershell
Initialize-LXSSHost -Verbose
```
##### Note
    This is not strictly required to use the New-LXSubsystem function but future code may be written assuming 
    this has been ran.
    
## Creating a new LX subsystem
  Run the following function to create a new LX subsystem:
```powershell
New-LXSubsystem -Name ubuntu -LXSSRoot "C:\.lxss" -Password "Change2day!" -AsPlainText -SetLXSSPassword
```
##### Note
    New LX subsystems can be created after with -Password, and everything after, omitted. Doing so assumes the 
    user password should be set to the same password originally specified with the -SetLXSSPassword parameter.
    
### Details on what this is doing:
    
    - A user account is created, -SetLXSSPassword exports the credentials to a text file (converted from a secure 
    string).
    - Invokes Windows command prompt to create the user profile in the directory specified by LXSSRoot.
      * This can allow you to redirect the LX subsystem to a drive other than the system drive.
    - The user account is set to be hidden from the Windows logon screen
    
##### Warning
    By default, every LXSS user account created is added to both a custom created LX Subsystems group and the 
    built in Administrators group. This may be a security concern for some so do so at your own risk but all 
    my testing has always had the LXSS user accounts created members of these two groups.
    
## Accessing the LX subsystems
  The following function invokes bash.exe under the context of the user account specified in -Name. The -Name 
  parameter options is defined at runtime and will update (listing members of the "LX Subsystems", if that
  group exists).
```powershell
Enter-BashSession -Name ubuntu
```

#### Interacting with the LX subsystems from Windows
  The following starts a Windows prompt in the context of the LXSS user account:
```powershell
Start-LXSubsystemCommand -Name ubuntu
```
   
## Final Notes
  The host setup involves creating json files that I hope to eventually take as the default input values 
  for subsequent functions.
  
#### Future builds
  Create a separate default user profile for the LXSS user accounts or use a shared user profile directory 
  that only defines a unique location between the accounts for the user's local AppData folder.
  
  If bash can be started as a service and creating a separate unique service for each LX 
  subsystem enabling the ability to run concurrent LX subsystems that are able to interact with one another.
  
  I am not sure of the value in doing this because the local host would be like acting as a "pseudo-hypervisor" 
  for LX subsystems. At that point, most would prefer to run a true hypervisor run true linux virtual machines.
    
  Please enjoy and feel free to share, contribute, or report bugs found.
    
## Author
    Victor Pham
    Last updated 2017-06-18
    
#### Version:
    0.0.1.0 - Created.
