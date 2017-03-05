# disable-smb1-powershell
Disabling the SMB1 Protocol with PowerShell

These scripts are intended to be used with System Center Configuration Manager, specifically as configuration items.

DetectSMB1State.ps1 for detection (returns a boolean value of True if SMB1 is Disabled, False if Enabled)
RemediateSMB1.ps1 will disable the protocol for Windows 7, 8.x, and 10 (or server equivalents).
