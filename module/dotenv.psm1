Get-ChildItem $PSScriptRoot\functions -Filter '*.ps1' -Recurse |
    Foreach-Object { . $_.FullName }
