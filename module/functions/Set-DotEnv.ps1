<#
 .Synopsis
  Load environment variables from local .env file

 .Description
  Searches for local .env files and loads the defined environment variables
  into the current environement. The search for environemnt files can also
  be done recursively across all parent directories.

  Already existing variables are only overwritten if the `-Force` parameter
  is given.

 .Parameter Path
  The path to the .env file that should be processed.

 .Parameter Environment
  This parameter can be used to define different execution environements
  (e.g. differentiate between run-time locations or between dev and prod
  environment).

  With this communale settings can be kept in the default file and only
  the ones that differ need to be put into the respective second file.

  If provided the 'Environment' value will be used to search for additional
  environment files that take precedence over the settings in the default
  file.

  E.g: `-Environment dev` searches also for `.env.dev`

 .Parameter Recurse
  The `.env` files are searched for from the current working directory up until
  one is found. Then the search is aborted.

  Again: within a directory level, the `.env.<env>` files takes precedence
  over the default `.env` file.

 .Parameter PassThru
  returns the added and overwritten environment variables with their values.
  This can be used to completely restore the original environment

 .Parameter Force
  Already existing environment variables will be overwritten. Default is to
  keep the values of existing variables.

 .Example
  Set-DotEnv -Force -Environment dev -Recurse
  Search for .env and .env.dev files in the current and all parent directories
  until one is found and set environment variables accordingly.

 .Link
  Restore-DotEnv
#>
function Set-DotEnv {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Environment')]
    [OutputType([System.Object[]])]
    param(
        [Parameter(ParameterSetName = 'Path')]
        [string]$Path,
        [Parameter(ParameterSetName = 'Environment')]
        [string]$Environment,
        [Parameter(ParameterSetName = 'Environment')]
        [switch]$Recurse,
        [switch]$PassThru,
        [switch]$Force
    )

    if ($PSCmdlet.ParameterSetName -eq 'Environment') {
        $searchDir = Get-Item (Get-Location)
        $pattern = "(^\.env$)|(^\.env\.$Environment$)"
        do {
            Write-Verbose "looking in $searchDir..."
            $envfiles = @(Get-ChildItem $searchDir.FullName -File | Where-Object { $_.Name -match $pattern }) | Sort-Object -Descending
            $searchDir = $searchDir.Parent
        } while ($envfiles.Count -eq 0 -and $searchDir -and $Recurse)
        "Found $($envfiles.Count) .env files:" | Write-Verbose
        $envfiles.FullName | Write-Verbose

    }
    else {
        $envfiles = Resolve-Path $Path
    }

    $dotenv_added_vars = @{}      # a special var that tells us what we added
    $dotenv_overwritten_vars = @{} # a special var that tells us what we've overwritten

    foreach ($file in $envfiles) {
        Write-Debug "processing file: $file"

        foreach ($line in Get-Content $file) {
            $line = $line.Trim()

            if ($line -eq '' -or $line -like '#*') {
                continue
            }

            $key, $value = ($line -split '=', 2).Trim()

            if ($value -like '"*"') {
                # expand \n to `n for double quoted values
                $value = $value -replace '^"|"$', '' -replace '(?<!\\)(\\n)', "`n"
            }
            elseif ($value -like "'*'") {
                $value = $value -replace "^'|'$", ''
            }

            if ( -not (Test-Path env:\$key) -or $Force ) {
                # save only orignal value == when overwritten the first time
                if ((Test-Path env:\$key) -and -not $dotenv_added_vars.ContainsKey($key) ) {
                    Write-Verbose "Saving already existing env variable '$key=$value'"
                    $value_old = [System.Environment]::GetEnvironmentVariable($key)
                    $dotenv_overwritten_vars[$key] = $value_old
                }
                else {
                    $dotenv_added_vars[$key] = $value
                }
                if ($PSCmdlet.ShouldProcess("`$env:$key", "Set to value '$value'")) {
                    Write-Verbose "Setting DotEnv '$key' with value '$value'"
                    [System.Environment]::SetEnvironmentVariable($key, $value)
                }
            }
        }
    }

    $env:dotenv_overwritten_vars = $dotenv_overwritten_vars.keys -join (",")
    $env:dotenv_added_vars = $dotenv_added_vars.keys -join (",")

    if ($PassThru) {
        Write-Verbose "PassThru was specified, returning the array of found vars"
        return [PSCustomObject]@{
            Added       = $dotenv_added_vars
            Overwritten = $dotenv_overwritten_vars
        }
    }
}
