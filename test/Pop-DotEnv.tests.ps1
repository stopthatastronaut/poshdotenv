Describe 'Pop-DotEnv' {
    BeforeAll {
        . $PSScriptRoot/../module/dotenv/functions/Pop-DotEnv.ps1
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
            Pop-DotEnv
            $env:DID_NOT_EXIST | Should -BeNullOrEmpty
            $env:WAS_OVERWRITTEN | Should -Be 'previous'
        }
    }

    AfterEach {
        Get-ChildItem env:\ | Where-Object { $script:originalEnv -notcontains $_ } | Remove-Item
    }
}
