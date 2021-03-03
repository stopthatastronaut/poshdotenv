<#
.SYNOPSIS
Pop-DotEnv removes environment variables previously loaded by Push-DotEnv
AND restores overwritten ones. Needs as input the return value from `Push-DotEnv -PassThru`.
#>
function Pop-DotEnv {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if (-not $env:DOTENV_PREVIOUS) {
        return
    }
    $InputObject = @{}
    ($env:DOTENV_PREVIOUS | ConvertFrom-Json).PSObject.Properties |
        ForEach-Object { $InputObject[$_.Name] = $_.Value }

    foreach ($item in $InputObject.GetEnumerator()) {
        if ($PSCmdlet.ShouldProcess("`$env:$($item.Name)", "Set value to '$($item.Value)'")) {
            [System.Environment]::SetEnvironmentVariable($item.Name, $item.Value)
        }
    }
}
