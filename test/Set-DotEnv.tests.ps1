Describe 'Set-DotEnv' {
    BeforeAll {
        . $PSScriptRoot/../module/functions/Set-DotEnv.ps1
        Push-Location $PSScriptRoot
    }

    BeforeEach {
        $script:originalEnv = Get-ChildItem env:\
    }

    Context 'Given the -PassThru switch is set' {
        It 'Returns the value of envvars that did not previously exist in the "Added" section' {
            $env:NEWENV = ''
            'NEWENV=newenv' | Set-Content TestDrive:\.env
            $vars = Set-DotEnv -Path TestDrive:\.env -PassThru
            $env:NEWENV | Should -Be 'newenv'
            $vars.Added.NEWENV | Should -Be 'newenv'
        }
    }

    Context 'Given the -PassThru and -Force switches are set' {
        It 'Returns the previous value of envvars that did already exist in the "Overwritten" section' {
            $env:OLDENV = 'oldenv'
            'OLDENV=newenv' | Set-Content TestDrive:\.env
            $vars = Set-DotEnv -Path TestDrive:\.env -PassThru -Force
            $env:OLDENV | Should -Be 'newenv'
            $vars.Overwritten.OLDENV | Should -Be 'oldenv'
        }
    }

    Context 'Given no specific parameters' {
        It 'does not overwrite already existing envvars' {
            $env:OLDENV = 'oldenv'
            'OLDENV=newenv' | Set-Content TestDrive:\.env
            Set-DotEnv -Path TestDrive:\.env
            $env:OLDENV | Should -Be 'oldenv'
        }
        It 'BASIC=basic becomes $env:BASIC = "basic"' {
            Set-DotEnv
            $env:BASIC | Should -Be 'basic'
        }
        It 'empty lines are skipped' {
            '',
            '    ' | Set-Content TestDrive:\.env
            { Set-DotEnv -Path TestDrive:\.env -ErrorAction Stop } | Should -Not -Throw
            Get-ChildItem Env:\ | Where-Object { $script:originalEnv -notcontains $_ } | Should -Be -Empty
        }
        It 'lines beginning with # are treated as comments' {
            '# this is a comment',
            '#this is another comment',
            '    # this is an indented comment' | Set-Content TestDrive:\.env
            { Set-DotEnv -Path TestDrive:\.env -ErrorAction Stop } | Should -Not -Throw
            Get-ChildItem Env:\ | Where-Object { $script:originalEnv -notcontains $_ } | Should -Be -Empty
        }
        # setting env variables to empty string is not possible in PowerShell
        It 'empty values become $null (EMPTY= becomes $env:EMPTY = $null)' {
            Set-DotEnv
            $env:EMPTY | Should -Be $null
        }
        It 'inner quotes are maintained (think JSON) (JSON={"foo": "bar"} becomes $env:JSON = "{`"foo`": `"bar`"}")' {
            Set-DotEnv
            $env:JSON | Should -Be '{"foo": "bar"}'
        }
        It 'whitespace is removed from both ends of unquoted values (FOO= some value becomes $env:FOO = "some value")' {
            Set-DotEnv
            $env:FOO | Should -Be 'some value'
        }
        # TODO specification unclear
        It 'single and doulbe quoted values are escaped (SINGLE_QUOTE=''quoted'' becomes $env:SINGLE_QUOTE = "quoted")' -Pending {
            Set-DotEnv
            $env:SINGLE_QUOTE | Should -Be "'quoted'"
            $env:DOUBLE_QUOTE | Should -Be '"quoted"'
        }
        It 'single and double quoted values maintain whitespace from both ends (FOO='' some value '' becomes $env:FOO = " some value ")' {
            Set-DotEnv
            $env:SINGLE_QUOTE_WHITESPACE | Should -Be ' some value '
            $env:DOUBLE_QUOTE_WHITESPACE | Should -Be ' some value '
        }
        It 'double quoted values expand new lines (MULTILINE="new\nline" becomes $env:MULTILINE = "new`nline"' {
            Set-DotEnv
            $env:MULTILINE | Should -Be "new`nline"
        }
        It 'can handle values with equals signs that are quoted' {
            Set-DotEnv
            $env:QUOTED_EQUALS | Should -Be "this=value=has=equals=signs=in=it"
        }
    }

    AfterEach {
        Get-ChildItem env:\ | Where-Object { $script:originalEnv -notcontains $_ } | Remove-Item
    }

    AfterAll {
        Pop-Location
    }
}

