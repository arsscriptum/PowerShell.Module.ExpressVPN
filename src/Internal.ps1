#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   Internals.ps1                                                                ║
#║   Internals  - part of the docker powershell module                            ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝


function New-RandomFile { 
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Path = "$ENV:Temp",
        [Parameter(Mandatory=$false)]
        [string]$Extension = 'tmp',
        [Parameter(Mandatory=$false)]
        [int]$MaxLen = 6,
        [Parameter(Mandatory=$false)]
        [switch]$CreateFile,
        [Parameter(Mandatory=$false)]
        [switch]$CreateDirectory
    )
    try{
        if($MaxLen -lt 4)   {   throw "MaxLen must be between 4 and 36" }
        if($MaxLen -gt 36)  {   throw "MaxLen must be between 4 and 36" }

        [string]$filepath   = $Null
        [string]$rname      = (New-Guid).Guid
        [int]$rval          = Get-Random -Minimum 0 -Maximum 9
        [string]$rname      = $rname.replace('-',"$rval")
        [string]$rname      = $rname.SubString(0,$MaxLen) + '.' + $Extension

        if($CreateDirectory -eq $true){
            [string]$rdirname = (New-Guid).Guid
            $newdir = Join-Path "$Path" $rdirname

            $Null = New-Item -Path $newdir -ItemType "Directory" -Force -ErrorAction Ignore
            $filepath = Join-Path "$newdir" "$rname"
        }
        $filepath = Join-Path "$Path" $rname
        Write-Verbose "Generated filename: $filepath"

        if($CreateFile -eq $true){
            Write-Verbose "CreateFile option: creating file: $filepath"
            $Null = New-Item -Path $filepath -ItemType "File" -Force -ErrorAction Ignore
        }
        return $filepath

    }catch{
        Show-ExceptionDetails $_ -ShowStack
    }
 } 




function Invoke-ExpressVpnCommand{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $False, Position=0)]
        [string[]]$CommandArguments,
        [Parameter(Mandatory = $False)]
        [switch]$Elevate
    )
    try{
        [bool]$RunAsAdministrator = $False
        if(-not(Get-CurrentContext)){
            if($Elevate){
                [bool]$RunAsAdministrator = $True
            }else{
                throw "need to be administrator!"
            }
        }
        $ExpressVpnCli = "C:\Program Files (x86)\ExpressVPN\services\ExpressVPN.CLI.exe"

        $FNameOut = New-RandomFile -Extension 'log' -CreateDirectory
        $FNameErr = New-RandomFile -Extension 'log' -CreateDirectory
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        if($RunAsAdministrator){
            $cmd = Start-Process -FilePath $ExpressVpnCli -ArgumentList $CommandArguments -PassThru -Wait -Verb RunAs -RedirectStandardOutput $FNameOut 
        }else{
            $cmd = Start-Process -FilePath $ExpressVpnCli -ArgumentList $CommandArguments -NoNewWindow -PassThru -Wait -RedirectStandardError $FNameErr -RedirectStandardOutput $FNameOut
        }

        $ElapsedSeconds     =   $stopwatch.Elapsed.Seconds
        $ElapsedMs          =   $stopwatch.Elapsed.Milliseconds
        $cmdExitCode        =   $cmd.ExitCode
        $cmdId              =   $cmd.Id 
        $cmdHasExited       =   $cmd.HasExited 
        $cmdTotalCpuTime    =   $cmd.TotalProcessorTime 

        $stdOut = Get-Content -Path $FNameOut -Raw
        $stdErr = Get-Content -Path $FNameErr -Raw

        if ([string]::IsNullOrEmpty($stdOut) -eq $false) {
            $stdOut = $stdOut.Trim()
        }
        if ([string]::IsNullOrEmpty($stdErr) -eq $false) {
            $stdErr = $stdErr.Trim()
        }
        Write-Verbose -Message "Results cmdExitCode $cmdExitCode cmdId $cmdId cmdName $cmdName"
        $res = [PSCustomObject]@{
                CmdArgs            = $CommandArguments
                HasExited          = $cmdHasExited
                TotalProcessorTime = $cmdTotalProcessorTime
                Id                 = $cmdId
                ExitCode           = $cmdExitCode
                Output             = $stdOut
                Error              = $stdErr
                ElapsedSeconds     = $stopwatch.Elapsed.Seconds
                ElapsedMs          = $stopwatch.Elapsed.Milliseconds
        }
            
        return $res
    }catch{
        Show-ExceptionDetails ($_) -ShowStack 
    }
}

function Start-VpnModuleTest { 
    [CmdletBinding(SupportsShouldProcess)]
    param()
    try{
        $MsgTitle = "PowerShell ExpressVPN Module Test Script"
        $MsgText = @"
This is a test for the PowerShell ExpressVPN Module. Do you want to continue the test script ?`n`n`t- If you press `"Yes`", the test continues.`n`t- If you choose `"No`" the test will stop.`n`t- Press `"Cancel`" to cancel the test.
"@
        [string]$Result = New-MessageBox -Message $MsgText -Title $MsgTitle -Buttons YesNoCancel -Icon Question -ShowOnTop

        if($Result -eq 'Yes'){
            # Yes
            Invoke-ExpressVpnCommand -CommandArguments @('disconnect') -Elevate
        }elseif($Result -eq 'No'){
            # No
        }else{
            # Cancel
        }
    }catch{

    }
 } 


Start-VpnModuleTest 