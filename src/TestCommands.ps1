
function ConvertTo-ServerList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$Data
    )

    begin {
        # Initialize the result array
        [System.Collections.ArrayList]$result = [System.Collections.ArrayList]::new()
        $DataCount = $Data.Count
        if($DataCount -lt 2){ throw "data error (not enough data)" }
        [string]$DataTitle = $Data[0]
        
        [int]$IndexName = $DataTitle.IndexOf('VPN Location Name')
        [int]$IndexId = $DataTitle.IndexOf('VPN Location Id')
        if( ($IndexName -eq -1) -Or ($IndexId -eq -1) ){ throw "invalid data - cannot find title" }

        
    }

    process {
        foreach ($line in $Data) {
            # Match lines that end with a numeric ID
            if ($line -match '(.+)\s+(\d+)$') {
                $location = $matches[1].Trim()
                $id = [int]$matches[2]
                $result += [PSCustomObject]@{
                    ServerID       = $id
                    ServerLocation = $location
                }
            }
        }
    }

    end {
        # Output the result array
        $result
    }
}

function Test-CommandSucceeded{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline=$true, Position=0)]
        [PSCustomObject]$CommandResult
    )
    $ecode = $Res.ExitCode
    if($ecode -eq $Null){throw "invalid object - no ExitCode property"}
    return ($ecode -eq 0)
}


function Test-CommandFailed{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline=$true, Position=0)]
        [PSCustomObject]$CommandResult
    )
    $ecode = $Res.ExitCode
    if($ecode -eq $Null){throw "invalid object - no ExitCode property"}
    return ($ecode -ne 0)
}


function Out-CommandFailed{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline=$true, Position=0)]
        [PSCustomObject]$CommandResult
    )
    try{
        $CmdArgs = $CommandResult.CmdArgs
        $ExitCode = $CommandResult.ExitCode
        $OutputMessage = $CommandResult.Output
        $ErrorMessage = $CommandResult.Error 
        $ElapsedSeconds = $CommandResult.ElapsedSeconds
        $ElapsedMs = $CommandResult.ElapsedMs
        
        $AllCmd = ''
        $CmdArgs | % { $AllCmd += "$_ " }
        $AllCmd = $AllCmd.Trim()
        Write-Host "[ExpressVPN] " -NoNewLine -f DarkRed 
        Write-Host "Command Failed" -f DarkYellow
        Write-Host "  Cmd: `"$AllCmd`"" -f DarkYellow
        $Duration = "Dur: {0}.{1}ms" -f $ElapsedSeconds, $ElapsedMs
        Write-Host "  $Duration"  -f DarkYellow
        Write-Host "  Out: `"$OutputMessage`"" -f DarkYellow
        Write-Host "  Err: `"$ErrorMessage`"" -f DarkYellow
    }catch{
        Write-Error "$_"
    }
}