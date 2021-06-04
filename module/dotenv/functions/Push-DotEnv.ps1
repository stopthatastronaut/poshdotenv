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
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Name')]
    [OutputType([Hashtable])]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Path', Position = 0)]
        [string]$Path,
        [Parameter(ParameterSetName = 'Name', Position = 0)]
        [string]$Name = '.env',
        [Parameter(ParameterSetName = 'Name', Position = 1)]
        [string]$Environment,
        [Parameter(ParameterSetName = 'Name')]
        [switch]$Up,
        [switch]$AllowClobber,
        [switch]$PassThru
    )

    if ($PSCmdlet.ParameterSetName -eq 'Name') {
        $pattern = "(^$([regex]::Escape($Name))$)"
        if ($Environment) { $pattern += "|(^$([regex]::Escape("$Name.$Environment"))$)" }

        $searchDir = Get-Item (Get-Location)
        do {
            Write-Verbose "looking in $($searchDir.FullName)..."
            $envfiles = @(Get-ChildItem $searchDir.FullName -File -Hidden | Where-Object { $_.Name -match $pattern }) | Sort-Object
            $searchDir = $searchDir.Parent
        } while ($envfiles.Count -eq 0 -and $searchDir -and $Up)
        "Found $($envfiles.Count) .env files:" | Write-Verbose
        $envfiles | Write-Verbose
    }
    else {
        $envfiles = Resolve-Path $Path
    }

    if (-not $envfiles) { return }

    $newEnv = @{}
    foreach ($file in $envfiles) {
        Write-Debug "processing file: $file"

        foreach ($line in $file | Get-Content) {
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
        if ( (Test-Path "Env:/$($item.Name)") -eq $false -or $AllowClobber -eq $true ) {
            if ($PSCmdlet.ShouldProcess("`$env:$($item.Name)", "Set value to '$($item.Value)'")) {
                $previousValues[$item.Name] = if (Test-Path "Env:/$($item.Name)") {
                    Get-Item "Env:/$($item.Name)" | Select-Object -expand Value
                }
                else {
                    ""
                }
                Set-Item -Path "Env:/$($item.Name)" -Value $item.Value
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
