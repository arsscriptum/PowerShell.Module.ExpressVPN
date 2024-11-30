


function Confirm-RegistryPathExists {
    param (
        [Parameter(Mandatory)]
        [string]$RegistryPath
    )

    # Helper to split the hive and key
    function Get-HiveAndKey {
        param (
            [string]$FullPath
        )
        if ($FullPath -match "^(HKLM|HKCU|HKCR|HKU|HKCC):\\(.+)$") {
            return @($matches[1], $matches[2])
        } else {
            throw "[Confirm-RegistryPathExists] Invalid registry path format: $FullPath"
        }
    }

    try {
        # Split the hive and key
        $hive, $key = Get-HiveAndKey -FullPath $RegistryPath

        # Check if the registry path exists
        if (-not (Test-Path -Path $RegistryPath)) {
            Write-Verbose "[Confirm-RegistryPathExists] Registry path '$RegistryPath' does not exist. Creating..."
            
            # Create the registry path
            New-Item -Path $RegistryPath -Force | Out-Null
            Write-Verbose "[Confirm-RegistryPathExists] Registry path '$RegistryPath' created successfully."
        } else {
            Write-Verbose "[Confirm-RegistryPathExists] Registry path '$RegistryPath' already exists."
        }
    } catch {
        Write-Error "[Confirm-RegistryPathExists] An error occurred: $_"
    }
}


