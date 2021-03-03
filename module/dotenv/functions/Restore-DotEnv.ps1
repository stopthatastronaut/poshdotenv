<#
.SYNOPSIS
Restore-DotEnv removes environment variables previously loaded by Set-DotEnv
AND restores overwritten ones. Needs as input the return value from `Set-DotEnv -PassThru`.
#>
function Restore-DotEnv {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(ValueFromPipeline)]
        [Hashtable]$InputObject
    )

    Process {
        if (-not $InputObject) {
            if (-not $env:DOTENV_PREVIOUS) {
                return
            }
            $InputObject = @{}
            ($env:DOTENV_PREVIOUS | ConvertFrom-Json).PSObject.Properties |
                ForEach-Object { $InputObject[$_.Name] = $_.Value }
        }
        $InputObject.GetEnumerator() |
            ForEach-Object -Begin {
                Write-Verbose "Removing updated env vars"
            } -Process {
                if ($PSCmdlet.ShouldProcess("`$env:$($_.Name)", "Set value to '$($_.Value)'")) {
                    [System.Environment]::SetEnvironmentVariable($_.Name, $_.Value)
                }
            }

        $env:DOTENV_PREVIOUS = $null
    }
}
