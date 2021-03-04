<#
 .Synopsis
  Load environment variables from local .env file

 .Description
  Searches for local .env files and loads the defined environment variables
  into the current environement. The search for environemnt files can also
  be done recursively across all parent directories.

  Already existing variables are only overwritten if the `-AllowClobber` parameter
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

 .Parameter Up
  The `.env` files are searched for from the current working directory up until
  one is found. Then the search is aborted.

  Again: within a directory level, the `.env.<env>` files takes precedence
  over the default `.env` file.

 .Parameter PassThru
  returns the added and overwritten environment variables with their values.
  This can be used to completely restore the original environment

 .Parameter AllowClobber
  Already existing environment variables will be overwritten. Default is to
  keep the values of existing variables.

 .Example
  Push-DotEnv -AllowClobber -Environment dev -Up
  Search for .env and .env.dev files in the current and all parent directories
  until one is found and set environment variables accordingly.

 .Link
  Pop-DotEnv
#>
function Push-DotEnv {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Environment')]
    [OutputType([Hashtable])]
    param(
        [Parameter(ParameterSetName = 'Path', Position = 1)]
        [string]$Path,
        [Parameter(ParameterSetName = 'Environment')]
        [string]$Environment,
        [Parameter(ParameterSetName = 'Environment')]
        [switch]$Up,
        [switch]$AllowClobber,
        [switch]$PassThru
    )

    if ($PSCmdlet.ParameterSetName -eq 'Environment') {
        $searchDir = Get-Item (Get-Location)
        $pattern = "(^\.env$)|(^\.env\.$Environment$)"
        do {
            Write-Verbose "looking in $searchDir..."
            $envfiles = @(Get-ChildItem $searchDir.FullName -File | Where-Object { $_.Name -match $pattern }) | Sort-Object
            $searchDir = $searchDir.Parent
        } while ($envfiles.Count -eq 0 -and $searchDir -and $Up)
        "Found $($envfiles.Count) .env files:" | Write-Verbose
        $envfiles.FullName | Write-Verbose

    }
    else {
        $envfiles = Resolve-Path $Path
    }

    $newEnv = @{}
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

            $newEnv[$key] = $value
        }
    }

    $previousValues = @{
        DOTENV_PREVIOUS = $env:DOTENV_PREVIOUS
    }
    foreach ($item in $newEnv.GetEnumerator()) {
        if ( -not (Test-Path "Env:\$($item.Name)") -or $AllowClobber ) {
            if ($PSCmdlet.ShouldProcess("`$env:$($item.Name)", "Set value to '$($item.Value)'")) {
                $previousValues[$item.Name] = [System.Environment]::GetEnvironmentVariable($item.Name)
                [System.Environment]::SetEnvironmentVariable($item.Name, $item.Value)
            }
        }
    }

    if ($PSCmdlet.ShouldProcess('$env:DOTENV_PREVIOUS', "Push previous env values")) {
        $env:DOTENV_PREVIOUS = $previousValues | ConvertTo-Json -Compress
    }

    if ($PassThru) {
        Write-Verbose "PassThru was specified, returning the array of found vars"
        return $previousValues
    }
}
