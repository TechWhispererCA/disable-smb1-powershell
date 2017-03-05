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
            Return $false
        }
        if ((Get-SmbServerConfiguration).EnableSMB1Protocol) {
            Return $false
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
        if ($ProcessOutput -match '.*MRxSmb10.*') {Return $false}
        
        Try {
            [string]$SMB1Key = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name SMB1 -ErrorAction Stop).SMB1
            if ($SMB1Key -ne '0') {
                Return $false
            }
        }
        Catch {
            Return $false
        }
    }

    Return $true

} Catch {
    $LastError = $Error | Select-Object -First 1 -ExpandProperty Exception | Select-Object -ExpandProperty Message
    Write-Warning -Message $LastError
    Exit 1
}