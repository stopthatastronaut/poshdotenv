$here = Split-Path -Parent $MyInvocation.MyCommand.Path

# first, move the env file to the root temporarily
Copy-Item $here/.env ./.env -force -verbose
# import the module
# Import-Module ./module/dotenv/dotenv.psm1

Describe "Syntax and linting" {
    Context "PSScriptAnalyzer" {
        It "Should have Zero script analyzer issues" {
            Invoke-ScriptAnalyzer ./ -Recurse -ReportSummary | Measure-Object | Select-Object -ExpandProperty Count | Should -be 0
        }
    }
}

Describe "The module's functionality" {

    Context "Doing a returnvars" {
        It "Finds the value of APP_ENV, which is 'staging'" {

            Import-Module ./module/dotenv/dotenv.psm1

            $vars = Set-DotEnv -returnvars

            $vars.APP_ENV | Should -Be "staging"

            Remove-Module dotenv -Verbose
        }
    }

    Context "Default Usage" {

        Import-Module ./module/dotenv/dotenv.psm1
        Set-DotEnv

        It "Finds the value of APP_ENV, which is 'staging'" {
            $env:APP_ENV | Should -Be "staging"
        }

        It "ignores comments" {
            # how to test this?
        }

        It "Can handle values with equals signs that are single quoted" {
            $env:QUOTED_TEST_VALUE | Should -Be "this=value=has=equals=signs=in=it"
        }

        It "Can handle double-quoted strings" {
            $env:QUOTED_AND_SPACED | Should -be "this=value has both=equals=and spaces"
        }

        Remove-DotEnv

        Remove-Module dotenv -verbose


        Context "Testing Remove-DotEnv" {

        }
    }
}



# remove the module
Remove-Module dotenv -force -ErrorAction SilentlyContinue -verbose
# remove the temporary env file from the root
# Remove-Item -Path ./.env -force