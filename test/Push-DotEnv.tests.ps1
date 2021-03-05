Describe 'Push-DotEnv' {
    BeforeAll {
        . $PSScriptRoot/../module/dotenv/functions/Push-DotEnv.ps1
        Push-Location $PSScriptRoot
    }

    BeforeEach {
        $script:originalEnv = Get-ChildItem env:\
    }

    Context 'Given an explicit .env file path with the -Path parameter' {
        It 'Reports an error if the file does not exist' {
            { Push-DotEnv -Path TestDrive:\.env -ErrorAction Stop } | Should -Throw
        }
    }

    Context 'Given that no path is provided' {
        BeforeAll {
            Push-Location TestDrive:\
        }
        It 'uses the default ".env"' {
            $env:NEWENV = ''
            'NEWENV=newenv' | Set-Content TestDrive:\.env
            $vars = Push-DotEnv -PassThru
            $env:NEWENV | Should -Be 'newenv'
            $vars.Keys | Should -Contain 'NEWENV'
            $vars.NEWENV | Should -BeNullOrEmpty
        }
        AfterAll {
            Pop-Location
        }
    }

    Context 'Given the -PassThru switch is set' {
        It 'Returns the value of envvars that did not previously exist' {
            $env:NEWENV = ''
            'NEWENV=newenv' | Set-Content TestDrive:\.env
            $vars = Push-DotEnv -Path TestDrive:\.env -PassThru
            $env:NEWENV | Should -Be 'newenv'
            $vars.Keys | Should -Contain 'NEWENV'
            $vars.NEWENV | Should -BeNullOrEmpty
        }
    }

    Context 'Given the -PassThru and -AllowClobber switches are set' {
        It 'Returns the previous value of envvars that did already exist and were overwritten' {
            $env:OLDENV = 'oldenv'
            'OLDENV=newenv' | Set-Content TestDrive:\.env
            $vars = Push-DotEnv -Path TestDrive:\.env -PassThru -AllowClobber
            $env:OLDENV | Should -Be 'newenv'
            $vars.OLDENV | Should -Be 'oldenv'
        }
    }

    Context 'Given no specific parameters' {
        It 'does not overwrite already existing envvars' {
            $env:OLDENV = 'oldenv'
            'OLDENV=newenv' | Set-Content TestDrive:\.env
            Push-DotEnv -Path TestDrive:\.env
            $env:OLDENV | Should -Be 'oldenv'
        }
        It 'BASIC=basic becomes $env:BASIC = "basic"' {
            Push-DotEnv
            $env:BASIC | Should -Be 'basic'
        }
        It 'empty lines are skipped' {
            '',
            '    ' | Set-Content TestDrive:\.env
            { Push-DotEnv -Path TestDrive:\.env -ErrorAction Stop } | Should -Not -Throw
            Get-ChildItem Env:\ | Where-Object { $script:originalEnv -notcontains $_ -and $_.Name -ne 'DOTENV_PREVIOUS' } | Should -BeNullOrEmpty
        }
        It 'lines beginning with # are treated as comments' {
            '# this is a comment',
            '#this is another comment',
            '    # this is an indented comment' | Set-Content TestDrive:\.env
            { Push-DotEnv -Path TestDrive:\.env -ErrorAction Stop } | Should -Not -Throw
            Get-ChildItem Env:\ | Where-Object { $script:originalEnv -notcontains $_ -and $_.Name -ne 'DOTENV_PREVIOUS' } | Should -BeNullOrEmpty
        }
        # setting env variables to empty string is not possible in PowerShell
        It 'empty values become $null (EMPTY= becomes $env:EMPTY = $null)' {
            Push-DotEnv
            $env:EMPTY | Should -Be $null
        }
        It 'inner quotes are maintained (think JSON) (JSON={"foo": "bar"} becomes $env:JSON = "{`"foo`": `"bar`"}")' {
            Push-DotEnv
            $env:JSON | Should -Be '{"foo": "bar"}'
        }
        It 'whitespace is removed from both ends of unquoted values (FOO= some value becomes $env:FOO = "some value")' {
            Push-DotEnv
            $env:FOO | Should -Be 'some value'
        }
        # TODO specification unclear
        It 'single and doulbe quoted values are escaped (SINGLE_QUOTE=''quoted'' becomes $env:SINGLE_QUOTE = "quoted")' -Pending {
            Push-DotEnv
            $env:SINGLE_QUOTE | Should -Be "'quoted'"
            $env:DOUBLE_QUOTE | Should -Be '"quoted"'
        }
        It 'single and double quoted values maintain whitespace from both ends (FOO='' some value '' becomes $env:FOO = " some value ")' {
            Push-DotEnv
            $env:SINGLE_QUOTE_WHITESPACE | Should -Be ' some value '
            $env:DOUBLE_QUOTE_WHITESPACE | Should -Be ' some value '
        }
        It 'double quoted values expand new lines (MULTILINE="new\nline" becomes $env:MULTILINE = "new`nline"' {
            Push-DotEnv
            $env:MULTILINE | Should -Be "new`nline"
        }
        It 'can handle values with equals signs that are quoted' {
            Push-DotEnv
            $env:QUOTED_EQUALS | Should -Be "this=value=has=equals=signs=in=it"
        }
    }
    Context 'Given a specific environment is specified with the -Environment parameter' {
        BeforeAll {
            Push-Location TestDrive:\
        }
        It 'gives precedence to environment-specific .env files (e.g. .env.prod)' {
            'ENVIRONMENT=default' | Set-Content TestDrive:\.env
            'ENVIRONMENT=prod' | Set-Content TestDrive:\.env.prod
            Push-DotEnv -Environment 'prod'
            $env:ENVIRONMENT | Should -Be 'prod'
        }
        AfterAll {
            Pop-Location
        }
    }
    Context 'Given the -Environment and -AllowClobber parameters are set' {
        BeforeAll {
            Push-Location TestDrive:\
        }
        It 'gives precedence to environment-specific .env files (e.g. .env.prod) while saving the original value for restore' {
            $env:ENVIRONMENT = 'previous'
            'ENVIRONMENT=default' | Set-Content TestDrive:\.env
            'ENVIRONMENT=prod' | Set-Content TestDrive:\.env.prod
            $original = Push-DotEnv -Environment 'prod' -AllowClobber -PassThru
            $env:ENVIRONMENT | Should -Be 'prod'
            $original.ENVIRONMENT | Should -Be 'previous'
        }
        AfterAll {
            Pop-Location
        }
    }

    Context 'Given a -Name and an empty -Environment' {
        BeforeAll {
            Push-Location TestDrive:\
            'ENVIRONMENT=default' | Set-Content TestDrive:\test.env
            'ENVIRONMENT=empty' | Set-Content TestDrive:\test.env.
        }
        It 'only reads the named file and no other env file (e.g. only "test.env" and not "test.env.")' {
            Push-DotEnv -Name test.env -Environment ''
            $env:ENVIRONMENT | Should -Be 'default'
        }
        AfterAll {
            Pop-Location
        }
    }

    Context 'Given a -Name and an "$null" for -Environment' {
        BeforeAll {
            Push-Location TestDrive:\
            'ENVIRONMENT=default' | Set-Content TestDrive:\test.env
            'ENVIRONMENT=empty' | Set-Content TestDrive:\test.env.
        }
        It 'only reads the named file and no other env file (e.g. only "test.env" and not "test.env.")' {
            Push-DotEnv -Name test.env -Environment $null
            $env:ENVIRONMENT | Should -Be 'default'
        }
        AfterAll {
            Pop-Location
        }
    }

    Context 'Given a -Name and an -Environment' {
        BeforeAll {
            Push-Location TestDrive:\
            'ENVIRONMENT=default' | Set-Content TestDrive:\test.env
            'ENVIRONMENT=prod' | Set-Content TestDrive:\test.env.prod
        }
        It 'searches for the right file and gives precedence to environment-specific .env files (e.g. test.env.prod)' {
            Push-DotEnv -Name test.env -Environment 'prod'
            $env:ENVIRONMENT | Should -Be 'prod'
        }
        AfterAll {
            Pop-Location
        }
    }

    Context 'Given a -Name and an -Environment with env files in a parent directory' {
        BeforeAll {
            'ENVIRONMENT=default' | Set-Content TestDrive:\test.env
            'ENVIRONMENT=prod' | Set-Content TestDrive:\test.env.prod
            New-Item "TestDrive:\subdir" -ItemType Directory
            Push-Location "TestDrive:\subdir"
        }
        It 'searches for the right files when searching "-Up" and give precedence to environment specific file in the same folder' {
            Push-DotEnv -Name test.env -Environment 'prod' -Up
            $env:ENVIRONMENT | Should -Be 'prod'
        }
        AfterAll {
            Pop-Location
        }
    }

    AfterEach {
        Get-ChildItem env:\ | Where-Object { $script:originalEnv -notcontains $_ } | Remove-Item
    }

    AfterAll {
        Pop-Location
    }
}

