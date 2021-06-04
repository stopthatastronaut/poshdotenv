Describe "The module" {
    It "has zero script analyzer issues" {
        Invoke-ScriptAnalyzer "$PSScriptRoot/.." -Recurse -ReportSummary |
            ForEach-Object { $_ | Out-String | Write-Warning; $_ } |
            Measure-Object |
            Select-Object -ExpandProperty Count |
            Should -be 0
    }
}
