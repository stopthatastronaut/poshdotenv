Get-ChildItem $PSScriptRoot\functions -Filter '*.ps1' -Recurse |
    ForEach-Object { . $_.FullName }

New-Alias -Name 'Set-DotEnv' -Value 'Push-DotEnv'
New-Alias -Name 'Remove-DotEnv' -Value 'Pop-DotEnv'
