<#
.SYNOPSIS
Set-DotEnv loads from local .ENV files
#>
Function Set-DotEnv {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.Object[]])]
    param(
        [switch]$recurse, #NYI
        [string]$path = './.env',
        [switch]$returnvars
    )
    $dotenv_added_vars = @() # a special var that tells us what we added
    $linecursor = 0

    $content = Get-Content $path -ErrorAction SilentlyContinue # if i doesn't exist, forget it

    $content | ForEach-Object { # go through line by line
        [string]$line = $_.trim() # trim whitespace
        if ($line -like "#*") {
            # it's a comment
            Write-Verbose "Found comment $line at line $linecursor. discarding"
        }
        elseif ($line -eq "") {
            # it's a blank line
            Write-Verbose "Found a blank line at line $linecursor, discarding"
        }
        else {
            # it's not a comment, parse it
            # find the first '='
            $eq = $line.IndexOf('=')
            $fq = $eq + 1
            $ln = $line.Length
            Write-Verbose "Found an assignment operator at position $eq in a string of length $ln on line $linecursor"

            $key = $line.Substring(0, $eq).trim()
            $value = $line.substring($fq, $line.Length - $fq).trim()
            Write-Verbose "Found $key with value $value"

            if ($value -match "`'|`"") {
                Write-Verbose "`tQuoted value found, trimming quotes"
                $value = $value.trim('"').trim("'")
                Write-Verbose "`tValue is now $value"
            }

            [System.Environment]::SetEnvironmentVariable($key, $value)

            $dotenv_added_vars += @{$key = $value }
            $env:dotnetenv_added_vars = ($dotenv_added_vars.keys -join (","))
        }
        $linecursor++
    }

    if ($returnvars) {
        Write-Verbose "returnvars was specified, returning the array of found vars"
        return $dotenv_added_vars
    }

}

<#
.SYNOPSIS
REmove-DotEnv removes environmetn variabels previously loaded by Set-DotEnv from local .ENV files
#>
Function Remove-DotEnv {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    Write-Verbose "Removing env vars"

    $addedvars = $env:dotnetenv_added_vars
    $addedvars.split(",") | ForEach-Object {
        Remove-Item "ENV:/$_" -ErrorAction SilentlyContinue
    }

    Remove-item "ENV/:dotenv_added_vars" -ErrorAction SilentlyContinue

}

Export-ModuleMember @('Set-DotEnv', 'Remove-DotEnv')