Describe "The module" {
    It "Should have Zero script analyzer issues" {
        Invoke-ScriptAnalyzer "$PSScriptRoot/.." -Recurse -ReportSummary |
            ForEach-Object { $_ | Out-String | Write-Warning; $_ } |
            Measure-Object |
            Select-Object -ExpandProperty Count |
            Should -be 0
    }
}
