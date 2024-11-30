#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   ConfigSetters.ps1                                                            ║
#║   Config Getters - part of the docker powershell module                        ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝


function Get-ExpressVpnModuleRegistryPath {
    [CmdletBinding(SupportsShouldProcess)]
    param ()
    if( $ExecutionContext -eq $null ) { throw "not in module"; return "" ; }
    $ModuleName = ($ExecutionContext.SessionState).Module
    $Path = "$ENV:OrganizationHKCU\$ModuleName"
   
    return $Path
}




function Set-PortainerAccessToken{   # NOEXPORT
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false, ValueFromPipeline=$true, HelpMessage="Overwrite if present")]
        [String]$Username,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Overwrite if present")]
        [ValidateNotNullOrEmpty()]
        [String]$Token    
    )
    try{
        $RegPath = $BaseRegPath = Get-DockerModuleRegistryPath
        if( $RegPath -eq "" ) { throw "not in module"; }
        
        if($PSBoundParameters.ContainsKey('Username') -eq $False){
            $Username = (Get-PortainerUserCredentials).UserName
        }
         
        if([string]::IsNullOrEmpty($Username)){ throw "PortainerUserCredentials not set. Use Set-PortainerUserCredentials or Initialize-PortainerModule" }

        $RegPath = Join-Path $BaseRegPath $Username
        Write-Verbose "set $RegPath access_token"
        Remove-RegistryValue -Path "$RegPath" -Name 'access_token'
        New-RegistryValue -Path "$RegPath" -Name 'access_token' -Value $Token -Type 'string'
        
    }catch{
         Show-ExceptionDetails $_
    }
}



function Set-PortainerUserCredentials {    # NOEXPORT
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Git Username")]
        [String]$Username,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Git Username")]
        [String]$Password 
    )
    
    if( $ExecutionContext -eq $null ) { throw "not in module"; return "" ; }
    $ModuleName = ($ExecutionContext.SessionState).Module
    Write-Verbose "Register-AppCredentials -Id $ModuleName -Username $Username -Password $Password"
    Register-AppCredentials -Id $ModuleName -Username $Username -Password $Password
    
}
function Set-PortainerAppCredentials {    # NOEXPORT
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Git Username")]
        [String]$Client,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Git Username")]
        [String]$Secret 
        )
    
    if( $ExecutionContext -eq $null ) { throw "not in module"; return "" ; }
    $ModuleName = ($ExecutionContext.SessionState).Module
    $CredId = "$ModuleName-App"
    Write-Verbose "CredId $CredId ModuleName $ModuleName"

    
    Write-Verbose " Register-AppCredentials -Id $CredId -Username $Client -Password $Secret"
    Register-AppCredentials -Id $CredId -Username $Client -Password $Secret
    
}




function Set-DefaultDockerServer {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true)]
        [String]$Server
    )
    try{    
        $RegPath = $BaseRegPath = Get-DockerModuleRegistryPath
        if( $RegPath -eq "" ) { throw "not in module"; }
        
        Remove-RegistryValue -Path "$RegPath" -Name 'default_server'
        New-RegistryValue -Path "$RegPath" -Name 'default_server' -Value $Server -Type 'string'
    }catch{
         Show-ExceptionDetails $_
    }
}
