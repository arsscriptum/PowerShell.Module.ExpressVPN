
#===============================================================================
# LogConfiguration
#===============================================================================

function Write-ExpressVPNInitLog{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $True, Position=0)]
        [string]$Message,
        [Parameter(Mandatory = $False)]
        [Alias('i')]
        [switch]$Important,
        [Parameter(Mandatory = $False)]
        [Alias('s')]
        [switch]$Success,
        [Parameter(Mandatory = $False)]
        [Alias('h')]
        [switch]$Highlight
    )
    try{
        [string]$fcolor1 = 'DarkCyan'
        [string]$fcolor2 = 'DarkGray'
        [string]$bcolor1 = $Host.UI.RawUI.BackgroundColor
        if($Success){
            [string]$fcolor1 = 'DarkCyan'
            [string]$fcolor2 = 'DarkGreen'
        }elseif($Important){
            [string]$fcolor1 = 'DarkRed'
            [string]$fcolor2 = 'DarkYellow'
        }elseif($Highlight){
            [string]$fcolor1 = 'DarkRed'
            [string]$fcolor2 = 'White'
            [string]$bcolor1 = 'Blue'
        }
        
        Write-Host "[ExpressVPN Module Initialization] " -NoNewLine -f DarkRed -b $bcolor1
        Write-Host "$Message" -f DarkYellow -b $bcolor1
    }catch{
        Show-ExceptionDetails ($_) -ShowStack 
    }
}


function Write-ExpressVPNLog{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $True, Position=0)]
        [string]$Message,
        [Parameter(Mandatory = $False)]
        [Alias('i')]
        [switch]$Important,
        [Parameter(Mandatory = $False)]
        [Alias('s')]
        [switch]$Success,
        [Parameter(Mandatory = $False)]
        [Alias('h')]
        [switch]$Highlight
    )
    try{
        [string]$fcolor1 = 'DarkCyan'
        [string]$fcolor2 = 'DarkGray'
        [string]$bcolor1 = $Host.UI.RawUI.BackgroundColor
        [string]$bcolor2 = $Host.UI.RawUI.BackgroundColor
        if($Success){
            [string]$fcolor1 = 'DarkCyan'
            [string]$fcolor2 = 'DarkGreen'
        }elseif($Important){
            [string]$fcolor1 = 'DarkRed'
            [string]$fcolor2 = 'DarkYellow'
        }elseif($Highlight){
            [string]$fcolor1 = 'Blue'
            [string]$fcolor2 = 'White'
        }
        
        Write-Host "[SpeedTest] " -NoNewLine -f $fcolor1 -b $bcolor1
        Write-Host "$Message" -f $fcolor2 -b $bcolor2
    }catch{
        Show-ExceptionDetails ($_) -ShowStack 
    }
}

