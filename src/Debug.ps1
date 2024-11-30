
set-Variable -Name "DebugShowStack" -Value $False -Scope Global -Force -Option AllScope,ReadOnly -Visibility Public -ErrorAction Ignore

function Out-DumpTable {     # NOEXPORT
    [CmdletBinding(SupportsShouldProcess)]
     param(
         [Parameter(Mandatory=$true,ValueFromPipeline=$true, 
            HelpMessage="hash table") ]
         [Hashtable]$Table
     )
 
    try{
        $Table.Keys.ForEach({"$_ = $($Table.$_)"}) -join ' | '
    } catch {
        Show-ExceptionDetails($_) -ShowStack
    }
}

