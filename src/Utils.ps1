#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   Utils.ps1                                                                    ║
#║   Utils - part of the docker powershell module                                 ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝

# Example usage:
# Test-OpenPorts -ServerAddress "10.0.0.111" -Ports @(8000, 9000, 9443) -Timeout 1000

function Test-PortainerPorts { 
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $Server=Get-DefaultDockerServer
    Test-OpenPorts -ServerAddress "$Server" -Ports @(8000, 9000, 9443) -Timeout 50
}


function Test-OpenPorts {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory=$true, Position = 0, HelpMessage="The server address") ]
        [string]$ServerAddress,
        [Parameter(Mandatory=$false, Position = 1, HelpMessage="The ports") ]
        [int[]]$Ports = @(8000, 9000, 9443),
        [Parameter(Mandatory=$false, HelpMessage="Timeout in milliseconds") ]
        [int]$Timeout = 100 # im on the LAN
    )

    try{
        # Array to store jobs
        $jobs = @()

        # Start a job for each port to check its connectivity with async timeout
        foreach ($port in $Ports) {
            $jobs += Start-Job -ScriptBlock {
                param ($server, $port, $timeout)
                try {
                    $tcpClient = [System.Net.Sockets.TcpClient]::new()
                    $connectTask = $tcpClient.ConnectAsync($server, $port)
                    $completed = $connectTask.Wait($timeout)
                    
                    if ($completed -and $tcpClient.Connected) {
                        $tcpClient.Close()
                        return $true
                    } else {
                        return $false
                    }
                } catch {
                    return $false
                }
            } -ArgumentList $ServerAddress, $port, $Timeout
        }
        $ErrorOccured = $False
        # Wait for all jobs to complete
        try{
            $jobs | ForEach-Object { $OutJob = Wait-Job -Job $_ }
        }catch{
            $ErrorOccured = $True
        }
        # Retrieve results and clean up jobs
        $portCheckResults = $jobs | ForEach-Object {
            $result = Receive-Job -Job $_
            Remove-Job -Job $_
            $result
        }
        if($ErrorOccured){ return $False }
        # Check if all results are $true
        return ($portCheckResults -notcontains $false)
    }catch{
        Show-ExceptionDetails $_
    }
}




function Invoke-ParseDockerPsOutput {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string[]]$Out
    )
    try{
        # Determine the maximum line length and pad all lines to this length
        $maxLength = ($Out | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum

        # Pad each line to ensure uniform length
        $Out = $Out | ForEach-Object { $_.PadRight($maxLength) }

        # Parse header line to get column positions
        $header = $Out[0]
        $positions = @{
            'CONTAINER ID' = $header.IndexOf('CONTAINER ID')
            'IMAGE'        = $header.IndexOf('IMAGE')
            'COMMAND'      = $header.IndexOf('COMMAND')
            'CREATED'      = $header.IndexOf('CREATED')
            'STATUS'       = $header.IndexOf('STATUS')
            'PORTS'        = $header.IndexOf('PORTS')
            'NAMES'        = $header.IndexOf('NAMES')
        }

        # Get column widths based on the next column's start position
        $widths = @{
            'CONTAINER ID' = $positions['IMAGE'] - $positions['CONTAINER ID']
            'IMAGE'        = $positions['COMMAND'] - $positions['IMAGE']
            'COMMAND'      = $positions['CREATED'] - $positions['COMMAND']
            'CREATED'      = $positions['STATUS'] - $positions['CREATED']
            'STATUS'       = $positions['PORTS'] - $positions['STATUS']
            'PORTS'        = $positions['NAMES'] - $positions['PORTS']
            'NAMES'        = ($header.Length - $positions['NAMES'])
        }
    
        # Helper function to parse time strings into TimeSpan
        function Convert-ToTimeSpan($timeString) {
            if ($timeString -match '(\d+)\s+seconds?') {
                return [TimeSpan]::FromSeconds([double]$matches[1])
            } elseif ($timeString -match '(\d+)\s+minutes?') {
                return [TimeSpan]::FromMinutes([double]$matches[1])
            } elseif ($timeString -match '(\d+)\s+hours?') {
                return [TimeSpan]::FromHours([double]$matches[1])
            } elseif ($timeString -match '(\d+)\s+days?') {
                return [TimeSpan]::FromDays([double]$matches[1])
            } else {
                return [TimeSpan]::Zero
            }
        }


        # Parse each line into objects
        $parsedOutput = $Out[1..($Out.Count - 1)] | ForEach-Object {
            $PortsString = $_.Substring($positions['PORTS'], $widths['PORTS']).Trim()
            Write-Verbose "PortsString = $PortsString"
            if([string]::IsNullOrEmpty($PortsString)){
                $ContainerPorts = ''
            }else{
                $ContainerPorts = Convert-ToContainerPorts -InputString $PortsString
            }
            
            [pscustomobject]@{
                'CONTAINER ID' = $_.Substring($positions['CONTAINER ID'], $widths['CONTAINER ID']).Trim()
                'IMAGE'        = $_.Substring($positions['IMAGE'], $widths['IMAGE']).Trim()
                'COMMAND'      = $_.Substring($positions['COMMAND'], $widths['COMMAND']).Trim()
                'CREATED'      =  Convert-ToTimeSpan ( $_.Substring($positions['CREATED'], $widths['CREATED']).Trim() ) 
                'STATUS'       =  Convert-ToTimeSpan ( $_.Substring($positions['STATUS'], $widths['STATUS']).Trim() )
                'PORTS'        =  $ContainerPorts
                'NAMES'        = $_.Substring($positions['NAMES'], $widths['NAMES']).Trim()
            }
        }

        return $parsedOutput
    }catch{
        Show-ExceptionDetails ($_) -ShowStack
    }
}


function Invoke-DockerPs { 
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $False)]
        [string]$Server
    )
    try{
        $Remote = ''
        if([string]::IsNullOrEmpty($Server)){
            $Remote = Get-DefaultDockerServer
        }else{
            $Remote = $Server
        }
        $SshExe = (Get-Command 'ssh.exe').Source
        Write-Verbose "ssh.exe is `"$SshExe`""
        if([string]::IsNullOrEmpty($Remote)){ throw "$_" }
        Write-Verbose "Running 'docker ps' on server `"$Remote`""
        &"$SshExe" "$Remote" 'docker ps' *> "$ENV:Temp\outssh.log"
        [string[]]$Out = Get-Content "$ENV:Temp\outssh.log"
        try{
            if($Out -match 'Is the docker daemon running'){ throw "not running" }
            Invoke-ParseDockerPsOutput -Out $Out
        }catch{
            Write-Warning "Docker Not Running"
        }
    }catch{
        Show-ExceptionDetails ($_) -ShowStack
    }
}


function Convert-ToContainerPorts {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$InputString
    )

    # Use regex to extract port mappings and their protocol
    $regex = '(\d+)->(\d+)/(tcp|udp)'
    $matches = [regex]::Matches($InputString, $regex)

    # Initialize a hash set to track unique entries
    $uniqueEntries = @{}
    $result = @()

    foreach ($match in $matches) {
        # Extract host port, container port, and protocol
        $hostPort = [int]$match.Groups[1].Value
        $containerPort = [int]$match.Groups[2].Value
        $protocol = $match.Groups[3].Value

        # Create a unique key for the entry
        $key = "$hostPort|$containerPort|$protocol"

        # Add only unique entries
        if (-not $uniqueEntries.ContainsKey($key)) {
            $uniqueEntries[$key] = $true
            $result += [PSCustomObject]@{
                HostPort      = $hostPort
                ContainerPort = $containerPort
                Protocol      = $protocol
            }
        }
    }

    # Return the array of unique PSCustomObjects
    return $result
}





function Get-OpenVpnExePath { 
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $False)]
        [string]$Server
    )
    try{
        $RegPath = "HKLM:\SOFTWARE\OpenVPN"

        $Prop = (Get-ItemProperty -Path $Path -ErrorAction Stop )
        if($Null -eq $Prop){ throw "Error looking up property in registry $RegPath" }
        $Value =  $Prop | Select-Object -ExpandProperty 'exe_path'
        return $Value

    } catch {
        return $null
    }
}


function Get-OpenVpnSiteList { 
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $False)]
        [string]$Server
    )
    try{
        $RegPath = "HKLM:\SOFTWARE\OpenVPN"

        $Prop = (Get-ItemProperty -Path $Path -ErrorAction Stop )
        if($Null -eq $Prop){ throw "Error looking up property in registry $RegPath" }
        $Value =  $Prop | Select-Object -ExpandProperty 'exit_nodes_list'
        $JsonData = $Value | ConvertFrom-Json
        return $JsonData

    } catch {
        return $null
    }
}





function Get-OpenVpnDefaultConfigPath { 
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $False)]
        [string]$Server
    )
    try{
        $RegPath = "HKLM:\SOFTWARE\OpenVPN"

        $Prop = (Get-ItemProperty -Path $Path -ErrorAction Stop )
        if($Null -eq $Prop){ throw "Error looking up property in registry $RegPath" }
        $Value =  $Prop | Select-Object -ExpandProperty 'default_config_path'
        return $Value

    } catch {
        return $null
    }
}



