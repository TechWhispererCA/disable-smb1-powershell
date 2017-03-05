Try {
    [string]$OperatingSystemVersion = (Get-WmiObject -Class Win32_OperatingSystem).Version
    [bool]$WindowsOptionalFeature = $false
    switch -Regex ($OperatingSystemVersion) {
        '^10\.0.*' {
            [bool]$WindowsOptionalFeature = $true
        }
        '^6\.(2|3).*' {
            [bool]$WindowsOptionalFeature = $true
        }
        '^6\.1.*' {
            [bool]$WindowsOptionalFeature = $false
        }
        default {
            Throw "Unsupported Operating System"
        }
    }

    if ($WindowsOptionalFeature) {
        $SMB1Protocol = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
        if ($SMB1Protocol.State -eq 'Enabled') {
            Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart
        }
        if ((Get-SmbServerConfiguration).EnableSMB1Protocol) {
            Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
        }
    } else {
        $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
        [string]$ProcessInfo.FileName = "sc.exe"
        [bool]$ProcessInfo.RedirectStandardError = $true
        [bool]$ProcessInfo.RedirectStandardOutput = $true
        [bool]$ProcessInfo.UseShellExecute = $false
        [bool]$ProcessInfo.CreateNoWindow = $true
        [string]$ProcessInfo.Arguments = 'qc lanmanworkstation'
        $Process = New-Object System.Diagnostics.Process
        $Process.StartInfo = $ProcessInfo
        $Process.Start() | Out-Null
        $Process.WaitForExit()
        [string]$ProcessError = $Process.StandardError.ReadToEnd()
        if ($ProcessError) {
            Throw "Error encountered while querying SMB1 status."
        }
        [string]$ProcessOutput = $Process.StandardOutput.ReadToEnd()
        [string[]]$SCResults = $ProcessOutput.Split([environment]::NewLine,[System.StringSplitOptions]::RemoveEmptyEntries)
        if ($ProcessOutput -match '.*MRxSmb10.*') {
            #sc.exe config lanmanworkstation depend= bowser/mrxsmb20/nsi
            #sc.exe config mrxsmb10 start= disabled
            # SMB1 Client Settings
            Start-Process -FilePath "$env:windir\System32\sc.exe" -ArgumentList 'config lanmanworkstation depend= bowser/mrxsmb20/nsi' -NoNewWindow
            Start-Process -FilePath "$env:windir\System32\sc.exe" -ArgumentList 'config mrxsmb10 start= disabled' -NoNewWindow
        }

        # SMB1 Server Settings
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" SMB1 -Type DWORD -Value 0 -Force
    }

} Catch {
    $LastError = $Error | Select-Object -First 1 -ExpandProperty Exception | Select-Object -ExpandProperty Message
    Write-Warning -Message $LastError
    Exit 1
}