$(Get-ChildItem $PSScriptRoot -Recurse ).where({ $([regex]::Matches($_.Name, "^.*\.(h|cpp|ps1)$"))}).ForEach({Set-Content $_.FullName -Encoding utf8 -Value $(Get-Content $_.FullName); });
