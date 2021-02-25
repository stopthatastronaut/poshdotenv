<#
.SYNOPSIS
Function Remove-DotEnv removes environment variabels previously loaded by Set-DotEnv.
#>
Function Remove-DotEnv {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    Write-Verbose "Removing env vars"

    $addedvars = $env:dotnetenv_added_vars
    $addedvars.split(",") | ForEach-Object {
        Remove-Item "ENV:/$_" -ErrorAction SilentlyContinue
    }

    Remove-item "ENV:/dotenv_added_vars" -ErrorAction SilentlyContinue
    Remove-item "ENV:/dotenv_overwritten_vars" -ErrorAction SilentlyContinue
}
