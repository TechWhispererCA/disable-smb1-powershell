# disable-smb1-powershell
Disabling the SMB1 Protocol with PowerShell

These scripts are intended to be used with System Center Configuration Manager, specifically as configuration items. The script to disable SMB1 could be used with Group Policy as a startup/shutdown script, or via a scheduled task (recommended).

DetectSMB1Enabled.ps1 for detection (returns a boolean value of True if SMB1 is Enabled, False if Disabled)
DisableSMB1.ps1 will disable the protocol for Windows Vista, 7, 8.x, and 10 (or server equivalents).
