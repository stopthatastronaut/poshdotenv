<#
 .Synopsis
  Load environment variables from local .env file

 .Description
  Searches for local .env files and a load the defined environment variables
  into the current environement. The search for environemnt files can also
  be done recursively across all parent directories.

  Already existing variables are only overwritten when the `-Force` parameter
  is given.

 .Parameter Name
  The filename to look for. can be relative or absolute.
  If a relative path is given, the file name can be looked
  for recursively in the parent directories if the `-up`
  paramter ist given.

  Optional, default : '.env'

 .Parameter env
  This parameter can be used to define different execution environements
  (e.g. differentiate between run-time locations or between dev and prod
  environment).

  With this communale settings can be kept in the default file and only
  the ones that differ need to be put into the respective second file.

  If provided the 'env' value will be used to search for additional
  environment files that take precedence over the settings in the default
  file.

  E.g: `-env dev` searches also for `.env.dev`

  Optional, default : disabled

 .Parameter up
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
   # search all
   PS> Set-DotEnv -Force -name localenv -env dev -up

 .Link
  Restore-DotEnv
#>
function Set-DotEnv {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.Object[]])]
    param(
        [string]$name = '.env',
        [string]$env = '',
        [switch]$up,
        [switch]$PassThru,
        [switch]$Force
    )
    # location / environment specific file
    $nameenv = "$name.$env"
    $isNameAbsolute = [System.IO.Path]::IsPathRooted($name)

    $dotenv_added_vars = @{}      # a special var that tells us what we added
    $dotenv_overwritte_vars = @{} # a special var that tells us what we've overwritten

    $fileslist = @()

    $dir = ( Get-Location | Select-Object -ExpandProperty Path )
    do {
        if ( $env -ne "") {
            $fullnameenv = if ($isNameAbsolute) { $nameenv } Else { Join-Path $dir $nameenv }
            if (Test-Path $fullnameenv) {
                $fileslist = , $fullnameenv + $fileslist
            }
        }

        $fullname = if ($isNameAbsolute) { $name } Else { Join-Path $dir $name }
        if (Test-Path $fullname) {
            $fileslist = , $fullname + $fileslist
        }

        # exit if not search up
        # no hierarchical search if absolute env name is given
        if (-not $up -or $isNameAbsolute ) { break }

        # found something, stop searching
        if ( $fileslist.Count -ne 0 ) { break }

        $dir = Split-Path $dir -Parent
    } while ($dir -ne "")

    if (  $fileslist.Count -eq 0 ) {
        Write-Verbose "no env file found"
    }
    else {
        $count = $fileslist.Count
        Write-Verbose "found $count env files:"
        $fileslist | ForEach-Object { Write-Verbose "`t$_" }
    }

    foreach ( $file in $fileslist) {

        Write-Verbose "### processing file: $file"
        $content = Get-Content $file -ErrorAction SilentlyContinue # if i doesn't exist, forget it

        $linecursor = 1
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

                if ( $eq -eq -1) {
                    Write-Error "File $file : NO assignment operator in line $linecursor. Syntax correct?"
                }
                else {
                    #Write-Verbose "Found an assignment operator at position $eq in a string of length $ln on line $linecursor"

                    $key = $line.Substring(0, $eq).trim()
                    $value = $line.substring($fq, $line.Length - $fq).trim()
                    Write-Verbose "Found '$key' with value '$value'"

                    if ($value -match "`'|`"") {
                        Write-Verbose "`tQuoted value found, trimming quotes"
                        $value = $value.trim('"').trim("'")
                        Write-Verbose "`tValue is now '$value'"
                    }

                    # if set by previous env file, remove  ...
                    if ( $dotenv_added_vars.ContainsKey($key) ) {
                        Write-Verbose "Overwriting already set DotEnv '$key' with value '$value'"
                        # overwrite because new content comes from a different .env.<> file
                        [System.Environment]::SetEnvironmentVariable($key, $value)
                        $dotenv_added_vars[$key] = $value
                    }
                    elseif ( -not ( Test-Path env:\$key ) -or $Force) {
                        # if env not already set or Force is given

                        if ( Test-Path env:\$key ) {
                            # save only orignal value == when overwritte the first time
                            if ( -not $dotenv_added_vars.ContainsKey($key) ) {
                                Write-Verbose "Saving env variable '$key=$value'"
                                $value_old = [System.Environment]::GetEnvironmentVariable($key)
                                $dotenv_overwritte_vars[$key] = $value_old
                            }
                        }

                        Write-Verbose "Setting DotEnv '$key' with value '$value'"
                        [System.Environment]::SetEnvironmentVariable($key, $value)
                        # set add new value
                        $dotenv_added_vars[$key] = $value
                    }
                    else {
                        Write-Verbose "ignore '$key', already set in original environment"
                    }
                }
            }
            $linecursor++
        }
    }

    $env:dotenv_overwritten_vars = ($dotenv_overwritte_vars.keys -join (","))
    $env:dotenv_added_vars = ($dotenv_added_vars.keys -join (","))

    if ($PassThru) {
        Write-Verbose "PassThru was specified, returning the array of found vars"
        return @{ added = $dotenv_added_vars
            overwritten = $dotenv_overwritte_vars
        }
    }
}
