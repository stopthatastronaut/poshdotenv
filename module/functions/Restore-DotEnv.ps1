<#
.SYNOPSIS
Restore-DotEnv removes environment variables previously loaded by Set-DotEnv
AND restores overwritten ones. Needs as input the return value from `Set-DotEnv -returnvars`.
#>
function Restore-DotEnv {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [Hashtable]$returnvars
    )

    Write-Verbose "Removing updated env vars"
    $returnvars.added.keys | ForEach-Object {
        Remove-Item "ENV:/$_" -ErrorAction SilentlyContinue
    }
    Write-Verbose "Restore overwritten env vars"
    $returnvars.overwritten.GetEnumerator() | ForEach-Object {
        [System.Environment]::SetEnvironmentVariable($_.Name, $_.Value)
    }

    Remove-Item "ENV:/dotenv_added_vars" -ErrorAction SilentlyContinue
    Remove-Item "ENV:/dotenv_overwritten_vars" -ErrorAction SilentlyContinue

}
