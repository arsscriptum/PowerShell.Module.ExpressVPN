#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   ConfigGetters.ps1                                                            ║
#║   Config Getters - part of the docker powershell module                        ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝



function Get-VpnModuleRegistryPath {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $False, Position=0)]
        [string[]]$ChildPaths,
        [Parameter(Mandatory = $False)]
        [switch]$Create
    )
    if( $ExecutionContext -eq $null ) { throw "not in module"; return "" ; }
    $ModuleName = ($ExecutionContext.SessionState).Module
    $RootPath = "$ENV:OrganizationHKCU\$ModuleName"
   
    $Path = $RootPath
    if($ChildPaths){
        ForEach($child in $ChildPaths){
            $Path = Join-Path $Path $child
        }
    }else{
        Write-Verbose "no arguments"
    }

    if(($Create) -And (-not(Test-Path -Path $Path))){
        Write-Verbose "[Get-VpnModuleRegistryPath] Confirm-RegistryPathExists -RegistryPath $Path"
        Confirm-RegistryPathExists -RegistryPath $Path
    }

    Write-Verbose "[Get-VpnModuleRegistryPath] $Path"
    return $Path
}





function Get-VpnModuleInformation{

        $ModuleName = $ExecutionContext.SessionState.Module
        $ModuleScriptPath = $ScriptMyInvocation = $Script:MyInvocation.MyCommand.Path
        $ModuleScriptPath = (Get-Item "$ModuleScriptPath").DirectoryName
        $CurrentScriptName = $Script:MyInvocation.MyCommand.Name
        $ModuleInformation = @{
            Module        = $ModuleName
            ModuleScriptPath  = $ModuleScriptPath
            CurrentScriptName = $CurrentScriptName
        }
        return $ModuleInformation
}





function Get-VpnAppCredentials {    
    [CmdletBinding(SupportsShouldProcess)]
    param()
    if( $ExecutionContext -eq $null ) { throw "not in module"; return "" ; }
    $ModuleName = ($ExecutionContext.SessionState).Module
    $CredId = "$ModuleName-App"
    $Credz =  Get-AppCredentials $CredId
    
    return $Credz
}

function Get-VpnUserCredentials {    
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if( $ExecutionContext -eq $null ) { throw "not in module"; return "" ; }
    $ModuleName = ($ExecutionContext.SessionState).Module

    $Credz =  Get-AppCredentials $ModuleName
    
    return $Credz
}

