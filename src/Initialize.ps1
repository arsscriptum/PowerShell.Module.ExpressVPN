#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   Initialize-ExpressVPNModule.ps1                                              ║
#║                                                                                ║
#║   ExpressVPN Setup Script                                                      ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝




function Test-IsExpressVpnInstalled {
    <#
    .SYNOPSIS
        Retrieves a list of all software installed
    .EXAMPLE
        Get-InstalledSoftware
        
        This example retrieves all software installed on the local computer
    .PARAMETER Name
        The software title you'd like to limit the query to.
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding()]
    param ()

    [string[]]$UninstallKeys = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    $null = New-PSDrive -Name HKU -PSProvider Registry -Root Registry::HKEY_USERS
    $UninstallKeys += Get-ChildItem HKU: -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'S-\d-\d+-(\d+-){1,14}\d+$' } | ForEach-Object { "HKU:\$($_.PSChildName)\Software\Microsoft\Windows\CurrentVersion\Uninstall" }
    if (-not $UninstallKeys) {
        Write-Verbose -Message 'No software registry keys found'
    } else {
        $List = foreach ($UninstallKey in $UninstallKeys) {
            if ($PSBoundParameters.ContainsKey('Name')) {
                $WhereBlock = { ($_.PSChildName -match '^{[A-Z0-9]{8}-([A-Z0-9]{4}-){3}[A-Z0-9]{12}}$') -and ($_.GetValue('DisplayName') -imatch $Name) }
            } else {
                $WhereBlock = { ($_.PSChildName -match '^{[A-Z0-9]{8}-([A-Z0-9]{4}-){3}[A-Z0-9]{12}}$') -and ($_.GetValue('DisplayName')) }
            }
            $gciParams = @{
                Path        = $UninstallKey
                ErrorAction = 'SilentlyContinue'
            }
            $selectProperties = @(
                @{n='GUID'; e={$_.PSChildName}}, 
                @{n='Name'; e={$_.GetValue('DisplayName')}}
                @{n='Version'; e={$_.GetValue('Version')}}
                @{n='DisplayVersion'; e={$_.GetValue('DisplayVersion')}}
                @{n='VersionMajor'; e={$_.GetValue('VersionMajor')}}
                @{n='VersionMinor'; e={$_.GetValue('VersionMinor')}}
                @{n='UninstallString'; e={$_.GetValue('UninstallString')}}
                @{n='InstallLocation'; e={$_.GetValue('InstallLocation')}}
            )
            Get-ChildItem @gciParams | Where $WhereBlock | Select-Object -Property $selectProperties | Where Name -eq 'ExpressVPN'
        }

        [bool]$ExpressVpnFound = ( ( $List.Count -gt 0 ) -And ($List.Name.Contains('ExpressVPN') ) )
        return $ExpressVpnFound
    }
    return $False
}



function Initialize-ExpressVPNModule{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true,Position=0)][ValidateNotNullOrEmpty()][String]$Username,
        [Parameter(Mandatory=$true,Position=1)][ValidateNotNullOrEmpty()][String]$Password,
        [Parameter(Mandatory=$true,Position=2)][ValidateNotNullOrEmpty()][String]$Client,
        [Parameter(Mandatory=$true,Position=3)][ValidateNotNullOrEmpty()][String]$Secret,
        [Parameter(Mandatory=$true,Position=4)][ValidateNotNullOrEmpty()][String]$Token
    ) 

    $IsExpressVpnInstalled = Test-IsExpressVpnInstalled
    if(-not $IsExpressVpnInstalled){ throw "could not find expsress vpn installation" }

    $Result = $True

    # 1) Find the ExpressVPN Path

    $ExpressVpnPath = Resolve-ExpressVpnPath
    if( ([string]::IsNullOrEmpty($ExpressVpnPath)) -Or (-not(Test-Path -Path $ExpressVpnPath -PathType Container)) ){ throw "could not Resolve ExpressVpnPath" }

    $ExpressVpnCli = Resolve-ExpressVpnCli
    if( ([string]::IsNullOrEmpty($ExpressVpnCli)) -Or (-not(Test-Path -Path $ExpressVpnCli -PathType Leaf)) ){ throw "could not Resolve ExpressVpnCli" }

    $RegPath = Get-VpnModuleRegistryPath 


    Write-Verbose "RegPath $RegPath"

    Write-Verbose "Writing Registry Values in $RegPath"
    Write-Verbose "New-RegistryValue `"RootPath`" " -s
    $res = New-RegistryValue -Path $RegPath -Name "ExpressVpnPath" -Value  $ExpressVpnPath -Type String
    $res = New-RegistryValue -Path $RegPath -Name "ExpressVpnCli" -Value  $ExpressVpnCli -Type String

    $EnvPath = [Environment]::GetEnvironmentVariable('EXPRESSVPN_PATH',[EnvironmentVariableTarget]::User)
    if(($EnvPath -eq $Null) -And (Test-Path -Path "$ExpressVpnPath" -PathType Container)){
        Write-Verbose "SetEnvironmentVariable `"EXPRESSVPN_PATH`"" 
        [Environment]::SetEnvironmentVariable('EXPRESSVPN_PATH',"$ExpressVpnPath",[EnvironmentVariableTarget]::User)
    }else{
        Write-Verbose "EnvironmentVariable `"EXPRESSVPN_PATH`" OK" 
    }

    $EnvPath = [Environment]::GetEnvironmentVariable('EXPRESSVPN_CLI',[EnvironmentVariableTarget]::User)
    if(($EnvPath -eq $Null) -And (Test-Path -Path "$ExpressVpnCli" -PathType Leaf)){
        Write-Verbose "SetEnvironmentVariable `"EXPRESSVPN_CLI`"" 
        [Environment]::SetEnvironmentVariable('EXPRESSVPN_CLI',"$ExpressVpnCli",[EnvironmentVariableTarget]::User)
    }else{
        Write-Verbose "EnvironmentVariable `"EXPRESSVPN_CLI`" OK" 
    }

    Write-Verbose "Initialize-ExpressVPNModule => Set-PortainerAppCredentials -Client $Client -Secret $Secret"
    $Result = $Result -and (Set-PortainerAppCredentials -Client $Client -Secret $Secret)
    Write-Verbose "Initialize-ExpressVPNModule => Set-PortainerUserCredentials -Username $Username -Password $Password"
    $Result = $Result -and (Set-PortainerUserCredentials -Username $Username -Password $Password)
    Write-Verbose "Initialize-ExpressVPNModule => Set-PortainerAccessToken -Username $Username -Token $Token"
    $Result = $Result -and (Set-PortainerAccessToken -Username $Username -Token $Token)
    if(!$Result) { throw "Error" }
}





function Get-ExpressVpnPath{

    [CmdletBinding(SupportsShouldProcess)]
    param()

    $ExpressVpnPath = [Environment]::GetEnvironmentVariable('EXPRESSVPN_PATH',[EnvironmentVariableTarget]::User)
    if(($ExpressVpnPath -eq $Null) -Or (-not(Test-Path -Path "$ExpressVpnPath" -PathType Container))){
        Write-Verbose "Get-RegistryValue -Path `"$RegPath`" -Name `"ExpressVpnPath`" "
        $ExpressVpnPath = Get-RegistryValue -Path $RegPath -Name "ExpressVpnPath"    
    }

    if(($ExpressVpnPath -eq $Null) -Or (-not(Test-Path -Path "$ExpressVpnPath" -PathType Container))){
        Write-Verbose "Resolve-ExpressVpnPath"
        $ExpressVpnPath = Resolve-ExpressVpnPath
    } 
    return $ExpressVpnPath
}


function Get-ExpressVpnCli{

    [CmdletBinding(SupportsShouldProcess)]
    param()

    $ExpressVpnCli = [Environment]::GetEnvironmentVariable('EXPRESSVPN_CLI',[EnvironmentVariableTarget]::User)
    if(($ExpressVpnCli -eq $Null) -Or (-not(Test-Path -Path "$ExpressVpnCli" -PathType Leaf))){
        Write-Verbose "Get-RegistryValue -Path `"$RegPath`" -Name `"ExpressVpnCli`" "
        $ExpressVpnCli = Get-RegistryValue -Path $RegPath -Name "ExpressVpnCli"    
    }

    if(($ExpressVpnCli -eq $Null) -Or (-not(Test-Path -Path "$ExpressVpnCli" -PathType Leaf))){
        Write-Verbose "Resolve-ExpressVpnCli"
        $ExpressVpnCli = Resolve-ExpressVpnCli
    } 
    return $ExpressVpnCli
}


function Initialize-ExpressVpnModule{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $False, Position=0)]
        [string]$Path = "$PSScriptRoot"
    )
    try{
        
    }catch{
        Show-ExceptionDetails ($_) -ShowStack 
    }
}


function Resolve-ExpressVpnCli{

    [CmdletBinding(SupportsShouldProcess)]
    param()

    $ExpressVpnPath = Resolve-ExpressVpnPath
    if(-not(Test-Path "$ExpressVpnPath")){ throw "missing $ExpressVpnPath" }
    $ExpressVpnCLI = Get-ChildItem -Path $ExpressVpnPath -Depth 2 -File -Filter "*.exe" | Where Name -eq "ExpressVPN.CLI.exe"
    if(($ExpressVpnCLI -ne $Null) -And (Test-Path -Path "$ExpressVpnCLI" -PathType Leaf)){
        return $ExpressVpnCLI
    }
    return $Null
}

function Resolve-ExpressVpnPath{

    [CmdletBinding(SupportsShouldProcess)]
    param()

    $ProgramsDirectories="${ENV:ProgramFiles(x86)}","$ENV:ProgramFiles"
    $ExpressVPNPath = Get-ChildItem -Path $ProgramsDirectories -Depth 0 -Directory | Where Name -eq "ExpressVPN"
    if(($ExpressVPNPath -ne $Null) -And (Test-Path -Path "$ExpressVPNPath" -PathType Container)){
        return $ExpressVPNPath
    }
    return $Null
}

















<#


Function Get-SpeedTestState {
    [CmdletBinding(SupportsShouldProcess)]
    param ()
    try{
        if([string]::IsNullOrEmpty($ENV:OrganizationHKCU)){ throw "missing ENV:OrganizationHKCU" }
        $IsValid = $True
        $ProjectName = "SpeedTest"
        $RegPath = Join-Path $ENV:OrganizationHKCU "$ProjectName"
        $Scripts = "Initialize", "SpeedTest"
        $RootPath = Get-RegistryValue -Path $RegPath -Name "RootPath"
        if(-not(Test-Path "$RootPath")){ throw "missing $RootPath" }
        $Scripts | % { $Base = "$_" ;
            $Filename = "{0}.ps1" -f $Base
            $RegName = "{0}Script" -f $Base
            $Filepath = "{0}\{1}" -f $RootPath,$Filename
            Write-Verbose "[Validate] [$Base] - Checking for script `"$Filename`""
            $RegValue = Get-RegistryValue -Path $RegPath -Name "$RegName"
            Write-Verbose "[Validate] [$Base] - Registry  Value `"$RegValue`""
            Write-Verbose "[Validate] [$Base] - Script Location `"$Filepath`""
            if("$Filepath" -ne "$RegValue"){ throw "$RegValue != $Filepath" }
            if(-not(Test-Path "$Filepath")){ throw "missing $Filepath" }
        }
    }catch{
        $IsValid = $False
        Show-ExceptionDetails ($_) -ShowStack 
    }
    return $IsValid
}


#>

















<#

function Initialize-SpeedTest{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $False, Position=0)]
        [string]$Path = "$PSScriptRoot"
    )
    try{
        $ProjectName = "SpeedTest"
        $RegPath = Join-Path $ENV:OrganizationHKCU "$ProjectName"
        $RootPathInfo = Resolve-Path -Path "$Path"
        [string]$RootPath = $RootPathInfo.Path
        setup_log "Installing SpeedTest from path $RootPath"
        Write-Verbose "RootPath $RootPath"

        [System.IO.FileSystemInfo]$RootPathFs = Get-Item $RootPath


    $EnvPath = [Environment]::GetEnvironmentVariable('EXPRESSVPN_PATH',[EnvironmentVariableTarget]::Machine)
    if(($EnvPath -ne $Null) -And (Test-Path -Path "$EnvPath" -PathType Container)){
        return $EnvPath
    }

        $EnvPath = [Environment]::GetEnvironmentVariable('SpeedTest',[EnvironmentVariableTarget]::User)
        if(($EnvPath -eq $Null) -And (Test-Path -Path "$RootPath" -PathType Container)){
            setup_log "SetEnvironmentVariable `"SpeedTest`"" 
            [Environment]::SetEnvironmentVariable('SpeedTest',"$RootPath",[EnvironmentVariableTarget]::User)
        }else{
            setup_log "EnvironmentVariable `"SpeedTest`" OK" 
        }


        $RegPath = Join-Path $ENV:OrganizationHKCU "$ProjectName"
        Write-Verbose "RegPath $RegPath"

        setup_log "Writing Registry Values in $RegPath"
        setup_log "New-RegistryValue `"RootPath`" " -s
        $res = New-RegistryValue -Path $RegPath -Name "RootPath" -Value  $RootPath -Type String

        $Scripts = "Initialize", "SpeedTest"

        ForEach($script in $Scripts){
            $Filename = "{0}.ps1" -f $script
            $Filepath = "{0}\{1}" -f $RootPath,$Filename
            if(-not(Test-Path -Path "$Filepath" -PathType Leaf)){throw "missing file $Filepath"}
            $reg_entry = "{0}Script" -f $script
            $reg_value = $Filepath
            setup_log "Added Registry entry `"$reg_entry`" Value `"$reg_value`""
            $res = New-RegistryValue -Path $RegPath -Name $reg_entry -Value $reg_value -Kind String
        }

        $FileExe = "{0}\{1}" -f $RootPath,"speedtest.exe"
        if(-not(Test-Path -Path "$Filepath" -PathType Leaf)){throw "missing file $Filepath"}
        $reg_entry = "{0}Script" -f $script
        setup_log "Added Registry entry `"Path`" Value `"$FileExe`""
        $res = New-RegistryValue -Path $RegPath -Name 'Path' -Value $FileExe -Kind String
        $ServerList = "{0}\{1}" -f $RootPath,"serverlist.json"
        $res = New-RegistryValue -Path $RegPath -Name 'ServerList' -Value $ServerList -Kind String
        
    }catch{
        Show-ExceptionDetails ($_) -ShowStack 
    }
}

Function Get-SpeedTestState {
    [CmdletBinding(SupportsShouldProcess)]
    param ()
    try{
        if([string]::IsNullOrEmpty($ENV:OrganizationHKCU)){ throw "missing ENV:OrganizationHKCU" }
        $IsValid = $True
        $ProjectName = "SpeedTest"
        $RegPath = Join-Path $ENV:OrganizationHKCU "$ProjectName"
        $Scripts = "Initialize", "SpeedTest"
        $RootPath = Get-RegistryValue -Path $RegPath -Name "RootPath"
        if(-not(Test-Path "$RootPath")){ throw "missing $RootPath" }
        $Scripts | % { $Base = "$_" ;
            $Filename = "{0}.ps1" -f $Base
            $RegName = "{0}Script" -f $Base
            $Filepath = "{0}\{1}" -f $RootPath,$Filename
            Write-Verbose "[Validate] [$Base] - Checking for script `"$Filename`""
            $RegValue = Get-RegistryValue -Path $RegPath -Name "$RegName"
            Write-Verbose "[Validate] [$Base] - Registry  Value `"$RegValue`""
            Write-Verbose "[Validate] [$Base] - Script Location `"$Filepath`""
            if("$Filepath" -ne "$RegValue"){ throw "$RegValue != $Filepath" }
            if(-not(Test-Path "$Filepath")){ throw "missing $Filepath" }
        }
    }catch{
        $IsValid = $False
        Show-ExceptionDetails ($_) -ShowStack 
    }
    return $IsValid
}

#>