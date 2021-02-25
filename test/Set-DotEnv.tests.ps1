Describe 'Set-DotEnv' {
    BeforeAll {
        . $PSScriptRoot/../module/functions/Set-DotEnv.ps1
        Push-Location $PSScriptRoot
    }

    BeforeEach {
        $script:originalEnv = Get-ChildItem env:\
    }

    Context "Given the -PassThru switch is set" {
        It "Returns that value of APP_ENV, which is 'staging' in the 'added' section" {
            $vars = Set-DotEnv -PassThru
            $vars.added.APP_ENV | Should -Be "staging"
        }
    }

    Context "Given no parameters are given" {
        It "Finds the value of APP_ENV, which is 'staging'" {
            Set-DotEnv
            $env:APP_ENV | Should -Be "staging"
        }

        It "ignores comments" {
            # how to test this?
        }

        It "Can handle values with equals signs that are single quoted" {
            Set-DotEnv
            $env:QUOTED_TEST_VALUE | Should -Be "this=value=has=equals=signs=in=it"
        }

        It "Can handle double-quoted strings" {
            Set-DotEnv
            $env:QUOTED_AND_SPACED | Should -be "this=value has both=equals=and spaces"
        }
    }

    AfterEach {
        Get-ChildItem env:\ | Where-Object { $script:originalEnv -notcontains $_ } | Remove-Item
    }

    AfterAll {
        Pop-Location
    }
}

