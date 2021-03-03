<#
.SYNOPSIS
Restore-DotEnv removes environment variables previously loaded by Set-DotEnv
AND restores overwritten ones. Needs as input the return value from `Set-DotEnv -PassThru`.
#>
function Restore-DotEnv {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSCustomObject]$InputObject
    )

    Process {
        $InputObject.Added.GetEnumerator() |
            ForEach-Object -Begin {
                Write-Verbose "Removing updated env vars"
            } -Process {
                Remove-Item "Env:/$($_.Name)" -ErrorAction SilentlyContinue
            }
        $InputObject.Overwritten.GetEnumerator() |
            ForEach-Object -Begin {
                Write-Verbose "Restore overwritten env vars"
            } -Process {
                [System.Environment]::SetEnvironmentVariable($_.Name, $_.Value)
            }
    }
}
