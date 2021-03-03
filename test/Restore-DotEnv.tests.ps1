Describe 'Set-DotEnv' {
    BeforeAll {
        . $PSScriptRoot/../module/dotenv/functions/Restore-DotEnv.ps1
    }

    BeforeEach {
        $script:originalEnv = Get-ChildItem env:\
    }

    Context 'Given the output of Set-DotEnv -PassThru' {
        It 'removes added EnvVars' {
            $env:ADDED = 'added'
            [PSCustomObject]@{
                Added       = @{
                    ADDED = 'added'
                }
                Overwritten = @{}
            } | Restore-DotEnv
            $env:ADDED | Should -BeNullOrEmpty
        }
        It 'restores overwritten EnvVars to their previous value' {
            $env:OVERWRITTEN = 'custom'
            [PSCustomObject]@{
                Added       = @{ }
                Overwritten = @{
                    OVERWRITTEN = 'previous'
                }
            } | Restore-DotEnv
            $env:OVERWRITTEN | Should -Be 'previous'
        }
    }

    AfterEach {
        Get-ChildItem env:\ | Where-Object { $script:originalEnv -notcontains $_ } | Remove-Item
    }
}
