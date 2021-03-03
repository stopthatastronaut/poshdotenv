Describe 'Set-DotEnv' {
    BeforeAll {
        . $PSScriptRoot/../module/dotenv/functions/Restore-DotEnv.ps1
    }

    BeforeEach {
        $script:originalEnv = Get-ChildItem env:\
    }

    Context 'Given no input' {
        It 'uses $env:DOTENV_PREVIOUS to restore previous EnvVars' {
            $env:DOTENV_PREVIOUS = @{
                DID_NOT_EXIST   = $null
                WAS_OVERWRITTEN = 'previous'
            } | ConvertTo-Json
            $env:DID_NOT_EXIST = 'but does now'
            $env:WAS_OVERWRITTEN = 'current'
            Restore-DotEnv
            $env:DID_NOT_EXIST | Should -BeNullOrEmpty
            $env:WAS_OVERWRITTEN | Should -Be 'previous'
        }
    }

    Context 'Given the output of Set-DotEnv -PassThru' {
        It 'removes added EnvVars' {
            $env:ADDED = 'added'
            @{
                ADDED = $null
            } | Restore-DotEnv
            $env:ADDED | Should -BeNullOrEmpty
        }
        It 'restores overwritten EnvVars to their previous value' {
            $env:OVERWRITTEN = 'custom'
            @{
                OVERWRITTEN = 'previous'
            } | Restore-DotEnv
            $env:OVERWRITTEN | Should -Be 'previous'
        }
    }

    AfterEach {
        Get-ChildItem env:\ | Where-Object { $script:originalEnv -notcontains $_ } | Remove-Item
    }
}
